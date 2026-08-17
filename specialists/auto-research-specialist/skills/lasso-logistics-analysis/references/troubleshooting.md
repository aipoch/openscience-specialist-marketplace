# Troubleshooting Guide

## Common Errors

### SKILL_FILE_NOT_FOUND

**Error:**
```text
SKILL_FILE_NOT_FOUND: expression_matrix.csv does not exist: path/to/file.csv
```

**Solution:**
- Verify the file path is correct.
- Confirm the file is readable.
- Use absolute paths if needed.

### SKILL_EMPTY_FILE

**Error:**
```text
SKILL_EMPTY_FILE: expression_matrix.csv is empty: path/to/file.csv
```

**Solution:**
- Confirm the file contains data rows.
- Regenerate or replace the empty file.

### SKILL_PARSE_ERROR

**Error:**
```text
SKILL_PARSE_ERROR: Failed to parse input file: path/to/file.csv - more columns than column names
```

**Solution:**
- Check whether the file is CSV or TSV.
- Verify the delimiter and header row.
- Remove malformed rows or encoding artifacts.

### SKILL_FILE_WRITE_ERROR

**Error:**
```text
SKILL_FILE_WRITE_ERROR: Unable to write to output directory: path/to/output
```

**Solution:**
- Confirm the output path is a directory.
- Check file-system permissions.
- Make sure the disk is writable and has free space.

### SKILL_EMPTY_DATA

**Error:**
```text
SKILL_EMPTY_DATA: Expression matrix is empty
```

**Solution:**
- Ensure the input file has at least one header row and data rows.
- Confirm filtering did not remove all records before analysis.

### SKILL_MISSING_COLUMNS

**Error:**
```text
SKILL_MISSING_COLUMNS: Group file must have at least sample and group columns
```

**Solution:**
- Provide a group file with at least two columns.
- Ensure sample IDs and group labels are present.

### SKILL_INVALID_TYPE

**Error:**
```text
SKILL_INVALID_TYPE: Expression values must be numeric
```

**Solution:**
- Remove text columns from the matrix body.
- Convert expression values to numeric format.
- Check that CLI parameters use the expected types.

### SKILL_SAMPLE_MISMATCH

**Error:**
```text
SKILL_SAMPLE_MISMATCH: Samples in group file not found in expression matrix: SampleA, SampleB
```

**Solution:**
- Make sure group-file sample IDs match matrix column names exactly.
- Check for hidden whitespace or renamed samples.
- Confirm you are using the same dataset version for both files.

### SKILL_INVALID_GROUP

**Error:**
```text
SKILL_INVALID_GROUP: case_group or control_group not found in group file
```

**Solution:**
- Check unique values in the group column.
- Match the spelling and case of `--case_group` and `--control_group`.

### SKILL_INVALID_DATA

**Possible Causes:**
- expression matrix contains missing or non-numeric values
- fewer than 2 samples in one class
- duplicate sample IDs or feature IDs
- requested features are not present in the matrix

**Solution:**
- Remove missing values or non-numeric columns.
- Ensure both classes contain at least 2 samples.
- Deduplicate identifiers before analysis.
- Verify the feature panel matches matrix row names.

### SKILL_INVALID_PARAMETER

**Error:**
```text
SKILL_INVALID_PARAMETER: --nfolds must be one of 3, 5, 7, or 10
```

**Other Common Messages:**
- `SKILL_INVALID_PARAMETER: --case_group and --control_group must be different`
- `SKILL_INVALID_PARAMETER: nfolds cannot exceed the smallest class size`
- `SKILL_INVALID_PARAMETER: --feature did not contain any valid feature names`
- `SKILL_INVALID_PARAMETER: --output_dir points to an existing file, not a directory`
- `SKILL_INVALID_PARAMETER: --input_file, --group_file, --case_group, and --control_group are required`
- `SKILL_INVALID_PARAMETER: --timeout_seconds must be >= 1`
- `SKILL_INVALID_PARAMETER: --seed must be >= 0`

**Solution:**
- Use one of the supported fold counts.
- Make sure `--case_group` and `--control_group` are different labels.
- Ensure `nfolds` does not exceed the smallest class size.
- Provide at least one valid feature name when using `--feature`.
- Ensure `--output_dir` is a directory path, not an existing file.
- Confirm all required arguments are provided.
- Check that `--timeout_seconds` is positive.
- Check that `--seed` is zero or a positive integer.

### SKILL_DEPENDENCY_MISSING

**Error:**
```text
SKILL_DEPENDENCY_MISSING: Install required packages before running: glmnet
```

**Solution:**
- Install missing packages from CRAN.
- Example: `install.packages(c("optparse", "glmnet"))`

### SKILL_TIMEOUT

**Error:**
```text
SKILL_TIMEOUT: Analysis exceeded the configured time limit
```

**Solution:**
- Reduce the feature set with `--feature`.
- Use a smaller input matrix for debugging.
- Increase `--timeout_seconds` if the larger runtime is expected.
- Check whether the runtime environment is resource constrained.

### SKILL_MEMORY_ERROR

**Error:**
```text
SKILL_MEMORY_ERROR: cannot allocate vector of size ...
```

**Solution:**
- Reduce the number of features or samples.
- Run on a machine with more available memory.
- Close other memory-intensive jobs.

### SKILL_MEMORY_WARNING

**Warning:**
```text
SKILL_MEMORY_WARNING: High memory usage detected at model fitting (10023.50 MB)
```

**Meaning:**
- The analysis is still running, but memory usage exceeded the warning threshold.
- This warning is emitted to help detect runs that may become unstable on larger datasets.

**Action:**
- Reduce the number of features or samples if possible.
- Use `--feature` to limit the feature panel during debugging.
- Run on a machine with more available memory for larger matrices.
- Treat repeated memory warnings as a sign that the current workload is close to the environment limit.

### SKILL_RUNTIME_ERROR

**Error:**
```text
SKILL_RUNTIME_ERROR: unexpected runtime failure message
```

**Solution:**
- Review the full console message.
- Re-check input files and parameter values.
- Retry after resolving file, memory, or dependency problems.

## Plot Issues

### Empty `selected_features.txt`

**Cause:**
Only the intercept is retained at `lambda.min`, so no non-intercept feature is written.

**Solution:**
- Provide a different feature panel.
- Increase sample size.
- Inspect the coefficient path plot to understand model sparsity.

### PDF Plots Not Created

**Cause:**
The analysis stopped before the plotting step, or the output directory is not writable.

**Solution:**
- Check the earlier error message.
- Confirm write permission for `--output_dir`.

### Plot Titles Are Blank

**Cause:**
This is the default behavior.

**Solution:**
- Leave as is if you want title-free plots.
- Use `--cv_title` and `--path_title` when you want custom titles.

## Warning Logs

Warnings are emitted to the console with the `[WARN]` prefix.

**Action:**
- Review the warning text in the console.
- If outputs were produced, inspect them before re-running.
- Treat repeated warnings as a signal to check input quality or package versions.
