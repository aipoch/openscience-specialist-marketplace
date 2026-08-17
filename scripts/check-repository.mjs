#!/usr/bin/env node
import { lstat, readdir, readFile } from "node:fs/promises";
import path from "node:path";

const root = path.resolve(import.meta.dirname, "..");
const ignored = new Set([".git", "node_modules", "dist"]);
const forbiddenDirectories = ["plugins", "catalog", "listings"];
const secretPatterns = [
  [/-----BEGIN (?:RSA |EC )?PRIVATE KEY-----/, "private PEM key"],
  [/\bAKIA[0-9A-Z]{16}\b/, "AWS access key"],
  [/arn:aws:iam::[0-9]{12}:role\//, "AWS role ARN"],
  [/https:\/\/[^\s"']+\.cloudfront\.net\b/, "CloudFront hostname"],
  [/https:\/\/[^\s"']+\.s3(?:\.[^\s"']+)?\.amazonaws\.com\b/, "S3 hostname"],
];

async function files(directory, relative = "") {
  const result = [];
  for (const name of await readdir(directory)) {
    if (!relative && ignored.has(name)) continue;
    const childRelative = relative ? `${relative}/${name}` : name;
    const child = path.join(directory, name);
    const stat = await lstat(child);
    if (stat.isSymbolicLink()) continue;
    if (stat.isDirectory()) result.push(...(await files(child, childRelative)));
    else if (stat.isFile()) result.push(childRelative);
  }
  return result;
}

for (const directory of forbiddenDirectories) {
  try {
    if ((await lstat(path.join(root, directory))).isDirectory()) {
      throw new Error(`forbidden repository abstraction: ${directory}/`);
    }
  } catch (error) {
    if (error.code !== "ENOENT") throw error;
  }
}

for (const relativePath of await files(root)) {
  if (relativePath === "protocol/fixtures/keys/test-only-private-key.pk8.b64")
    continue;
  let text;
  try {
    text = await readFile(path.join(root, relativePath), "utf8");
  } catch {
    continue;
  }
  for (const [pattern, label] of secretPatterns) {
    if (pattern.test(text))
      throw new Error(`${relativePath} contains a prohibited ${label}`);
  }
}
console.log("Repository safety checks passed");
