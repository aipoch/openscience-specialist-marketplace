import { readFile } from "node:fs/promises";
import path from "node:path";

import { assertUniqueIds, readJson, sha256 } from "./common.mjs";
import { contentDigest } from "./content-digest.mjs";
import { assertSafeRelativePath } from "./paths.mjs";
import { validateDocument as validateSchema } from "./schema.mjs";
import { verifyMarketplaceSignature } from "./signing.mjs";
import { inspectZip } from "./zip.mjs";

export function validateDocument(name, value) {
  validateSchema(name, value);
  if (name === "marketplace") assertUniqueIds(value.specialists, "Specialist");
  if (name === "release") {
    assertUniqueIds(value.skills, "Skill");
    assertUniqueIds(value.connectors, "Connector");
    const skills = new Set(value.skills.map((item) => item.id));
    const connectors = new Set(value.connectors.map((item) => item.id));
    for (const id of value.defaults.skill_ids) {
      if (!skills.has(id))
        throw new Error(`default Skill is absent from descriptor: ${id}`);
    }
    for (const id of value.defaults.connector_ids) {
      if (!connectors.has(id))
        throw new Error(`default Connector is absent from descriptor: ${id}`);
    }
    for (const connector of value.connectors) {
      if (connector.required && !connector.default_selected) {
        throw new Error(
          `required Connector must be default-selected: ${connector.id}`,
        );
      }
      if (
        connector.default_selected !==
        value.defaults.connector_ids.includes(connector.id)
      ) {
        throw new Error(`Connector defaults disagree: ${connector.id}`);
      }
    }
  }
  return value;
}

function parseEntryJson(entries, name) {
  const bytes = entries.get(name);
  if (!bytes) throw new Error(`ZIP is missing ${name}`);
  try {
    return JSON.parse(bytes.toString("utf8"));
  } catch (error) {
    throw new Error(`ZIP ${name} is invalid JSON: ${error.message}`);
  }
}

function resolveInside(rootDirectory, relativePath) {
  assertSafeRelativePath(relativePath);
  const resolvedRoot = path.resolve(rootDirectory);
  const resolved = path.resolve(resolvedRoot, ...relativePath.split("/"));
  if (!resolved.startsWith(`${resolvedRoot}${path.sep}`))
    throw new Error(`path escapes root: ${relativePath}`);
  return resolved;
}

