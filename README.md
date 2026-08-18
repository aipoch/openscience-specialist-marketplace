# OpenScience Specialist Marketplace

The official open-source Marketplace, package registry, and secure distribution protocol for
installable AI research **Specialists** in [Open Science](https://github.com/aipoch/open-science),
AIPOCH's local-first AI research workbench. Specialists combine Agent instructions, reusable Skills,
and references to scientific data Connectors into versioned packages for reproducible research
workflows.

[Open Science on GitHub](https://github.com/aipoch/open-science) ·
[AIPOCH website](https://www.aipoch.com) ·
[Download Open Science](https://github.com/aipoch/open-science/releases/latest) ·
[Published Marketplace](https://github.com/aipoch/openscience-specialist-marketplace/tree/published) ·
[Protocol v1](protocol/README.md) · [Contributing](CONTRIBUTING.md)

> Looking for the desktop software? Visit the
> [Open Science repository](https://github.com/aipoch/open-science) or
> [www.aipoch.com](https://www.aipoch.com) for downloads, documentation, and product updates.

## What is a Specialist?

A **Specialist** is a versioned, installable OpenScience package that gives an AI research Agent a
reviewable set of instructions and capabilities for a specific scientific workflow. A package can
contain:

- Specialist identity, instructions, and default selections;
- reusable **Skills** for domain knowledge and research methods; and
- reference-only **Connectors** for scientific databases and tools configured in the App.

Marketplace resources are not built into the OpenScience App. Remote Skills and Connector references
do not enter an Agent context until the user reviews and installs the Specialist. Connector entries
never contain credentials, tokens, or executable server configuration; those settings remain under
the user's control in the App.

## Available Specialists

| Specialist                                                                 | Latest version                                                                                                       | Capabilities                          | Research focus                                                                                                                                                                    |
| -------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- | ------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Auto Research Specialist](specialists/auto-research-specialist/README.md) | [`1.0.1`](https://github.com/aipoch/openscience-specialist-marketplace/releases/tag/auto-research-specialist-v1.0.1) | 27 Skills and 24 Connector references | Reproducible biomedical research from question framing and literature retrieval through study design, statistical and bioinformatics analysis, validation, and manuscript writing |

The signed discovery index and immutable release descriptors are available on the
[`published` branch](https://github.com/aipoch/openscience-specialist-marketplace/tree/published).
New Specialist versions are added through reviewed pull requests and the protected publication
workflow.

## What this repository provides

- **Specialist Marketplace** — reviewed, versioned packages for scientific and biomedical AI research
  workflows.
- **Open distribution protocol** — strict JSON schemas for discovery, release metadata, Skill
  digests, and Connector references.
- **Secure publication** — deterministic ZIP archives, SHA-256 digests, byte-exact Ed25519 signatures,
  immutable releases, and GitHub/CDN verification.
- **Reference tooling** — Node.js commands for package validation, reproducible builds, publication,
  and independent Marketplace verification.
- **Contribution workflow** — an App-export-compatible example and authoring guide for publishing a
  new Specialist version.

Any public GitHub repository may implement the open
[OpenScience Specialist Marketplace Protocol v1](protocol/README.md). The official Open Science App
integration and future Marketplace work are tracked in the [roadmap](ROADMAP.md).

## Repository layout

| Path                                      | Purpose                                                                |
| ----------------------------------------- | ---------------------------------------------------------------------- |
| [`specialists/`](specialists/README.md)   | Authored, immutable Specialist versions and the authoring guide        |
| [`protocol/`](protocol/README.md)         | Protocol v1 schemas, fixtures, trust model, and compatibility rules    |
| [`example/`](example/README.md)           | Non-publishable, copyable Specialist contribution example              |
| [`scripts/`](scripts)                     | Build, validation, signing, publication, and verification tools        |
| [`test/`](test)                           | Protocol, packaging, safety, and publication regression tests          |
| [`.github/workflows/`](.github/workflows) | Protected validation, release, publication, and verification workflows |

## Distribution and trust model

GitHub is the Marketplace authority. Each immutable Specialist ZIP is a GitHub Release asset, while
the `published` branch contains the signed shallow discovery index and immutable release descriptors.
An independently configured CDN mirrors the exact verified bytes for availability and speed; clients
can fall back to GitHub without changing trust semantics.

- `main` owns authoring input, protocol schemas, validation tools, tests, and workflows.
- `published` owns generated `marketplace.json`, `marketplace.json.sig`, and `releases/` metadata.
- GitHub Releases own immutable Specialist ZIPs.
- The CDN mirrors metadata and ZIPs without defining another catalog format.

No generated production index or signature is committed to `main`. Published descriptors and ZIP
bytes are never replaced; changes require a new SemVer version.

## Validate locally

Use Node.js 22 and npm:

```bash
npm ci
npm run format:check
npm test
npm run validate
```

Fixtures under `protocol/fixtures/` are non-publishable. They include an intentionally public,
test-only signing key used to prove deterministic builds and byte-exact signature verification.

## Contribute a Specialist version

Create one immutable version under `specialists/<specialist-id>/versions/<semver>/`, using the
App-export-compatible layout documented in the [Specialist authoring guide](specialists/README.md).
Start with the [complete contribution example](example/README.md) if this is your first Specialist.
Open a pull request with the upstream commit, license, security review notes, and reproducibility
evidence. Publication is maintainer-only and runs through the protected GitHub `production`
environment.

See the [contribution guide](CONTRIBUTING.md) for the full review and validation requirements. Report
security issues according to the [security policy](SECURITY.md).

## Releases and compatibility

Project release tags such as `v0.1.0` describe this repository and its protocol tooling. Specialist
release tags such as `auto-research-specialist-v1.0.1` identify independently published installable
packages.

Protocol schema v1 becomes immutable when consumed by a production App. Incompatible changes require
a new protocol version. Protocol v1 `specialist.json` fields use snake_case, and all stable IDs use
strict lowercase kebab-case. The shallow Marketplace root may advance to a newer version while
historical release descriptors and ZIPs remain available.

## License

Licensed under the [Apache License 2.0](LICENSE).
