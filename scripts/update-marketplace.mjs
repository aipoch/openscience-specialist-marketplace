#!/usr/bin/env node
import { readFile, writeFile } from "node:fs/promises";

import { jsonBytes, parseArgs, readJson } from "./lib/common.mjs";
import { updateMarketplace } from "./lib/marketplace.mjs";

const args = parseArgs(process.argv.slice(2));
for (const required of ["base", "entry", "release", "output"]) {
  if (!args[required]) throw new Error(`missing --${required}`);
}
const [{ value: baseMarketplace }, { value: entry }, releaseDescriptorBytes] =
  await Promise.all([
    readJson(args.base),
    readJson(args.entry),
    readFile(args.release),
  ]);
const marketplace = updateMarketplace({
  baseMarketplace,
  entry,
  releaseDescriptorBytes,
});
await writeFile(args.output, jsonBytes(marketplace));
console.log(`Prepared Marketplace revision ${marketplace.revision}`);
