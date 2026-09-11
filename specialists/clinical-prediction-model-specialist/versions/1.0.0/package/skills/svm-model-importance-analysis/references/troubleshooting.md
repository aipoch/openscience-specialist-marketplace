# Troubleshooting

## Error Codes

### `SKILL_FILE_NOT_FOUND`

Meaning:

- An input file does not exist.
- `--plot_only TRUE` was used before `data/svm_result.rds` had been created.

How to fix:

- Confirm the file exists and the path is correct.
- For plot-only mode, run a full analysis first so `data/svm_result.rds` is created.

### `SKILL_MISSING_COLUMNS`

Meaning:

- The group file has fewer than two columns.
- The expression matrix lacks a sample column plus at least two feature columns.

How to fix:

- Ensure the first row contains column names.
- Ensure the expression matrix has one sample column and at least two feature columns.
- Ensure the group file has the sample column plus at least one group column.

### `SKILL_EMPTY_DATA`

Meaning:

- The expression matrix or group file is empty.
- A plot-only run attempted to reuse an incomplete model object.

How to fix:

- Recreate the input file with valid rows.
- Rerun the full analysis to regenerate the model bundle.

### `SKILL_INVALID_PARAMETER`

Meaning:

- A required argument is missing.
- A numeric argument is out of range.
- `--case_group` and `--control_group` are identical.
- The output directory is outside the skill root.
- The expression matrix contains non-numeric feature values.
- The group file does not contain exactly two valid groups.
- `--svm_select_rule` is not `min` or `tolerance`.
- In `--plot_only TRUE` mode, `data/svm_result.rds` is unreadable or missing required fields.

How to fix:

- Check `Rscript scripts/main.R --help`.
- Use a relative `--output_dir` that stays inside the skill root.
- Confirm all numeric feature columns are numeric.
- Provide distinct case and control labels that exist in the group file.
- If `svm_result.rds` is corrupt or incomplete, rerun a full analysis to regenerate the saved bundle.

### `SKILL_SAMPLE_MISMATCH`

Meaning:

- Sample IDs do not match exactly between the expression matrix and the group file.

How to fix:

- Make sure both files contain the same sample IDs.
- Remove leading and trailing spaces from sample names.
- Ensure no sample is duplicated in either file.

### `SKILL_PACKAGE_NOT_FOUND`

Meaning:

- At least one required CRAN package is not installed.

Required packages:

- `optparse`
- `e1071`
- `ggplot2`

How to fix:

```r
install.packages(c("optparse", "e1071", "ggplot2"))
```

## Log Interpretation

Console messages use a single format:

```text
[INFO] 2026-04-20 01:57:11 | Reading input files.
[WARN] 2026-04-20 01:57:12 | A non-critical plotting or selection warning was handled.
[ERROR] 2026-04-20 01:57:12 | SKILL_FILE_NOT_FOUND: --input_file does not exist: ...
```

## Additional Checks

- Inspect `session_info.txt` when reproducing package-version differences.
- Re-run the command and review the console messages when troubleshooting failed runs.
