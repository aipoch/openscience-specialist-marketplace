---
name: lightgbm-analysis
description: Use when training a LightGBM model on tabular data in R and returning model metrics, feature importance ranking tables, and feature importance plots.
license: MIT
author: AIPOCH
---
> **Source**: [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills)

# LightGBM Analysis

Use this skill to build a LightGBM model on tabular data and export feature importance ranking results as both a table and a figure.

## Use This Skill When

- You need a command-line LightGBM workflow written in R.
- You need classification or regression on structured tabular data.
- You need ranked feature importance outputs for reporting or interpretation.
- You need standardized outputs under `table/`, `figure/`, and `data/`.

## Primary Command

```bash
Rscript scripts/main.R \
  --data_file <input_file> \
  --target_var <target_column> \
  --output_dir <output_dir>
```

## Prerequisites

- `Rscript` is available in the shell.
- Required R packages: `optparse`, `data.table`, `lightgbm`.
- Install basic dependencies with `Rscript -e 'install.packages(c("optparse", "data.table"), repos="https://cloud.r-project.org")'`.
- Install the R `lightgbm` package from the LightGBM project because it is usually not available from CRAN.

## Core Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `--data_file` | Yes | Input data file in CSV format or tab-delimited TXT/TSV format |
| `--target_var` | Yes | Target column used for modeling |
| `--output_dir` | No | Output directory, default `./LightGBM_Results` |
| `--fail_if_output_exists` | No | Stop instead of overwriting when `output_dir` already contains files |
| `--task_type` | No | `auto`, `regression`, `binary`, or `multiclass`. Default `auto` |
| `--feature_cols` | No | Comma-separated feature columns. Default uses all columns except target and dropped columns |
| `--drop_cols` | No | Comma-separated columns to exclude before modeling |
| `--importance_type` | No | `gain` or `split`. Default `gain` |
| `--top_n` | No | Number of features to show in the importance plot. Default `20` |
| `--output_format` | No | `csv` or `txt` table export. Default `csv` |

## Modeling Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `--metric` | `auto` | Evaluation metric matched to task type |
| `--test_size` | `0.2` | Test-set proportion |
| `--valid_size` | `0.2` | Validation proportion taken from the training partition |
| `--nrounds` | `500` | Maximum boosting rounds |
| `--learning_rate` | `0.05` | Shrinkage rate |
| `--num_leaves` | `31` | Maximum leaf count per tree |
| `--max_depth` | `-1` | Maximum tree depth, `-1` means no explicit limit |
| `--min_data_in_leaf` | `5` | Minimum samples per leaf |
| `--feature_fraction` | `0.8` | Column sampling ratio |
| `--bagging_fraction` | `0.8` | Row sampling ratio |
| `--bagging_freq` | `1` | Bagging frequency |
| `--lambda_l1` | `0` | L1 regularization |
| `--lambda_l2` | `0` | L2 regularization |
| `--early_stopping_rounds` | `50` | Early stopping patience |
| `--seed` | `42` | Random seed |

## Input Requirements

- The input file must include the target column.
- Prefer `.csv` or `.tsv` inputs. `.txt` files must be tab-delimited.
- The skill expects at least 20 rows after removing missing target values.
- Features may be numeric, integer, logical, character, or factor-like text.
- Character features are label-encoded internally for LightGBM.
- Missing target values are removed before modeling.
- Missing feature values are left for LightGBM to handle.
- If `task_type=auto`, the script infers regression or classification from the target values.

Bundled test data examples:

```csv
V1,fustat,CAMK2N2,GGT6,GPR161,RAB26,RIBC2
TCGA-C5-A1M5,1,2.248291938,5.274690305,2.825215762,3.121114894,5.35318565
TCGA-EA-A5O9,0,3.346176843,5.404368414,2.604616977,0.629473197,4.429314674
TCGA-C5-A3HL,0,3.363100974,5.363314779,4.124799581,4.127228806,4.916596068
```

## Minimal Workflow

1. Confirm the input file exists and the target column name is correct.
2. Remove identifier or sensitive columns such as `id`, `sample_id`, `patient_id`, accession numbers, or the bundled sample identifier column `V1` before training.
3. Set `--drop_cols` and optionally `--feature_cols` so the model only sees intended predictors.
4. If you need overwrite protection, add `--fail_if_output_exists` or choose a fresh `--output_dir`.
5. Run `scripts/main.R`.
6. Check `table/` for the importance table, model metrics, and remediation guidance.
7. Check `figure/` for the feature importance ranking plot and `data/` for the run summary.

