# Troubleshooting Guide

## Common `SKILL_*` Errors

### SKILL_INVALID_PARAMETER

**Typical messages**
```text
SKILL_INVALID_PARAMETER: --mode must be one of build, plot
SKILL_INVALID_PARAMETER: --years must contain positive numeric time points
```

**How to fix**
- Check that build mode and plot mode arguments are not mixed incorrectly.
- Use comma-separated positive numeric values for `--years`.

### SKILL_FILE_NOT_FOUND

**Typical message**
```text
SKILL_FILE_NOT_FOUND: --data_file does not exist: path/to/file.csv
```

**How to fix**
- Verify the input path.
- Use an absolute path if the working directory is uncertain.

### SKILL_EMPTY_DATA

**Typical messages**
```text
SKILL_EMPTY_DATA: --data_file is empty: path/to/file.csv
SKILL_EMPTY_DATA: Clinical data file contains no usable rows or columns
```

**How to fix**
- Confirm the source file contains rows and columns.
- Re-export the source file if it was truncated.
- Confirm the CSV contains at least one non-header row.
- Verify that delimiters and quoting were preserved during export.
- Recreate the file if filtering or preprocessing removed all rows.

### SKILL_MISSING_COLUMNS

**Typical message**
```text
SKILL_MISSING_COLUMNS: Clinical data is missing columns: risk, futime
```

**How to fix**
- Check feature names and survival column names.
- Confirm the CSV header matches the command-line arguments exactly.

### SKILL_INVALID_DATA

**Typical messages**
```text
SKILL_INVALID_DATA: Time column must contain finite values greater than 0
SKILL_INVALID_DATA: Event column must use 0/1 encoding
SKILL_INVALID_DATA: Failed to read nomogram bundle: ...
```

**How to fix**
- Verify the time column is numeric and positive.
- Encode event status strictly as `0` and `1`.
- Rebuild the nomogram bundle if the `.qs` file is corrupted.

### SKILL_INSUFFICIENT_DATA

**Typical messages**
```text
SKILL_INSUFFICIENT_DATA: At least 3 prognostic features are required for nomogram construction
SKILL_INSUFFICIENT_DATA: At least 10 events are required for nomogram construction
```

**How to fix**
- Provide at least 3 clinically meaningful predictors.
- Use a larger cohort or more events.

### SKILL_ANALYSIS_ERROR

**Typical messages**
```text
SKILL_ANALYSIS_ERROR: Failed to fit cph model: ...
SKILL_ANALYSIS_ERROR: Failed to build nomogram object: ...
```

**How to fix**
- Check for unstable factor levels or too few events.
- Simplify the feature set if model fitting is unstable.

### SKILL_TIMEOUT

**Typical message**
```text
SKILL_TIMEOUT: Operation exceeded the configured time limit
```

**How to fix**
- Increase `--timeout_seconds`.
- Reduce dataset size or number of predictors.

### SKILL_PACKAGE_NOT_FOUND

**Typical message**
```text
SKILL_PACKAGE_NOT_FOUND: Required packages are not installed: rms, qs
```

**How to fix**
- Install the missing CRAN packages in the active R environment.
- Re-run `Rscript scripts/main.R --help` to confirm the CLI starts cleanly after installation.
- Make sure the same R library path is used for both interactive and command-line execution.

---

## Recommended Validation Commands

```bash
Rscript scripts/main.R --help

Rscript scripts/main.R \
  --mode build \
  -d tests/data/yuhou_cli_data.csv \
  -f age,gender,risk \
  -o tests/expected_output/ \
  --overwrite

Rscript scripts/main.R \
  --mode plot \
  -n tests/expected_output/data/Nomogram_list.qs \
  -p tests/expected_output/plot/nomogram_plot.pdf
```

If the problem persists, capture the full console log together with `session_info.txt`.
