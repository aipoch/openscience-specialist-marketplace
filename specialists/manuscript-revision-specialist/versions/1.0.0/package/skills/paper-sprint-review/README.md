# PaperSprint v2.2

[![Skill](https://img.shields.io/badge/skill-PaperSprint-0f766e)](https://github.com/OhMyOpenCode/paper-sprint-review)
[![Method](https://img.shields.io/badge/method-Scrum--inspired-1d4ed8)]()
[![Scope](https://img.shields.io/badge/scope-review%20%7C%20revision%20%7C%20R%26R-b45309)]()
[![License](https://img.shields.io/badge/license-MIT-111827)]()
[![Version](https://img.shields.io/badge/version-2.2-22c55e)]()

> **Scrum-inspired paper agent for review, revision, and R&R.**
>
>
---

## What is PaperSprint?

PaperSprint transforms academic paper polishing into structured **Scrum-style sprints**. Instead of ad-hoc editing suggestions, it provides:

- **Sprint-based workflow** with clear goals and deliverables
- **Stage-aware estimation** calibrated to manuscript maturity
- **Multi-lens review** with actionable, specific feedback
- **Prioritized backlog** of revision items
- **Quality gates** for publication readiness
- **Process continuity** across sessions

---

## Quick Start

### Basic Usage

```
Use PaperSprint (paper-sprint-review) for my manuscript.
Target venue: ECIS 2026
Current stage: early draft
Materials: ./manuscript.md
```

### Command Reference

| Command | Action |
|---------|--------|
| `/ps` | Start full workflow from intake |
| `/ps intake` | Run intake only |
| `/ps review` | Run review increment |
| `/ps amend` | Run amendment increment |
| `/ps status` | Show current progress |
| `/ps backlog` | View/manage backlog |
| `/ps backlog critical` | View critical items only |
| `/ps backlog next` | Show next priority item |
| `/ps backlog close B1` | Close backlog item |
| `/ps gate check contribution` | Check contribution gate |
| `/ps gate check rigor` | Check rigor gate |
| `/ps gate check writing` | Check writing gate |
| `/ps export` | Export all artifacts |
| `/ps reset` | Reset current session |

---

## Use Cases

### A. Paper Review

| # | Scenario | Description | How to Test |
|---|----------|-------------|-------------|
| A1 | **Full Paper Review** | Multi-perspective systematic review | Provide PDF/MD file |
| A2 | **Quick Review** | Focus on specific dimension | Specify review focus |
| A3 | **Conference Paper Review** | Conference submission format | Provide paper + venue name |
| A4 | **Journal Paper Review** | Journal submission format | Provide paper + journal name |

### B. Revision & R&R

| # | Scenario | Description | How to Test |
|---|----------|-------------|-------------|
| B1 | **Reviewer Response** | Strategy for reviewer comments | Provide paper + review comments |
| B2 | **Major Revision** | Handle major revision requests | Provide paper + review comments |
| B3 | **Minor Revision** | Handle minor revision requests | Provide paper + review comments |
| B4 | **Rebuttal Writing** | Draft response letter | Provide paper + review comments |

### C. Stage Detection

| # | Scenario | Description | How to Test |
|---|----------|-------------|-------------|
| C1 | **Idea/Outline Stage** | Detect early conceptual stage | Provide rough notes |
| C2 | **Early Draft Stage** | Detect incomplete draft | Provide partial draft |
| C3 | **Mature Draft Stage** | Detect near-complete manuscript | Provide complete draft |
| C4 | **Auto Detection** | Automatic stage identification | Provide any manuscript |

### D. Sprint Planning

| # | Scenario | Description | How to Test |
|---|----------|-------------|-------------|
| D1 | **Work Estimation** | Estimate sprint count needed | Provide paper + target venue |
| D2 | **Sprint Planning** | Create phased revision plan | Provide paper + revision goals |
| D3 | **Focus Shift** | Recommend focus adjustment | After review discovers issues |

### E. Review Lenses

| # | Scenario | Description | How to Test |
|---|----------|-------------|-------------|
| E1 | **Contribution Lens** | Focus on novelty & significance | `--lens contribution` |
| E2 | **Rigor Lens** | Focus on theory & method | `--lens rigor` |
| E3 | **Writing Lens** | Focus on clarity & structure | `--lens writing` |
| E4 | **Editor Lens** | Overall publication merit | `--lens editor` |
| E5 | **Custom Lens** | User-defined perspective | Describe review needs |

### F. Export Formats

| # | Scenario | Description | How to Test |
|---|----------|-------------|-------------|
| F1 | **Markdown Export** | Export report as MD | `/ps export --format md` |
| F2 | **PDF Export** | Export report as PDF | `/ps export --format pdf` |
| F3 | **DOCX Export** | Export report as Word | `/ps export --format docx` |
| F4 | **HTML Export** | Export report as HTML | `/ps export --format html` |
| F5 | **LaTeX Export** | Export report as LaTeX | `/ps export --format latex` |
| F6 | **All Formats** | Export all formats at once | `/ps export --all` |

### G. Backlog Management

| # | Scenario | Description | How to Test |
|---|----------|-------------|-------------|
| G1 | **Generate Backlog** | Convert review to prioritized list | After review completion |
| G2 | **View Critical** | Show only critical issues | `/ps backlog critical` |
| G3 | **Close Item** | Mark issue as resolved | `/ps backlog close B001` |
| G4 | **Add Item** | Manually add backlog item | `/ps backlog add` |

### H. Session Recovery

| # | Scenario | Description | How to Test |
|---|----------|-------------|-------------|
| H1 | **Cross-Session Resume** | Continue from last session | Provide Process Log file |
| H2 | **View Status** | Check current progress | `/ps status` |

### I. Format Support

| # | Scenario | Description | How to Test |
|---|----------|-------------|-------------|
| I1 | **PDF Paper** | Review PDF format papers | Provide PDF file |
| I2 | **DOCX Paper** | Review Word format papers | Provide DOCX file |
| I3 | **LaTeX Paper** | Review LaTeX format papers | Provide TEX file |
| I4 | **Bilingual** | Chinese/English support | Communicate in preferred language |

### J. Quality Gates

| # | Scenario | Description | How to Test |
|---|----------|-------------|-------------|
| J1 | **Contribution Gate** | Check contribution clarity | `/ps gate check contribution` |
| J2 | **Rigor Gate** | Check theory/method soundness | `/ps gate check rigor` |
| J3 | **Writing Gate** | Check writing quality | `/ps gate check writing` |
| J4 | **Finalization Gate** | Generate human checklist | Near submission |

---

## Recommended Test Combinations

**Quick Validation**: A1 + F2 (Full review + PDF export)

**Complete Workflow**: C4 + D1 + A1 + G1 + F6 (Auto-detect + Estimate + Review + Backlog + All exports)

**R&R Scenario**: B1 + G1 + B4 (Reviewer response + Backlog + Rebuttal)

**Multi-Format Test**: I1 + I2 + I3 (PDF + DOCX + LaTeX support)

---

## Sprint Estimation

| Draft Stage | Sprint Range | Default Focus |
|-------------|--------------|---------------|
| Idea/outline | **12-18** | Contribution, framing, venue fit |
| Early draft | **8-14** | Theory, structure, method |
| Mature draft | **5-9** | Evidence, discussion, polish |
| Revise & Resubmit | **4-7** | Comment mapping, response strategy |
| Rebuttal/Camera-ready | **2-4** | Targeted fixes, final readiness |

---

## Workflow Overview

```
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│  INTAKE  │──▶│ PLANNING │──▶│  REVIEW  │──▶│ AMENDMENT│
└──────────┘   └──────────┘   └──────────┘   └──────────┘
                                    │               │
                                    ▼               ▼
                               ┌──────────┐   ┌──────────┐
                               │ BACKLOG  │◀──│ SUMMARY  │
                               └──────────┘   └──────────┘
                                    │
                                    ▼
                          ┌─────────────────┐
                          │  QUALITY GATES  │
                          │ Contribution    │
                          │ Rigor           │
                          │ Writing         │
                          │ Submission      │
                          └─────────────────┘
                                    │
                                    ▼
                          ┌─────────────────┐
                          │     EXPORT      │
                          │ MD/DOCX/HTML    │
                          └─────────────────┘
```

---

## Key Features

### 1. Progressive Intake
Don't answer a long questionnaire. PaperSprint asks only for missing facts and can auto-detect manuscript stage.

### 2. Multi-Lens Review
Default configuration: 3 reviewer lenses + 1 editor lens

| Lens | Focus |
|------|-------|
| Contribution | Novelty, significance, positioning |
| Rigor | Theory, method, evidence quality |
| Writing | Clarity, structure, flow |
| Editor | Overall publication merit |

### 3. Actionable Backlog
Every critique becomes a structured backlog item with:
- Severity rating (critical/high/medium/low)
- Bucket classification (contribution/theory/method/evidence/writing/compliance)
- Affected sections with specific locations
- Proposed action
- Dependencies
- Done criterion

### 4. Quality Gates
| Gate | Phase | Purpose |
|------|-------|---------|
| Contribution | Early | Verify contribution clarity |
| Rigor | Middle | Verify theory and method soundness |
| Writing | Late | Verify writing quality |
| Submission | Final | Human verification required |

### 5. Human Finalization Gate
**NEVER auto-submits.** Before any submission decision, author must:
- Verify all citations
- Verify all claims
- Check format compliance
- Make final submission decision

---

## Artifacts Generated

| Artifact | Purpose |
|----------|---------|
| Intake Summary | Project context |
| Sprint Brief | Current sprint goals |
| Review Memo | Structured critique |
| Backlog | Prioritized action items |
| Gate Report | Quality gate status |
| Amendment Summary | Changes made |
| Human Finalization Note | Pre-submission checklist |

---

## Example Workflow

### Sprint 1: Intake & Planning

**Input:**
```
/ps intake

Venue: ICIS 2026
Stage: early draft
File: ./my_paper.md
```

**Output:**
```markdown
## Intake Summary

**Project ID**: PS-20260313
**Venue**: ICIS 2026
**Stage**: early draft (auto-detected)
**Estimated Sprints**: 8-12

**Priority Focus**: Contribution and theory framing
**Key Risks**: Method section incomplete, missing empirical results
```

### Sprint 2: Review

**Input:**
```
/ps review
```

**Output:**
```markdown
## Review Memo - Sprint 2

**Gate**: major revision

**Critical Issues**:
- B001: Contribution claim not differentiated from [Prior Work]
- B002: Theory section lacks construct definitions

**Recommendations**:
- Focus next sprint on contribution clarity
- Add construct definition table
```

### Sprint 3: Amendment

**Input:**
```
/ps amend
```

**Output:**
```markdown
## Amendment Summary - Sprint 3

**Changes Made**:
- Added construct definition table (Section 3.1)
- Revised contribution statement (Abstract, Introduction)

**Concerns Addressed**: B001, B002

**Remaining**: B003, B004, B005
```

---

## Export Formats

| Format | Command | Status |
|--------|---------|--------|
| Markdown | `/ps export --format md` | ✅ Supported |
| DOCX | `/ps export --format docx` | ✅ Supported (requires pandoc) |
| HTML | `/ps export --format html` | ✅ Supported (requires pandoc) |
| PDF | `/ps export --format pdf` | ⚠️ Requires xelatex or wkhtmltopdf |
| LaTeX | `/ps export --format latex` | ✅ Supported (requires pandoc) |

---

## Critical Rules

| Rule | Enforcement |
|------|-------------|
| Never auto-submit | MANDATORY human finalization gate |
| Never invent citations | Explicit verification required |
| Always explain focus shifts | Document in process log |
| Always be actionable | Point to specific locations |
| Always provide ranges | Never give false precision |

---

## File Structure

```
paper-sprint-review/
├── SKILL.md              # Core workflow rules
├── README.md             # This file
├── LICENSE               # MIT License
├── agents/
│   └── openai.yaml       # Agent configuration
├── templates/            # Artifact templates
│   ├── sprint_brief.md
│   ├── process_log.md
│   ├── backlog_item.md
│   ├── review_memo.md
│   ├── amendment_summary.md
│   ├── sprint_review.md
│   ├── retrospective.md
│   ├── human_finalization.md
│   └── export_report.md
├── references/           # Detailed rules (loaded on demand)
│   ├── intake.md
│   ├── review.md
│   ├── backlog.md
│   ├── export.md
│   ├── gates.md
│   └── sprint_estimation.md
├── detection/            # Stage & quality detection
│   ├── stage_detector.md
│   └── quality_checker.md
├── commands/             # Command definitions
└── examples/             # Usage examples
```

---

## Dependencies

### Required
- OpenCode or compatible agent framework

### Optional (for export)
- `pandoc` - For DOCX/HTML/LaTeX export
- `xelatex` or `wkhtmltopdf` or `weasyprint` - For PDF export

```bash
# Install pandoc (recommended)
apt install pandoc

# For PDF support, install one of:
apt install texlive-xetex
# or
apt install wkhtmltopdf
# or
pip install weasyprint
```

---

## Installation

Place the skill directory in your OpenCode skills folder:

```bash
# For OpenCode
cp -r paper-sprint-review ~/.config/opencode/skills/

# Or use the skill installer if available
```

Restart OpenCode after installation.

---

## License

MIT License - See [LICENSE](LICENSE) for details.

---

## Disclaimer

**PaperSprint is a drafting assistant, not a submission service.**

A strong PaperSprint draft is NOT automatically submission-ready. The author must:
- Inspect and tune the manuscript
- Verify all citations and claims
- Check format compliance
- Make the final submission decision

**You remain responsible for your work.**

---

*PaperSprint v2.2*
