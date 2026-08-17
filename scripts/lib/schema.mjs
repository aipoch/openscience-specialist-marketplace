import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

import Ajv2020 from "ajv/dist/2020.js";

const root = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "../..",
);
const schemaFiles = {
  marketplace: "marketplace.schema.json",
  signature: "marketplace-signature.schema.json",
  release: "specialist-release.schema.json",
};

const ajv = new Ajv2020({ allErrors: true, strict: true });
const validators = {};
for (const [name, file] of Object.entries(schemaFiles)) {
  const schema = JSON.parse(
    await readFile(path.join(root, "protocol/schemas", file), "utf8"),
  );
  validators[name] = ajv.compile(schema);
}

export function validateDocument(name, value) {
  const validator = validators[name];
  if (!validator) throw new Error(`unknown schema: ${name}`);
  if (!validator(value)) {
    const details = validator.errors
      .map(
        (error) =>
          `${error.instancePath || "/"} ${error.keyword}: ${error.message}`,
      )
      .join("; ");
    throw new Error(`${name} schema validation failed: ${details}`);
  }
  return value;
}
