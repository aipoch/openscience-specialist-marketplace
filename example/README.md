# Specialist contribution example

This directory is a non-publishable reference for contributors. It shows the smallest complete
Specialist contribution: one immutable version, one Skill, and one Connector reference. Marketplace
validation and publication only discover versions under `specialists/`, so nothing below `example/`
is released.

The sample values are intentionally fictional. Do not submit the example unchanged.

## What each file does

```text
example/literature-review-specialist/
├── README.md
└── versions/
    └── 1.0.0/
        ├── release.config.json
        └── package/
            ├── manifest.json
            ├── specialist.json
            ├── README.txt
            └── skills/
                └── evidence-summary/
                    └── SKILL.md
```

- `README.md` describes the Specialist and lists its immutable versions.
- `release.config.json` records the exact upstream source, Marketplace display metadata, bundled
  Skills, and reference-only Connectors.
- `package/` is the App-export-compatible archive root. Do not add Marketplace metadata inside it.
- `manifest.json` binds the package to one stable Specialist ID and SemVer version.
- `specialist.json` contains only `name`, optional `display_name`, `description`, `system_prompt`,
  `skill_ids`, and `connector_ids`. CamelCase aliases are not accepted.
- `skills/<skill-id>/SKILL.md` contains one bundled capability. Its directory, frontmatter `name`,
  release-config ID, and `specialist.json` entry use the same stable ID.
- `README.txt` is optional package guidance shown here only to demonstrate its location.

Connector entries are references, not executable configuration. Never include endpoints, commands,
environment variables, credentials, or tokens. The OpenScience App resolves a reference against its
own reviewed local Connector configuration.

## Adapt the example

1. Copy `example/literature-review-specialist/` to `specialists/<your-specialist-id>/`.
2. Choose a lowercase, hyphenated Specialist ID and keep it stable. Use it for the directory and
   `manifest.json` `id`.
3. Replace the fictional source repository, 40-character commit SHA, license, publisher, and display
   metadata in `release.config.json`.
4. Replace the sample Specialist instructions and Skills with the unchanged App export you intend to
   publish. Keep every Skill ID and path aligned across all files.
5. List only reviewed Connector IDs in strict lowercase kebab-case. A required Connector must also
   be selected by default.
6. Remove any secrets, private endpoints, local commands, or executable Connector configuration.
7. Add exactly one new SemVer directory. Never edit an already published version; changed bytes
   require a new version.

## Validate the contribution

From the repository root, run the checks required by [CONTRIBUTING.md](../CONTRIBUTING.md). Build the
copied version with its real ID and version:

```bash
npm ci
npm run format:check
npm test
npm run validate
npm run build:release -- --specialist-id <your-specialist-id> --version <semver>
```

Build the unchanged input twice and record the identical ZIP and descriptor SHA-256 values in the
pull request. Also describe Skill changes, Connector flags, network and command execution, data
handling, destructive operations, and any trust changes.

To verify this reference itself without copying it into `specialists/`, use a temporary output
directory:

```bash
npm run build:release -- \
  --specialist-id literature-review-specialist \
  --version 1.0.0 \
  --version-directory example/literature-review-specialist/versions/1.0.0 \
  --output /tmp/openscience-example-build
```
