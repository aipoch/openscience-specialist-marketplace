# Mendelian Randomization and Causal Genomics Specialist

Designs assumption-audited Mendelian randomization, pleiotropy-sensitivity, and QTL colocalization studies from GWAS summary statistics, with instrument, ancestry, overlap, and harmonization gates and supporting MR execution, without claiming proven causality or clinical advice.

## Versions

- `1.0.0` - initial release with 9 bundled Skills and 7 Connector references.

The package uses the OpenScience App export/import v1 layout. Connector entries are references only;
credentials and executable Connector configuration are not included.

## Bundled Skills

Scores come from the upstream skill-auditor report shipped with each Skill (`eval_report_*.json`),
except where that report's test section is templated; there the score recorded in the Skill's
`POLISH_CHANGELOG.md` is used and the reported figure is shown alongside.

| Skill                                                 | Display name                             | Role       | Audit score                                                           |
| ----------------------------------------------------- | ---------------------------------------- | ---------- | --------------------------------------------------------------------- |
| `mendelian-randomization-protocol-designer`           | MR Protocol Designer                     | core       | 91 (Production Ready, 2026-04-22)                                     |
| `two-sample-mr-exposure-screening-reference-grounded` | Two-Sample MR Exposure Screening Planner | core       | 89 (Production Ready, 2026-04-22)                                     |
| `mendelian-randomisation`                             | Two-Sample MR Estimator                  | supporting | 77 (polish changelog; report claims 87 from a templated test section) |
| `bio-causal-genomics-pleiotropy-detection`            | MR Pleiotropy Sensitivity Toolkit        | supporting | 79 (polish changelog; report claims 86 from a templated test section) |
| `qtl-colocalization-study-planner`                    | QTL Colocalization Study Planner         | core       | 91 (Production Ready, 2026-04-22)                                     |
| `bidirectional-multi-phenotype-mr-research-planner`   | Bidirectional Multi-Phenotype MR Planner | supporting | 91 (Production Ready, 2026-04-22)                                     |
| `mr-scrna-research-planner`                           | MR and Single-Cell Integration Planner   | supporting | 90 (Production Ready, 2026-04-22)                                     |
| `bio-causal-genomics-mediation-analysis`              | Genetic Effect Mediation Analysis        | supporting | 78 (polish changelog; report claims 86 from a templated test section) |
| `gwas-database`                                       | GWAS Catalog Retrieval                   | supporting | 75 (polish changelog; report claims 87 from a templated test section) |

## Connector references

`human-genetics`, `variants`, `genes`, `expression`, `pubmed`, `literature`, `biorxiv`

## Source

Skills from [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills) at `f5ef65b9bea79b6dd9553f52f95b0d08f7d64d26` (MIT).

Packaging notes (Skill files are otherwise byte-identical to that commit; audit reports are not
packaged):

- gwas-database: upstream SKILL.md references `references/api_reference.md`, which upstream never shipped — accepted: supplementary API reference not shipped upstream; SKILL.md body documents the queries
- 3 text file(s) normalized to repository format: LF line endings, no trailing whitespace, no blank lines at end of file
