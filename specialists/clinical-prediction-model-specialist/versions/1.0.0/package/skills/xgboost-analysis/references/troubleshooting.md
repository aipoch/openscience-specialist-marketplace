# Troubleshooting Guide

## Common Errors

### SKILL_FILE_NOT_FOUND

**Error:**
```text
SKILL_FILE_NOT_FOUND: Data file not found: path/to/file.csv
```

**Solution:**
- Verify the path is correct.
- Use an absolute path if needed.
- Check read permissions.

### SKILL_MISSING_COLUMNS

**Error:**
```text
SKILL_MISSING_COLUMNS: Target variable 'outcome' not found in data
```

**Solution:**
- Check the header row of the input file.
- Ensure `--target_var` matches the column name exactly.
- If using `--ignore_vars`, make sure the target column is not listed there.

### SKILL_INVALID_PARAMETER

**Error:**
```text
SKILL_INVALID_PARAMETER: task_type must be one of: auto, classification, regression
SKILL_INVALID_PARAMETER: importance_metric must be one of: gain, cover, frequency
SKILL_INVALID_PARAMETER: test_size must be between 0 and 1
```

**Solution:**
- Recheck argument spelling and value ranges.
- Run `Rscript scripts/main.R --help`.

### SKILL_INVALID_DATA

**Error:**
```text
SKILL_INVALID_DATA: Regression target must be numeric
SKILL_INVALID_DATA: Binary classification requires exactly 2 target classes
SKILL_INVALID_DATA: Each class must contain at least 2 rows for train-test splitting
SKILL_INVALID_DATA: No usable predictor columns remain after excluding target and ignored columns
```

**Solution:**
- Remove identifier-only columns with `--ignore_vars`.
- The bundled test data use a first unnamed sample column that is auto-excluded as `V1`.
- Ensure the target matches the intended task.
- For classification, ensure the target has exactly 2 classes.
- Check that enough rows remain after removing missing target values.
- Ensure both classes have enough observations.

### SKILL_DEPENDENCY_MISSING

**Error:**
```text
SKILL_DEPENDENCY_MISSING: xgboost
```

**Solution:**
- Install the required packages:
  ```r
  install.packages(c("optparse", "data.table", "Matrix", "xgboost"), repos = "https://cloud.r-project.org")
  ```

## Modeling Issues

### Importance Table Is Empty

**Possible causes:**
- The model stopped too early and used no effective splits.
- Predictors are nearly constant.
- The dataset is too small or too noisy.

**What to try:**
- Increase `--nrounds`.
- Lower `--min_child_weight`.
- Check predictors for zero variance.
- Reduce leakage or duplicated columns.

### Poor Test Performance

**Possible causes:**
- Data leakage during feature construction.
- Small dataset or unstable split.
- Strong class imbalance.
- Inadequate tuning.

**What to try:**
- Remove identifiers and leakage-prone columns.
- Adjust `--seed` and re-run.
- Tune `--max_depth`, `--eta`, `--subsample`, and `--colsample_bytree`.
- Use a larger dataset if available.

### Unexpected Task Detection

**Cause:**
- `--task_type auto` uses a simple heuristic.

**What to try:**
- Set `--task_type classification` or `--task_type regression` explicitly.

### Sample ID Column Appears In Feature Importance

**Cause:**
- A non-standard identifier column was not excluded automatically.

**What to try:**
- Pass it manually with `--ignore_vars`.
- The current auto-exclusion only targets a first unnamed identifier column such as `V1` with unique sample IDs.

### Binary Positive Class Not As Expected

**Cause:**
- The positive class defaults to the second sorted class level when `--positive_class` is omitted.

**What to try:**
- Set `--positive_class <label>` explicitly.

## Output Issues

### Plot Not Generated

**Possible causes:**
- No non-zero feature importance values were produced.
- The output directory is not writable.

**What to try:**
- Confirm the run completed without error.
- Inspect `table/<output_prefix>_feature_importance.*` first.
- Re-run with a writable `--output_dir`.

### Categorical Variables Show Multiple Encoded Columns

**Explanation:**
- XGBoost is trained on one-hot encoded columns.
- The skill aggregates encoded columns back to the original feature before saving the final importance table.

**Where to look:**
- Aggregated table: `table/<output_prefix>_feature_importance.*`

## General Checks

1. Confirm the input file loads correctly in R.
2. Confirm the target column exists and has valid values.
3. Run the bundled test example first.
4. Inspect `session_info.txt` if package-version issues are suspected.
