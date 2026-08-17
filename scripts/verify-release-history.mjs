#!/usr/bin/env node
import path from "node:path";

import { parseArgs } from "./lib/common.mjs";
import { validateReleaseHistory } from "./lib/history.mjs";

const args = parseArgs(process.argv.slice(2));
if (!args.root) throw new Error("missing --root");

const releaseCount = await validateReleaseHistory({
  rootDirectory: path.resolve(args.root),
});
console.log(`Verified ${releaseCount} historical Specialist release(s)`);
