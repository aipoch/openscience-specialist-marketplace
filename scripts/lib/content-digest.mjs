import { createHash } from "node:crypto";

const DOMAIN = Buffer.from("OpenScience Skill content digest v1\0");

function uint64(value) {
  const bytes = Buffer.alloc(8);
  bytes.writeBigUInt64BE(BigInt(value));
  return bytes;
}

export function contentDigest(files) {
  const hash = createHash("sha256").update(DOMAIN);
  for (const file of [...files].sort((a, b) =>
    Buffer.compare(Buffer.from(a.path, "utf8"), Buffer.from(b.path, "utf8")),
  )) {
    const relativePath = Buffer.from(file.path, "utf8");
    hash.update(uint64(relativePath.length));
    hash.update(relativePath);
    hash.update(uint64(file.bytes.length));
    hash.update(file.bytes);
  }
  return hash.digest("hex");
}
