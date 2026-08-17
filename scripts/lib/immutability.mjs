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
