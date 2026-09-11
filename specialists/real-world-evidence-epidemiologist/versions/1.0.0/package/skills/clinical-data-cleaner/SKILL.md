---
name: clinical-data-cleaner
description: Use when cleaning clinical trial data, preparing data for FDA/EMA submission, standardizing SDTM datasets, handling missing values in clinical studies, detecting outliers in lab results, or converting raw CRF data to CDISC format. Cleans and standardizes clinical trial data fo...
license: MIT
author: AIPOCH
---
> **Source**: [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills)

# Clinical Data Cleaner

Clean, validate, and standardize clinical trial data to meet CDISC SDTM standards for regulatory submissions to FDA or EMA.

## Quick Check

Use this command to verify that the packaged script entry point can be parsed before deeper execution.

```bash
python -m py_compile scripts/main.py
```

## Audit-Ready Commands

Use these concrete commands for validation. They are intentionally self-contained and avoid placeholder paths.

```bash
python -m py_compile scripts/main.py
python scripts/main.py --help
python scripts/main.py --input "Audit validation sample with explicit symptoms, history, assessment, and next-step plan."
```

## When to Use

- Use this skill when the task needs Use when cleaning clinical trial data, preparing data for FDA/EMA submission, standardizing SDTM datasets, handling missing values in clinical studies, detecting outliers in lab results, or converting raw CRF data to CDISC format. Cleans and standardizes clinical trial data for regulatory compliance with audit trails.
- Use this skill for data analysis tasks that require explicit assumptions, bounded scope, and a reproducible output format.
- Use this skill when you need a documented fallback path for missing inputs, execution errors, or partial evidence.

## Workflow

1. Confirm the user objective, required inputs, and non-negotiable constraints before doing detailed work.
2. Validate that the request matches the documented scope and stop early if the task would require unsupported assumptions.
3. Use the packaged script path or the documented reasoning path with only the inputs that are actually available.
4. Return a structured result that separates assumptions, deliverables, risks, and unresolved items.
5. If execution fails or inputs are incomplete, switch to the fallback path and state exactly what blocked full completion.

## Quick Start

```python
from scripts.main import ClinicalDataCleaner

# Initialize for Demographics domain
cleaner = ClinicalDataCleaner(domain='DM')

# Clean data with default settings
cleaned = cleaner.clean(raw_data)

# Save with audit trail
cleaner.save_report('output.csv')
```

## Core Capabilities

### 1. SDTM Domain Validation

```python
cleaner = ClinicalDataCleaner(domain='DM')  # or 'LB', 'VS'
is_valid, missing = cleaner.validate_domain(data)
```

**Required Fields:**
- **DM**: STUDYID, USUBJID, SUBJID, RFSTDTC, RFENDTC, SITEID, AGE, SEX, RACE
- **LB**: STUDYID, USUBJID, LBTESTCD, LBCAT, LBORRES, LBORRESU, LBSTRESC, LBDTC
- **VS**: STUDYID, USUBJID, VSTESTCD, VSORRES, VSORRESU, VSSTRESC, VSDTC

### 2. Missing Value Handling

```python
cleaner = ClinicalDataCleaner(
    domain='DM',
    missing_strategy='median'  # mean, median, mode, forward, drop
)
cleaned = cleaner.handle_missing_values(data)
```

### 3. Outlier Detection

```python
cleaner = ClinicalDataCleaner(
    domain='LB',
    outlier_method='domain',  # iqr, zscore, domain
    outlier_action='flag'     # flag, remove, cap
)
flagged = cleaner.detect_outliers(data)
```

**Clinical Thresholds:**
| Parameter | Range | Unit |
|-----------|-------|------|
| Glucose | 50-500 | mg/dL |
| Hemoglobin | 5-20 | g/dL |
| Systolic BP | 70-220 | mmHg |

### 4. Date Standardization

```python
standardized = cleaner.standardize_dates(data)
# Converts to ISO 8601: 2023-01-15T09:30:00
```

### 5. Complete Pipeline

```python
cleaner = ClinicalDataCleaner(
    domain='DM',
    missing_strategy='median',
    outlier_method='iqr',
    outlier_action='flag'
)
cleaned_data = cleaner.clean(data)
cleaner.save_report('output.csv')
```

**Output Files:**
- `output.csv` - Cleaned SDTM data
- `output.report.json` - Audit trail for regulatory submission

## CLI Usage

```text
# Clean demographics
python scripts/main.py \
  --input dm_raw.csv \
  --domain DM \
  --output dm_clean.csv \
  --missing-strategy median \
  --outlier-method iqr \
  --outlier-action flag

# Clean lab data with clinical thresholds
python scripts/main.py \
  --input lb_raw.csv \
  --domain LB \
  --output lb_clean.csv \
  --outlier-method domain
```