Avoid ambiguous text exports. If a `.txt` file is parsed as one column, re-export it as tab-delimited text or CSV before rerunning.

For quick validation in small audit environments, prefer the bundled `dt_sample3.txt` smoke test shown below with reduced `--nrounds` and `--early_stopping_rounds`. The full binary example on `dt_sample1.csv` is still useful as a complete workflow example, but it can exceed short runtime budgets.

If you omit `--data_file` or `--target_var`, the script exits with `SKILL_MISSING_INPUT`.

## Outputs

Expected output structure:

```text
<output_dir>/
├── table/
├── figure/
└── data/
```

Primary result files:

- `table/lightgbm_feature_importance.<output_format>`
- `table/lightgbm_model_metrics.<output_format>`
- `table/lightgbm_remediation.<output_format>`
- `figure/lightgbm_feature_importance_<importance_type>.pdf`
- `data/lightgbm_run_summary.txt`
- `data/lightgbm_categorical_levels.txt` when categorical or character predictors were encoded

Feature importance table fields include:

- `feature`
- `gain`
- `split`
- `cover`
- `importance_type`
- `importance_value`
- `rank`
- `gain_share`
- `split_share`

Model metrics include:

- `task_type`
- `metric_primary`
- `best_iteration`
- `train_rows`
- `valid_rows`
- `test_rows`
- `prediction_collapse_flag`
- `model_quality_flag`
- `interpretation_status`
- `primary_issue`
- `model_quality_issues`
- `rerun_hint`
- `model_quality_note`
- task-specific evaluation metrics such as `rmse`, `mae`, `accuracy`, `auc`, or `logloss`

Remediation table fields include:

- `task_type`
- `model_quality_flag`
- `interpretation_status`
- `issue_code`
- `issue_detail`
- `recommended_action`
- `suggested_rerun_change`

Run summary file includes the task type, best iteration, primary quality fields, top features, and artifact paths for the completed run.

## Overwrite Behavior

- Rerunning into an existing `output_dir` replaces prior result files with the new metrics, importance table, remediation table, figure, and session metadata.
- Set `--fail_if_output_exists` when you want the run to stop instead of replacing prior artifacts.
- If you need an audit trail, prefer a timestamped or per-run `output_dir`.
- The script now warns when `output_dir` already contains files.

## Success And Failure Contract

Success:

- Console output should end with `LightGBM analysis completed successfully`.
- `table/lightgbm_model_metrics.<output_format>` and `table/lightgbm_feature_importance.<output_format>` should exist.
- `table/lightgbm_remediation.<output_format>` and `data/lightgbm_run_summary.txt` should exist.
- `figure/lightgbm_feature_importance_<importance_type>.pdf` should exist.
- The importance table should contain at least one non-zero `gain` or `split` value.

Failure or caution:

- If parsing fails, expect a `SKILL_*` message instead of a raw stack trace.
- If `best_iteration <= 1`, predictions collapse to one class, `recall` is `0`, `f1` is `NA`, or the selected importance values are mostly zero, do not treat the ranking as reliable.
- Review `model_quality_flag` and `model_quality_note` in `table/lightgbm_model_metrics.csv` before interpreting the exported ranking.
- Use `interpretation_status` to decide whether the run is report-ready: `eligible` means interpretation-ready, `eligible_with_caveats` means the ranking may still be usable with caveats, and `caution_only` means diagnostic-only.
- Review `table/lightgbm_remediation.csv` and `rerun_hint` for the exact failure mode and recommended rerun changes.
- Recheck delimiter choice, identifier leakage, and `--min_data_in_leaf` before trusting the outputs.

## Caution Remediation

- `best_iteration<=1`: lower `--min_data_in_leaf` and verify that the selected predictors have usable signal.
- `single_predicted_class`: review class balance and feature selection before using the ranking downstream.
- `recall=0` or `no_positive_predictions`: revisit `--feature_cols` and the target balance before treating the run as report-ready.
- `<importance_type>_importance_sparse`: compare against the alternate importance type and review whether the retained predictors have enough signal.

## Agent Response Contract

When this skill completes, the agent should report:

- resolved `task_type`
- `best_iteration`
- primary evaluation metrics from `table/lightgbm_model_metrics.<output_format>`
- top ranked features from `table/lightgbm_feature_importance.<output_format>`
- `model_quality_flag` and `interpretation_status`
- artifact paths for the metrics table, importance table, remediation table, figure, and run summary file

