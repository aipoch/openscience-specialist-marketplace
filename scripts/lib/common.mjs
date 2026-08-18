import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";

export const ID_PATTERN = /^(?=.{1,128}$)[a-z0-9]+(?:-[a-z0-9]+)*$/;
export const SEMVER_PATTERN =
  /^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(?:-(?:0|[1-9][0-9]*|[0-9A-Za-z-]*[A-Za-z-][0-9A-Za-z-]*)(?:\.(?:0|[1-9][0-9]*|[0-9A-Za-z-]*[A-Za-z-][0-9A-Za-z-]*))*)?(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$/;

export function compareSemver(left, right) {
  if (!SEMVER_PATTERN.test(left) || !SEMVER_PATTERN.test(right)) {
    throw new Error("cannot compare invalid SemVer values");
  }
  const parse = (value) => {
    const [withoutBuild] = value.split("+");
    const separator = withoutBuild.indexOf("-");
    const main =
      separator === -1 ? withoutBuild : withoutBuild.slice(0, separator);
    const prerelease =
      separator === -1 ? undefined : withoutBuild.slice(separator + 1);
    return {
      main: main.split("."),
      prerelease: prerelease?.split("."),
    };
  };
  const compareNumeric = (a, b) =>
    BigInt(a) < BigInt(b) ? -1 : BigInt(a) > BigInt(b) ? 1 : 0;
  const a = parse(left);
  const b = parse(right);
  for (let index = 0; index < 3; index += 1) {
    const result = compareNumeric(a.main[index], b.main[index]);
    if (result) return result;
  }
  if (!a.prerelease && !b.prerelease) return 0;
  if (!a.prerelease) return 1;
  if (!b.prerelease) return -1;
  for (
    let index = 0;
    index < Math.max(a.prerelease.length, b.prerelease.length);
    index += 1
  ) {
    const leftPart = a.prerelease[index];
    const rightPart = b.prerelease[index];
    if (leftPart === undefined) return -1;
    if (rightPart === undefined) return 1;
    if (leftPart === rightPart) continue;
    const leftNumeric = /^[0-9]+$/.test(leftPart);
    const rightNumeric = /^[0-9]+$/.test(rightPart);
    if (leftNumeric && rightNumeric) return compareNumeric(leftPart, rightPart);
    if (leftNumeric !== rightNumeric) return leftNumeric ? -1 : 1;
    return leftPart < rightPart ? -1 : 1;
  }
  return 0;
}

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
