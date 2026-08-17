import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

import { parse as parseYaml } from "yaml";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

test("GitHub workflows are valid YAML documents", async () => {
  const workflows = {};
  for (const name of [
    "validate.yml",
    "publish.yml",
    "verify-published.yml",
    "release.yml",
  ]) {
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
  assert.deepEqual(workflows["release.yml"].permissions, {
    contents: "read",
  });
  assert.deepEqual(workflows["release.yml"].jobs.release.permissions, {
    contents: "write",
  });
  assert.equal(
    workflows["release.yml"].jobs.release.environment,
    "project-release",
  );
  assert.equal(workflows["publish.yml"].jobs.publish["timeout-minutes"], 45);
  assert.equal(
    workflows["verify-published.yml"].jobs.verify["timeout-minutes"],
    20,
  );
  assert.equal(workflows["release.yml"].jobs.release["timeout-minutes"], 10);
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
  assert.equal(awsCredentials, undefined);
  const protectedConfiguration = workflows[
    "publish.yml"
  ].jobs.publish.steps.find(
    (step) => step.name === "Require protected publication configuration",
  );
  assert.equal(protectedConfiguration.env.AWS_REGION, undefined);
  assert.doesNotMatch(protectedConfiguration.run, /\bAWS_REGION\b/);
  assert.doesNotMatch(
    JSON.stringify(workflows["publish.yml"]),
    /AWS_REGION|aws-region/,
  );
  for (const name of [
    "Stage and verify exact CDN bytes",
    "Promote immutable CDN objects and stable root",
  ]) {
    const awsStep = workflows["publish.yml"].jobs.publish.steps.find(
      (step) => step.name === name,
    );
    assert.equal(
      awsStep.env.AWS_ACCESS_KEY_ID,
      "${{ secrets.AWS_ACCESS_KEY_ID }}",
    );
    assert.equal(
      awsStep.env.AWS_SECRET_ACCESS_KEY,
      "${{ secrets.AWS_SECRET_ACCESS_KEY }}",
    );
  }
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

  const prepareCommands = workflows["publish.yml"].jobs.publish.steps.find(
    (step) => step.name === "Prepare candidate Marketplace",
  ).run;
  assert.match(
    prepareCommands,
    /gh release download "\$tag"[\s\S]{0,240}--skip-existing/,
  );

  const promotionCommands = workflows["publish.yml"].jobs.publish.steps.find(
    (step) => step.name === "Promote immutable CDN objects and stable root",
  ).run;
  const s3Copies = promotionCommands
    .split("\n")
    .filter((line) => line.trimStart().startsWith('aws s3 cp "s3://'));
  assert.equal(s3Copies.length, 2);
  for (const command of s3Copies) {
    assert.match(command, /--copy-props none/);
  }

  const verificationCommands = workflows[
    "verify-published.yml"
  ].jobs.verify.steps
    .map((step) => step.run || "")
    .join("\n");
  assert.match(verificationCommands, /--history true/);
  assert.match(verificationCommands, /verify:history/);

  const releaseCommands = workflows["release.yml"].jobs.release.steps
    .map((step) => step.run || "")
    .join("\n");
  assert.match(releaseCommands, /Tag .* does not match project version/);
  assert.match(releaseCommands, /SEMVER_PATTERN/);
  assert.match(releaseCommands, /scripts\/lib\/common\.mjs/);
  assert.match(releaseCommands, /Project releases require an annotated tag/);
  assert.match(releaseCommands, /git merge-base --is-ancestor/);
  assert.match(releaseCommands, /gh release create/);
  assert.match(releaseCommands, /--verify-tag/);
  assert.match(releaseCommands, /--generate-notes/);
  assert.match(releaseCommands, /release_args\+=\(--prerelease\)/);
  assert.match(
    releaseCommands,
    /--title "Open Science Specialist Marketplace \$tag"/,
  );
});
