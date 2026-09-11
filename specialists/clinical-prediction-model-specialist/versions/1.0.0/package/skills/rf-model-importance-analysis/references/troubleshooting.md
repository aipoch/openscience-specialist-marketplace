# Troubleshooting Guide

## Common Errors

### `SKILL_FILE_NOT_FOUND`

**Meaning**

A required input file or plot-only model artifact does not exist.

**Typical triggers**

- `--input_file` path is wrong
- `--group_file` path is wrong
- `--plot_only TRUE` was used before `output_dir/data/rf_result.rds` had been created

**How to fix**

- Verify the file path is correct.
- Confirm the file exists before running.
- For plot-only mode, run a full analysis first so `data/rf_result.rds` is created.

### `SKILL_MISSING_COLUMNS`

**Meaning**

The input file does not contain the required columns.

**Typical triggers**

- The group file has fewer than two columns
- The expression matrix has fewer than three columns
- The delimiter does not match the actual file format
- The header row is missing or malformed

**How to fix**

- Ensure the first row contains column names.
- Ensure the group file has a sample column plus at least one additional column.
- Ensure the expression matrix has a sample column plus at least two feature columns.
- Use `.csv` for comma-separated files and `.tsv` or tab-delimited text for tab-separated files.

### `SKILL_EMPTY_DATA`

**Meaning**

An input file is empty, or a required model structure is missing.

**Typical triggers**

- The expression matrix is empty
- The group file is empty
- The stored random forest bundle is incomplete
- The random forest object does not contain error-rate or importance information

**How to fix**

- Recreate the input file with valid rows.
- Rerun the full analysis to regenerate a complete `rf_result.rds` file.
- Confirm the output bundle was produced by this skill and was not manually edited.

### `SKILL_INVALID_PARAMETER`

**Meaning**

A CLI argument, path, group setting, or numeric constraint is invalid.

**Typical triggers**

- Missing required arguments in full-analysis mode
- `--case_group` and `--control_group` are identical
- `--rf_imp_type` is not `1` or `2`
- Numeric arguments are non-positive
- Probability-like arguments are outside the allowed range
- `--output_dir` points outside the skill root
- The expression matrix contains non-numeric feature values
- The group file contains blank or duplicated sample IDs
- The expression matrix contains blank or duplicated sample IDs
- The case/control labels are not found in the group file
- One group contains fewer than two samples
- More or fewer than two groups are present after alignment

**How to fix**

- Review `Rscript scripts/main.R --help`.
- Use distinct case and control labels that exist in the group file.
- Check that numeric parameters are positive.
- Use `--rf_imp_type 1` or `--rf_imp_type 2` only.
- Keep `--output_dir` inside the skill root.
- Confirm all feature columns are numeric.
- Remove duplicate or blank sample IDs.
- Ensure each group has at least two samples.

### `SKILL_SAMPLE_MISMATCH`

**Meaning**

The expression matrix and group file do not contain the same sample IDs.

**Typical triggers**

- Samples are missing from one file
- Naming conventions differ between files
- Leading or trailing spaces are present in sample names
- Sample IDs were reordered or partially renamed

**How to fix**

- Make sure both files contain exactly the same sample IDs.
- Remove whitespace differences.
- Check for hidden formatting or encoding issues.
- Confirm no sample was dropped during preprocessing.

### `SKILL_PACKAGE_NOT_FOUND`

**Meaning**

One or more required R packages are not installed.

**Required packages**

- `optparse`
- `randomForest`
- `ggplot2`
- `tidyr`

**How to fix**

```r
install.packages(c("optparse", "randomForest", "ggplot2", "tidyr"))
```

## Warnings and Non-Fatal Issues

### `--rf_importance_top_n` Exceeds Available Features

**Behavior**

The skill does not fail. It logs a warning and uses the number of available features instead.

**How to fix**

- Lower `--rf_importance_top_n`.
- Or keep the current value and accept the automatically reduced number.

## Plot Issues

### Plot-Only Mode Fails Immediately

**Cause**

The expected model file `output_dir/data/rf_result.rds` does not exist.

**How to fix**

- Run a full analysis first.
- Confirm that `--output_dir` points to the same location used in the previous full run.

### RF Error Plot Cannot Be Generated

**Cause**

The stored model does not contain `err.rate`.

**How to fix**

- Regenerate the model with a full analysis run.
- Avoid manually modifying `rf_result.rds`.

### RF Importance Plot Cannot Be Generated

**Cause**

The stored model does not contain importance values.

**How to fix**

- Regenerate the model with a full analysis run.
- Confirm the model was trained with `importance = TRUE`.

## Log Interpretation

The script writes standardized log lines in this format:

```text
[INFO] 2026-04-20 01:35:32 | Starting rf-model-importance-analysis.
[WARN] 2026-04-20 01:35:32 | --rf_importance_top_n exceeded the number of available features. Using 8 instead.
[ERROR] 2026-04-20 01:35:32 | SKILL_FILE_NOT_FOUND: --input_file does not exist: ...
```

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | Error |

## Additional Checks

- Run `Rscript scripts/main.R --help` to verify CLI parsing.
- Inspect `session_info.txt` when reproducing package-version differences.
- Confirm that all output files were created under the requested `output_dir`.
- In plot-only mode, verify that `data/rf_result.rds` belongs to the same parameter context you intend to reuse.
