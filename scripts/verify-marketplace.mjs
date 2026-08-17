#!/usr/bin/env node
import path from "node:path";

import { parseArgs } from "./lib/common.mjs";
import { validatePublishedMarketplace } from "./lib/validation.mjs";

const args = parseArgs(process.argv.slice(2));
if (!args.marketplace || !args.signature) {
  throw new Error(
    "usage: npm run verify:marketplace -- --marketplace <path> --signature <path> [--root <directory>]",
  );
}
const result = await validatePublishedMarketplace({
  marketplacePath: path.resolve(args.marketplace),
  signaturePath: path.resolve(args.signature),
  rootDirectory: path.resolve(args.root || path.dirname(args.marketplace)),
  expectedPublicKeyBase64:
    process.env.MARKETPLACE_EXPECTED_PUBLIC_KEY_SPKI_BASE64,
});
console.log(`Verified ${result.specialistCount} Specialist release(s)`);
