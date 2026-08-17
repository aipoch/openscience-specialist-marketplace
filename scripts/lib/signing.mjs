import {
  createHash,
  createPrivateKey,
  createPublicKey,
  sign,
  verify,
} from "node:crypto";

function decodeBase64(value, label) {
  if (typeof value !== "string" || !/^[A-Za-z0-9+/]+={0,2}$/.test(value)) {
    throw new Error(`${label} must be canonical base64`);
  }
  return Buffer.from(value, "base64");
}

export function publicKeyFingerprint(publicKeySpki) {
  return createHash("sha256").update(publicKeySpki).digest("hex");
}

export function signMarketplace({
  marketplaceBytes,
  privateKeyPkcs8Base64,
  keyId,
  expectedPublicKeyBase64,
  expectedFingerprint,
}) {
  if (!/^openscience-[a-z0-9][a-z0-9-]{0,117}$/.test(keyId)) {
    throw new Error("invalid signing key ID");
  }
  const privateKey = createPrivateKey({
    key: decodeBase64(privateKeyPkcs8Base64, "private key"),
    format: "der",
    type: "pkcs8",
  });
  if (privateKey.asymmetricKeyType !== "ed25519") {
    throw new Error("protocol v1 requires an Ed25519 private key");
  }
  const publicKey = createPublicKey(privateKey);
  const publicKeySpki = publicKey.export({ format: "der", type: "spki" });
  const publicKeyBase64 = publicKeySpki.toString("base64");
  const fingerprint = publicKeyFingerprint(publicKeySpki);
  if (expectedPublicKeyBase64 && publicKeyBase64 !== expectedPublicKeyBase64) {
    throw new Error(
      "derived public key does not match the expected public key",
    );
  }
  if (
    expectedFingerprint &&
    fingerprint !== expectedFingerprint.toLowerCase()
  ) {
    throw new Error(
      "derived public key does not match the expected fingerprint",
    );
  }
  return {
    schema_version: 1,
    algorithm: "ed25519",
    key_id: keyId,
    public_key: publicKeyBase64,
    signature: sign(null, marketplaceBytes, privateKey).toString("base64"),
  };
}

export function verifyMarketplaceSignature({
  marketplaceBytes,
  signature,
  expectedPublicKeyBase64,
}) {
  if (signature.algorithm !== "ed25519") return false;
  if (
    expectedPublicKeyBase64 &&
    signature.public_key !== expectedPublicKeyBase64
  )
    return false;
  try {
    const publicKey = createPublicKey({
      key: decodeBase64(signature.public_key, "public key"),
      format: "der",
      type: "spki",
    });
    if (publicKey.asymmetricKeyType !== "ed25519") return false;
    return verify(
      null,
      marketplaceBytes,
      publicKey,
      decodeBase64(signature.signature, "signature"),
    );
  } catch {
    return false;
  }
}
