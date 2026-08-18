#!/usr/bin/env node
import { mkdtemp, readdir } from "node:fs/promises";
import os from "node:os";
import path from "node:path";

import { assertExactKeys, parseArgs, readJson } from "./lib/common.mjs";
import { buildRelease } from "./lib/release.mjs";
import { validatePublishedMarketplace } from "./lib/validation.mjs";

const root = path.resolve(import.meta.dirname, "..");
const args = parseArgs(process.argv.slice(2));

async function validateAuthoring() {
  const { value: config } = await readJson(
    path.join(root, "marketplace.config.json"),
  );
  assertExactKeys(
    config,
    ["schema_version", "marketplace", "specialists"],
    "marketplace.config.json",
  );
  if (config.schema_version !== 1)
    throw new Error("marketplace.config.json schema_version must be 1");
  assertExactKeys(
    config.marketplace,
    ["id", "name"],
    "marketplace.config.json marketplace",
  );
  if (
    config.marketplace.id !== "openscience" ||
    config.marketplace.name !== "OpenScience Specialist Marketplace"
  ) {
    throw new Error(
      "marketplace.config.json contains the wrong Marketplace identity",
    );
  }
  if (!Array.isArray(config.specialists))
    throw new Error("marketplace.config.json specialists must be an array");

  const specialistsRoot = path.join(root, "specialists");
  let versionCount = 0;
  for (const specialistId of await readdir(specialistsRoot)) {
    if (specialistId === "README.md") continue;
    const versionsRoot = path.join(specialistsRoot, specialistId, "versions");
    for (const version of await readdir(versionsRoot)) {
      const output = await mkdtemp(
        path.join(os.tmpdir(), "marketplace-validate-"),
      );
      await buildRelease({
        specialistId,
        version,
        versionDirectory: path.join(versionsRoot, version),
        outputDirectory: output,
      });
      versionCount += 1;
    }
  }
  console.log(
    `Validated authoring input (${versionCount} Specialist version(s))`,
  );
}

if (args.marketplace || args.signature || args.root) {
  if (!args.marketplace || !args.signature)
    throw new Error("--marketplace and --signature must be used together");
  await validatePublishedMarketplace({
    marketplacePath: path.resolve(args.marketplace),
    signaturePath: path.resolve(args.signature),
    rootDirectory: path.resolve(args.root || path.dirname(args.marketplace)),
    expectedPublicKeyBase64:
      process.env.MARKETPLACE_EXPECTED_PUBLIC_KEY_SPKI_BASE64,
  });
  console.log("Published Marketplace validation passed");
} else {
  await validateAuthoring();
  await import("./check-repository.mjs");
}
