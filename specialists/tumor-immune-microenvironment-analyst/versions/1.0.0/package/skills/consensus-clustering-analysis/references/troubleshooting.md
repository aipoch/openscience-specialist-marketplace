# Troubleshooting Guide

## Common Errors

### SKILL_FILE_NOT_FOUND

**Error:**
```text
SKILL_FILE_NOT_FOUND: Input file not found: path/to/file.csv
```

**Solution:**
- Verify the file path is correct
- Check file permissions
- Use absolute paths if running from another directory

### SKILL_MISSING_COLUMNS

**Error:**
```text
SKILL_MISSING_COLUMNS: Could not detect the sample column.
```

**Solution:**
- Ensure the group file contains sample and group columns
- Use accepted names such as `sample`, `sample_id`, `group`, or `condition`

### SKILL_SAMPLE_MISMATCH

**Error:**
```text
SKILL_SAMPLE_MISMATCH: Expression matrix samples are missing from the group file.
```

**Solution:**
- Verify sample IDs match exactly between files
- Check for whitespace or encoding issues
- Ensure matrix columns are sample IDs, not metadata fields

### SKILL_INVALID_PARAMETER

**Error:**
```text
SKILL_INVALID_PARAMETER: --p_item and --p_feature must be within (0, 1].
```

**Solution:**
- Re-run `Rscript scripts/main.R --help`
- Check numeric ranges for `max_k`, `reps`, `p_item`, `p_feature`, and `timeout_seconds`
- Ensure `--gene_list` is provided when `--gene_selection custom` is used

### SKILL_INVALID_DATA

**Error:**
```text
SKILL_INVALID_DATA: Disease-group sample count must be at least 3 and not smaller than max_k.
```

**Solution:**
- Lower `--max_k`
- Increase the number of samples in the selected disease group
- Check whether the gene list is too restrictive
- Confirm the expression matrix contains only numeric values after the first column

### SKILL_TIMEOUT

**Error:**
```text
SKILL_TIMEOUT: Execution exceeded the configured time limit.
```

**Solution:**
- Reduce `--reps` for a faster test run
- Lower `--max_k` when sample size is limited
- Increase `--timeout_seconds` for larger datasets

### SKILL_DEPENDENCY_MISSING

**Error:**
```text
SKILL_DEPENDENCY_MISSING: data.table, ConsensusClusterPlus
```

**Solution:**
- Install the missing packages before rerunning

```r
if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager")
install.packages(c("optparse", "data.table", "testthat"))
BiocManager::install("ConsensusClusterPlus")
```

## Plot Issues

### Missing PDF files

**Cause:** The selected method did not finish successfully or no valid model was available.

**Solution:**
- Inspect `Cluster_res.csv`
- Re-run with a smaller `--max_k` and `--reps 20`

### Unstable clustering across methods

**Cause:** Weak subtype structure, small sample size, or an overly restrictive custom gene list.

**Solution:**
- Start with `gene_selection=highly_variable`
- Increase the sample size if possible
- Compare PAC values across all tested methods in `Cluster_res.csv`

## Runtime Checks

When a run fails or produces unexpected results, inspect:

- `session_info.txt` for R and package versions
- `Cluster_res.csv` for method-level PAC values
- `Cluster_res.csv` for the selected model row where `is_best=TRUE`
