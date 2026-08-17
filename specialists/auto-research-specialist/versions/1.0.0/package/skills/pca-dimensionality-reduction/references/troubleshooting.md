# Troubleshooting Guide

## Common Errors

### SKILL_FILE_NOT_FOUND

**Error:**

```text
SKILL_FILE_NOT_FOUND: Data file not found: path/to/file.csv
```

**Solution:**

- Verify the file path.
- Check file permissions.
- Use an absolute path if needed.

### SKILL_MISSING_COLUMNS

**Error:**

```text
SKILL_MISSING_COLUMNS: Requested feature columns not found: GeneA, GeneB
SKILL_MISSING_COLUMNS: Sample ID column 'SampleID' not found in data
SKILL_MISSING_COLUMNS: Group column 'Group' not found in data
```

**Solution:**

- Check the header row in the input file.
- Ensure column names match exactly, including case and spaces.
- If using `--feature_columns`, confirm every listed name exists.

### SKILL_INVALID_DATA

**Error:**

```text
SKILL_INVALID_DATA: Selected feature columns must be numeric. Non-numeric columns: Group
SKILL_INVALID_DATA: PCA cannot be performed with zero-variance feature columns: Marker4
SKILL_INVALID_DATA: Sample ID column 'SampleID' contains missing or empty values
```

**Solution:**

- Use only numeric columns for PCA.
- Remove or exclude constant-value columns.
- Ensure sample IDs are unique and non-empty if a sample ID column is used.

### SKILL_INSUFFICIENT_DATA

**Error:**

```text
SKILL_INSUFFICIENT_DATA: At least 2 numeric feature columns are required for PCA
SKILL_INSUFFICIENT_DATA: Need at least 2 complete samples after filtering, found: 1
```

**Solution:**

- Select at least two usable numeric features.
- Reduce missing values in the selected columns.
- Make sure enough rows remain after filtering incomplete samples.

### SKILL_INVALID_PARAMETER

**Error:**

```text
SKILL_INVALID_PARAMETER: center_data must be one of true or false
SKILL_INVALID_PARAMETER: n_components must be a positive integer
SKILL_INVALID_PARAMETER: output_format must be one of: 'csv', 'txt'
```

**Solution:**

- Use `true` or `false` for logical parameters.
- Use positive integers for `n_components` and `top_loadings`.
- Run `Rscript scripts/main.R --help` to review supported options.

### SKILL_DEPENDENCY_MISSING

**Error:**

```text
SKILL_DEPENDENCY_MISSING: data.table
```

**Solution:**

- Install required packages:

```r
install.packages(c("optparse", "data.table"), repos = "https://cloud.r-project.org")
```

## Plot Issues

### Score Plot Not Generated

**Cause:** Fewer than two components were exported.

**Solution:**

- Ensure at least two usable features are available.
- Increase sample completeness so more components can be computed.

## Interpretation Issues

### PC1 Explains Much More Variance Than Other Components

**Cause:** The data have one dominant direction of variation.

**Solution:**

- This is common and not necessarily a problem.
- Check whether the dominant feature pattern is biological or technical.
- Review the top loadings for `PC1`.

### Group Separation Is Weak in the Score Plot

**Cause:** The main variance structure may not align with the provided groups.

**Solution:**

- Examine later components, not only `PC1` and `PC2`.
- Review whether scaling should be enabled.
- Confirm that the selected features are relevant to the biological or technical question.

### Too Many Samples Removed

**Cause:** Missing or non-finite values exist in one or more selected features.

**Solution:**

- Inspect the raw data for blanks, `NA`, `Inf`, or `-Inf`.
- Reduce the selected feature set if only a subset is needed.
- Impute missing values outside this CLI if your workflow allows it.

## Validation Checklist

1. Run help to confirm the interface loads.

```bash
Rscript scripts/main.R --help
```

2. Run the bundled test data.

```bash
Rscript scripts/main.R \
  --data_file tests/data/sample_pca_1.csv \
  --sample_id_column SampleID \
  --group_column Group \
  --feature_columns GeneA,GeneB,GeneC,GeneD,GeneE \
  --output_dir ./test_output
```

3. Check whether `table/pca_summary.csv` and `figure/pca_scree_plot.png` were created.
