import assert from "node:assert/strict";
import { mkdtemp, readFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test from "node:test";

import {
  readReleaseHistory,
  validateReleaseHistory,
} from "../scripts/lib/history.mjs";
import {
  findPublishedVersionChanges,
  isMarketplaceOnlyReleaseConfigChange,
  parsePublicationSpecialistIds,
  resolvePublicationVersion,
} from "../scripts/lib/immutability.mjs";
import { buildRelease } from "../scripts/lib/release.mjs";

const fixtureVersion = path.resolve(
  "protocol/fixtures/valid/example-specialist/versions/1.0.0",
);

test("official discovery metadata uses the canonical publisher and source authors", async () => {
  const authors = {
    "aerodynamics-cfd-validator": "K-Dense Inc.",
    "astronomical-photometry-analyzer": "K-Dense Inc.",
    "atmospheric-chemistry-modeler": "K-Dense Inc.",
    "auto-research-specialist": "AIPOCH",
    "cryoem-structure-validator": "K-Dense Inc.",
    "high-throughput-dft-screener": "K-Dense Inc.",
    "neuroimaging-connectomics-architect": "K-Dense Inc.",
    "pharmacometrics-pkpd-designer": "K-Dense Inc.",
    "precision-ag-phenotyping-designer": "K-Dense Inc.",
    "synthesis-route-optimizer": "K-Dense Inc.",
  };
  for (const [specialistId, author] of Object.entries(authors)) {
    const versionsRoot = path.resolve("specialists", specialistId, "versions");
    const version =
      specialistId === "auto-research-specialist" ? "1.0.1" : "1.0.0";
    const config = JSON.parse(
      await readFile(
        path.join(versionsRoot, version, "release.config.json"),
        "utf8",
      ),
    );
    assert.deepEqual(config.marketplace.publisher, {
      id: "aipoch",
      name: "AIPOCH",
      url: "https://github.com/aipoch",
    });
    assert.equal(config.marketplace.author, author);
  }
});

test("published Specialist versions reject authoring changes", () => {
  assert.deepEqual(
    findPublishedVersionChanges({
      changedPaths: [
        "specialists/example/versions/1.0.0/package/manifest.json",
        "specialists/example/versions/2.0.0/package/manifest.json",
        "README.md",
      ],
      publishedReleasePaths: ["releases/example/1.0.0.json"],
    }),
    ["example@1.0.0"],
  );
});

test("published release configs allow only discovery metadata changes", () => {
  const before = {
    source: { repository: "https://example.com", commit: "a".repeat(40) },
    marketplace: {
      display_name: "Example",
      publisher: { id: "example", name: "Example" },
    },
    skills: [],
    connectors: [],
  };
  const after = structuredClone(before);
  after.marketplace.author = "Example Author";
  after.marketplace.publisher.name = "EXAMPLE";
  assert.equal(isMarketplaceOnlyReleaseConfigChange(before, after), true);

  const changedSource = structuredClone(after);
  changedSource.source.commit = "b".repeat(40);
  assert.equal(
    isMarketplaceOnlyReleaseConfigChange(before, changedSource),
    false,
  );

  const configPath = "specialists/example/versions/1.0.0/release.config.json";
  assert.deepEqual(
    findPublishedVersionChanges({
      changedPaths: [configPath],
      publishedReleasePaths: ["releases/example/1.0.0.json"],
      marketplaceOnlyReleaseConfigs: [configPath],
    }),
    [],
  );
  assert.deepEqual(
    findPublishedVersionChanges({
      changedPaths: [configPath],
      publishedReleasePaths: ["releases/example/1.0.0.json"],
    }),
    ["example@1.0.0"],
  );
});

test("publication selects one unpublished version and preserves retries", () => {
  assert.deepEqual(
    resolvePublicationVersion({
      specialistId: "example",
      authoredVersions: ["1.0.0", "1.1.0"],
      publishedReleasePaths: ["releases/example/1.0.0.json"],
    }),
    { version: "1.1.0", alreadyPublished: false },
  );
  assert.deepEqual(
    resolvePublicationVersion({
      specialistId: "example",
      authoredVersions: ["1.0.0", "0.9.0"],
      publishedReleasePaths: [
        "releases/example/0.9.0.json",
        "releases/example/1.0.0.json",
        "releases/other/2.0.0.json",
      ],
    }),
    { version: "1.0.0", alreadyPublished: true },
  );
  assert.throws(
    () =>
      resolvePublicationVersion({
        specialistId: "example",
        authoredVersions: ["1.0.0", "1.1.0", "2.0.0"],
        publishedReleasePaths: ["releases/example/1.0.0.json"],
      }),
    /multiple unpublished versions for example: 1\.1\.0, 2\.0\.0/,
  );
});

test("publication accepts one single or batch Specialist input", () => {
  assert.deepEqual(
    parsePublicationSpecialistIds({ specialistId: "single-specialist" }),
    ["single-specialist"],
  );
  assert.deepEqual(
    parsePublicationSpecialistIds({
      specialistIds: "second-specialist, first-specialist\nthird-specialist",
    }),
    ["first-specialist", "second-specialist", "third-specialist"],
  );
  assert.throws(() => parsePublicationSpecialistIds({}), /provide exactly one/);
  assert.throws(
    () =>
      parsePublicationSpecialistIds({
        specialistId: "one",
        specialistIds: "two",
      }),
    /provide exactly one/,
  );
  assert.throws(
    () => parsePublicationSpecialistIds({ specialistIds: "valid,invalid_" }),
    /invalid Specialist ID: invalid_/,
  );
  assert.throws(
    () =>
      parsePublicationSpecialistIds({ specialistIds: "duplicate duplicate" }),
    /duplicate Specialist ID: duplicate/,
  );
});

test("published release history includes and validates every immutable version", async () => {
  const output = await mkdtemp(
    path.join(os.tmpdir(), "marketplace-release-history-"),
  );
  await buildRelease({
    specialistId: "fixture-specialist",
    version: "1.0.0",
    versionDirectory: fixtureVersion,
    outputDirectory: output,
  });

  const history = await readReleaseHistory({ rootDirectory: output });
  assert.deepEqual(
    history.map(({ descriptor_path, tag, asset_name, path: artifactPath }) => ({
      descriptor_path,
      tag,
      asset_name,
      path: artifactPath,
    })),
    [
      {
        descriptor_path: "releases/fixture-specialist/1.0.0.json",
        tag: "fixture-specialist-v1.0.0",
        asset_name: "fixture-specialist-1.0.0.zip",
        path: "specialists/fixture-specialist/1.0.0/fixture-specialist-1.0.0.zip",
      },
    ],
  );
  assert.equal(await validateReleaseHistory({ rootDirectory: output }), 1);
});
