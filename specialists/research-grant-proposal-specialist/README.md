# Research Grant Proposal Specialist

Frames testable aims, drafts agency-aligned proposal sections, and stress-tests them with structured mock review, verifying the current funding notice and never inventing preliminary data, citations, budgets, or reviewer scores.

## Versions

- `1.0.0` - initial release with 8 bundled Skills and 5 Connector references.

The package uses the OpenScience App export/import v1 layout. Connector entries are references only;
credentials and executable Connector configuration are not included.

## Bundled Skills

Scores come from the upstream skill-auditor report shipped with each Skill (`eval_report_*.json`),
except where that report's test section is templated; there the score recorded in the Skill's
`POLISH_CHANGELOG.md` is used and the reported figure is shown alongside.

| Skill                                      | Display name                             | Role       | Audit score                                                           |
| ------------------------------------------ | ---------------------------------------- | ---------- | --------------------------------------------------------------------- |
| `grant-proposal-assistant`                 | Grant Proposal Assistant                 | supporting | 76 (polish changelog; report claims 91 from a templated test section) |
| `grant-specific-aims-writer`               | Grant Specific Aims Writer               | core       | 86 (Production Ready, 2026-04-22)                                     |
| `aim-and-hypothesis-designer`              | Aim and Hypothesis Designer              | core       | 89 (Production Ready, 2026-04-22)                                     |
| `grant-mock-reviewer`                      | Grant Mock Reviewer                      | supporting | 76 (polish changelog; report claims 90 from a templated test section) |
| `grant-budget-justification`               | Grant Budget Justification               | supporting | 77 (polish changelog; report claims 91 from a templated test section) |
| `novelty-vs-feasibility-assessor`          | Novelty vs. Feasibility Assessor         | supporting | 87 (Production Ready, 2026-04-22)                                     |
| `feasibility-aware-study-planner`          | Feasibility-Aware Study Planner          | core       | 90 (Production Ready, 2026-04-22)                                     |
| `sample-size-and-power-planning-assistant` | Sample Size and Power Planning Assistant | supporting | 90 (Production Ready, 2026-04-22)                                     |

## Connector references

`pubmed`, `literature`, `biorxiv`, `research-resources`, `clinical-trials`

## Source

Skills from [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills) at `f5ef65b9bea79b6dd9553f52f95b0d08f7d64d26` (MIT).

Packaging notes (Skill files are otherwise byte-identical to that commit; audit reports are not
packaged):

- novelty-vs-feasibility-assessor: bytes reused from published auto-research-specialist@1.0.1 (content digest d8137f2f4b8e) so installing both Specialists does not raise a Skill conflict
