#!/usr/bin/env node
import path from "node:path";

import { jsonBytes, parseArgs, readJson } from "./lib/common.mjs";
import { readReleaseHistory } from "./lib/history.mjs";
import { readIndexedReleases } from "./lib/validation.mjs";

const args = parseArgs(process.argv.slice(2));
if (!args.root || (!args.marketplace && !args.history)) {
  throw new Error("missing --root and either --marketplace or --history");
}

const rootDirectory = path.resolve(args.root);
let artifacts;
if (args.history) {
  artifacts = await readReleaseHistory({ rootDirectory });
} else {
  const { value: marketplace } = await readJson(args.marketplace);
  const releases = await readIndexedReleases({ marketplace, rootDirectory });
  artifacts = releases.map(({ specialist, descriptor }) => ({
    descriptor_path: specialist.latest.release.path,
    tag: descriptor.artifact.github_release.tag,
    asset_name: descriptor.artifact.github_release.asset_name,
    path: descriptor.artifact.path,
  }));
}
process.stdout.write(
  jsonBytes(
    artifacts.map(({ descriptor_path, tag, asset_name, path }) => ({
      descriptor_path,
      tag,
      asset_name,
      path,
    })),
  ),
);