export async function validateReleaseArtifact({ descriptor, rootDirectory }) {
  validateDocument("release", descriptor);
  const expectedTag = `${descriptor.specialist_id}-v${descriptor.version}`;
  const expectedAssetName = `${descriptor.specialist_id}-${descriptor.version}.zip`;
  if (
    descriptor.artifact.github_release.tag !== expectedTag ||
    descriptor.artifact.github_release.asset_name !== expectedAssetName
  ) {
    throw new Error("GitHub Release tag or asset name is not canonical");
  }
  const expectedArtifactPath = `specialists/${descriptor.specialist_id}/${descriptor.version}/${descriptor.specialist_id}-${descriptor.version}.zip`;
  if (descriptor.artifact.path !== expectedArtifactPath)
    throw new Error("release artifact path is not canonical");
  const zipBytes = await readFile(
    resolveInside(rootDirectory, descriptor.artifact.path),
  );
  if (sha256(zipBytes) !== descriptor.artifact.sha256)
    throw new Error("artifact SHA-256 mismatch");
  if (zipBytes.length !== descriptor.artifact.compressed_bytes)
    throw new Error("artifact compressed size mismatch");
  const archive = inspectZip(zipBytes);
  if (archive.fileCount !== descriptor.artifact.file_count)
    throw new Error("artifact file count mismatch");
  if (archive.uncompressedBytes !== descriptor.artifact.uncompressed_bytes)
    throw new Error("artifact expanded size mismatch");

  const manifest = parseEntryJson(archive.entries, "manifest.json");
  const specialist = parseEntryJson(archive.entries, "specialist.json");
  if (
    manifest.schema_version !== 1 ||
    manifest.id !== descriptor.specialist_id ||
    manifest.version !== descriptor.version ||
    typeof manifest.exported_with_app_version !== "string" ||
    !manifest.exported_with_app_version
  ) {
    throw new Error("manifest.json compatibility fields mismatch");
  }
  for (const field of ["name", "description", "systemPrompt"]) {
    if (typeof specialist[field] !== "string" || !specialist[field]) {
      throw new Error(`specialist.json ${field} must be a non-empty string`);
    }
  }
  if (
    !Array.isArray(specialist.skillIds) ||
    !Array.isArray(specialist.connectorIds)
  ) {
    throw new Error("specialist.json references must be arrays");
  }
  const expectedSkills = new Set(descriptor.skills.map((item) => item.id));
  const expectedConnectors = new Set(
    descriptor.connectors.map((item) => item.id),
  );
  for (const id of specialist.skillIds) {
    if (!expectedSkills.has(id))
      throw new Error(`specialist.json references unknown Skill: ${id}`);
  }
  for (const id of specialist.connectorIds) {
    if (!expectedConnectors.has(id))
      throw new Error(`specialist.json references unknown Connector: ${id}`);
  }
  if (
    [...specialist.skillIds].sort().join("\0") !==
      [...descriptor.defaults.skill_ids].sort().join("\0") ||
    [...specialist.connectorIds].sort().join("\0") !==
      [...descriptor.defaults.connector_ids].sort().join("\0")
  ) {
    throw new Error("specialist.json defaults do not match release descriptor");
  }
  for (const skill of descriptor.skills) {
    const prefix = `${skill.path}/`;
    const files = [...archive.entries]
      .filter(([name]) => name.startsWith(prefix))
      .map(([name, bytes]) => ({ path: name.slice(prefix.length), bytes }));
    if (files.length !== skill.file_count)
      throw new Error(`Skill file count mismatch: ${skill.id}`);
    if (
      files.reduce((sum, file) => sum + file.bytes.length, 0) !==
      skill.uncompressed_bytes
    ) {
      throw new Error(`Skill expanded size mismatch: ${skill.id}`);
    }
    if (contentDigest(files) !== skill.content_digest)
      throw new Error(`Skill content digest mismatch: ${skill.id}`);
  }
  return archive;
}

export async function readIndexedReleases({ marketplace, rootDirectory }) {
  validateDocument("marketplace", marketplace);
  const releases = [];
  for (const specialist of marketplace.specialists) {
    const expectedReleasePath = `releases/${specialist.id}/${specialist.latest.version}.json`;
    if (specialist.latest.release.path !== expectedReleasePath)
      throw new Error("release descriptor path is not canonical");
    const releasePath = resolveInside(
      rootDirectory,
      specialist.latest.release.path,
    );
    const releaseBytes = await readFile(releasePath);
    if (sha256(releaseBytes) !== specialist.latest.release.sha256)
      throw new Error("release descriptor SHA-256 mismatch");
    const descriptor = JSON.parse(releaseBytes.toString("utf8"));
    validateDocument("release", descriptor);
    if (
      descriptor.specialist_id !== specialist.id ||
      descriptor.version !== specialist.latest.version
    ) {
      throw new Error("indexed release identity/version mismatch");
    }
    releases.push({ specialist, descriptor, releaseBytes });
  }
  return releases;
}

export async function validatePublishedMarketplace({
  marketplacePath,
  signaturePath,
  rootDirectory = path.dirname(marketplacePath),
  expectedPublicKeyBase64,
}) {
  const { bytes: marketplaceBytes, value: marketplace } =
    await readJson(marketplacePath);
  validateDocument("marketplace", marketplace);
  const { value: signature } = await readJson(signaturePath);
  validateDocument("signature", signature);
  if (
    !verifyMarketplaceSignature({
      marketplaceBytes,
      signature,
      expectedPublicKeyBase64,
    })
  ) {
    throw new Error("marketplace signature verification failed");
  }
  const releases = await readIndexedReleases({ marketplace, rootDirectory });
  for (const { descriptor } of releases) {
    await validateReleaseArtifact({ descriptor, rootDirectory });
  }
  return {
    specialistCount: marketplace.specialists.length,
    releaseCount: releases.length,
  };
}