## Common Patterns

See [references/common-patterns.md](references/common-patterns.md) for detailed examples:
- Regulatory Submission Preparation
- Interim Analysis Data Preparation
- Database Migration Cleanup
- External Lab Data Integration

## Troubleshooting

See [references/troubleshooting.md](references/troubleshooting.md) for solutions to:
- Validation failures
- Date parsing errors
- Memory errors with large datasets
- Outlier detection issues

## Quality Checklist

**Pre-Cleaning:**
- [ ] IACUC approval obtained (animal studies)
- [ ] Sample size adequately powered
- [ ] Randomization method documented

**Post-Cleaning:**
- [ ] Validate against CDISC SDTM IG
- [ ] Review all cleaning actions in audit trail
- [ ] Test import to analysis software

## References

- `references/sdtm_ig_guide.md` - CDISC SDTM Implementation Guide
- `references/domain_specs.json` - Domain-specific field requirements
- `references/outlier_thresholds.json` - Clinical outlier thresholds
- `references/common-patterns.md` - Detailed usage patterns
- `references/troubleshooting.md` - Problem-solving guide

---

**Skill ID**: 189 | **Version**: 2.0 | **License**: MIT

## Output Requirements

Every final response should make these items explicit when they are relevant:

- Objective or requested deliverable
- Inputs used and assumptions introduced
- Workflow or decision path
- Core result, recommendation, or artifact
- Constraints, risks, caveats, or validation needs
- Unresolved items and next-step checks

## Error Handling

- If required inputs are missing, state exactly which fields are missing and request only the minimum additional information.
- If the task goes outside the documented scope, stop instead of guessing or silently widening the assignment.
- If `scripts/main.py` fails, report the failure point, summarize what still can be completed safely, and provide a manual fallback.
- Do not fabricate files, citations, data, search results, or execution outcomes.

## Input Validation

This skill accepts requests that match the documented purpose of `clinical-data-cleaner` and include enough context to complete the workflow safely.

Do not continue the workflow when the request is out of scope, missing a critical input, or would require unsupported assumptions. Instead respond:

> `clinical-data-cleaner` only handles its documented workflow. Please provide the missing required inputs or switch to a more suitable skill.

## Response Template

Use the following fixed structure for non-trivial requests:

1. Objective
2. Inputs Received
3. Assumptions
4. Workflow
5. Deliverable
6. Risks and Limits
7. Next Checks

If the request is simple, you may compress the structure, but still keep assumptions and limits explicit when they affect correctness.

## When Not to Use

- Do not proceed when required input files, identifiers, parameters, or context are missing — ask the user to provide them first.
- Do not assume capabilities beyond this skill's declared scope when the user requests external operations or inferences.
- Do not proceed without user confirmation when overwriting existing results, executing high-cost batch operations, or expanding task scope.

## Required Inputs

| Field | Required | Format/Source | Example | If Missing |
|---|---|---|---|---|
| User task description | Yes | Text | Research question, writing goal, analysis objective | Stop and ask user to provide |
| Primary input material | Depends on task | Text, file path, ID, table, or literature | PMID, PDF, CSV, DOCX, keywords, etc. | Specify which material type is missing |
| Output preference | No | Text | Language, format, target journal, template | Use skill default format |

## Output Contract

- Primary output: Structured result or target file aligned with this skill's objective.
- Optional output: Intermediate check notes, issue list, supplementary suggestions, or generated file paths.
- Format requirement: Unless the user specifies otherwise, prefer stable, reviewable Markdown or JSON; if the skill's bundled script requires a fixed format, use that format.
- If partially complete: Must explicitly mark as PARTIAL and state which steps are completed and which remain.

## Failure Handling

- Missing critical input: Explicitly state which fields, files, or identifiers are missing and pause.
- Script, template, or resource execution failure: Report the failing step, likely cause, and recovery suggestions — do not silently degrade.
- Partial completion only: Return the verified portion first, then list remaining blockers and suggested next steps.

## User Checkpoints

- Before executing batch processing, overwriting files, long-running searches, or multi-stage generation, confirm scope and output format with the user.
- Before proceeding when a key judgment is ambiguous, evidence is insufficient, or the workflow is entering the next stage, confirm with the user.

## Quick Validation

- Check that key scripts, templates, or reference file paths this skill depends on exist.
- Check that the final output contains the core fields, sections, or files specified for this task.
- Check that results clearly mark assumptions, limitations, and incomplete items.
