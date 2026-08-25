#!/usr/bin/env node
import { execFileSync } from "node:child_process";
import { readdir } from "node:fs/promises";
import path from "node:path";

import { jsonBytes, parseArgs } from "./lib/common.mjs";
import {
  parsePublicationSpecialistIds,
  resolvePublicationVersion,
} from "./lib/immutability.mjs";

const args = parseArgs(process.argv.slice(2));
const specialistIds = parsePublicationSpecialistIds({
  specialistId: args["specialist-id"],
  specialistIds: args["specialist-ids"],
});
const publishedReleasePaths = args.published
  ? execFileSync(
      "git",
      ["ls-tree", "-r", "--name-only", args.published, "--", "releases"],
      { encoding: "utf8" },
    )
      .trim()
      .split("\n")
      .filter(Boolean)
  : [];

const plan = [];
for (const specialistId of specialistIds) {
  const versionsRoot = path.resolve("specialists", specialistId, "versions");
  const authoredVersions = (
    await readdir(versionsRoot, { withFileTypes: true })
  )
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name);
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
  plan.push({
    specialist_id: specialistId,
    version: result.version,
    already_published: result.alreadyPublished,
  });
}

process.stdout.write(jsonBytes(plan));
