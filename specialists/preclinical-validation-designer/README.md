# Preclinical Mechanism Validation Design Specialist

Designs claim-locked cell and animal validation routes from computational or association findings, with defined experimental units, randomization, blinding, controls, and escalation gates, without inventing models, effect sizes, or ethics approvals.

## Versions

- `1.0.0` - initial release with 8 bundled Skills and 7 Connector references.

The package uses the OpenScience App export/import v1 layout. Connector entries are references only;
credentials and executable Connector configuration are not included.

## Bundled Skills

Scores come from the upstream skill-auditor report shipped with each Skill (`eval_report_*.json`),
except where that report's test section is templated; there the score recorded in the Skill's
`POLISH_CHANGELOG.md` is used and the reported figure is shown alongside.

| Skill                                | Display name                       | Role       | Audit score                                                           |
| ------------------------------------ | ---------------------------------- | ---------- | --------------------------------------------------------------------- |
| `mechanism-to-validation-planner`    | Mechanism-to-Validation Planner    | core       | 89 (Production Ready, 2026-04-22)                                     |
| `animal-and-cell-validation-planner` | Animal and Cell Validation Planner | core       | 88 (Production Ready, 2026-04-22)                                     |
| `translational-study-blueprint`      | Translational Study Blueprint      | core       | 89 (Production Ready, 2026-04-22)                                     |
| `experiment-design`                  | Experiment Design                  | supporting | 78 (polish changelog; report claims 87 from a templated test section) |
| `sample-size-basic`                  | Basic Sample Size Estimator        | supporting | 76 (polish changelog; report claims 90 from a templated test section) |
| `randomization-gen`                  | Randomization Generator            | supporting | 76 (polish changelog; report claims 90 from a templated test section) |
| `sop-writer`                         | SOP Writer                         | supporting | 77 (polish changelog; report claims 91 from a templated test section) |
| `methodology-extractor`              | Methodology Extractor              | supporting | 77 (polish changelog; report claims 91 from a templated test section) |

## Connector references

`cancer-models`, `research-resources`, `genes`, `protein-annotation`, `expression`, `pubmed`, `literature`

## Source

Skills from [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills) at `f5ef65b9bea79b6dd9553f52f95b0d08f7d64d26` (MIT).

Packaging notes (Skill files are otherwise byte-identical to that commit; audit reports are not
packaged):

- 11 text file(s) normalized to repository format: LF line endings, no trailing whitespace, no blank lines at end of file
