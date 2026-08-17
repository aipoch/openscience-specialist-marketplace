# Troubleshooting Guide

## Common Errors

### SKILL_FILE_NOT_FOUND

**Error:**
```text
SKILL_FILE_NOT_FOUND: --exp_file does not exist: path/to/file.csv
```

**Solution:**
- Verify the file path is correct.
- Use absolute paths if you are unsure about the working directory.
- Confirm the file extension is `.csv`.

### SKILL_MISSING_COLUMNS

**Error:**
```text
SKILL_MISSING_COLUMNS: Clinical data is missing columns: OS, OS.time
```

**Solution:**
- Ensure the clinical file contains both `OS` and `OS.time`.
- Ensure the model file contains both `Gene` and `Coef`.
- Check column names for extra spaces or different capitalization.

### SKILL_SAMPLE_MISMATCH

**Error:**
```text
SKILL_SAMPLE_MISMATCH: No overlapping samples were found between expression and clinical data
```

**Solution:**
- Verify expression column names match clinical row names exactly.
- Remove hidden whitespace or spreadsheet-added formatting changes.
- Confirm both files describe the same cohort.

### SKILL_EMPTY_DATA

**Error examples:**
```text
SKILL_EMPTY_DATA: Expression matrix is empty
SKILL_EMPTY_DATA: Clinical data is empty
SKILL_EMPTY_DATA: Model file is empty
```

**Solution:**
- Confirm the CSV file is not blank and contains a header plus at least one data row.
- Re-export the file as plain CSV if spreadsheet software produced an empty-looking file.
- Verify upstream filtering did not remove all genes or samples before validation.

### SKILL_INVALID_DATA

**Typical causes:**
- duplicate gene identifiers in expression data
- duplicate genes in the model file
- non-numeric coefficients in `Coef`
- empty CSV input
- non-positive or non-finite survival time
- non-binary `OS` values

**Solution:**
- Deduplicate gene rows before running.
- Convert `Coef` to numeric values only.
- Ensure `OS` uses `0/1` encoding.
- Remove rows or samples with malformed survival data.

### SKILL_ANALYSIS_ERROR

**Error examples:**
```text
SKILL_ANALYSIS_ERROR: Risk groups collapsed into a single class; check model coefficients and input data
SKILL_ANALYSIS_ERROR: At least 2 events are required for survival and ROC analysis
```

**Solution:**
- Check whether all coefficients are zero or nearly identical in effect.
- Confirm the cohort contains enough outcome events.
- Verify the model genes are truly present and variable in the dataset.

### SKILL_INVALID_PARAMETER

**Typical causes:**
- unsupported `--time_unit`
- invalid color values
- empty or non-numeric `--roc_times`
- `--roc_times` greater than available follow-up time
- `--output_dir` already exists and is not empty without `--overwrite`

**Solution:**
- Use `day`, `month`, or `year` for `--time_unit`.
- Use standard color names or hex colors such as `#E64B35`.
- Keep every ROC time point below the maximum follow-up time in years.
- Use a fresh output directory, or rerun with `--overwrite` only if replacing prior outputs is intentional.

## Common Warnings

### Samples Removed Because of Missing Values

**Warning:**
```text
Removed N samples with incomplete values before analysis
```

**Meaning:**
- One or more required values were missing in expression, survival, or calculated risk score inputs.

**Action:**
- Inspect missingness before analysis.
- Confirm removed samples are acceptable for the validation design.

### Heatmap Skipped Because All Model Genes Have Zero Variance

**Warning:**
```text
Skipped heatmap because all model genes have zero variance
```

**Meaning:**
- The selected model genes do not vary across retained samples, so row-scaled heatmap display is not informative.

**Action:**
- Confirm the expression matrix was imported correctly.
- Check whether the cohort or preprocessing collapsed the signal.

## Dependency Issues

Required packages:

- `optparse`
- `survival`
- `survminer`
- `timeROC`
- `pheatmap`
- `ggplot2`

### SKILL_PKG_VERSION

**Error:**
```text
SKILL_PKG_VERSION: pkg must be >= x.y.z
```

**Solution:**
- Update the named package to a compatible version.
- Restart the R session after upgrading if the old namespace is still loaded.

If a package is missing, install it in R before running:

```r
install.packages(c("optparse", "survival", "survminer", "timeROC", "pheatmap", "ggplot2"))
```

## Runtime and Output Checks

### Script finishes but output looks incomplete

Check these files first:

- `analysis.log`
- `run_parameters.tsv`
- `session_info.txt`

These files tell you:

- which parameters were actually used
- whether warnings were emitted
- which package versions were loaded

If a run fails during plotting or validation, partial outputs may still exist in `data/`, `plot/`, or `table/`. Use `analysis.log` together with `run_parameters.tsv` to determine which step completed before failure.

### Refreshing the retained example output

If you want to update the checked-in example result bundle under `tests/output/`, run:

```bash
Rscript tests/refresh_example_output.R
```

This helper automatically uses the bundled test data and passes `--overwrite`.

### ROC plot error caused by time horizon

If the ROC step fails, reduce `--roc_times` so all requested horizons are below the maximum follow-up time after conversion to years.

### Timeout issues on larger cohorts

Increase the timeout if the cohort is larger or plotting takes longer:

```bash
Rscript scripts/main.R ... --timeout_seconds 7200
```
