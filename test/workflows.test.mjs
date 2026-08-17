import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

import { parse as parseYaml } from "yaml";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

test("GitHub workflows are valid YAML documents", async () => {
  const workflows = {};
  for (const name of ["validate.yml", "publish.yml"]) {
    const source = await readFile(
      path.join(root, ".github/workflows", name),
      "utf8",
    );
    const workflow = parseYaml(source);
    assert.equal(typeof workflow.name, "string");
    assert.equal(typeof workflow.jobs, "object");
    workflows[name] = workflow;
  }
  assert.deepEqual(workflows["validate.yml"].permissions, { contents: "read" });
  assert.deepEqual(workflows["publish.yml"].permissions, {
    contents: "write",
    "id-token": "write",
  });
  assert.equal(
    workflows["publish.yml"].jobs.publish.env.MARKETPLACE_CDN_BASE_URL,
    "${{ vars.MARKETPLACE_CDN_BASE_URL }}",
  );
  assert.equal(
    workflows["publish.yml"].jobs.publish.env.MARKETPLACE_CDN_PREFIX,
    "/open-science/specialist-marketplace/v1/",
  );
  const publishCommands = workflows["publish.yml"].jobs.publish.steps
    .map((step) => step.run || "")
    .join("\n");
  assert.match(publishCommands, /Publication must be dispatched from main/);
  assert.match(publishCommands, /list-release-artifacts\.mjs/);
  assert.match(publishCommands, /--marketplace dist\/base-marketplace\.json/);
});
