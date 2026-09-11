# Troubleshooting Guide

## Common Errors

### SKILL_FILE_NOT_FOUND

**Error:**

```text
SKILL_FILE_NOT_FOUND: Data file not found: path/to/file.csv
```

**Solution:**

- Verify the file path.
- Prefer absolute paths if the working directory is uncertain.
- Ensure the file is readable.

### SKILL_MISSING_INPUT

**Error:**

```text
SKILL_MISSING_INPUT: Data file (-d) option is required
SKILL_MISSING_INPUT: Target variable (-t) option is required
```

**Solution:**

- Pass both `--data_file` and `--target_var`.
- Run `Rscript scripts/main.R --help` to inspect the interface.

### SKILL_MISSING_COLUMNS

**Error:**

```text
SKILL_MISSING_COLUMNS: target_var 'fustat' not found in data
SKILL_MISSING_COLUMNS: Requested feature columns not found: CAMK2N2, GGT6
```

**Solution:**

- Check spelling and case sensitivity.
- Inspect column names in the source file.
- Remove unavailable columns from `--feature_cols` or `--drop_cols`.

### SKILL_INVALID_DATA

**Error:**

```text
SKILL_INVALID_DATA: Need at least 20 rows after removing missing target values
SKILL_INVALID_DATA: Regression target must be numeric
SKILL_INVALID_DATA: Unsupported feature type for column 'notes'
```

**Solution:**

- Ensure enough rows remain after removing missing target values.
- Use numeric targets for regression.
- Remove unsupported columns such as free-text notes or JSON strings.
- Drop identifier columns that should not be used as predictors.
- For `.txt` or `.tsv` inputs, ensure the file is tab-delimited. If the loader reports a single-column table, re-export as tab-delimited text or CSV.

### SKILL_OUTPUT_EXISTS

**Error:**

```text
SKILL_OUTPUT_EXISTS: Output directory already contains files: path/to/output. Choose a fresh --output_dir or rerun without --fail_if_output_exists.
```

**Solution:**

- Choose a new `--output_dir` for the rerun.
- Remove or archive prior artifacts if overwrite is intentional.
- Omit `--fail_if_output_exists` when replacement is acceptable.

### SKILL_DEGENERATE_MODEL

**Error:**

```text
SKILL_DEGENERATE_MODEL: The trained model produced an all-zero feature importance table.
```

**Solution:**

- Lower `--min_data_in_leaf`, especially on small datasets.
- Recheck whether the chosen features contain usable signal.
- Prefer `--importance_type gain` while debugging weak split-based results.
- Inspect the console for warnings about `best_iteration` stopping at `1` or predictions collapsing to one class.

### SKILL_INVALID_PARAMETER

**Error:**

```text
SKILL_INVALID_PARAMETER: importance_type must be one of: gain, split
SKILL_INVALID_PARAMETER: test_size must be between 0 and 0.5
```

**Solution:**

- Use valid parameter values only.
- Keep `test_size` and `valid_size` below `0.5`.
- Use `gain` or `split` for `--importance_type`.

### SKILL_DEPENDENCY_MISSING

**Error:**

```text
SKILL_DEPENDENCY_MISSING: lightgbm
```

**Solution:**

- Install `optparse` and `data.table` from CRAN.
- Install the R `lightgbm` package from the official LightGBM source instructions.
- Re-run `Rscript -e "requireNamespace('lightgbm', quietly = TRUE)"` to verify availability.

### SKILL_TRAINING_FAILED

**Error:**

```text
SKILL_TRAINING_FAILED: [LightGBM training error message]
```

**Solution:**

- Check if the target definition matches the selected task.
- Reduce model complexity with smaller `num_leaves` or constrained `max_depth`.
- Confirm that categorical-like text columns are not malformed.

## Interpretation Issues

### Feature Importance Looks Counterintuitive

**Possible Causes:**

- Highly correlated features share importance.
- A leaked identifier column is still present.
- The chosen `importance_type` is `split` instead of `gain`.

**What to Do:**

- Re-run with `--importance_type gain`.
- Exclude obvious identifiers using `--drop_cols`.
- Compare the top-ranked features against domain knowledge and leakage risks.

### Feature Importance Is All Zero

**Cause:**

- The model stopped before learning useful splits.
- `--min_data_in_leaf` is too large for the training split.
- The selected features do not contain enough predictive signal.

**What to Do:**

- Lower `--min_data_in_leaf` and rerun.
- Switch to `--importance_type gain` for a more stable ranking view.
- Verify that the target and features were parsed correctly and that identifier columns were dropped.

### Numeric Target Was Treated as Classification

**Cause:**

- `--task_type auto` inferred a small integer-valued target as classes.

**What to Do:**

- Set `--task_type regression` explicitly.

### Plot Was Not Generated

**Cause:**

- Training failed before importance extraction.
- The model returned no usable importance values.

**What to Do:**

- Check console output for `SKILL_TRAINING_FAILED` or dependency errors.
- Verify that the selected feature set is not empty.

## Data Preparation Advice

1. Remove identifiers such as `id`, `sample_id`, patient IDs, accession numbers, and the bundled sample identifier column `V1` before training.
2. Remove or exclude sensitive columns that should not be model inputs or exported artifacts.
3. Keep the target column clean and explicit.
4. Avoid passing long free-text columns directly.
5. Use explicit `--feature_cols` when you need strict control over the model inputs.
6. Prefer `.csv` or `.tsv` files over ambiguous plain-text exports.

## Verification Command

Fast smoke test:

```bash
Rscript scripts/main.R \
  --data_file tests/data/dt_sample3.txt \
  --target_var Group \
  --drop_cols V1 \
  --task_type binary \
  --nrounds 80 \
  --early_stopping_rounds 20 \
  --top_n 15 \
  --output_dir tests/validation_smoke_output
```

Complete binary validation:

```bash
Rscript scripts/main.R \
  --data_file tests/data/dt_sample1.csv \
  --target_var fustat \
  --drop_cols V1 \
  --task_type binary \
  --nrounds 120 \
  --early_stopping_rounds 20 \
  --output_dir tests/validation_output
```

On success, verify:

- `tests/validation_smoke_output/table/lightgbm_feature_importance.csv`
- `tests/validation_smoke_output/table/lightgbm_model_metrics.csv`
- `tests/validation_smoke_output/table/lightgbm_remediation.csv`
- `tests/validation_smoke_output/figure/lightgbm_feature_importance_gain.pdf`
- `tests/validation_smoke_output/data/lightgbm_run_summary.txt`
- `tests/validation_output/table/lightgbm_feature_importance.csv`
- `tests/validation_output/table/lightgbm_model_metrics.csv`
- `tests/validation_output/table/lightgbm_remediation.csv`
- `tests/validation_output/figure/lightgbm_feature_importance_gain.pdf`
- `tests/validation_output/data/lightgbm_run_summary.txt`

`data/lightgbm_categorical_levels.txt` is optional and appears only when categorical or character predictors are encoded.

If `lightgbm_model_metrics.csv` shows `model_quality_flag` other than `ok`, treat the run as a smoke test or diagnostic check rather than an interpretable feature ranking.
