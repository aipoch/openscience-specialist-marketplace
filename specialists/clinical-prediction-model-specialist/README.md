# Clinical Prediction Model Development and Validation Specialist

Plans, develops, and validates diagnostic and prognostic clinical prediction models with leakage-safe selection, sample-size and optimism checks, calibration, decision curves, and TRIPOD-aligned reporting for research, without issuing individual patient risk predictions.

## Versions

- `1.0.0` - initial release with 18 bundled Skills and 4 Connector references.

The package uses the OpenScience App export/import v1 layout. Connector entries are references only;
credentials and executable Connector configuration are not included.

## Bundled Skills

Scores come from the upstream skill-auditor report shipped with each Skill (`eval_report_*.json`),
except where that report's test section is templated; there the score recorded in the Skill's
`POLISH_CHANGELOG.md` is used and the reported figure is shown alongside.

| Skill                                      | Display name                                 | Role       | Audit score                       |
| ------------------------------------------ | -------------------------------------------- | ---------- | --------------------------------- |
| `prognostic-biomarker-protocol-designer`   | Prognostic Biomarker Protocol Designer       | core       | 90 (Production Ready, 2026-04-22) |
| `validation-strategy-designer`             | Validation Strategy Designer                 | core       | 88 (Production Ready, 2026-04-22) |
| `sample-size-and-power-planning-assistant` | Sample Size and Power Planning Assistant     | supporting | 90 (Production Ready, 2026-04-22) |
| `lasso-logistics-analysis`                 | LASSO Logistic Regression Analysis           | core       | 85 (Production Ready, 2026-04-27) |
| `univariate-multivariable-cox-regression`  | Univariable and Multivariable Cox Regression | core       | 86 (Production Ready, 2026-04-27) |
| `nomogram-construction`                    | Nomogram Construction                        | core       | 96 (Production Ready, 2026-04-27) |
| `model-calibration-curve`                  | Survival Model Calibration Curve             | core       | 95 (Production Ready, 2026-04-27) |
| `decision-curve-analysis`                  | Decision Curve Analysis                      | core       | 87 (Production Ready, 2026-04-27) |
| `external-model-validation`                | External Signature Validation                | core       | 90 (Production Ready, 2026-04-27) |
| `roc-diagnostic-performance`               | ROC Diagnostic Performance                   | supporting | 85 (Production Ready, 2026-04-27) |
| `time-dependent-roc`                       | Time-Dependent ROC Analysis                  | core       | 87 (Production Ready, 2026-04-16) |
| `elastic-net-feature-selection`            | Elastic Net Feature Selection                | supporting | 87 (Production Ready, 2026-04-27) |
| `rf-model-importance-analysis`             | Random Forest Importance Analysis            | supporting | 92 (Production Ready, 2026-04-20) |
| `svm-model-importance-analysis`            | SVM-RFE Feature Ranking                      | supporting | 93 (Production Ready, 2026-04-20) |
| `xgboost-analysis`                         | XGBoost Modeling and Importance              | supporting | 88 (Production Ready, 2026-04-20) |
| `lightgbm-analysis`                        | LightGBM Modeling and Importance             | supporting | 86 (Production Ready, 2026-04-22) |
| `km-survival-curve`                        | Kaplan-Meier Survival Curve                  | supporting | 92 (Production Ready, 2026-04-20) |
| `reporting-guideline-compliance-checker`   | Reporting Guideline Compliance Checker       | supporting | 91 (Production Ready, 2026-04-22) |

## Connector references

`pubmed`, `literature`, `expression`, `omics-archives`

## Source

Skills from [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills) at `f5ef65b9bea79b6dd9553f52f95b0d08f7d64d26` (MIT).

Packaging notes (Skill files are otherwise byte-identical to that commit; audit reports are not
packaged):

- validation-strategy-designer: bytes reused from published auto-research-specialist@1.0.1 (content digest fad52ea8f5f9) so installing both Specialists does not raise a Skill conflict
- lasso-logistics-analysis: bytes reused from published auto-research-specialist@1.0.1 (content digest 22ac45da3abb) so installing both Specialists does not raise a Skill conflict
- nomogram-construction: upstream SKILL.md references `scripts/install_dependencies.R`, which upstream never shipped — accepted: dependency installer not shipped upstream; analysis scripts present
- model-calibration-curve: upstream SKILL.md references `scripts/install_dependencies.R`, which upstream never shipped — accepted: dependency installer not shipped upstream; analysis scripts present
- external-model-validation: bytes reused from published auto-research-specialist@1.0.1 (content digest a95dfa782a67) so installing both Specialists does not raise a Skill conflict
