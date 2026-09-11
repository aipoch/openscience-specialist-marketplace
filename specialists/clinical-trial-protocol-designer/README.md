# Clinical Trial Protocol Design Specialist

Designs estimand-anchored, registry-informed clinical trial protocols—endpoints, eligibility, sample size, randomization, interim rules, and reporting checks—for research and regulatory planning without giving individual treatment advice or implying ethics approval.

## Versions

- `1.0.0` - initial release with 10 bundled Skills and 4 Connector references.

The package uses the OpenScience App export/import v1 layout. Connector entries are references only;
credentials and executable Connector configuration are not included.

## Bundled Skills

Scores come from the upstream skill-auditor report shipped with each Skill (`eval_report_*.json`),
except where that report's test section is templated; there the score recorded in the Skill's
`POLISH_CHANGELOG.md` is used and the reported figure is shown alongside.

| Skill                                      | Display name                             | Role       | Audit score                                                           |
| ------------------------------------------ | ---------------------------------------- | ---------- | --------------------------------------------------------------------- |
| `clinical-trial-protocol-skill`            | Clinical Trial Protocol Generator        | supporting | 77 (polish changelog; report claims 88 from a templated test section) |
| `endpoint-definition-designer`             | Endpoint Definition Designer             | core       | 90 (Production Ready, 2026-04-22)                                     |
| `inclusion-exclusion-criteria-builder`     | Inclusion-Exclusion Criteria Builder     | core       | 90 (Production Ready, 2026-04-22)                                     |
| `sample-size-and-power-planning-assistant` | Sample Size and Power Planning Assistant | core       | 90 (Production Ready, 2026-04-22)                                     |
| `randomization-gen`                        | Randomization Sequence Generator         | supporting | 76 (polish changelog; report claims 90 from a templated test section) |
| `adaptive-trial-simulator`                 | Adaptive Trial Simulator                 | supporting | 76 (polish changelog; report claims 91 from a templated test section) |
| `tooluniverse-clinical-trial-design`       | Trial Feasibility Assessment Framework   | supporting | 77 (polish changelog; report claims 89 from a templated test section) |
| `sop-writer`                               | SOP Writer                               | supporting | 77 (polish changelog; report claims 91 from a templated test section) |
| `clinicaltrials-database`                  | ClinicalTrials.gov Database              | supporting | 77 (polish changelog; report claims 88 from a templated test section) |
| `reporting-guideline-compliance-checker`   | Reporting Guideline Compliance Checker   | core       | 91 (Production Ready, 2026-04-22)                                     |

## Connector references

`clinical-trials`, `drug-regulatory`, `pubmed`, `literature`

## Source

Skills from [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills) at `f5ef65b9bea79b6dd9553f52f95b0d08f7d64d26` (MIT).

Packaging notes (Skill files are otherwise byte-identical to that commit; audit reports are not
packaged):

- endpoint-definition-designer: bytes reused from published auto-research-specialist@1.0.1 (content digest f6ec94c36758) so installing both Specialists does not raise a Skill conflict
- 27 text file(s) normalized to repository format: LF line endings, no trailing whitespace, no blank lines at end of file
