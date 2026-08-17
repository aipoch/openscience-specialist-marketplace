#!/usr/bin/env node
import path from "node:path";

import { jsonBytes, parseArgs, readJson } from "./lib/common.mjs";
import { readIndexedReleases } from "./lib/validation.mjs";

const args = parseArgs(process.argv.slice(2));
if (!args.marketplace || !args.root)
  throw new Error("missing --marketplace or --root");

const { value: marketplace } = await readJson(args.marketplace);
const releases = await readIndexedReleases({
  marketplace,
  rootDirectory: path.resolve(args.root),
});
process.stdout.write(
  jsonBytes(
    releases.map(({ descriptor }) => ({
      tag: descriptor.artifact.github_release.tag,
      asset_name: descriptor.artifact.github_release.asset_name,
      path: descriptor.artifact.path,
    })),
  ),
);
