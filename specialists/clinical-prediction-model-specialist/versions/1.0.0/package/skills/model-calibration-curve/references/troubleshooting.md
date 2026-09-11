# Troubleshooting Guide

## Common `SKILL_*` Errors

### SKILL_INVALID_PARAMETER

**Typical messages**
```text
SKILL_INVALID_PARAMETER: --features must contain at least one value
SKILL_INVALID_PARAMETER: Survival time values must be finite numbers greater than 0
SKILL_INVALID_PARAMETER: Event indicator values must use 0/1 encoding
SKILL_INVALID_PARAMETER: At least 30 complete samples are required for bootstrap calibration
SKILL_INVALID_PARAMETER: At least 10 events are required for stable calibration
SKILL_INVALID_PARAMETER: Failed to read --data_file: ...
```

**How to fix**
- Confirm all required arguments were provided.
- Check that the time column is numeric and strictly positive.
- Encode the event column as `0` and `1` only.
- Use more complete samples or reduce missingness before rerunning.
- Increase event count or choose a better-supported cohort for calibration.

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
SKILL_MISSING_COLUMNS: Missing required columns: age, risk
```

**How to fix**
- Check the CSV header exactly.
- Verify that `--features`, `--time_col`, and `--event_col` all refer to real columns.

### SKILL_EMPTY_DATA

**Typical messages**
```text
SKILL_EMPTY_DATA: --data_file contains no usable rows or columns
SKILL_EMPTY_DATA: No complete rows remained after filtering required columns
```

**How to fix**
- Ensure the CSV has both data rows and columns.
- Remove all-empty rows and columns.
- Check whether missing values across required columns removed the full cohort.

### SKILL_SAMPLE_MISMATCH

**Typical message**
```text
SKILL_SAMPLE_MISMATCH: Reserved for cross-file sample mismatch scenarios
```

**How to fix**
- This single-file workflow should not normally raise this error.
- If you add multi-file extensions later, verify sample IDs match exactly.

### SKILL_PACKAGE_NOT_FOUND

**Typical message**
```text
SKILL_PACKAGE_NOT_FOUND: Required packages are not installed: rms, qs
```

**How to fix**
- Install the missing CRAN packages before rerunning.
- Verify your R environment can load `optparse`, `survival`, `rms`, `qs`, and `openxlsx`.

---

## Recommended Validation Commands

```bash
Rscript scripts/main.R --help

Rscript scripts/main.R \
  --data_file tests/data/sample_clinical_survival_data.csv \
  --features age,gender,risk \
  --bootstrap_reps 20 \
  --output_dir tests/output/ \
  --overwrite

Rscript tests/run_smoke_test.R
```

If the problem persists, capture the full console log together with `session_info.txt`.
