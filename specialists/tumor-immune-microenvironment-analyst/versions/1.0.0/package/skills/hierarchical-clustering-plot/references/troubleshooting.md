# Troubleshooting Guide

## Common Errors

### SKILL_DEPENDENCY_MISSING

**Typical Causes:**
- `optparse` is not installed for CLI execution
- `data.table` is not installed for CSV loading
- `testthat` is not installed for automated tests

**Solution:**
- Install the missing package with `install.packages()`.
- Re-run the same command after installation completes.

### SKILL_FILE_NOT_FOUND

**Error:**
```text
SKILL_FILE_NOT_FOUND: Expression matrix file does not exist: path/to/file.csv
```

**Solution:**
- Verify the input path is correct.
- Ensure the file is readable.
- Use an absolute path if needed.

### SKILL_EMPTY_FILE

**Error:**
```text
SKILL_EMPTY_FILE: Input file is empty: path/to/file.csv
```

**Solution:**
- Confirm the exported CSV contains rows.
- Recreate the file without empty sheets or filters.
- Check the file size before rerunning.

### SKILL_EMPTY_DATA

**Error:**
```text
SKILL_EMPTY_DATA: Expression matrix contains no rows
```

**Solution:**
- Ensure the CSV includes at least one data row below the header.
- Re-export the source table without filtering all rows away.
- Confirm the group file also contains at least one sample row.

### SKILL_PARSE_ERROR

**Typical Causes:**
- The file is not valid CSV
- Encoding or delimiter issues prevented parsing
- Spreadsheet software added malformed quoting

**Solution:**
- Re-save the file as standard UTF-8 CSV.
- Confirm the delimiter is a comma and the header row is intact.
- Open the raw file to inspect broken quotes or separators.

### SKILL_MISSING_COLUMNS

**Typical Causes:**
- Blank header names in the expression matrix
- Missing sample or label columns in the group file

**Solution:**
- Ensure the CSV header row is present.
- Keep the first group-file column as sample IDs.
- Ensure the selected `--label_column` exists.

### SKILL_INVALID_TYPE

**Typical Causes:**
- Non-numeric values in expression columns
- Non-numeric `--label_cex` or `--timeout_seconds`

**Solution:**
- Remove text values from numeric matrix columns.
- Re-export numeric values from the source table.
- Pass numeric CLI arguments only.

### SKILL_SAMPLE_MISMATCH

**Error:**
```text
SKILL_SAMPLE_MISMATCH: Samples in group file not found in expression matrix: Sample01, Sample02
```

**Solution:**
- Make sure the first column in `group_file` exactly matches matrix column names.
- Remove extra spaces or hidden characters in sample IDs.
- Check encoding if the CSV was edited in spreadsheet software.

### SKILL_INVALID_DATA

**Typical Causes:**
- Duplicate feature IDs in the first matrix column
- Duplicate sample IDs in the group file
- Empty labels in the selected label column
- Non-numeric values in the expression matrix
- Fewer than two matched samples

**Solution:**
- Keep unique IDs in both input files.
- Ensure all expression values are numeric.
- Fill in the chosen label column completely.
- Re-export the CSV files without merged cells or formatting artifacts.

### SKILL_INVALID_PARAMETER

**Typical Causes:**
- Unsupported `--distance_method`
- Unsupported `--linkage_method`
- `--label_column` not found in the group file
- Non-positive `--label_cex`

**Solution:**
- Use only documented parameter values.
- Check spelling and case sensitivity.
- Run `Rscript scripts/main.R --help` to review accepted arguments.

### SKILL_TIMEOUT

**Typical Causes:**
- Very large matrices
- Slow I/O or constrained runtime environment

**Solution:**
- Increase `--timeout_seconds`.
- Reduce matrix size upstream if appropriate.
- Re-run in an environment with more CPU or I/O capacity.

### SKILL_PLOT_ERROR

**Typical Causes:**
- Output directory is not writable
- PDF device failed to open
- Invalid plot label settings

**Solution:**
- Confirm that the output directory exists and is writable.
- Try a different output path.
- Reduce label size if labels overlap heavily.

### SKILL_WRITE_ERROR

**Typical Causes:**
- Output directory is not writable
- Intermediate output copy failed

**Solution:**
- Check directory permissions.
- Ensure there is enough free disk space.
- Retry with a clean output directory.

### SKILL_WARNING

Warnings are printed to the console with the standard `[WARN]` prefix.

**What to do:**
- Inspect the console warning message for the exact condition.
- Verify whether the warning indicates malformed input data.
- If results look suspicious, rerun after fixing the upstream issue.

### SKILL_MEMORY_WARNING

This warning is logged when memory usage crosses the internal warning threshold.

**What to do:**
- Reduce the number of features or samples before rerunning.
- Re-run in an environment with more available memory.
- Inspect upstream preprocessing if the matrix is unexpectedly large.

## Interpretation Issues

### Samples cluster primarily by batch

**Cause:** Batch effects may dominate biological signal.

**What to do:**
- Verify whether the label column is a batch variable.
- Apply normalization or batch correction upstream if appropriate.
- Re-run clustering after preprocessing.

### Dendrogram does not match expectations

**Cause:** Distance metric or linkage method changes cluster topology.

**What to do:**
- Compare `complete` vs `average` linkage.
- Compare `euclidean` vs `manhattan` distance.
- Confirm the matrix contains the intended set of features.

### Tree looks unstable with very few features

**Cause:** Too little information is available to separate samples robustly.

**What to do:**
- Use more informative features.
- Remove constant or near-constant rows upstream.
- Check whether the matrix was filtered too aggressively.
