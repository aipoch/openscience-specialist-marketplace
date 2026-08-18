# OpenScience Specialist Marketplace Roadmap

This roadmap describes the intended evolution of the official Marketplace authority and Protocol
v1 reference implementation. Priorities may change as the OpenScience App integration and the
Specialist ecosystem mature.

## v0.1.0 — Initial public release

- Establish the authoritative Specialist, Skill, Connector, publisher, and release data model.
- Validate authored releases against strict Protocol v1 schemas and package-safety rules.
- Build deterministic Specialist ZIPs with reproducible SHA-256 digests.
- Sign byte-exact discovery metadata with Ed25519 and verify it before publication.
- Publish immutable Specialist artifacts through protected GitHub and CDN distribution paths.
- Preserve and periodically verify historical release descriptors and artifacts.
- Include Auto Research Specialist 1.0.1 as the first authored reference Specialist, ready for
  independent publication through the protected workflow.
- Document a complete, reviewable contribution flow for additional Specialists.

## Next

- Complete the official Marketplace source integration in the OpenScience App, including trusted-key
  configuration, explicit user review, installation, update discovery, and GitHub fallback.
- Add more first-party and community Specialists without weakening provenance, Connector-reference,
  or reproducibility requirements.
- Expand protocol conformance fixtures and compatibility evidence as independent implementations
  adopt Protocol v1.
- Improve operational guidance for signing-key rotation, publication recovery, and long-term
  verification of historical releases.
- Publish clearer ecosystem guidance for Specialist maintainers, reviewers, and downstream clients.

## Toward v1.0

Protocol v1 is intended to remain stable once consumed in production. A project v1.0 release will
follow sustained production use, successful recovery and key-rotation exercises, and demonstrated
compatibility across multiple Specialists and client implementations. Any incompatible protocol
change will use a new protocol version rather than rewriting the consumed v1 contract.
