---
name: xgboost-analysis
description: Use when building XGBoost models on tabular data and returning feature importance ranking outputs. Supports binary classification and regression with automatic task detection, train-test split, performance tables, feature importance ranking tables, and PNG importance plots.
license: MIT
author: AIPOCH
---
> **Source**: [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills)

# XGBoost Modeling And Feature Importance Ranking

Use this skill to train an XGBoost model from a tabular dataset and export both feature importance ranking tables and feature importance plots.

## Use This Skill When

- You need a command-line XGBoost workflow in R for tabular data.
- You need a reproducible train-test split, model training, and evaluation.
- You need feature importance ranking outputs as both a table and a figure.
- You need automatic one-hot encoding for categorical predictors.
- Your data may contain a first unnamed sample ID column such as `V1` that should not enter the model.

## Do Not Use This Skill When

- Your classification target has more than 2 classes.
- Your input is not tabular CSV, TXT, or TSV data.
- You need causal interpretation, mechanism claims, or policy, business, or clinical conclusions.
- You only need narrative interpretation or triage of an existing result rather than model training.

## Primary Command

```bash
Rscript scripts/main.R \
  --data_file <input_file> \
  --target_var <target_column> \
  --task_type <auto|classification|regression> \
  --output_dir <output_dir>
```

## Prerequisites

- `Rscript` is available in the shell.
- Required R packages: `optparse`, `data.table`, `Matrix`, `xgboost`.
- Install missing packages with `Rscript -e 'install.packages(c("optparse", "data.table", "Matrix", "xgboost"), repos="https://cloud.r-project.org")'`.

## Core Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `--data_file` | Yes | Input CSV, TXT, or TSV file |
| `--target_var` | Yes | Target column used for modeling |
| `--task_type` | No | `auto`, `classification`, or `regression`. Default `auto` |
| `--output_dir` | No | Output directory, default `./XGBoost_Results` |
| `--ignore_vars` | No | Comma-separated columns to exclude from predictors |
| `--positive_class` | No | Positive class label for binary classification |
| `--test_size` | No | Test set proportion between 0 and 1, default `0.2` |
| `--seed` | No | Random seed, default `123` |
| `--nrounds` | No | Maximum boosting rounds, default `300` |
| `--max_depth` | No | Tree depth, default `6` |
| `--eta` | No | Learning rate, default `0.1` |
| `--subsample` | No | Row sampling ratio, default `0.8` |
| `--colsample_bytree` | No | Column sampling ratio, default `0.8` |
| `--min_child_weight` | No | Minimum child weight, default `1` |
| `--gamma` | No | Minimum split loss reduction, default `0` |
| `--lambda` | No | L2 regularization, default `1` |
| `--alpha` | No | L1 regularization, default `0` |
| `--early_stopping_rounds` | No | Early stopping rounds, default `20` |
| `--importance_metric` | No | `gain`, `cover`, or `frequency`. Default `gain` |
| `--top_n` | No | Number of features to plot, default `20` |
| `--output_format` | No | Table format: `csv` or `txt`, default `csv` |
| `--output_prefix` | No | Output filename prefix, default `xgboost` |

## Input Requirements

- The input file must contain the target column.
- Predictor columns can be numeric, integer, logical, character, or factor-like text.
- Character and factor predictors are one-hot encoded automatically.
- A first unnamed identifier column such as `V1` is automatically excluded when it contains unique sample IDs.
- Rows with missing target values are removed before training.
- For classification, exactly 2 classes are required.
- For regression, the target column must be numeric.
- Each class should have at least 2 rows so both training and test sets can be created.

Example input:

```csv
,fustat,CAMK2N2,GGT6,GPR161,RAB26,RIBC2
TCGA-C5-A1M5,1,2.248291938,5.274690305,2.825215762,3.121114894,5.35318565
TCGA-EA-A5O9,0,3.346176843,5.404368414,2.604616977,0.629473197,4.429314674
TCGA-C5-A3HL,0,3.363100974,5.363314779,4.124799581,4.127228806,4.916596068
```

## Minimal Workflow

1. Confirm the input file exists and the target column name is correct.
2. Run `scripts/main.R` with `--data_file` and `--target_var`.
3. Check the output directory for `table/feature_importance_*` and `figure/feature_importance_*`.

If you omit `--data_file` or `--target_var`, the script exits with `SKILL_MISSING_INPUT`.

## Outputs

Expected output structure:

```text
<output_dir>/
├── table/
├── figure/
└── data/
```

Primary outputs:

- `table/<output_prefix>_feature_importance.csv`
- `table/<output_prefix>_model_performance.csv`
- `figure/<output_prefix>_feature_importance_<importance_metric>.png`

Additional outputs:

- `session_info.txt`

Feature importance table fields include:

- `Rank`
- `Feature`
- `Gain`
- `Cover`
- `Frequency`
- `SelectedMetric`
- `SelectedValue`

## Feature Importance Metrics

- `gain`: Average contribution to loss reduction. Recommended for most ranking use cases.
- `cover`: Relative sample coverage contributed by a feature.
- `frequency`: How often the feature is used in splits.

## Read These Files When Needed

| Need | File |
|------|------|
| XGBoost method details and importance interpretation | `references/algorithm.md` |
| More CLI examples | `references/cli-guide.md` |
| Error diagnosis | `references/troubleshooting.md` |
| Main execution entry point | `scripts/main.R` |
| Bundled test data | `tests/data/` |

## Quick Examples

Auto-detected binary classification on `dt_sample1.csv`:

```bash
Rscript scripts/main.R \
  --data_file tests/data/dt_sample1.csv \
  --target_var fustat \
  --task_type auto \
  --output_dir tests/output_binary
```

Binary classification on `dt_sample2.csv`:

```bash
Rscript scripts/main.R \
  --data_file tests/data/dt_sample2.csv \
  --target_var fustat \
  --task_type classification \
  --importance_metric gain \
  --output_dir tests/output_gain
```

Character-label classification on `dt_sample3.txt`:

```bash
Rscript scripts/main.R \
  --data_file tests/data/dt_sample3.txt \
  --target_var Group \
  --task_type classification \
  --positive_class high \
  --top_n 15 \
  --output_dir tests/output_group
```

## Validation

```bash
Rscript scripts/main.R --help
```

```bash
Rscript scripts/main.R \
  --data_file tests/data/dt_sample1.csv \
  --target_var fustat \
  --task_type classification \
  --output_dir tests/validation_output
```

After running analysis, verify that these files exist:

- `tests/validation_output/table/xgboost_feature_importance.csv`
- `tests/validation_output/table/xgboost_model_performance.csv`
- `tests/validation_output/figure/xgboost_feature_importance_gain.png`

## Common Errors

- `SKILL_FILE_NOT_FOUND`: Input file path is wrong or inaccessible.
- `SKILL_MISSING_COLUMNS`: The target column is missing.
- `SKILL_INVALID_DATA`: Data is malformed, the target type is unsuitable, classification has more or fewer than 2 classes, or too few usable rows remain.
- `SKILL_INVALID_PARAMETER`: An argument value is invalid.
- `SKILL_DEPENDENCY_MISSING`: A required R package such as `xgboost` is unavailable.

If the issue is not obvious, read `references/troubleshooting.md`.
