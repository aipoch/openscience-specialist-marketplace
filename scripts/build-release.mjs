#!/usr/bin/env node
import path from "node:path";

import { parseArgs } from "./lib/common.mjs";
import { buildRelease } from "./lib/release.mjs";

const args = parseArgs(process.argv.slice(2));
if (!args["specialist-id"] || !args.version) {
  throw new Error(
    "usage: npm run build:release -- --specialist-id <id> --version <semver> [--output <directory>]",
  );
}
const outputDirectory = path.resolve(args.output || "dist");
const result = await buildRelease({
  specialistId: args["specialist-id"],
  version: args.version,
  versionDirectory: path.resolve(
    args["version-directory"] ||
      path.join("specialists", args["specialist-id"], "versions", args.version),
  ),
  outputDirectory,
});

const { writeFile } = await import("node:fs/promises");
const { jsonBytes } = await import("./lib/common.mjs");
await writeFile(
  path.join(outputDirectory, "marketplace-entry.json"),
  jsonBytes(result.marketplaceEntry),
);
console.log(
  `Built ${result.descriptor.specialist_id}@${result.descriptor.version}`,
);
console.log(`Artifact SHA-256: ${result.descriptor.artifact.sha256}`);
