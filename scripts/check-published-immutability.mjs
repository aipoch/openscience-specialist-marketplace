#!/usr/bin/env node
import { execFileSync } from "node:child_process";

import { parseArgs } from "./lib/common.mjs";
import { findPublishedVersionChanges } from "./lib/immutability.mjs";

const args = parseArgs(process.argv.slice(2));
if (!args.base || !args.published)
  throw new Error("missing --base or --published");

function gitLines(commandArgs) {
  return execFileSync("git", commandArgs, { encoding: "utf8" })
    .trim()
    .split("\n")
    .filter(Boolean);
}

const collisions = findPublishedVersionChanges({
  changedPaths: gitLines([
    "diff",
    "--name-only",
    `${args.base}...${args.head || "HEAD"}`,
  ]),
  publishedReleasePaths: gitLines([
    "ls-tree",
    "-r",
    "--name-only",
    args.published,
    "--",
    "releases",
  ]),
});

if (collisions.length) {
  throw new Error(
    `published Specialist authoring input is immutable: ${collisions.join(", ")}`,
  );
}
console.log("Published Specialist immutability check passed");
