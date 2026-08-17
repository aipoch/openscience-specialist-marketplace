#!/usr/bin/env node
import { execFileSync } from "node:child_process";
import { readdir } from "node:fs/promises";
import path from "node:path";

import { ID_PATTERN, parseArgs } from "./lib/common.mjs";
import { resolvePublicationVersion } from "./lib/immutability.mjs";

const args = parseArgs(process.argv.slice(2));
const specialistId = args["specialist-id"];
if (!specialistId || !ID_PATTERN.test(specialistId)) {
  throw new Error("missing or invalid --specialist-id");
}

const versionsRoot = path.resolve("specialists", specialistId, "versions");
const authoredVersions = (await readdir(versionsRoot, { withFileTypes: true }))
  .filter((entry) => entry.isDirectory())
  .map((entry) => entry.name);
const publishedReleasePaths = args.published
  ? execFileSync(
      "git",
      [
        "ls-tree",
        "-r",
        "--name-only",
        args.published,
        "--",
        `releases/${specialistId}`,
      ],
      { encoding: "utf8" },
    )
      .trim()
      .split("\n")
      .filter(Boolean)
  : [];
const result = resolvePublicationVersion({
  specialistId,
  authoredVersions,
  publishedReleasePaths,
});
if (result.alreadyPublished) {
  console.error(
    `No unpublished version found; retrying ${specialistId}@${result.version}`,
  );
}
console.log(result.version);
