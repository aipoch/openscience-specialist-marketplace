import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

import { parse as parseYaml } from "yaml";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

test("GitHub workflows are valid YAML documents", async () => {
  const workflows = {};
  for (const name of ["validate.yml", "publish.yml", "verify-published.yml"]) {
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
    contents: "read",
  });
  assert.deepEqual(workflows["publish.yml"].jobs.publish.permissions, {
    contents: "write",
  });
  assert.deepEqual(workflows["verify-published.yml"].permissions, {
    contents: "read",
  });
  assert.equal(workflows["publish.yml"].jobs.publish["timeout-minutes"], 45);
  assert.equal(
    workflows["verify-published.yml"].jobs.verify["timeout-minutes"],
    20,
  );
  assert.equal(
    workflows["verify-published.yml"].jobs.verify.environment,
    undefined,
  );
  for (const name of [
    "GH_TOKEN",
    "MARKETPLACE_SIGNING_PRIVATE_KEY_PKCS8_BASE64",
    "MARKETPLACE_CDN_BASE_URL",
    "MARKETPLACE_BUCKET",
    "AWS_ACCESS_KEY_ID",
    "AWS_SECRET_ACCESS_KEY",
  ]) {
    assert.equal(workflows["publish.yml"].jobs.publish.env[name], undefined);
  }
  assert.equal(
    workflows["publish.yml"].jobs.publish.env.MARKETPLACE_CDN_PREFIX,
    "/open-science/specialist-marketplace/v1/",
  );
  assert.equal(
    workflows["verify-published.yml"].jobs.verify.steps.find(
      (step) => step.name === "Download and verify exact CDN mirror",
    ).env.MARKETPLACE_CDN_PREFIX,
    "/open-science/specialist-marketplace/v1/",
  );
  assert.equal(
    workflows["publish.yml"].jobs.publish.steps.find(
      (step) => step.name === "Prove GitHub and CDN byte equality",
    ).env.MARKETPLACE_CDN_BASE_URL,
    "${{ secrets.MARKETPLACE_CDN_BASE_URL }}",
  );

  for (const workflow of Object.values(workflows)) {
    for (const job of Object.values(workflow.jobs)) {
      for (const step of job.steps) {
        if (step.uses) {
          assert.match(step.uses, /@[0-9a-f]{40}$/);
        }
      }
    }
  }

  const validateCommands = workflows["validate.yml"].jobs.validate.steps
    .map((step) => step.run || "")
    .join("\n");
  assert.match(validateCommands, /check:immutability/);
  assert.equal(
    workflows["validate.yml"].jobs.validate.steps.some((step) =>
      step.uses?.startsWith("raven-actions/actionlint@"),
    ),
    true,
  );

  const awsCredentials = workflows["publish.yml"].jobs.publish.steps.find(
    (step) => step.name === "Configure AWS credentials",
  );
  assert.equal(
    awsCredentials.with["aws-access-key-id"],
    "${{ secrets.AWS_ACCESS_KEY_ID }}",
  );
  assert.equal(
    awsCredentials.with["aws-secret-access-key"],
    "${{ secrets.AWS_SECRET_ACCESS_KEY }}",
  );
  assert.equal(awsCredentials.with["role-to-assume"], undefined);
  const publishCommands = workflows["publish.yml"].jobs.publish.steps
    .map((step) => step.run || "")
    .join("\n");
  assert.match(publishCommands, /Publication must be dispatched from main/);
  assert.match(publishCommands, /list-release-artifacts\.mjs/);
  assert.match(publishCommands, /--marketplace dist\/base-marketplace\.json/);
  assert.match(publishCommands, /RELEASE_EXISTS=true/);
  assert.match(publishCommands, /Existing GitHub Release must be public/);
  assert.match(publishCommands, /Existing CDN object bytes do not match/);
  assert.match(publishCommands, /cloudfront wait invalidation-completed/);
  assert.match(publishCommands, /--retry-all-errors/);
  assert.doesNotMatch(publishCommands, /git fetch[^\n]+\|\| true/);

  const verificationCommands = workflows[
    "verify-published.yml"
  ].jobs.verify.steps
    .map((step) => step.run || "")
    .join("\n");
  assert.match(verificationCommands, /--history true/);
  assert.match(verificationCommands, /verify:history/);
});
