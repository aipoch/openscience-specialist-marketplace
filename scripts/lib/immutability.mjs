import { compareSemver, ID_PATTERN } from "./common.mjs";

export function parsePublicationSpecialistIds({ specialistId, specialistIds }) {
  const single = specialistId?.trim();
  const batch = specialistIds?.trim();
  if (Boolean(single) === Boolean(batch)) {
    throw new Error(
      "provide exactly one of --specialist-id or --specialist-ids",
    );
  }

  const ids = single ? [single] : batch.split(/[\s,]+/).filter(Boolean);
  const seen = new Set();
  for (const id of ids) {
    if (!ID_PATTERN.test(id)) {
      throw new Error(`invalid Specialist ID: ${id}`);
    }
    if (seen.has(id)) {
      throw new Error(`duplicate Specialist ID: ${id}`);
    }
    seen.add(id);
  }
  return ids.sort();
}

export function findPublishedVersionChanges({
  changedPaths,
  publishedReleasePaths,
}) {
  const published = new Set(publishedReleasePaths);
  const collisions = new Set();
  for (const changedPath of changedPaths) {
    const match = changedPath.match(
      /^specialists\/([a-z0-9][a-z0-9-]{0,127})\/versions\/([^/]+)\//,
    );
    if (match && published.has(`releases/${match[1]}/${match[2]}.json`)) {
      collisions.add(`${match[1]}@${match[2]}`);
    }
  }
  return [...collisions].sort();
}

export function resolvePublicationVersion({
  specialistId,
  authoredVersions,
  publishedReleasePaths,
}) {
  const publishedVersions = new Set(
    publishedReleasePaths.flatMap((releasePath) => {
      const match = releasePath.match(/^releases\/([^/]+)\/([^/]+)\.json$/);
      return match?.[1] === specialistId ? [match[2]] : [];
    }),
  );
  const unpublished = authoredVersions
    .filter((version) => !publishedVersions.has(version))
    .sort(compareSemver);
  if (unpublished.length > 1) {
    throw new Error(
      `multiple unpublished versions for ${specialistId}: ${unpublished.join(", ")}`,
    );
  }
  if (unpublished.length === 1) {
    return { version: unpublished[0], alreadyPublished: false };
  }

  const published = authoredVersions
    .filter((version) => publishedVersions.has(version))
    .sort(compareSemver);
  if (!published.length) {
    throw new Error(`no authored versions found for ${specialistId}`);
  }
  return { version: published.at(-1), alreadyPublished: true };
}
