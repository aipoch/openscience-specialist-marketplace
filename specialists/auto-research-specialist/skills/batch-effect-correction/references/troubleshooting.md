# Troubleshooting Guide

## Common Errors

### SKILL_FILE_NOT_FOUND

**Error:**
```
SKILL_FILE_NOT_FOUND: --input_file does not exist: path/to/expression_matrix.csv
```

**Solution:**
- Verify the file path is correct
- Check that the file exists before running
- Ensure you passed a file path rather than a directory path

### SKILL_EMPTY_FILE

**Error:**
```
SKILL_EMPTY_FILE: --group_file is empty: path/to/sample_info.csv
```

**Solution:**
- Re-export the CSV file with actual content
- Check that the file size is greater than zero
- Confirm the file was not truncated during transfer or preprocessing

### SKILL_MISSING_COLUMNS

**Error:**
```
SKILL_MISSING_COLUMNS: Metadata is missing column(s): batch
```

**Solution:**
- Verify the metadata header contains the expected sample, group, and batch columns
- Pass custom column names with `--sample_column`, `--group_column`, and `--batch_column`
- Check for spelling, capitalization, and delimiter issues in the CSV header

### SKILL_SAMPLE_MISMATCH

**Error:**
```
SKILL_SAMPLE_MISMATCH: Metadata samples not found in expression matrix: GSM0001, GSM0002
```

**Solution:**
- Verify metadata sample IDs match expression matrix column names exactly
- Check for whitespace, encoding issues, or hidden characters
- Ensure metadata and expression files refer to the same merged cohort
- If metadata intentionally covers only a subset of samples, keep only valid sample IDs in metadata; extra expression columns will be ignored with a warning

### SKILL_INVALID_PARAMETER

**Error:**
```
SKILL_INVALID_PARAMETER: --log_transform must be one of auto, yes, no
```

**Solution:**
- Use valid values for all CLI options
- Confirm `--log_transform` is `auto`, `yes`, or `no`
- Ensure `--seed` and `--timeout_seconds` are non-negative numeric values

### SKILL_INVALID_DATA

**Error:**
```
SKILL_INVALID_DATA: Each batch must contain at least 2 samples
```

**Solution:**
- Ensure the design contains at least 2 batches and 2 biological groups
- Confirm each batch and each group has at least 2 samples
- Check that gene IDs and sample IDs are unique and non-empty
- Remove negative values if you plan to use `--log_transform yes`

### SKILL_INVALID_TYPE

**Error:**
```
SKILL_INVALID_TYPE: Expression values must be numeric and finite
```

**Solution:**
- Ensure all expression columns are numeric
- Remove `NA`, `NaN`, `Inf`, and non-numeric tokens before running
- Re-export the matrix as a clean CSV rather than a formatted spreadsheet

### SKILL_DEPENDENCY_MISSING

**Error:**
```
SKILL_DEPENDENCY_MISSING: Missing package(s): sva, limma, ggplot2
```

**Solution:**
- Install the required R packages before running
- Use `requireNamespace()` or `installed.packages()` to verify installation
- Re-run the command after package installation completes successfully

### SKILL_TIMEOUT

**Error:**
```
SKILL_TIMEOUT: Analysis exceeded the configured time limit
```

**Solution:**
- Increase `--timeout_seconds` for larger datasets
- Use `--timeout_seconds 0` to disable the elapsed-time limit
- Reduce upstream matrix size if the dataset is excessively large

### SKILL_RUNTIME_ERROR

**Error:**
```
SKILL_RUNTIME_ERROR: Failed to write session information: <details>
```

**Solution:**
- Check that the output directory is writable
- Verify input files are readable and not locked by another process
- Re-run on a local writable filesystem if the current environment is restricted

## Visualization Issues

### Crowded Boxplots or Clustering Labels

**Cause:** Large merged cohorts can produce dense sample labels in PDF plots.

**Solution:**
- Review PCA plots first for a cleaner global overview
- Use the clustering and boxplot PDFs for detailed inspection after confirming broad trends
- If needed, subset samples upstream for presentation-quality figures

### Limited Separation Change After Correction

**Cause:** Batch effects may be weak, biological groups may dominate variance, or the dataset may not satisfy the assumptions for strong ComBat correction.

**Solution:**
- Confirm that batch labels are correct and meaningful
- Check whether the matrix was already normalized and batch-adjusted upstream
- Review PCA and clustering plots together rather than relying on a single figure type

### PCA Ellipse Not Shown For A Small Batch

**Cause:** Some small or low-rank batches do not have enough variation in the first two PCs to support a stable ellipse fit.

**Solution:**
- This is now handled by skipping the ellipse while still saving the PCA scatter plot
- Review the point cloud, boxplots, and clustering plot together for these small cohorts
- If ellipse overlays are required for presentation, increase cohort size or use a dataset with more within-batch variance

## Design-Specific Issues

### Single-batch Input

**Cause:** ComBat requires at least 2 batches to estimate batch effects.

**Solution:**
- Verify that the metadata actually contains more than one technical batch
- Do not use this skill for single-batch studies

### Single-group Input

**Cause:** This workflow preserves biological group structure with `model.matrix(~ group)`, so at least 2 groups are required by design.

**Solution:**
- Provide metadata with at least 2 biological groups
- If the study has only one biological condition, use a different normalization-only workflow
