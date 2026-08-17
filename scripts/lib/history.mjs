import { readdir } from "node:fs/promises";
import path from "node:path";

import { readJson } from "./common.mjs";
import { validateDocument, validateReleaseArtifact } from "./validation.mjs";

async function jsonFiles(directory, relative = "") {
  const result = [];
  for (const entry of await readdir(directory, { withFileTypes: true })) {
    const childRelative = relative ? `${relative}/${entry.name}` : entry.name;
    const child = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      result.push(...(await jsonFiles(child, childRelative)));
    } else if (entry.isFile() && entry.name.endsWith(".json")) {
      result.push(childRelative);
    } else {
      throw new Error(`unexpected published release entry: ${childRelative}`);
    }
  }
  return result;
}

export async function readReleaseHistory({ rootDirectory }) {
  const releasesDirectory = path.join(rootDirectory, "releases");
  const records = [];
  const identities = new Set();
  const tags = new Set();
  const artifactPaths = new Set();
  for (const relativePath of (await jsonFiles(releasesDirectory)).sort()) {
    const { value: descriptor } = await readJson(
      path.join(releasesDirectory, ...relativePath.split("/")),
    );
    validateDocument("release", descriptor);
    const descriptorPath = `releases/${relativePath}`;
    const expectedDescriptorPath = `releases/${descriptor.specialist_id}/${descriptor.version}.json`;
    if (descriptorPath !== expectedDescriptorPath) {
      throw new Error(
        `release descriptor path is not canonical: ${descriptorPath}`,
      );
    }
    const identity = `${descriptor.specialist_id}@${descriptor.version}`;
    const tag = descriptor.artifact.github_release.tag;
    const assetName = descriptor.artifact.github_release.asset_name;
    const artifactPath = descriptor.artifact.path;
    const expectedTag = `${descriptor.specialist_id}-v${descriptor.version}`;
    const expectedAssetName = `${descriptor.specialist_id}-${descriptor.version}.zip`;
    const expectedArtifactPath = `specialists/${descriptor.specialist_id}/${descriptor.version}/${expectedAssetName}`;
    if (
      tag !== expectedTag ||
      assetName !== expectedAssetName ||
      artifactPath !== expectedArtifactPath
    ) {
      throw new Error(
        `published release artifact identity is not canonical: ${identity}`,
      );
    }
    if (
      identities.has(identity) ||
      tags.has(tag) ||
      artifactPaths.has(artifactPath)
    ) {
      throw new Error(`duplicate published release identity: ${identity}`);
    }
    identities.add(identity);
    tags.add(tag);
    artifactPaths.add(artifactPath);
    records.push({
      descriptor,
      descriptor_path: descriptorPath,
      tag,
      asset_name: assetName,
      path: artifactPath,
    });
  }
  return records;
}

export async function validateReleaseHistory({ rootDirectory }) {
  const records = await readReleaseHistory({ rootDirectory });
  for (const { descriptor } of records) {
    await validateReleaseArtifact({ descriptor, rootDirectory });
  }
  return records.length;
}
