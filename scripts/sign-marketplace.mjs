#!/usr/bin/env node
import { readFile, writeFile } from "node:fs/promises";

import { jsonBytes, parseArgs } from "./lib/common.mjs";
import { publicKeyFingerprint, signMarketplace } from "./lib/signing.mjs";

const args = parseArgs(process.argv.slice(2));
if (!args.marketplace || !args.output)
  throw new Error("missing --marketplace or --output");
const requiredEnvironment = [
  "MARKETPLACE_SIGNING_PRIVATE_KEY_PKCS8_BASE64",
  "MARKETPLACE_SIGNING_KEY_ID",
  "MARKETPLACE_EXPECTED_PUBLIC_KEY_SPKI_BASE64",
  "MARKETPLACE_EXPECTED_KEY_FINGERPRINT",
];
for (const name of requiredEnvironment) {
  if (!process.env[name])
    throw new Error(`missing protected publication configuration: ${name}`);
}
const testOnlyFingerprint =
  "662eac5d6d8eb26bb2c8ea13fdaf243ed17b0a3228256e9a2737b64451a8d40f";
if (
  process.env.MARKETPLACE_SIGNING_KEY_ID.includes("test") ||
  process.env.MARKETPLACE_EXPECTED_KEY_FINGERPRINT.toLowerCase() ===
    testOnlyFingerprint
) {
  throw new Error("the production signer refuses the committed test-only key");
}
const marketplaceBytes = await readFile(args.marketplace);
const signature = signMarketplace({
  marketplaceBytes,
  privateKeyPkcs8Base64:
    process.env.MARKETPLACE_SIGNING_PRIVATE_KEY_PKCS8_BASE64,
  keyId: process.env.MARKETPLACE_SIGNING_KEY_ID,
  expectedPublicKeyBase64:
    process.env.MARKETPLACE_EXPECTED_PUBLIC_KEY_SPKI_BASE64,
  expectedFingerprint: process.env.MARKETPLACE_EXPECTED_KEY_FINGERPRINT,
});
await writeFile(args.output, jsonBytes(signature));
console.log(`Signed with key ID: ${signature.key_id}`);
console.log(
  `Public key fingerprint: ${publicKeyFingerprint(Buffer.from(signature.public_key, "base64"))}`,
);
