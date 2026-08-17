import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";

export const ID_PATTERN = /^[a-z0-9][a-z0-9-]{0,127}$/;
export const SEMVER_PATTERN =
  /^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(?:-[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$/;

export function sha256(bytes) {
  return createHash("sha256").update(bytes).digest("hex");
}

export async function readJson(filePath) {
  const bytes = await readFile(filePath);
  try {
    return { bytes, value: JSON.parse(bytes.toString("utf8")) };
  } catch (error) {
    throw new Error(`${filePath}: invalid JSON: ${error.message}`);
  }
}

export function jsonBytes(value) {
  return Buffer.from(`${JSON.stringify(value, null, 2)}\n`);
}

export function assertExactKeys(value, keys, label) {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new Error(`${label} must be an object`);
  }
  const expected = new Set(keys);
  for (const key of Object.keys(value)) {
    if (!expected.has(key))
      throw new Error(`${label} contains unknown field: ${key}`);
  }
  for (const key of keys) {
    if (!(key in value)) throw new Error(`${label} is missing field: ${key}`);
  }
}

export function assertUniqueIds(values, label) {
  const seen = new Set();
  for (const value of values) {
    if (seen.has(value.id))
      throw new Error(`duplicate ${label} ID: ${value.id}`);
    seen.add(value.id);
  }
}

export function parseArgs(argv) {
  const result = {};
  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];
    if (!token.startsWith("--"))
      throw new Error(`unexpected argument: ${token}`);
    const name = token.slice(2);
    const value = argv[index + 1];
    if (!value || value.startsWith("--"))
      throw new Error(`missing value for --${name}`);
    result[name] = value;
    index += 1;
  }
  return result;
}
