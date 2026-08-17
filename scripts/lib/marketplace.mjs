import { assertUniqueIds, sha256 } from "./common.mjs";
import { validateDocument } from "./schema.mjs";

export function updateMarketplace({
  baseMarketplace,
  entry,
  releaseDescriptorBytes,
}) {
  validateDocument("marketplace", baseMarketplace);
  const nextEntry = structuredClone(entry);
  nextEntry.latest.release.sha256 = sha256(releaseDescriptorBytes);
  const existing = baseMarketplace.specialists.find(
    (item) => item.id === nextEntry.id,
  );
  if (existing && existing.latest.version === nextEntry.latest.version) {
    throw new Error(
      `Specialist version is already indexed: ${nextEntry.id}@${nextEntry.latest.version}`,
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
