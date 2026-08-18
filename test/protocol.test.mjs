import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { cp, mkdtemp, readFile, writeFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

import { zipSync } from "fflate";

import { compareSemver } from "../scripts/lib/common.mjs";
import { buildRelease } from "../scripts/lib/release.mjs";
import { inspectZip } from "../scripts/lib/zip.mjs";
import { updateMarketplace } from "../scripts/lib/marketplace.mjs";
import {
  signMarketplace,
  verifyMarketplaceSignature,
} from "../scripts/lib/signing.mjs";
import {
  validateDocument,
  validatePublishedMarketplace,
  validateReleaseArtifact,
} from "../scripts/lib/validation.mjs";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const fixtureVersion = path.join(
  root,
  "protocol/fixtures/valid/example-specialist/versions/1.0.0",
);
const testKeyPath = path.join(
  root,
  "protocol/fixtures/keys/test-only-private-key.pk8.b64",
);
const snakeCaseSpecialist = {
  name: "FIXTURE_SPECIALIST",
  display_name: "Fixture Specialist",
  description: "Non-publishable protocol fixture",
  system_prompt: "Help verify the Marketplace protocol.",
  skill_ids: ["example-skill"],
  connector_ids: ["example-connector"],
};

const emptyMarketplace = {
  schema_version: 1,
  revision: "0",
  marketplace: {
    id: "openscience",
    name: "OpenScience Specialist Marketplace",
  },
  specialists: [],
};

test("SemVer comparison follows numeric and prerelease precedence", () => {
  assert.equal(compareSemver("1.0.0-alpha", "1.0.0"), -1);
  assert.equal(compareSemver("1.0.0-alpha.10", "1.0.0-alpha.2"), 1);
  assert.equal(compareSemver("1.0.0-alpha-b", "1.0.0-alpha-a"), 1);
  assert.equal(
    compareSemver("999999999999999999999.0.0", "999999999999999999998.0.0"),
    1,
  );
});

test("strict schemas reject unknown fields", async () => {
  const invalid = JSON.parse(
    await readFile(
      path.join(
        root,
        "protocol/fixtures/invalid/marketplace-unknown-field.json",
      ),
      "utf8",
    ),
  );
  assert.throws(
    () => validateDocument("marketplace", invalid),
    /additionalProperties/,
  );

  const invalidSemver = structuredClone(emptyMarketplace);
  invalidSemver.specialists = [
    {
      id: "example",
      display_name: "Example",
      summary: "Example",
      publisher: {
        id: "example",
        name: "Example",
        url: "https://example.com",
      },
      latest: {
        version: "1.0.0-01",
        release: {
          path: "releases/example/1.0.0-01.json",
          sha256: "0".repeat(64),
        },
      },
    },
  ];
  assert.throws(
    () => validateDocument("marketplace", invalidSemver),
    /pattern/,
  );
});

test("release builds are deterministic and App-export compatible", async () => {
  const first = await mkdtemp(path.join(os.tmpdir(), "marketplace-build-a-"));
  const second = await mkdtemp(path.join(os.tmpdir(), "marketplace-build-b-"));

  const a = await buildRelease({
    specialistId: "fixture-specialist",
    version: "1.0.0",
    versionDirectory: fixtureVersion,
    outputDirectory: first,
  });
  const b = await buildRelease({
    specialistId: "fixture-specialist",
    version: "1.0.0",
    versionDirectory: fixtureVersion,
    outputDirectory: second,
  });

  assert.deepEqual(await readFile(a.zipPath), await readFile(b.zipPath));
  assert.deepEqual(
    await readFile(a.descriptorPath),
    await readFile(b.descriptorPath),
  );
  assert.equal(a.descriptor.artifact.sha256, b.descriptor.artifact.sha256);
  assert.equal(
    a.descriptor.artifact.path,
    "specialists/fixture-specialist/1.0.0/fixture-specialist-1.0.0.zip",
  );
  assert.equal(
    a.descriptor.artifact.github_release.tag,
    "fixture-specialist-v1.0.0",
  );
  assert.equal(
    a.marketplaceEntry.latest.release.path,
    "releases/fixture-specialist/1.0.0.json",
  );
  assert.equal(a.descriptor.defaults.skill_ids[0], "example-skill");
  assert.equal(a.descriptor.defaults.connector_ids[0], "example-connector");
  const archive = inspectZip(await readFile(a.zipPath));
  assert.deepEqual(
    Object.keys(
      JSON.parse(archive.entries.get("specialist.json").toString("utf8")),
    ),
    ["name", "description", "system_prompt", "skill_ids", "connector_ids"],
  );
});

test("release building accepts the Specialist package v1 snake_case contract", async () => {
  const versionDirectory = await mkdtemp(
    path.join(os.tmpdir(), "marketplace-snake-case-specialist-"),
  );
  await cp(fixtureVersion, versionDirectory, { recursive: true });
  const specialistPath = path.join(versionDirectory, "package/specialist.json");
  await writeFile(
    specialistPath,
    `${JSON.stringify(snakeCaseSpecialist, null, 2)}\n`,
  );

  const built = await buildRelease({
    specialistId: "fixture-specialist",
    version: "1.0.0",
    versionDirectory,
    outputDirectory: path.join(versionDirectory, "out"),
  });
  assert.deepEqual(built.descriptor.defaults, {
    skill_ids: ["example-skill"],
    connector_ids: ["example-connector"],
  });
});

test("release building rejects camelCase Specialist package fields", async () => {
  const versionDirectory = await mkdtemp(
    path.join(os.tmpdir(), "marketplace-camel-case-specialist-"),
  );
  await cp(fixtureVersion, versionDirectory, { recursive: true });
  const specialistPath = path.join(versionDirectory, "package/specialist.json");
  await writeFile(
    specialistPath,
    `${JSON.stringify(
      {
        name: "FIXTURE_SPECIALIST",
        description: "Non-publishable protocol fixture",
        systemPrompt: "Help verify the Marketplace protocol.",
        skillIds: ["example-skill"],
        connectorIds: ["example-connector"],
      },
      null,
      2,
    )}\n`,
  );

  await assert.rejects(
    buildRelease({
      specialistId: "fixture-specialist",
      version: "1.0.0",
      versionDirectory,
      outputDirectory: path.join(versionDirectory, "out"),
      publishedHistory: true,
    }),
    /specialist\.json contains unknown field: systemPrompt/,
  );
});

test("release building validates optional Specialist display_name", async () => {
  const versionDirectory = await mkdtemp(
    path.join(os.tmpdir(), "marketplace-specialist-display-name-"),
  );
  await cp(fixtureVersion, versionDirectory, { recursive: true });
  const specialistPath = path.join(versionDirectory, "package/specialist.json");
  await writeFile(
    specialistPath,
    `${JSON.stringify(
      { ...snakeCaseSpecialist, display_name: 42 },
      null,
      2,
    )}\n`,
  );

  await assert.rejects(
    buildRelease({
      specialistId: "fixture-specialist",
      version: "1.0.0",
      versionDirectory,
      outputDirectory: path.join(versionDirectory, "out"),
    }),
    /specialist\.json display_name must be a non-empty string/,
  );
});

test("release building requires a non-empty snake_case system_prompt", async () => {
  const versionDirectory = await mkdtemp(
    path.join(os.tmpdir(), "marketplace-specialist-system-prompt-"),
  );
  await cp(fixtureVersion, versionDirectory, { recursive: true });
  const specialistPath = path.join(versionDirectory, "package/specialist.json");
  await writeFile(
    specialistPath,
    `${JSON.stringify(
      { ...snakeCaseSpecialist, system_prompt: " " },
      null,
      2,
    )}\n`,
  );

  await assert.rejects(
    buildRelease({
      specialistId: "fixture-specialist",
      version: "1.0.0",
      versionDirectory,
      outputDirectory: path.join(versionDirectory, "out"),
    }),
    /specialist\.json system_prompt must be a non-empty string/,
  );
});

test("release building rejects invalid or duplicate snake_case reference arrays", async () => {
  for (const [specialist, message] of [
    [
      { ...snakeCaseSpecialist, skill_ids: "example-skill" },
      /specialist\.json skill_ids must be an array/,
    ],
    [
      {
        ...snakeCaseSpecialist,
        connector_ids: ["example-connector", "example-connector"],
      },
      /duplicate specialist\.json connector_ids entry/,
    ],
  ]) {
    const versionDirectory = await mkdtemp(
      path.join(os.tmpdir(), "marketplace-specialist-references-"),
    );
    await cp(fixtureVersion, versionDirectory, { recursive: true });
    await writeFile(
      path.join(versionDirectory, "package/specialist.json"),
      `${JSON.stringify(specialist, null, 2)}\n`,
    );
    await assert.rejects(
      buildRelease({
        specialistId: "fixture-specialist",
        version: "1.0.0",
        versionDirectory,
        outputDirectory: path.join(versionDirectory, "out"),
      }),
      message,
    );
  }
});

test("ZIP inspection rejects traversal before extraction", () => {
  const archive = zipSync({ "../escape.txt": new TextEncoder().encode("bad") });
  assert.throws(() => inspectZip(archive), /unsafe ZIP path/);
});

test("ZIP inspection rejects unsafe names, types, encryption, methods, and resource abuse", () => {
  const text = new TextEncoder().encode("content");
  for (const name of ["/absolute.txt", "folder\\escape.txt"]) {
    assert.throws(
      () => inspectZip(zipSync({ [name]: text })),
      /unsafe ZIP path/,
    );
  }
  assert.throws(
    () =>
      inspectZip(
        zipSync({
          "caf\u00e9.txt": text,
          "cafe\u0301.txt": text,
        }),
      ),
    /duplicate normalized ZIP path/,
  );

  const encrypted = Buffer.from(zipSync({ "file.txt": text }));
  const central = encrypted.indexOf(Buffer.from([0x50, 0x4b, 0x01, 0x02]));
  encrypted.writeUInt16LE(encrypted.readUInt16LE(central + 8) | 1, central + 8);
  assert.throws(() => inspectZip(encrypted), /encrypted ZIP entries/);

  const unsupported = Buffer.from(zipSync({ "file.txt": text }));
  const unsupportedCentral = unsupported.indexOf(
    Buffer.from([0x50, 0x4b, 0x01, 0x02]),
  );
  unsupported.writeUInt16LE(99, unsupportedCentral + 10);
  assert.throws(() => inspectZip(unsupported), /unsupported ZIP compression/);

  const symlink = Buffer.from(zipSync({ "link.txt": text }));
  const symlinkCentral = symlink.indexOf(Buffer.from([0x50, 0x4b, 0x01, 0x02]));
  symlink.writeUInt16LE((3 << 8) | 20, symlinkCentral + 4);
  symlink.writeUInt32LE(0xa1ff0000, symlinkCentral + 38);
  assert.throws(() => inspectZip(symlink), /symlinks and special ZIP entries/);

  const compact = zipSync({ "large.txt": new Uint8Array(1_024) });
  assert.throws(() => inspectZip(compact, { maxFiles: 0 }), /too many files/);
  assert.throws(
    () => inspectZip(compact, { maxFileBytes: 100 }),
    /entry is too large/,
  );
  assert.throws(
    () =>
      inspectZip(compact, {
        maxExpandedBytes: 100,
        maxCompressionRatio: Number.POSITIVE_INFINITY,
      }),
    /expands beyond/,
  );
  assert.throws(
    () => inspectZip(compact, { maxCompressionRatio: 2 }),
    /unsafe ZIP compression ratio/,
  );
});

test("signatures cover the exact marketplace bytes", async () => {
  const bytes = Buffer.from(`${JSON.stringify(emptyMarketplace, null, 2)}\n`);
  const privateKeyPkcs8Base64 = (await readFile(testKeyPath, "utf8")).trim();
  const signature = signMarketplace({
    marketplaceBytes: bytes,
    privateKeyPkcs8Base64,
    keyId: "openscience-test-only",
  });
  assert.doesNotMatch(
    JSON.stringify(signature),
    new RegExp(privateKeyPkcs8Base64),
  );

  assert.equal(
    verifyMarketplaceSignature({ marketplaceBytes: bytes, signature }),
    true,
  );

  const mutated = Buffer.from(bytes);
  mutated[0] ^= 1;
  assert.equal(
    verifyMarketplaceSignature({ marketplaceBytes: mutated, signature }),
    false,
  );
});

test("published validation follows root digests through the exact ZIP", async () => {
  const output = await mkdtemp(
    path.join(os.tmpdir(), "marketplace-published-"),
  );
  const built = await buildRelease({
    specialistId: "fixture-specialist",
    version: "1.0.0",
    versionDirectory: fixtureVersion,
    outputDirectory: output,
  });
  let marketplace = updateMarketplace({
    baseMarketplace: emptyMarketplace,
    entry: built.marketplaceEntry,
    releaseDescriptorBytes: await readFile(built.descriptorPath),
  });
  const secondFixture = await mkdtemp(
    path.join(os.tmpdir(), "marketplace-second-specialist-"),
  );
  await cp(fixtureVersion, secondFixture, { recursive: true });
  const secondManifestPath = path.join(secondFixture, "package/manifest.json");
  const secondManifest = JSON.parse(await readFile(secondManifestPath, "utf8"));
  secondManifest.id = "second-fixture";
  await writeFile(
    secondManifestPath,
    `${JSON.stringify(secondManifest, null, 2)}\n`,
  );
  const second = await buildRelease({
    specialistId: "second-fixture",
    version: "1.0.0",
    versionDirectory: secondFixture,
    outputDirectory: output,
  });
  marketplace = updateMarketplace({
    baseMarketplace: marketplace,
    entry: second.marketplaceEntry,
    releaseDescriptorBytes: await readFile(second.descriptorPath),
  });
  const marketplacePath = path.join(output, "marketplace.json");
  const signaturePath = path.join(output, "marketplace.json.sig");
  const marketplaceBytes = Buffer.from(
    `${JSON.stringify(marketplace, null, 2)}\n`,
  );
  const privateKeyPkcs8Base64 = (await readFile(testKeyPath, "utf8")).trim();
  const signature = signMarketplace({
    marketplaceBytes,
    privateKeyPkcs8Base64,
    keyId: "openscience-test-only",
  });
  await writeFile(marketplacePath, marketplaceBytes);
  await writeFile(signaturePath, `${JSON.stringify(signature, null, 2)}\n`);

  const result = await validatePublishedMarketplace({
    marketplacePath,
    signaturePath,
    rootDirectory: output,
  });
  assert.equal(result.specialistCount, 2);
  assert.equal(result.releaseCount, 2);

  assert.throws(
    () =>
      updateMarketplace({
        baseMarketplace: marketplace,
        entry: built.marketplaceEntry,
        releaseDescriptorBytes: Buffer.from("different descriptor"),
      }),
    /published Specialist version collision/,
  );
});

test("reapplying an identical published release is idempotent", async () => {
  const output = await mkdtemp(
    path.join(os.tmpdir(), "marketplace-idempotent-update-"),
  );
  const built = await buildRelease({
    specialistId: "fixture-specialist",
    version: "1.0.0",
    versionDirectory: fixtureVersion,
    outputDirectory: output,
  });
  const descriptorBytes = await readFile(built.descriptorPath);
  const published = updateMarketplace({
    baseMarketplace: emptyMarketplace,
    entry: built.marketplaceEntry,
    releaseDescriptorBytes: descriptorBytes,
  });

  assert.deepEqual(
    updateMarketplace({
      baseMarketplace: published,
      entry: built.marketplaceEntry,
      releaseDescriptorBytes: descriptorBytes,
    }),
    published,
  );
});

test("release validation rejects digest, size, duplicate ID, and Connector contract mutations", async () => {
  const output = await mkdtemp(path.join(os.tmpdir(), "marketplace-release-"));
  const built = await buildRelease({
    specialistId: "fixture-specialist",
    version: "1.0.0",
    versionDirectory: fixtureVersion,
    outputDirectory: output,
  });

  const badDigest = structuredClone(built.descriptor);
  badDigest.artifact.sha256 = "0".repeat(64);
  await assert.rejects(
    validateReleaseArtifact({ descriptor: badDigest, rootDirectory: output }),
    /artifact SHA-256 mismatch/,
  );

  const badSize = structuredClone(built.descriptor);
  badSize.artifact.compressed_bytes += 1;
  await assert.rejects(
    validateReleaseArtifact({ descriptor: badSize, rootDirectory: output }),
    /artifact compressed size mismatch/,
  );

  const duplicateSkill = structuredClone(built.descriptor);
  duplicateSkill.skills.push(structuredClone(duplicateSkill.skills[0]));
  assert.throws(
    () => validateDocument("release", duplicateSkill),
    /duplicate Skill ID/,
  );

  const configuredConnector = structuredClone(built.descriptor);
  configuredConnector.connectors[0].command = "forbidden";
  assert.throws(
    () => validateDocument("release", configuredConnector),
    /additionalProperties/,
  );
});

test("release building rejects App package identity and default-reference drift", async () => {
  const identityFixture = await mkdtemp(
    path.join(os.tmpdir(), "marketplace-authoring-identity-"),
  );
  await cp(fixtureVersion, identityFixture, { recursive: true });
  const manifestPath = path.join(identityFixture, "package/manifest.json");
  const manifest = JSON.parse(await readFile(manifestPath, "utf8"));
  manifest.version = "2.0.0";
  await writeFile(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`);
  await assert.rejects(
    buildRelease({
      specialistId: "fixture-specialist",
      version: "1.0.0",
      versionDirectory: identityFixture,
      outputDirectory: path.join(identityFixture, "out"),
    }),
    /compatibility fields/,
  );

  const defaultFixture = await mkdtemp(
    path.join(os.tmpdir(), "marketplace-authoring-defaults-"),
  );
  await cp(fixtureVersion, defaultFixture, { recursive: true });
  const specialistPath = path.join(defaultFixture, "package/specialist.json");
  const specialist = JSON.parse(await readFile(specialistPath, "utf8"));
  specialist.connector_ids = [];
  await writeFile(specialistPath, `${JSON.stringify(specialist, null, 2)}\n`);
  await assert.rejects(
    buildRelease({
      specialistId: "fixture-specialist",
      version: "1.0.0",
      versionDirectory: defaultFixture,
      outputDirectory: path.join(defaultFixture, "out"),
    }),
    /Connector default does not match/,
  );
});

test("production signing entry point refuses the committed test-only key", async () => {
  const temporary = await mkdtemp(
    path.join(os.tmpdir(), "marketplace-signing-"),
  );
  const marketplacePath = path.join(temporary, "marketplace.json");
  await writeFile(
    marketplacePath,
    `${JSON.stringify(emptyMarketplace, null, 2)}\n`,
  );
  const privateKey = (await readFile(testKeyPath, "utf8")).trim();
  const result = spawnSync(
    process.execPath,
    [
      path.join(root, "scripts/sign-marketplace.mjs"),
      "--marketplace",
      marketplacePath,
      "--output",
      path.join(temporary, "marketplace.json.sig"),
    ],
    {
      encoding: "utf8",
      env: {
        ...process.env,
        MARKETPLACE_SIGNING_PRIVATE_KEY_PKCS8_BASE64: privateKey,
        MARKETPLACE_SIGNING_KEY_ID: "openscience-test-only",
        MARKETPLACE_EXPECTED_PUBLIC_KEY_SPKI_BASE64:
          "MCowBQYDK2VwAyEA8bHvgg7avOZlyw15XJeYzKHuYep/JoqM4IIOrRNa5hE=",
        MARKETPLACE_EXPECTED_KEY_FINGERPRINT:
          "662eac5d6d8eb26bb2c8ea13fdaf243ed17b0a3228256e9a2737b64451a8d40f",
      },
    },
  );
  assert.notEqual(result.status, 0);
  assert.match(result.stderr, /refuses the committed test-only key/);
  assert.doesNotMatch(result.stderr, new RegExp(privateKey));
});
