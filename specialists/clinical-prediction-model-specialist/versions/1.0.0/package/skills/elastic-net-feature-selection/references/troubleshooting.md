# Troubleshooting Guide

## Common Errors

### SKILL_FILE_NOT_FOUND

**Error:**
```text
SKILL_FILE_NOT_FOUND: File not found /path/to/file.csv
```

**Solution:**
- Verify the file path is correct
- Check file permissions
- Ensure the file exists before running

### SKILL_EMPTY_DATA

**Error:**
```text
SKILL_EMPTY_DATA: expression matrix file is empty
```

**Solution:**
- Re-export the CSV or text file
- Confirm the file contains header and data rows
- Check file size before rerunning

### SKILL_MISSING_COLUMNS

**Error:**
```text
SKILL_MISSING_COLUMNS: unable to detect sample/group columns
```

**Solution:**
- Ensure the group file contains sample and group columns
- Use clear column names such as `sample` and `group`
- Check for unexpected header formatting

### SKILL_SAMPLE_MISMATCH

**Error:**
```text
SKILL_SAMPLE_MISMATCH: too few overlapping samples between matrix and group file
```

**Solution:**
- Verify sample IDs in the group file match expression matrix column names exactly
- Check for whitespace or encoding issues
- Ensure all requested samples are present in both files

### SKILL_INVALID_PARAMETER

**Error:**
```text
SKILL_INVALID_PARAMETER: alpha must be a number between 0 and 1, or 'auto'
```

**Solution:**
- Use a numeric alpha between `0` and `1`, or `auto`
- Use a valid `alpha_grid` when `alpha=auto`
- Use `lambda.min` or `lambda.1se` for `--lambda_choice`
- Ensure `timeout_seconds > 0`
- Ensure `case_group` and `control_group` are different

### SKILL_INVALID_DATA

**Error:**
```text
SKILL_INVALID_DATA: all features have zero variance
```

**Another common example:**
```text
SKILL_INVALID_DATA: group file contains unsupported labels outside the requested binary comparison: other. This skill only supports binary case-vs-control analysis.
```

**Solution:**
- Ensure the expression matrix is numeric
- Keep at least 2 matched samples in each class
- Ensure at least 2 usable features remain after filtering
- Check that requested features exist in the matrix
- Remove unsupported labels from the group file; this skill only accepts exactly two outcome levels for the requested comparison

### SKILL_DEPENDENCY_MISSING

**Error:**
```text
SKILL_DEPENDENCY_MISSING: Package 'glmnet' is required
```

**Solution:**
- Install the missing package in the local R environment
- Verify the package loads successfully before rerunning

### SKILL_PKG_VERSION

**Error:**
```text
SKILL_PKG_VERSION: Package 'pkgname' version x.y.z or higher required
```

**Solution:**
- Update the package with `install.packages("pkgname")`
- Restart the R session if needed

### SKILL_TIMEOUT

**Error:**
```text
SKILL_TIMEOUT: Analysis exceeded the configured time limit
```

**Solution:**
- Increase `--timeout_seconds`
- Reduce the feature set using `--feature_file`
- Test the workflow on a smaller dataset first

### SKILL_RUNTIME_ERROR

**Error:**
```text
SKILL_RUNTIME_ERROR: failed to write output file /path/to/output.csv
```

**Solution:**
- Check that `--output_dir` is writable
- Ensure there is enough free disk space
- Rerun in a new empty output directory if partial files already exist

## Modeling Warnings

### Small-Sample Warning

**Warning:**
```text
[WARN] ... one multinomial or binomial class has fewer than 8 observations; dangerous ground
```

**Cause:** Class sizes are small for stable penalized logistic regression.

**Solution:**
- Interpret selected features cautiously
- Compare `lambda.min` and `lambda.1se`
- If `alpha=auto`, inspect `alpha_tuning.csv`

### No Selected Features

**Warning:**
```text
[WARN] ... No feature coefficients exceeded the selection tolerance (|coefficient| > 1e-08) at lambda.min.
```

**Cause:** The chosen regularization level is too strong for the current data.

**Solution:**
- Try `--lambda_choice lambda.min` if using `lambda.1se`
- Try `--alpha auto` to explore different penalty mixtures
- Review the input data and feature filtering choices

### Ridge Alpha Produces No Sparse Selection

**Warning:**
```text
[WARN] ... Selected alpha 0.000 corresponds to ridge regularization. selected_features.csv will be written empty because ridge does not perform sparse feature selection.
```

**Cause:** The selected or requested `alpha` is `0`, which gives ridge regularization rather than sparse feature selection.

**Solution:**
- Use `model_coefficients.csv` if you want a coefficient ranking from the ridge fit
- Use `--alpha` values greater than `0` if you need sparse selected features
- Remove `0` from `--alpha_grid` when sparse selection is the main goal
