# Specialist authoring

Production Specialist versions live here; protocol fixtures do not. Add exactly one immutable SemVer
version per contribution:

For a copyable walkthrough with all required files, see the repository's non-publishable
[contribution example](../example/README.md).

```text
specialists/<specialist-id>/
├── README.md
└── versions/
    └── <semver>/
        ├── release.config.json
        └── package/
            ├── manifest.json
            ├── specialist.json
            ├── skills/
            │   └── <skill-id>/
            │       ├── SKILL.md
            │       └── ...
            └── README.txt
```

`README.txt` is optional. The contents of `package/` are zipped at the archive root and must remain
compatible with OpenScience App export/import v1. Do not add a plugin manifest or `.claude-plugin`.

`release.config.json` has four strict fields:

- `source`: HTTPS `repository`, full 40-character lowercase `commit`, and `license`;
- `marketplace`: `display_name`, `summary`, and publisher `id`, `name`, and HTTPS `url`;
- `skills`: each Skill's stable `id`/`name`, display text, description, and canonical
  `skills/<skill-id>` path;
- `connectors`: reference-only `id`, `required`, and `default_selected` flags.

The `specialist.json` `skillIds` and `connectorIds` arrays define defaults and must agree with the
release config. Never include secrets, credentials, commands, or Connector server configuration.

Build one version locally with:

```bash
npm run build:release -- --specialist-id <id> --version <semver>
```

Generated files go to ignored `dist/`; maintainers publish through the protected workflow.
