# Real-World Evidence and Observational Epidemiology Specialist

Designs and audits target-trial-aligned cohort, case-control, and survey studies on EHR, claims, registry, and NHANES-type data with explicit time zero, DAG-justified confounding control, and bias sensitivity analyses, without drawing individual patient conclusions.

## Versions

- `1.0.0` - initial release with 12 bundled Skills and 5 Connector references.

The package uses the OpenScience App export/import v1 layout. Connector entries are references only;
credentials and executable Connector configuration are not included.

## Bundled Skills

Scores come from the upstream skill-auditor report shipped with each Skill (`eval_report_*.json`),
except where that report's test section is templated; there the score recorded in the Skill's
`POLISH_CHANGELOG.md` is used and the reported figure is shown alongside.

| Skill                                                      | Display name                                | Role       | Audit score                                                           |
| ---------------------------------------------------------- | ------------------------------------------- | ---------- | --------------------------------------------------------------------- |
| `real-world-evidence-study-designer`                       | Real-World Evidence Study Designer          | core       | 88 (Production Ready, 2026-04-22)                                     |
| `clinical-cohort-protocol-designer`                        | Clinical Cohort Protocol Designer           | core       | 90 (Production Ready, 2026-04-22)                                     |
| `confounder-and-bias-control-planner`                      | Confounder and Bias Control Planner         | core       | 89 (Production Ready, 2026-04-22)                                     |
| `case-control-study-planner`                               | Case-Control Study Planner                  | core       | 86 (Production Ready, 2026-04-22)                                     |
| `clinical-data-cleaner`                                    | Clinical Data Cleaner                       | supporting | 76 (polish changelog; report claims 91 from a templated test section) |
| `nhanes-clinical-retrospective-biomarker-research-planner` | NHANES Biomarker Research Planner           | supporting | 89 (Production Ready, 2026-04-22)                                     |
| `sample-size-and-power-planning-assistant`                 | Sample Size and Power Planning Assistant    | supporting | 90 (Production Ready, 2026-04-22)                                     |
| `table-1-generator-advanced`                               | Table 1 Generator                           | supporting | 75 (polish changelog; report claims 90 from a templated test section) |
| `univariate-multivariable-cox-regression`                  | Univariate and Multivariable Cox Regression | supporting | 86 (Production Ready, 2026-04-27)                                     |
| `km-survival-curve`                                        | Kaplan-Meier Survival Curve                 | supporting | 92 (Production Ready, 2026-04-20)                                     |
| `epidemiology`                                             | Epidemiology                                | supporting | 75 (polish changelog; report claims 86 from a templated test section) |
| `reporting-guideline-compliance-checker`                   | Reporting Guideline Compliance Checker      | core       | 91 (Production Ready, 2026-04-22)                                     |

## Connector references

`pubmed`, `literature`, `clinical-trials`, `drug-regulatory`, `research-resources`

## Source

Skills from [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills) at `f5ef65b9bea79b6dd9553f52f95b0d08f7d64d26` (MIT).

Packaging notes (Skill files are otherwise byte-identical to that commit; audit reports are not
packaged):

- 9 text file(s) normalized to repository format: LF line endings, no trailing whitespace, no blank lines at end of file
