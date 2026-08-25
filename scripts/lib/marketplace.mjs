import { assertUniqueIds, compareSemver, sha256 } from "./common.mjs";
import { validateDocument } from "./schema.mjs";

export function updateMarketplace({
  baseMarketplace,
  entry,
  releaseDescriptorBytes,
  authorPolicy = "include",
}) {
  validateDocument("marketplace", baseMarketplace);
  const nextEntry = structuredClone(entry);
  if (authorPolicy === "omit") delete nextEntry.author;
  else if (authorPolicy !== "include") {
    throw new Error(`invalid Marketplace author policy: ${authorPolicy}`);
  }
  nextEntry.latest.release.sha256 = sha256(releaseDescriptorBytes);
  const existing = baseMarketplace.specialists.find(
    (item) => item.id === nextEntry.id,
  );
  const versionOrder = existing
    ? compareSemver(nextEntry.latest.version, existing.latest.version)
    : 1;
  if (existing && versionOrder === 0) {
    if (JSON.stringify(existing) === JSON.stringify(nextEntry)) {
      return structuredClone(baseMarketplace);
    }
    if (
      existing.latest.release.path !== nextEntry.latest.release.path ||
      existing.latest.release.sha256 !== nextEntry.latest.release.sha256
    ) {
      throw new Error(
        `published Specialist version collision: ${nextEntry.id}@${nextEntry.latest.version}`,
      );
    }
  }
  if (existing && versionOrder < 0) {
    throw new Error(
      `Specialist latest version must advance beyond ${existing.latest.version}`,
    );
  }
  const specialists = baseMarketplace.specialists
    .filter((item) => item.id !== nextEntry.id)
    .concat(nextEntry)
    .sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0));
  assertUniqueIds(specialists, "Specialist");
  const result = {
    schema_version: 1,
    revision: (BigInt(baseMarketplace.revision) + 1n).toString(),
    marketplace: structuredClone(baseMarketplace.marketplace),
    specialists,
  };
  validateDocument("marketplace", result);
  return result;
}
