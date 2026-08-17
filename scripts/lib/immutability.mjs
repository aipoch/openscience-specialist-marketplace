import { compareSemver } from "./common.mjs";

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
