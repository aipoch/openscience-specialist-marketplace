# CLI Usage Guide

## Basic Syntax

```bash
Rscript scripts/main.R [OPTIONS]
```

## Required Arguments

| Argument | Description |
|----------|-------------|
| `-d FILE` or `--data_file FILE` | Input data file in CSV, TXT, or TSV format |
| `-t COL` or `--target_var COL` | Target column used for modeling |

## Common Optional Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `-o DIR` or `--output_dir DIR` | `./LightGBM_Results` | Output directory |
| `--fail_if_output_exists` | `FALSE` | Stop instead of overwriting an existing populated output directory |
| `--task_type TYPE` | `auto` | `auto`, `regression`, `binary`, `multiclass` |
| `--feature_cols COLS` | all eligible columns | Comma-separated feature list |
| `--drop_cols COLS` | none | Comma-separated columns to exclude |
| `--importance_type TYPE` | `gain` | `gain` or `split` |
| `--top_n N` | `20` | Top N features in the plot |
| `-f FORMAT` or `--output_format FORMAT` | `csv` | `csv` or `txt` |

## Training Arguments

| Argument | Default |
|----------|---------|
| `--metric` | `auto` |
| `--test_size` | `0.2` |
| `--valid_size` | `0.2` |
| `--nrounds` | `500` |
| `--learning_rate` | `0.05` |
| `--num_leaves` | `31` |
| `--max_depth` | `-1` |
| `--min_data_in_leaf` | `5` |
| `--feature_fraction` | `0.8` |
| `--bagging_fraction` | `0.8` |
| `--bagging_freq` | `1` |
| `--lambda_l1` | `0` |
| `--lambda_l2` | `0` |
| `--early_stopping_rounds` | `50` |
| `--seed` | `42` |

## Complete Examples

Use `dt_sample3.txt` for fast smoke tests in small audit environments. Prefer the audit-friendly binary and regression presets below when you need a fuller workflow under tighter runtime budgets.

### Example 0: Fast Smoke Test

```bash
Rscript scripts/main.R \
  --data_file tests/data/dt_sample3.txt \
  --target_var Group \
  --drop_cols V1 \
  --task_type binary \
  --nrounds 80 \
  --early_stopping_rounds 20 \
  --top_n 15 \
  --output_dir tests/output_smoke
```

### Example 1: Basic Binary Classification

Audit-friendly binary preset:

```bash
Rscript scripts/main.R \
  --data_file tests/data/dt_sample1.csv \
  --target_var fustat \
  --drop_cols V1 \
  --task_type binary \
  --nrounds 120 \
  --early_stopping_rounds 20 \
  --output_dir tests/output_binary_fast
```

Full binary workflow:

```bash
Rscript scripts/main.R \
  --data_file tests/data/dt_sample1.csv \
  --target_var fustat \
  --drop_cols V1 \
  --task_type binary \
  --output_dir tests/output_binary
```

### Example 2: Split-Based Importance Ranking

This example demonstrates split-based export behavior. Review `model_quality_flag`, `interpretation_status`, and `table/lightgbm_remediation.csv` before using the bundled output as a report-ready ranking.

```bash
Rscript scripts/main.R \
  --data_file tests/data/dt_sample2.csv \
  --target_var fustat \
  --drop_cols V1 \
  --task_type binary \
  --importance_type split \
  --output_dir tests/output_split
```

### Example 3: Explicit Feature Selection

```bash
Rscript scripts/main.R \
  --data_file tests/data/dt_sample1.csv \
  --target_var fustat \
  --feature_cols CAMK2N2,GGT6,GPR161,RAB26,RIBC2 \
  --drop_cols V1 \
  --task_type binary \
  --output_dir tests/output_selected
```

### Example 4: TXT Dataset With Group Labels

```bash
Rscript scripts/main.R \
  --data_file tests/data/dt_sample3.txt \
  --target_var Group \
  --drop_cols V1 \
  --task_type binary \
  --top_n 15 \
  --output_dir tests/output_group
```

### Example 5: Custom Hyperparameters

```bash
Rscript scripts/main.R \
  --data_file tests/data/dt_sample2.csv \
  --target_var fustat \
  --drop_cols V1 \
  --task_type binary \
  --learning_rate 0.03 \
  --num_leaves 63 \
  --nrounds 800 \
  --early_stopping_rounds 80 \
  --output_dir tests/output_tuned
```

### Example 6: Audit-Friendly Regression

```bash
Rscript scripts/main.R \
  --data_file tests/data/dt_sample1.csv \
  --target_var RIBC2 \
  --drop_cols V1 \
  --task_type regression \
  --nrounds 120 \
  --early_stopping_rounds 20 \
  --output_dir tests/output_regression_fast
```

### Example 7: Full Regression Workflow

```bash
Rscript scripts/main.R \
  --data_file tests/data/dt_sample1.csv \
  --target_var RIBC2 \
  --drop_cols V1 \
  --task_type regression \
  --output_dir tests/output_regression
```

## Output File Structure

```text
LightGBM_Results/
├── table/
│   ├── lightgbm_feature_importance.<output_format>
│   ├── lightgbm_model_metrics.<output_format>
│   └── lightgbm_remediation.<output_format>
├── figure/
│   └── lightgbm_feature_importance_gain.pdf
└── data/
    ├── lightgbm_run_summary.txt
    └── lightgbm_categorical_levels.txt  # optional
```

`data/lightgbm_categorical_levels.txt` is only written when categorical or character predictors are encoded.

## Getting Help

```bash
Rscript scripts/main.R --help
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Error |

## Typical Workflow

1. Inspect the input table and target column.
2. Remove identifier or sensitive columns before modeling.
3. Set `--drop_cols` and `--feature_cols` so only intended predictors are used.
4. Set `--task_type` explicitly if automatic inference may be ambiguous.
5. Run the model.
6. Review metrics in `table/`, including `model_quality_flag`, `interpretation_status`, and `model_quality_note`.
7. Review `table/lightgbm_remediation.csv` and `data/lightgbm_run_summary.txt` for rerun guidance and artifact paths.
8. Review importance ranking in both the table and the figure.

## Tips

1. Use `gain` for most reporting scenarios.
2. Exclude identifier-like columns such as `id`, `sample_id`, or the bundled sample identifier column `V1`.
3. If the target is numeric but actually a class label, set `--task_type` manually.
4. If `best_iteration <= 1`, predictions collapse to one class, or `model_quality_flag` is not `ok`, do not treat the ranking as reliable.
5. Use `--fail_if_output_exists` when you need a run to stop instead of replacing earlier artifacts.
6. If a feature importance plot looks unstable, retrain with a fixed `--seed` and review correlated variables.
