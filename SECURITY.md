# Security policy

## Reporting a vulnerability

Do not open a public issue for a signing-key, publication, ZIP-validation, or malicious-Skill
vulnerability. Use GitHub's private vulnerability reporting for this repository. If that channel is
unavailable, contact the OpenScience maintainers through a private organization channel and include
the affected Specialist/version, observed behavior, and safe reproduction details. Do not include
credentials or private keys in reports.

## Release immutability

Published version descriptors, GitHub Release assets, and versioned CDN objects are immutable. A fix
uses a new SemVer version. Historical descriptors remain available even after the shallow root points
to a newer version. Maintainers must never overwrite a tag, asset, descriptor, or versioned object.

## Compromised signing key

If compromise is suspected, maintainers stop publication, protect or disable affected environments,
preserve evidence, identify the last trusted signed revision, and notify App maintainers. Clients must
not trust a replacement key advertised only by remote Marketplace metadata. Recovery requires an App
update or existing overlapping trust that pins the replacement public key independently.

## Key rotation

Planned rotation uses an overlap period in which the App trusts both old and new public keys. The new
key ID and fingerprint are reviewed and configured independently before publication switches. After
supported App versions trust the new key, maintainers retire the old private key and document the last
revision it signed.

Production private keys exist only in the protected GitHub `production` environment. Publication
derives the public key and checks it against a separately configured expected key and fingerprint.
Logs contain only public repository/version/digest information, key ID, and public fingerprint.
