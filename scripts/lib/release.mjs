import { mkdir, readFile, writeFile } from "node:fs/promises";
import path from "node:path";

import {
  assertExactKeys,
  assertUniqueIds,
  ID_PATTERN,
  jsonBytes,
  readJson,
  SEMVER_PATTERN,
  sha256,
} from "./common.mjs";
import { contentDigest } from "./content-digest.mjs";
import { assertSafeRelativePath } from "./paths.mjs";
import { validateDocument } from "./schema.mjs";
import { parseSpecialistJson } from "./specialist.mjs";
import { buildDeterministicZip, inspectZip } from "./zip.mjs";

function assertString(value, label) {
  if (typeof value !== "string" || !value.trim())
    throw new Error(`${label} must be a non-empty string`);
}

function validateReleaseConfig(config) {
  assertExactKeys(
    config,
    ["source", "marketplace", "skills", "connectors"],
    "release.config.json",
  );
  assertExactKeys(config.source, ["repository", "commit", "license"], "source");
  assertExactKeys(
    config.marketplace,
    ["display_name", "summary", "publisher"],
    "marketplace",
  );
  assertExactKeys(
    config.marketplace.publisher,
    ["id", "name", "url"],
    "publisher",
  );
  if (!/^https:\/\//.test(config.source.repository))
    throw new Error("source.repository must use HTTPS");
  if (!/^[0-9a-f]{40}$/.test(config.source.commit))
    throw new Error("source.commit must be a full commit SHA");
  assertString(config.source.license, "source.license");
  assertString(config.marketplace.display_name, "marketplace.display_name");
  assertString(config.marketplace.summary, "marketplace.summary");
  if (!ID_PATTERN.test(config.marketplace.publisher.id))
    throw new Error("invalid publisher ID");
  assertString(config.marketplace.publisher.name, "publisher.name");
  if (!/^https:\/\//.test(config.marketplace.publisher.url))
    throw new Error("publisher.url must use HTTPS");
  if (!Array.isArray(config.skills) || !Array.isArray(config.connectors)) {
    throw new Error("skills and connectors must be arrays");
  }
  for (const skill of config.skills) {
    assertExactKeys(
      skill,
      ["id", "name", "display_name", "description", "path"],
      `Skill ${skill.id || ""}`,
    );
    if (!ID_PATTERN.test(skill.id) || skill.name !== skill.id)
      throw new Error(`invalid Skill identity: ${skill.id}`);
    assertString(skill.display_name, `Skill ${skill.id} display_name`);
    assertString(skill.description, `Skill ${skill.id} description`);
    assertSafeRelativePath(skill.path, `Skill ${skill.id} path`);
    if (skill.path !== `skills/${skill.id}`)
      throw new Error(`Skill ${skill.id} path must be skills/${skill.id}`);
  }
  for (const connector of config.connectors) {
    assertExactKeys(
      connector,
      ["id", "required", "default_selected"],
      `Connector ${connector.id || ""}`,
    );
    if (!ID_PATTERN.test(connector.id))
      throw new Error(`invalid Connector ID: ${connector.id}`);
    if (
      typeof connector.required !== "boolean" ||
      typeof connector.default_selected !== "boolean"
    ) {
      throw new Error(`Connector ${connector.id} flags must be booleans`);
    }
    if (connector.required && !connector.default_selected) {
      throw new Error(
        `required Connector must be default-selected: ${connector.id}`,
      );
    }
  }
  assertUniqueIds(config.skills, "Skill");
  assertUniqueIds(config.connectors, "Connector");
}

function parsePackageJson(entries, name) {
  const bytes = entries.get(name);
  if (!bytes) throw new Error(`package is missing ${name}`);
  try {
    return JSON.parse(bytes.toString("utf8"));
  } catch (error) {
    throw new Error(`${name} is invalid JSON: ${error.message}`);
  }
}

export async function buildRelease({
  specialistId,
  version,
  versionDirectory,
  outputDirectory,
}) {
  if (!ID_PATTERN.test(specialistId))
    throw new Error(`invalid Specialist ID: ${specialistId}`);
  if (!SEMVER_PATTERN.test(version))
    throw new Error(`invalid Specialist version: ${version}`);
  const packageDirectory = path.join(versionDirectory, "package");
  const { value: config } = await readJson(
    path.join(versionDirectory, "release.config.json"),
  );
  validateReleaseConfig(config);

  const built = await buildDeterministicZip(packageDirectory);
  const archive = inspectZip(built.bytes);
  const manifest = parsePackageJson(archive.entries, "manifest.json");
  const specialist = parseSpecialistJson(
    parsePackageJson(archive.entries, "specialist.json"),
  );
  if (
    manifest.schema_version !== 1 ||
    manifest.id !== specialistId ||
    manifest.version !== version ||
    typeof manifest.exported_with_app_version !== "string" ||
    !manifest.exported_with_app_version
  ) {
    throw new Error(
      "manifest.json compatibility fields do not match the requested release",
    );
  }
  const skills = config.skills.map((skill) => {
    const prefix = `${skill.path}/`;
    const files = [...archive.entries]
      .filter(([name]) => name.startsWith(prefix))
      .map(([name, bytes]) => ({ path: name.slice(prefix.length), bytes }));
    if (files.length === 0)
      throw new Error(`Skill directory is missing or empty: ${skill.path}`);
    return {
      ...skill,
      content_digest: contentDigest(files),
      file_count: files.length,
      uncompressed_bytes: files.reduce(
        (sum, file) => sum + file.bytes.length,
        0,
      ),
    };
  });
  const skillIds = new Set(skills.map((skill) => skill.id));
  const connectorIds = new Set(
    config.connectors.map((connector) => connector.id),
  );
  for (const id of specialist.skillIds) {
    if (!skillIds.has(id))
      throw new Error(`selected Skill is absent from release config: ${id}`);
  }
  for (const id of specialist.connectorIds) {
    if (!connectorIds.has(id))
      throw new Error(
        `selected Connector is absent from release config: ${id}`,
      );
  }
  for (const connector of config.connectors) {
    if (
      connector.default_selected !==
      specialist.connectorIds.includes(connector.id)
    ) {
      throw new Error(
        `Connector default does not match specialist.json: ${connector.id}`,
      );
    }
  }

  const assetName = `${specialistId}-${version}.zip`;
  const artifactPath = `specialists/${specialistId}/${version}/${assetName}`;
  const releasePath = `releases/${specialistId}/${version}.json`;
  const descriptor = {
    schema_version: 1,
    specialist_id: specialistId,
    version,
    source: config.source,
    artifact: {
      path: artifactPath,
      github_release: {
        tag: `${specialistId}-v${version}`,
        asset_name: assetName,
      },
      sha256: sha256(built.bytes),
      compressed_bytes: built.bytes.length,
      uncompressed_bytes: archive.uncompressedBytes,
      file_count: archive.fileCount,
    },
    defaults: {
      skill_ids: [...specialist.skillIds],
      connector_ids: [...specialist.connectorIds],
    },
    skills,
    connectors: config.connectors,
  };
  validateDocument("release", descriptor);
  const descriptorBytes = jsonBytes(descriptor);
  const zipPath = path.join(outputDirectory, ...artifactPath.split("/"));
  const descriptorPath = path.join(outputDirectory, ...releasePath.split("/"));
  await mkdir(path.dirname(zipPath), { recursive: true });
  await mkdir(path.dirname(descriptorPath), { recursive: true });
  await writeFile(zipPath, built.bytes);
  await writeFile(descriptorPath, descriptorBytes);
  return {
    descriptor,
    descriptorPath,
    zipPath,
    marketplaceEntry: {
      id: specialistId,
      display_name: config.marketplace.display_name,
      summary: config.marketplace.summary,
      publisher: config.marketplace.publisher,
      latest: {
        version,
        release: { path: releasePath, sha256: sha256(descriptorBytes) },
      },
    },
  };
}
