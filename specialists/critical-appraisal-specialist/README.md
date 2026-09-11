# Biomedical Critical Appraisal Specialist

Appraises individual biomedical papers or small paper sets for journal club, peer review and citation decisions, routing by verified study design to risk-of-bias, claim, spin and registry checks without reconstructing papers from memory.

## Versions

- `1.0.0` - initial release with 14 bundled Skills and 5 Connector references.

The package uses the OpenScience App export/import v1 layout. Connector entries are references only;
credentials and executable Connector configuration are not included.

## Bundled Skills

Scores come from the upstream skill-auditor report shipped with each Skill (`eval_report_*.json`),
except where that report's test section is templated; there the score recorded in the Skill's
`POLISH_CHANGELOG.md` is used and the reported figure is shown alongside.

| Skill                                          | Display name                                      | Role       | Audit score                                                           |
| ---------------------------------------------- | ------------------------------------------------- | ---------- | --------------------------------------------------------------------- |
| `study-design-identifier`                      | Study Design Identifier                           | core       | 86 (Production Ready, 2026-04-22)                                     |
| `medical-research-literature-reader-pro`       | Medical Research Literature Reader Pro            | core       | 93 (Production Ready, 2026-04-22)                                     |
| `rct-bias-assessment-rob2`                     | RCT Risk of Bias Assessment (RoB 2)               | supporting | 78 (polish changelog; report claims 91 from a templated test section) |
| `diagnostic-study-quality-assessment-quadas-2` | Diagnostic Accuracy Quality Assessment (QUADAS-2) | supporting | 78 (polish changelog; report claims 91 from a templated test section) |
| `result-reliability-checker`                   | Result Reliability Checker                        | core       | 88 (Production Ready, 2026-04-22)                                     |
| `paper-to-claim-verifier`                      | Paper-to-Claim Verifier                           | core       | 89 (Production Ready, 2026-04-22)                                     |
| `high-value-paper-screener`                    | High-Value Paper Screener                         | supporting | 88 (Production Ready, 2026-04-22)                                     |
| `figure-first-paper-reader`                    | Figure-First Paper Reader                         | supporting | 87 (Production Ready, 2026-04-22)                                     |
| `methods-reverse-engineer`                     | Methods Reverse Engineer                          | supporting | 90 (Production Ready, 2026-04-22)                                     |
| `reproducibility-check`                        | Reproducibility Check                             | supporting | 76 (polish changelog; report claims 90 from a templated test section) |
| `reporting-guideline-compliance-checker`       | Reporting Guideline Compliance Checker            | supporting | 91 (Production Ready, 2026-04-22)                                     |
| `scientific-critical-thinking`                 | Scientific Critical Thinking                      | supporting | 78 (polish changelog; report claims 87 from a templated test section) |
| `contradictory-findings-resolver`              | Contradictory Findings Resolver                   | supporting | 86 (Production Ready, 2026-04-22)                                     |
| `retraction-watcher`                           | Retraction Watcher                                | supporting | 76 (polish changelog; report claims 90 from a templated test section) |

## Connector references

`pubmed`, `literature`, `biorxiv`, `clinical-trials`, `drug-regulatory`

## Source

Skills from [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills) at `f5ef65b9bea79b6dd9553f52f95b0d08f7d64d26` (MIT).

Packaging notes (Skill files are otherwise byte-identical to that commit; audit reports are not
packaged):

- result-reliability-checker: bytes reused from published auto-research-specialist@1.0.1 (content digest 505bb5d05fab) so installing both Specialists does not raise a Skill conflict
- scientific-critical-thinking: upstream SKILL.md references `scripts/generate_schematic.py`, which upstream never shipped — accepted: schematic generator not shipped upstream; appraisal method is in SKILL.md and references
- retraction-watcher: upstream SKILL.md references `references/citation-formats.md`, which upstream never shipped — accepted: supplementary format notes never shipped upstream; parsing logic lives in scripts/main.py
- retraction-watcher: upstream SKILL.md references `references/api-documentation.md`, which upstream never shipped — accepted: supplementary API notes never shipped upstream; endpoints are hard-coded in scripts/main.py
- retraction-watcher: upstream SKILL.md references `references/example-reports/`, which upstream never shipped — accepted: sample reports never shipped upstream; output format is specified in SKILL.md
- retraction-watcher: upstream SKILL.md references `requirements.txt`, which upstream never shipped — accepted: never shipped upstream; scripts/main.py uses only the standard library except optional PyPDF2 for PDF input
