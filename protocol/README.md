# OpenScience Specialist Marketplace Protocol v1

This directory defines the open discovery and release protocol implemented by the official
OpenScience Specialist Marketplace. Any public GitHub repository may implement the same protocol.

## Published files

The `published` branch and CDN mirror expose:

```text
marketplace.json
marketplace.json.sig
releases/<specialist-id>/<version>.json
specialists/<specialist-id>/<version>/<specialist-id>-<version>.zip
```

The root index is intentionally shallow: it contains identity, publisher, summary, latest version,
and the exact SHA-256 of that version's release descriptor. It never embeds Skill contents,
Connector configuration, or complete release history.

Protocol JSON documents are UTF-8 JSON. Publishers in this repository serialize them with two-space
indentation and a trailing LF, but hashes and signatures always cover the exact published bytes—not
a parsed or reserialized equivalent.

## Contracts

- [`marketplace.schema.json`](schemas/marketplace.schema.json) defines discovery.
- [`marketplace-signature.schema.json`](schemas/marketplace-signature.schema.json) defines the
  byte-exact Ed25519 signature descriptor.
- [`specialist-release.schema.json`](schemas/specialist-release.schema.json) defines an immutable
  version and its ZIP, Skills, and Connector references.

Unknown fields fail validation. IDs match `^[a-z0-9][a-z0-9-]{0,127}$`; versions use SemVer; SHA-256
digests are 64 lowercase hexadecimal characters. Paths are relative POSIX paths without absolute
prefixes, backslashes, empty segments, `.` segments, or `..` segments.

Connector objects contain only `id`, `required`, and `default_selected`. They never carry tokens,
credentials, environment variables, commands, endpoints, or executable server configuration.
Required Connectors must be selected by default. The App resolves each reference against its own
reviewed local Connector configuration.

## Skill content digest

For every regular file below a Skill directory:

1. express its path relative to that Skill root using UTF-8 and `/` separators;
2. sort files lexicographically by their unsigned UTF-8 path bytes;
3. initialize SHA-256 with the ASCII domain separator
   `OpenScience Skill content digest v1` followed by one zero byte;
4. for each file, append the path byte length as an unsigned 64-bit big-endian integer, the path
   bytes, the file byte length in the same encoding, and the exact file bytes;
5. encode the final digest as lowercase hexadecimal.

Length prefixes make path/content boundaries unambiguous. Directory entries, timestamps, file modes,
and ZIP metadata are not part of this digest.

## ZIP safety and compatibility

The ZIP root is the App-exported `package/` directory: `manifest.json`, `specialist.json`, and
`skills/` appear at the archive root. Protocol v1 accepts only stored or DEFLATE-compressed regular
files. Validation rejects traversal and absolute paths, backslashes, duplicate Unicode-normalized
paths, symlinks, special files, encryption, unsupported compression, excessive counts or sizes, and
unsafe compression ratios before extraction.

The manifest identity and version must equal the release descriptor. Every selected Skill and
Connector must exist in the descriptor, every selected Skill must exist in the ZIP, and required
Connectors must be default-selected.

## Trust model

Protocol v1 uses Ed25519 only. The signature is over the exact `marketplace.json` bytes. Official App
builds pin the official public key independently from remote metadata; a signature descriptor cannot
replace that pin. Third-party GitHub sources use explicit trust on first use: users review the
repository, ref, key ID, and fingerprint before the App stores the source.

Production publication derives the public SPKI DER key from a protected PKCS#8 DER private key and
checks it against a separately configured expected key and fingerprint. Only the key ID and public
fingerprint may appear in logs. Rotation requires overlapping trusted keys in the App and a deliberate
transition—clients must never trust a replacement merely because remote metadata advertises it.

## Immutability and transport fallback

Versioned release descriptors and ZIPs are immutable and retain long-lived cache headers. The root
and signature use short caching or revalidation. A publisher uploads candidate bytes to CDN staging,
downloads and verifies them, publishes the same metadata to GitHub, promotes the same bytes to the CDN,
then proves GitHub and CDN byte equality. A root is not promoted until its referenced artifact passes
all checks. Clients may fall back from the CDN mirror to GitHub without changing trust semantics.

Schema v1 is immutable after production adoption. Incompatible contracts require a new versioned
prefix and schemas; additive Marketplace releases do not rewrite historical App-exported ZIPs.
