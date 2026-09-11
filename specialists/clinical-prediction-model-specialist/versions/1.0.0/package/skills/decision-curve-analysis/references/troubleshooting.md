# Troubleshooting Guide

## Common `SKILL_*` Errors

### SKILL_INVALID_PARAMETER

**Typical messages**
```text
SKILL_INVALID_PARAMETER: --study_design must be one of: case-control, cohort
SKILL_INVALID_PARAMETER: --population_prevalence must be between 0 and 1
SKILL_INVALID_PARAMETER: fustat must use 0/1 encoding
SKILL_INVALID_PARAMETER: riskScore must contain finite numeric values
SKILL_INVALID_PARAMETER: At least 20 rows are required for decision curve analysis
SKILL_INVALID_PARAMETER: Decision curve modeling failed: ...
```

**How to fix**
- Confirm the study design is `case-control` or `cohort`.
- Use prevalence values strictly between `0` and `1` for case-control analysis.
- Encode the outcome column using `0` and `1` only.
- Ensure the predictor column is numeric and finite.
- Use a cohort with enough rows and both outcome classes represented.

### SKILL_FILE_NOT_FOUND

**Typical message**
```text
SKILL_FILE_NOT_FOUND: --data_file does not exist: path/to/file.csv
```

**How to fix**
- Verify the path to the clinical CSV.
- Use an absolute path if the working directory is uncertain.

### SKILL_MISSING_COLUMNS

**Typical message**
```text
SKILL_MISSING_COLUMNS: Missing required columns: riskScore
```

**How to fix**
- Check the CSV header exactly.
- Verify that `--outcome_col` and `--predictor_col` point to real columns.

### SKILL_EMPTY_DATA

**Typical message**
```text
SKILL_EMPTY_DATA: --data_file contains no usable rows or columns
```

**How to fix**
- Ensure the CSV has both data rows and columns.
- Remove empty rows or columns before rerunning.

### SKILL_SAMPLE_MISMATCH

**Typical message**
```text
SKILL_SAMPLE_MISMATCH: Reserved for cross-file sample mismatch scenarios
```

**How to fix**
- This single-file workflow should not normally raise this error.
- If multi-file extensions are added later, verify sample IDs match exactly.

### SKILL_PACKAGE_NOT_FOUND

**Typical message**
```text
SKILL_PACKAGE_NOT_FOUND: Required packages are not installed: rmda
```

**How to fix**
- Install the missing CRAN packages before rerunning.
- Verify your R environment can load `optparse` and `rmda`.

---

## Recommended Validation Commands

```bash
Rscript scripts/main.R --help

Rscript scripts/main.R \
  --data_file tests/data/dca_data.csv \
  --outcome_col fustat \
  --predictor_col riskScore \
  --output_dir tests/output/ \
  --overwrite

Rscript tests/run_smoke_test.R
```

If the problem persists, capture the full console log together with `session_info.txt`.
