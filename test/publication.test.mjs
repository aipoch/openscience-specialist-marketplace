import assert from "node:assert/strict";
import { mkdtemp } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test from "node:test";

import {
  readReleaseHistory,
  validateReleaseHistory,
} from "../scripts/lib/history.mjs";
import {
  findPublishedVersionChanges,
  resolvePublicationVersion,
} from "../scripts/lib/immutability.mjs";
import { buildRelease } from "../scripts/lib/release.mjs";
import { validateReleaseArtifact } from "../scripts/lib/validation.mjs";

const fixtureVersion = path.resolve(
  "protocol/fixtures/valid/example-specialist/versions/1.0.0",
);
const legacyPublishedVersion = path.resolve(
  "specialists/auto-research-specialist/versions/1.0.0",
);

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

test("published 1.0.0 history has an isolated camelCase validation exception", async () => {
  const strictOutput = await mkdtemp(
    path.join(os.tmpdir(), "marketplace-strict-history-"),
  );
  await assert.rejects(
    buildRelease({
      specialistId: "auto-research-specialist",
      version: "1.0.0",
      versionDirectory: legacyPublishedVersion,
      outputDirectory: strictOutput,
    }),
    /specialist\.json contains unknown field: displayName/,
  );

  const historyOutput = await mkdtemp(
    path.join(os.tmpdir(), "marketplace-legacy-history-"),
  );
  const rebuilt = await buildRelease({
    specialistId: "auto-research-specialist",
    version: "1.0.0",
    versionDirectory: legacyPublishedVersion,
    outputDirectory: historyOutput,
    publishedHistory: true,
  });
  assert.equal(rebuilt.descriptor.version, "1.0.0");
  await validateReleaseArtifact({
    descriptor: rebuilt.descriptor,
    rootDirectory: historyOutput,
    publishedHistory: true,
  });
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
