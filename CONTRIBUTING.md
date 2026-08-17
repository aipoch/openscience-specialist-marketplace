# Contributing to the OpenScience Specialist Marketplace

Thanks for helping maintain a safe, reproducible Specialist ecosystem. Be respectful, constructive,
and focused on technical merits.

## Prerequisites and setup

- Node.js 22 (see [`.nvmrc`](.nvmrc))
- npm
- Git

```bash
git clone https://github.com/<your-username>/openscience-specialist-marketplace.git
cd openscience-specialist-marketplace
git remote add upstream https://github.com/aipoch/openscience-specialist-marketplace.git
npm ci
```

Create change branches from `main` using `<type>/<lowercase-hyphenated-description>`, such as
`feat/add-literature-review-specialist` or `docs/clarify-trust-model`.

## Specialist version requirements

Each contribution adds one immutable version. Never edit or replace an already published descriptor
or ZIP; changed bytes require a new SemVer version.

- Keep stable Specialist, Skill, Connector, and publisher IDs.
- Preserve the App-export-compatible package layout in [the authoring guide](specialists/README.md).
- Record the public upstream repository, exact 40-character commit SHA, and license.
- Do not include secrets, private endpoints, credentials, tokens, local commands, or Connector
  configuration. Connectors remain references for App-side review and reuse.
- Do not add a fake production Specialist, `plugins/`, `catalog/`, or `listings/` abstraction.
- Do not add generated production output to `main`.

Skill instructions can influence Agent behavior and therefore require maintainer review. Clearly call
out new network access, command execution, data handling, destructive actions, or trust changes in the
pull request.

## Required checks

Run all commands from the repository root after the final material change:

```bash
npm ci
npm run format:check
npm test
npm run validate
```

For a single authored release, also run:

```bash
npm run build:release -- --specialist-id <id> --version <semver>
```

Include the artifact SHA-256 and evidence that rebuilding unchanged input produces identical bytes.
Fixtures under `protocol/fixtures/` are test-only and cannot be published.

## Commits and pull requests

Commit and pull request subjects follow Conventional Commits with a required scope:

```text
<type>(<scope>): <imperative description>
```

Allowed types are `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`,
and `revert`. The scope starts lowercase and uses hyphens. Examples:

```text
feat(protocol): add Specialist release schema
docs(contributing): clarify Connector review
```

Open a focused pull request containing the Specialist ID/version, upstream commit, license, Skill
changes, Connector references, security impact, and reproducibility evidence. Maintainers publish
accepted versions through the protected `production` environment; contributors do not publish or
edit the `published` branch directly.

## Protocol changes

Protocol v1 is immutable after production adoption. Discuss incompatible changes before implementation;
they require a new schema and protocol version rather than edits to v1 contracts.

## License

By contributing, you agree that your contribution is licensed under the
[Apache License 2.0](LICENSE).
