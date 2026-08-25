#!/usr/bin/env node
import { execFileSync } from "node:child_process";

import { parseArgs } from "./lib/common.mjs";
import {
  findPublishedVersionChanges,
  isMarketplaceOnlyReleaseConfigChange,
} from "./lib/immutability.mjs";

const args = parseArgs(process.argv.slice(2));
if (!args.base || !args.published)
  throw new Error("missing --base or --published");

function gitLines(commandArgs) {
  return execFileSync("git", commandArgs, { encoding: "utf8" })
    .trim()
    .split("\n")
    .filter(Boolean);
}

function gitJson(revision, filePath) {
  return JSON.parse(
    execFileSync("git", ["show", `${revision}:${filePath}`], {
      encoding: "utf8",
    }),
  );
}

const head = args.head || "HEAD";
const changedPaths = gitLines([
  "diff",
  "--name-only",
  `${args.base}...${head}`,
]);
const publishedReleasePaths = gitLines([
  "ls-tree",
  "-r",
  "--name-only",
  args.published,
  "--",
  "releases",
]);
const published = new Set(publishedReleasePaths);
const marketplaceOnlyReleaseConfigs = changedPaths.filter((filePath) => {
  const match = filePath.match(
    /^specialists\/([a-z0-9][a-z0-9-]{0,127})\/versions\/([^/]+)\/release\.config\.json$/,
  );
  if (!match || !published.has(`releases/${match[1]}/${match[2]}.json`)) {
    return false;
  }
  try {
    return isMarketplaceOnlyReleaseConfigChange(
      gitJson(args.base, filePath),
      gitJson(head, filePath),
    );
  } catch {
    return false;
  }
});

const collisions = findPublishedVersionChanges({
  changedPaths,
  publishedReleasePaths,
  marketplaceOnlyReleaseConfigs,
});

if (collisions.length) {
  throw new Error(
    `published Specialist authoring input is immutable: ${collisions.join(", ")}`,
  );
}
console.log("Published Specialist immutability check passed");
