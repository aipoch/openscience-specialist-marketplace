# OpenScience Specialist Marketplace

The official Marketplace authority and reference implementation of the open **OpenScience
Specialist Marketplace Protocol v1**.

A **Specialist** is a versioned, installable OpenScience package containing a manifest, Specialist
instructions, Skills, and references to Connectors. Marketplace resources are not built into the
OpenScience App: remote Skills and Connector references do not enter an Agent context until the user
reviews and installs that Specialist. Connector entries are references only; credentials and local
Connector configuration remain under the user's control in the App.

## Distribution model

GitHub is the authority. Each immutable Specialist ZIP is a GitHub Release asset, while the
`published` branch contains the signed shallow discovery index and immutable release descriptors.
An independently configured CDN mirrors the exact same verified bytes for availability and speed;
clients can fall back to GitHub when the CDN is unavailable.

- `main` owns authoring input, protocol schemas, validation tools, tests, and workflows.
- `published` owns generated `marketplace.json`, `marketplace.json.sig`, and `releases/` metadata.
- The App's official GitHub source addresses this repository with `ref=published`.
- GitHub Releases own immutable ZIPs. The CDN mirrors metadata and ZIPs without defining another
  catalog format.

No generated production index or signature is committed to `main`.

## Production publication configuration

Create a protected GitHub environment named `production`, restrict deployments to `main`, and
require maintainer approval. Configure these environment variables:

| Variable                                      | Value                                                     |
| --------------------------------------------- | --------------------------------------------------------- |
| `AWS_REGION`                                  | AWS region containing the Marketplace bucket              |
| `MARKETPLACE_EXPECTED_KEY_FINGERPRINT`        | Pinned SHA-256 fingerprint of the signing public key      |
| `MARKETPLACE_EXPECTED_PUBLIC_KEY_SPKI_BASE64` | Pinned Ed25519 public key in base64-encoded SPKI DER form |
| `MARKETPLACE_SIGNING_KEY_ID`                  | Stable identifier for the active signing key              |

Configure these environment secrets:

| Secret                                         | Purpose                                               |
| ---------------------------------------------- | ----------------------------------------------------- |
| `AWS_ROLE_TO_ASSUME`                           | IAM role assumed through GitHub OIDC                  |
| `MARKETPLACE_BUCKET`                           | Existing S3 bucket mirrored by the CDN                |
| `MARKETPLACE_CDN_BASE_URL`                     | HTTPS CDN origin without a path                       |
| `MARKETPLACE_CDN_DISTRIBUTION_ID`              | Existing CloudFront distribution to invalidate        |
| `MARKETPLACE_SIGNING_PRIVATE_KEY_PKCS8_BASE64` | Ed25519 private key in base64-encoded PKCS#8 DER form |

The IAM role must trust the `production` environment for this repository and allow `s3:GetObject`
and `s3:PutObject` under `open-science/specialist-marketplace/v1/`, plus
`cloudfront:CreateInvalidation` for the configured distribution. Publication does not require S3 or
CloudFront delete permissions.

The CDN object paths are fixed by the publication workflow:

```text
/open-science/specialist-marketplace/v1/marketplace.json
/open-science/specialist-marketplace/v1/marketplace.json.sig
/open-science/specialist-marketplace/v1/releases/<specialist-id>/<version>.json
/open-science/specialist-marketplace/v1/specialists/<specialist-id>/<version>/<specialist-id>-<version>.zip
```

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

Create one immutable version under
`specialists/<specialist-id>/versions/<semver>/`, using the App-export-compatible layout documented
in [the Specialist authoring guide](specialists/README.md). Start with the
[complete contribution example](example/README.md) if this is your first Specialist. Open a pull
request with the upstream commit, license, security review notes, and reproducibility evidence.
Publication is maintainer-only and runs through the protected `production` GitHub environment.

See the [protocol specification](protocol/README.md), [contribution guide](CONTRIBUTING.md), and
[security policy](SECURITY.md).

## Protocol compatibility

Protocol schema v1 becomes immutable when consumed by a production App. Incompatible changes require
a new protocol version. Published descriptors and ZIP bytes are never replaced; the shallow root may
advance while historical versions remain available.

## License

Licensed under the [Apache License 2.0](LICENSE).