If `model_quality_flag` is not `ok`, the agent must explicitly say the run is diagnostic-only or caveat-limited and include the recommended rerun changes from `rerun_hint` or `table/lightgbm_remediation.<output_format>`.

## Feature Importance Guidance

- Use `gain` when you care about overall contribution to loss reduction.
- Use `split` when you care about how often a feature is used in tree splits.
- Prefer `gain` for most ranking summaries and reports.
- Low importance does not imply no business value, especially under correlated features.

## Read These Files When Needed

| Need | File |
|------|------|
| LightGBM method details and importance interpretation | `references/algorithm.md` |
| CLI examples | `references/cli-guide.md` |
| Error diagnosis | `references/troubleshooting.md` |
| Main entry point | `scripts/main.R` |
| Sample test data | `tests/data/` |

## Quick Examples

Fast smoke test with `dt_sample3.txt`:

```bash
Rscript scripts/main.R \
  --data_file tests/data/dt_sample3.txt \
  --target_var Group \
  --drop_cols V1 \
  --task_type binary \
  --nrounds 80 \
  --early_stopping_rounds 20 \
  --top_n 15 \
  --output_dir tests/output_smoke_txt
```

Audit-friendly binary preset for short runtime budgets:

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

Full binary workflow example with `dt_sample1.csv`:

```bash
Rscript scripts/main.R \
  --data_file tests/data/dt_sample1.csv \
  --target_var fustat \
  --drop_cols V1 \
  --task_type binary \
  --output_dir tests/output_binary
```

Split-based importance export example with `dt_sample2.csv`:

Use this to verify split-based ranking output. Review `model_quality_flag` and `interpretation_status` before treating the bundled example as report-ready because this path can remain diagnostic-only on small test splits.

```bash
Rscript scripts/main.R \
  --data_file tests/data/dt_sample2.csv \
  --target_var fustat \
  --feature_cols CAMK2N2,GGT6,GPR161,RAB26,RIBC2 \
  --drop_cols V1 \
  --task_type binary \
  --importance_type split \
  --output_dir tests/output_binary_split
```

Audit-friendly regression preset with `dt_sample1.csv` and `RIBC2` as the target:

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

Full regression workflow with `dt_sample1.csv` and `RIBC2` as the target:

```bash
Rscript scripts/main.R \
  --data_file tests/data/dt_sample1.csv \
  --target_var RIBC2 \
  --drop_cols V1 \
  --task_type regression \
  --output_dir tests/output_regression
```

Tab-delimited TXT input with automatic binary target encoding from `Group`:

```bash
Rscript scripts/main.R \
  --data_file tests/data/dt_sample3.txt \
  --target_var Group \
  --drop_cols V1 \
  --task_type binary \
  --top_n 15 \
  --output_dir tests/output_group_txt
```

## Validation

```bash
Rscript scripts/main.R --help
```

Use the smoke test under `## Quick Examples` for a fast validation pass. After a successful run, verify that these files exist under the selected `output_dir`:

- `table/lightgbm_feature_importance.csv`
- `table/lightgbm_model_metrics.csv`
- `table/lightgbm_remediation.csv`
- `figure/lightgbm_feature_importance_<importance_type>.pdf`
- `data/lightgbm_run_summary.txt`
- `data/lightgbm_categorical_levels.txt` if categorical or character predictors were encoded

## When Not To Use

- The input file is an unstructured note, JSON blob, or free-text report.
- The text file delimiter is unknown and you cannot inspect or re-export it.
- The table still contains sample IDs, patient IDs, accession numbers, or similar identifiers that should not be model features.
- The input still contains direct identifiers or sensitive fields that you have not reviewed and removed from modeling.

## Common Errors

- `SKILL_FILE_NOT_FOUND`: Input file path is wrong or inaccessible.
- `SKILL_MISSING_COLUMNS`: The target or requested feature columns are missing.
- `SKILL_INVALID_DATA`: Data types, target encoding, or row count are unsuitable for LightGBM.
- `SKILL_DEGENERATE_MODEL`: Training finished but the exported importance table is all zero and should not be interpreted.
- `SKILL_INVALID_PARAMETER`: An argument value is invalid.
- `SKILL_DEPENDENCY_MISSING`: Required package such as `lightgbm` is unavailable.
- `SKILL_TRAINING_FAILED`: LightGBM training failed.

Before sharing exported artifacts, verify that identifier-like columns such as `V1`, sample IDs, or patient IDs were excluded from modeling and from any published tables. If `model_quality_flag` is not `ok`, treat the run as a diagnostic result rather than an interpretable ranking.

If the issue is not obvious, read `references/troubleshooting.md`.
