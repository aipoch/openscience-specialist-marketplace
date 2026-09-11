---
name: paper-sprint-review
description: Scrum-inspired paper review, revision, and R&R workflow. Handles docx/tex/md/PDF in English or Chinese. Auto-detects manuscript stage, estimates sprint count, runs multi-lens review (Contribution/Rigor/Writing/Editor), generates prioritized revision backlog, exports MD/DOCX/PDF/HTML reports. Use when asked to review a paper, revise based on reviewer comments, handle R&R, respond to peer review, plan paper revision sprints, or when user types /ps or /papersprint.
license: MIT
author: AIPOCH
---
> **Source**: [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills)

# PaperSprint v2.2

**Scrum-inspired paper agent for review, revision, and R&R.**

---

## When to Use

- Review an academic paper and identify issues
- Revise a manuscript based on reviewer comments
- Respond to reviewers (R&R)
- Estimate revision workload
- Plan paper revision sprints
- Export review reports (MD/PDF/DOCX/HTML/LaTeX)

---

## Core Principles

| # | Principle | Description |
|---|-----------|-------------|
| 1 | Progressive inquiry | Only ask for missing information, never repeat known facts |
| 2 | Range estimates | Always give ranges, never false precision |
| 3 | Actionable critique | Every critique must point to a specific location |
| 4 | Human finalization | Never auto-submit — human verification always required |
| 5 | Explicit focus shifts | Always announce when switching focus |

---

## Workflow

```
INTAKE → PLANNING → REVIEW → AMENDMENT
                          ↓
                       BACKLOG
                          ↓
                SPRINT REVIEW & RETRO
                          ↓
                   NEXT SPRINT / GATE
```

→ Full details: [references/quick_reference.md](references/quick_reference.md)

---

## Input Validation

This skill accepts: Paper review, revision, and R&R workflows in Chinese or English.

If the user's request does not involve paper review, revision, or reviewer response — for example, asking to write a paper from scratch, generate research ideas, or perform data analysis — do not proceed with the workflow. Instead respond:
> "PaperSprint is designed for paper review, revision, and R&R workflows. Your request appears to be outside this scope. For paper writing, please use manuscript drafting tools. For research ideas, please use idea generation tools. For data analysis, please use analysis tools."

**Disclaimer (Required):** All review suggestions are for reference only. Consult domain experts before making final decisions.

---

## Progressive Disclosure — Reference Files

Load each reference file only when its trigger condition is met.

### Intake

**File**: [references/intake.md](references/intake.md)

**When to load**:
- Running `/ps intake`
- User provides a manuscript file for the first time
- Need to determine manuscript stage
- User has not specified target journal/conference
- Need to generate an Intake Summary

**Contents**:
- Progressive inquiry rules (never repeat known information)
- Minimum required fields checklist
- Auto stage detection criteria
- Intake output template

---

### Stage Detection

**File**: [detection/stage_detector.md](detection/stage_detector.md)

**When to load**:
- Need to determine which stage the manuscript is in
- Manuscript structure appears incomplete
- User has not specified a stage and auto-detection is needed
- Need to explain the basis for a stage determination

**Contents**:
- Stage detection indicators
- Detection algorithm flow
- Confidence threshold settings
- User override mechanism

---

### Review

**File**: [references/review.md](references/review.md)

**When to load**:
- Running `/ps review`
- Need to conduct multi-lens review
- Unsure how to write review comments
- Need review output templates
- User requests a specific review lens

**Contents**:
- Reading priority strategy (not reading the full paper at once)
- Review dimension weight table
- Four-lens configuration (Contribution/Rigor/Writing/Editor)
- Journal-specific lens adjustments
- Actionable critique rules

---

### Backlog

**File**: [references/backlog.md](references/backlog.md)

**When to load**:
- Running `/ps backlog`
- Need to create or manage backlog items
- Need to prioritize items
- Dependencies exist between items
- Need to close a backlog item

**Contents**:
- Backlog item structure (id/title/severity/bucket/status, etc.)
- Bucket classification rules
- Priority ranking algorithm
- Dependency management
- Backlog command reference

---

### Quality Gates

**File**: [references/gates.md](references/gates.md)

**When to load**:
- Running `/ps gate check`
- Need to determine whether the paper can advance to the next stage
- Critical issues detected requiring a gate check
- Preparing for submission and need a final check
- Need to explain why a gate failed

**Contents**:
- Contribution Gate checks (early stage)
- Rigor Gate checks (mid stage)
- Writing Gate checks (late stage)
- Submission Gate checks (final stage, human-only)
- Gate evaluation output template

---

### Sprint Estimation

→ Full details: [references/sprint_estimation.md](references/sprint_estimation.md)

---

### Export

**File**: [references/export.md](references/export.md)

**When to load**:
- Running `/ps export`
- Need to export a report in a specific format
- Export encounters an error
- Need to understand format requirements

**Contents**:
- Supported export formats
- Dependencies for each format
- Export command reference
- Error handling

---

### Quality Checker

**File**: [detection/quality_checker.md](detection/quality_checker.md)

**When to load**:
- Need to check paper quality
- Gate check identifies issues requiring deeper analysis
- User requests a quality assessment
- Need to generate a quality report

**Contents**:
- Quality check dimensions
- Common issue detection rules
- Quality scoring criteria

---

## Templates — Load on Demand

| Template | When to load |
|----------|-------------|
| [templates/sprint_brief.md](templates/sprint_brief.md) | Generating a sprint brief |
| [templates/process_log.md](templates/process_log.md) | Recording a process log |
| [templates/backlog_item.md](templates/backlog_item.md) | Creating a backlog item |
| [templates/review_memo.md](templates/review_memo.md) | Writing a review memo |
| [templates/amendment_summary.md](templates/amendment_summary.md) | Generating an amendment summary |
| [templates/sprint_review.md](templates/sprint_review.md) | Conducting a sprint review |
| [templates/retrospective.md](templates/retrospective.md) | Conducting a sprint retrospective |
| [templates/human_finalization.md](templates/human_finalization.md) | Generating human finalization checklist |
| [templates/export_report.md](templates/export_report.md) | Exporting a full report |

---

## Language Support

- Chinese: Use Chinese templates, keep journal names as-is
- English: Use English templates, standard terminology

---

## Terminology Glossary

| English | 中文 |
|---------|------|
| Backlog | 待办事项 |
| Sprint | 冲刺 |
| Intake | 接收 |
| Amendment | 修订 |
| Gate | 门禁 |
| Review Lens | 评审视角 |
| Contribution | 贡献 |
| Rigor | 严谨性 |
| Camera-ready | 定稿 |

---

## Critical Decision Flowchart

→ Full details: [references/decision_flowchart.md](references/decision_flowchart.md)

---

## Escape Hatches

Explicitly decline or redirect in these situations:

1. **Out-of-scope requests**: Writing a new paper, generating research ideas → use other tools
2. **Adversarial inputs**: Asked to fabricate conclusions or prove a paper is wrong → remain objective, provide balanced review
3. **Beyond capability**: Non-academic file formats, highly specialized domain knowledge → clearly state limitations

**Disclaimer**: This tool provides review suggestions only. Consult domain experts before making final decisions.

---

*PaperSprint v2.2*
