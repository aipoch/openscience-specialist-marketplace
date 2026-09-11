# Manuscript Submission and Peer-Review Revision Specialist

Runs pre-submission QA, reporting-guideline, consistency and reference checks, anonymization, revision triage, and location-mapped reviewer responses for biomedical manuscripts without claiming experiments, analyses, or edits the authors have not supplied.

## Versions

- `1.0.0` - initial release with 16 bundled Skills and 4 Connector references.

The package uses the OpenScience App export/import v1 layout. Connector entries are references only;
credentials and executable Connector configuration are not included.

## Bundled Skills

Scores come from the upstream skill-auditor report shipped with each Skill (`eval_report_*.json`),
except where that report's test section is templated; there the score recorded in the Skill's
`POLISH_CHANGELOG.md` is used and the reported figure is shown alongside.

| Skill                                    | Display name                           | Role       | Audit score                                                           |
| ---------------------------------------- | -------------------------------------- | ---------- | --------------------------------------------------------------------- |
| `paper-sprint-review`                    | Paper Sprint Review                    | core       | 95 (Production Ready, 2026-04-20)                                     |
| `revision-strategy-planner`              | Revision Strategy Planner              | core       | 91 (Production Ready, 2026-04-22)                                     |
| `response-letter`                        | Point-by-Point Response Letter         | supporting | 77 (polish changelog; report claims 90 from a templated test section) |
| `reporting-guideline-compliance-checker` | Reporting Guideline Compliance Checker | core       | 91 (Production Ready, 2026-04-22)                                     |
| `consistency-checker-across-manuscript`  | Cross-Manuscript Consistency Checker   | core       | 85 (Production Ready, 2026-04-22)                                     |
| `reference-integrity-checker`            | Reference Integrity Checker            | core       | 91 (Production Ready, 2026-04-22)                                     |
| `author-response-builder`                | Author Response Builder                | supporting | 84 (Limited Release, 2026-04-22)                                      |
| `rebuttal-letter-strategist`             | Rebuttal Letter Strategist             | supporting | 77 (polish changelog; report claims 91 from a templated test section) |
| `response-tone-polisher`                 | Response Tone Polisher                 | supporting | 76 (polish changelog; report claims 91 from a templated test section) |
| `claim-strength-calibrator`              | Claim Strength Calibrator              | supporting | 85 (Production Ready, 2026-04-22)                                     |
| `retraction-watcher`                     | Retraction Watcher                     | supporting | 76 (polish changelog; report claims 90 from a templated test section) |
| `cover-letter-drafter`                   | Cover Letter Drafter                   | supporting | 86 (Production Ready, 2026-04-22)                                     |
| `blind-review-sanitizer`                 | Blind Review Sanitizer                 | supporting | 77 (polish changelog; report claims 91 from a templated test section) |
| `figure-reference-checker`               | Figure Reference Checker               | supporting | 77 (polish changelog; report claims 92 from a templated test section) |
| `arxiv-preflight`                        | arXiv Preflight                        | supporting | 90 (Production Ready, 2026-05-21)                                     |
| `journal-recommender`                    | Journal Recommender                    | supporting | 77 (polish changelog; report claims 87 from a templated test section) |

## Connector references

`pubmed`, `literature`, `clinical-trials`, `biorxiv`

## Source

Skills from [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills) at `f5ef65b9bea79b6dd9553f52f95b0d08f7d64d26` (MIT).

Packaging notes (Skill files are otherwise byte-identical to that commit; audit reports are not
packaged):

- reference-integrity-checker: bytes reused from published auto-research-specialist@1.0.1 (content digest a9a06b5101b9) so installing both Specialists does not raise a Skill conflict
- response-tone-polisher: upstream SKILL.md references `references/examples/`, which upstream never shipped — accepted: optional before/after examples; polite_expressions.json and tone_patterns.md ship and SKILL.md carries the method
- response-tone-polisher: upstream SKILL.md references `requirements.txt`, which upstream never shipped — accepted: scripts/main.py imports only the Python standard library
- claim-strength-calibrator: bytes reused from published auto-research-specialist@1.0.1 (content digest 1421449d5557) so installing both Specialists does not raise a Skill conflict
- retraction-watcher: upstream SKILL.md references `references/citation-formats.md`, which upstream never shipped — accepted: peripheral format notes; scripts/main.py implements parsing and SKILL.md documents inputs
- retraction-watcher: upstream SKILL.md references `references/api-documentation.md`, which upstream never shipped — accepted: peripheral API notes; endpoints are hard-coded in scripts/main.py
- retraction-watcher: upstream SKILL.md references `references/example-reports/`, which upstream never shipped — accepted: sample outputs only; SKILL.md defines the report format
- retraction-watcher: upstream SKILL.md references `requirements.txt`, which upstream never shipped — accepted: scripts/main.py is standard library except optional PyPDF2 for PDF input
