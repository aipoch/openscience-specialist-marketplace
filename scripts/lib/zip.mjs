import { lstat, readdir, readFile } from "node:fs/promises";
import path from "node:path";

import { unzipSync, zipSync } from "fflate";

import { assertSafeRelativePath } from "./paths.mjs";

const CENTRAL_DIRECTORY_SIGNATURE = 0x02014b50;
const END_SIGNATURE = 0x06054b50;
const FIXED_MTIME = new Date(1980, 0, 1, 0, 0, 0);
const DEFAULT_LIMITS = {
  maxFiles: 1_000,
  maxFileBytes: 10 * 1024 * 1024,
  maxExpandedBytes: 100 * 1024 * 1024,
  maxCompressionRatio: 100,
};

async function collectFiles(root, current = "") {
  const directory = path.join(root, current);
  const names = (await readdir(directory)).sort();
  const files = [];
  for (const name of names) {
    const relativePath = current ? `${current}/${name}` : name;
    assertSafeRelativePath(relativePath);
    const filePath = path.join(root, ...relativePath.split("/"));
    const stat = await lstat(filePath);
    if (stat.isSymbolicLink())
      throw new Error(`symlinks are not allowed: ${relativePath}`);
    if (stat.isDirectory())
      files.push(...(await collectFiles(root, relativePath)));
    else if (stat.isFile())
      files.push({ path: relativePath, bytes: await readFile(filePath) });
    else throw new Error(`special files are not allowed: ${relativePath}`);
  }
  return files;
}

export async function buildDeterministicZip(packageDirectory) {
  const files = await collectFiles(packageDirectory);
  if (files.length === 0)
    throw new Error("Specialist package must contain at least one file");
  const entries = {};
  for (const file of files) {
    entries[file.path] = [
      new Uint8Array(file.bytes),
      { level: 9, mtime: FIXED_MTIME },
    ];
  }
  return { bytes: Buffer.from(zipSync(entries, { level: 9 })), files };
}

function findEnd(bytes) {
  const minimum = Math.max(0, bytes.length - 65_557);
  for (let offset = bytes.length - 22; offset >= minimum; offset -= 1) {
    if (bytes.readUInt32LE(offset) === END_SIGNATURE) return offset;
  }
  throw new Error("invalid ZIP: end-of-central-directory record not found");
}

export function inspectZip(input, limits = {}) {
  const bytes = Buffer.from(input);
  const effective = { ...DEFAULT_LIMITS, ...limits };
  const end = findEnd(bytes);
  const entryCount = bytes.readUInt16LE(end + 10);
  const centralSize = bytes.readUInt32LE(end + 12);
  let offset = bytes.readUInt32LE(end + 16);
  if (entryCount > effective.maxFiles)
    throw new Error("ZIP contains too many files");
  if (offset + centralSize > end)
    throw new Error("invalid ZIP central directory bounds");

  const decoder = new TextDecoder("utf-8", { fatal: true });
  const metadata = [];
  const seen = new Set();
  let expandedBytes = 0;
  for (let index = 0; index < entryCount; index += 1) {
    if (bytes.readUInt32LE(offset) !== CENTRAL_DIRECTORY_SIGNATURE) {
      throw new Error("invalid ZIP central directory entry");
    }
    const madeBy = bytes.readUInt16LE(offset + 4);
    const flags = bytes.readUInt16LE(offset + 8);
    const method = bytes.readUInt16LE(offset + 10);
    const compressedBytes = bytes.readUInt32LE(offset + 20);
    const uncompressedBytes = bytes.readUInt32LE(offset + 24);
    const nameLength = bytes.readUInt16LE(offset + 28);
    const extraLength = bytes.readUInt16LE(offset + 30);
    const commentLength = bytes.readUInt16LE(offset + 32);
    const externalAttributes = bytes.readUInt32LE(offset + 38);
    const nameStart = offset + 46;
    const nameEnd = nameStart + nameLength;
    if (nameEnd > bytes.length)
      throw new Error("invalid ZIP entry name bounds");
    const name = decoder.decode(bytes.subarray(nameStart, nameEnd));

    if (flags & 1)
      throw new Error(`encrypted ZIP entries are not allowed: ${name}`);
    if (![0, 8].includes(method))
      throw new Error(`unsupported ZIP compression method: ${method}`);
    if (name.endsWith("/"))
      throw new Error(
        `explicit ZIP directory entries are not allowed: ${name}`,
      );
    try {
      assertSafeRelativePath(name, "ZIP path");
    } catch {
      throw new Error(`unsafe ZIP path: ${name}`);
    }
    const normalized = name.normalize("NFC");
    if (seen.has(normalized))
      throw new Error(`duplicate normalized ZIP path: ${name}`);
    seen.add(normalized);

    const creatorSystem = madeBy >>> 8;
    const unixMode = externalAttributes >>> 16;
    const fileType = unixMode & 0o170000;
    if (creatorSystem === 3 && fileType !== 0 && fileType !== 0o100000) {
      throw new Error(
        `symlinks and special ZIP entries are not allowed: ${name}`,
      );
    }
    if (uncompressedBytes > effective.maxFileBytes)
      throw new Error(`ZIP entry is too large: ${name}`);
    if (
      compressedBytes === 0
        ? uncompressedBytes > 0
        : uncompressedBytes / compressedBytes > effective.maxCompressionRatio
    ) {
      throw new Error(`unsafe ZIP compression ratio: ${name}`);
    }
    expandedBytes += uncompressedBytes;
    if (expandedBytes > effective.maxExpandedBytes)
      throw new Error("ZIP expands beyond the size limit");
    metadata.push({ name, compressedBytes, uncompressedBytes });
    offset = nameEnd + extraLength + commentLength;
  }

  let extracted;
  try {
    extracted = unzipSync(new Uint8Array(bytes));
  } catch (error) {
    throw new Error(`invalid ZIP data: ${error.message}`);
  }
  const entries = new Map();
  for (const item of metadata) {
    const data = extracted[item.name];
    if (!data || data.length !== item.uncompressedBytes) {
      throw new Error(`ZIP size mismatch: ${item.name}`);
    }
    entries.set(item.name, Buffer.from(data));
  }
  return {
    entries,
    fileCount: metadata.length,
    compressedBytes: bytes.length,
    uncompressedBytes: expandedBytes,
  };
}
