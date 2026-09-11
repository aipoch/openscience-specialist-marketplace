# Pharmacovigilance Signal Study Design Specialist

Designs deduplicated, MedDRA-versioned FAERS disproportionality, single-drug safety-atlas, and active-comparator signal studies with reporting-bias controls, without inventing reporting ratios, case counts, case facts, or causal claims.

## Versions

- `1.0.0` - initial release with 4 bundled Skills and 4 Connector references.

The package uses the OpenScience App export/import v1 layout. Connector entries are references only;
credentials and executable Connector configuration are not included.

## Bundled Skills

Scores come from the upstream skill-auditor report shipped with each Skill (`eval_report_*.json`),
except where that report's test section is templated; there the score recorded in the Skill's
`POLISH_CHANGELOG.md` is used and the reported figure is shown alongside.

| Skill                                                         | Display name                                          | Role       | Audit score                       |
| ------------------------------------------------------------- | ----------------------------------------------------- | ---------- | --------------------------------- |
| `faers-pharmacovigilance-disproportionality-research-planner` | FAERS Disproportionality Research Planner             | core       | 89 (Production Ready, 2026-04-22) |
| `single-drug-faers-safety-profile-research-planner`           | Single-Drug FAERS Safety Profile Planner              | core       | 89 (Production Ready, 2026-04-22) |
| `active-comparator-single-soc-faers-safety-comparison`        | Active-Comparator Single-SOC FAERS Comparison Planner | core       | 89 (Production Ready, 2026-04-22) |
| `confounder-and-bias-control-planner`                         | Confounder and Bias Control Planner                   | supporting | 89 (Production Ready, 2026-04-22) |

## Connector references

`drug-regulatory`, `pubmed`, `literature`, `chembl`

## Source

Skills from [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills) at `f5ef65b9bea79b6dd9553f52f95b0d08f7d64d26` (MIT).

Packaging notes (Skill files are otherwise byte-identical to that commit; audit reports are not
packaged):

- None.
