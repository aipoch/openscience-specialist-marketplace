---
name: table-1-generator-advanced
description: Generate publication-ready baseline characteristics tables (Table 1) for clinical research papers with automatic variable type detection, appropriate statistics (mean±SD, median[IQR, n(%)), group comparisons (t-test, chi-square), and APA formatting.
license: MIT
author: AIPOCH
---
> **Source**: [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills)

# Table 1 Generator

Automated generation of baseline characteristics tables (Table 1) for clinical research papers.

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
```

## When to Use

**Trigger phrases**: "Table 1", "baseline characteristics", "demographic table", "clinical trial table", "summary statistics table"

- Generating baseline characteristics tables (Table 1) for clinical research manuscripts
- Comparing demographic and clinical variables across treatment groups
- Creating summary statistics tables for clinical trial reports
- Producing publication-ready tables with APA formatting

## Workflow

1. **Load and validate data** — Input: CSV file path via `--data` → verify columns exist, check for missing values, detect data types (continuous/categorical) → Output: data schema report
2. **Identify grouping variable** — Input: `--group` column name (e.g., treatment/control) → verify group balance → Output: group distribution summary
3. **Select variables** — Input: `--vars` list or auto-detect all eligible columns → classify each as continuous or categorical → Output: variable classification table
4. **Compute statistics** — Continuous: mean±SD or median[IQR] (based on normality); Categorical: n(%); Group comparisons: t-test/chi-square → ⛔ Checkpoint: Confirm statistical method choices with user if normality is borderline → Output: statistics matrix
5. **Format Table 1** — Apply APA formatting, add p-values, footnotes for abbreviations → Output: `--output` CSV/Excel file
6. **Report missing data** — Summarize missingness per variable, flag if >5% missing → Output: missing data appendix

## Usage

```text
python scripts/main.py --data patients.csv --group treatment --output table1.csv
```

## Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `--data` | str | Yes | - | Patient data CSV file path |
| `--group` | str | No | - | Grouping variable (e.g., treatment/control) |
| `--vars` | list[str] | No | - | Variables to include in the table |
| `--output` | str | Yes | - | Output file path for Table 1 |

## Features

- Automatic variable type detection
- Appropriate statistics (mean±SD, median[IQR], n(%))
- Group comparisons (t-test, chi-square)
- Missing data reporting
- APA formatting

## Output

- Table 1 (CSV/Excel)
- Statistical test results
- Formatted for publication

## Risk Assessment

| Risk Indicator | Assessment | Level |
|----------------|------------|-------|
| Code Execution | Python/R scripts executed locally | Medium |
| Network Access | No external API calls | Low |
| File System Access | Read input files, write output files | Medium |
| Instruction Tampering | Standard prompt guidelines | Low |
| Data Exposure | Output files saved to workspace | Low |

## Security Checklist

- [ ] No hardcoded credentials or API keys
- [ ] No unauthorized file system access (../)
- [ ] Output does not expose sensitive information
- [ ] Prompt injection protections in place
- [ ] Input file paths validated (no ../ traversal)
- [ ] Output directory restricted to workspace
- [ ] Script execution in sandboxed environment
- [ ] Error messages sanitized (no stack traces exposed)
- [ ] Dependencies audited

## Prerequisites

```text
# Python dependencies
pip install -r requirements.txt
```

## Evaluation Criteria

### Success Metrics
- [ ] Successfully executes main functionality
- [ ] Output meets quality standards
- [ ] Handles edge cases gracefully
- [ ] Performance is acceptable

### Test Cases
1. **Basic Functionality**: Standard input → Expected output
2. **Edge Case**: Invalid input → Graceful error handling
3. **Performance**: Large dataset → Acceptable processing time

## Lifecycle Status

- **Current Stage**: Draft
- **Next Review Date**: 2026-03-06
- **Known Issues**: None
- **Planned Improvements**:
  - Performance optimization
  - Additional feature support

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

This skill accepts requests that match the documented purpose of `table-1-generator` and include enough context to complete the workflow safely.

Do not continue the workflow when the request is out of scope, missing a critical input, or would require unsupported assumptions. Instead respond:

> `table-1-generator` only handles its documented workflow. Please provide the missing required inputs or switch to a more suitable skill.

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
