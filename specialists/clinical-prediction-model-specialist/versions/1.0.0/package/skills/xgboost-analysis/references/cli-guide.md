# CLI Usage Guide

## Basic Syntax

```bash
Rscript scripts/main.R [OPTIONS]
```

## Required Arguments

| Argument | Description |
|----------|-------------|
| `-d FILE` or `--data_file FILE` | Input data file in CSV, TXT, or TSV format |
| `-t VAR` or `--target_var VAR` | Target column to model |

## Optional Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `-o DIR` | ./XGBoost_Results | Output directory |
| `-k TYPE` | auto | Task type: auto, classification, regression |
| `-i VARS` | NULL | Comma-separated columns to ignore |
| `--positive_class LABEL` | NULL | Positive class label for binary classification |
| `--test_size NUM` | 0.2 | Test set proportion |
| `--seed INT` | 123 | Random seed |
| `--nrounds INT` | 300 | Maximum boosting rounds |
| `--max_depth INT` | 6 | Maximum tree depth |
| `--eta NUM` | 0.1 | Learning rate |
| `--subsample NUM` | 0.8 | Row sampling ratio |
| `--colsample_bytree NUM` | 0.8 | Column sampling ratio |
| `--min_child_weight NUM` | 1 | Minimum child weight |
| `--gamma NUM` | 0 | Minimum split loss reduction |
| `--lambda NUM` | 1 | L2 regularization |
| `--alpha NUM` | 0 | L1 regularization |
| `--early_stopping_rounds INT` | 20 | Early stopping rounds |
| `--importance_metric TYPE` | gain | Plot ranking metric: gain, cover, frequency |
| `--top_n INT` | 20 | Number of ranked features to plot |
| `--output_format TYPE` | csv | Table format: csv, txt |
| `--output_prefix STR` | xgboost | Output file prefix |

## Complete Examples

### Example 1: Minimal Binary Classification Run

```bash
Rscript scripts/main.R \
  --data_file tests/data/dt_sample1.csv \
  --target_var fustat
```

### Example 2: Binary Classification On The Second Bundled Dataset

```bash
Rscript scripts/main.R \
  --data_file tests/data/dt_sample2.csv \
  --target_var fustat \
  --task_type classification \
  --output_dir ./binary_results
```

### Example 3: Character-Label Classification From TXT Input

```bash
Rscript scripts/main.R \
  --data_file tests/data/dt_sample3.txt \
  --target_var Group \
  --task_type classification \
  --positive_class high \
  --top_n 15 \
  --output_dir ./group_results
```

### Example 4: Ignore Additional Columns Explicitly

```bash
Rscript scripts/main.R \
  --data_file tests/data/dt_sample1.csv \
  --target_var fustat \
  --ignore_vars CAMK2N2 \
  --output_dir ./custom_ignore_results
```

### Example 5: Custom Tuning Parameters

```bash
Rscript scripts/main.R \
  --data_file data/train.csv \
  --target_var outcome \
  --task_type classification \
  --nrounds 500 \
  --eta 0.05 \
  --max_depth 4 \
  --subsample 0.9 \
  --colsample_bytree 0.9 \
  --early_stopping_rounds 30 \
  --output_dir ./tuned_results
```

### Example 6: TXT Table Export

```bash
Rscript scripts/main.R \
  --data_file tests/data/dt_sample1.csv \
  --target_var fustat \
  --output_format txt \
  --output_prefix demo \
  --output_dir ./txt_results
```

## Output File Structure

```text
XGBoost_Results/
├── table/
│   ├── xgboost_feature_importance.csv
│   └── xgboost_model_performance.csv
├── figure/
│   └── xgboost_feature_importance_gain.png
└── data/
```

## Getting Help

```bash
Rscript scripts/main.R --help
```

## Run A Smoke Test

```bash
Rscript scripts/main.R \
  --data_file tests/data/dt_sample1.csv \
  --target_var fustat \
  --task_type classification \
  --output_dir tests/validation_output
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Error |

## Tips

1. Use `gain` for the default feature ranking view.
2. Use `ignore_vars` for IDs and leakage-prone columns.
3. If task detection is ambiguous, set `--task_type` manually.
4. For binary classification, set `--positive_class` when the business-positive label matters.
5. For the bundled datasets, the first unnamed sample column is auto-excluded and does not need to be passed in `--ignore_vars`.
