# CLI Usage Guide

## Install Dependencies

Install the required CRAN packages before running the skill:

```r
install.packages(c("optparse", "randomForest", "ggplot2", "tidyr"))
```

## Before You Run

- Input data must already be cleaned.
- Samples must be rows and features must be numeric columns.
- Missing values, imputation, normalization, and batch correction are outside this skill's scope.
- Only two-class classification is supported.
- In plot-only mode, `output_dir/data/rf_result.rds` must already exist.

## Basic Syntax

```bash
Rscript scripts/main.R [OPTIONS]
```

## Required Arguments

| Argument | Description |
|----------|-------------|
| `--input_file FILE` | Expression matrix file with samples in rows and numeric features in columns |
| `--group_file FILE` | Group file with sample IDs in the first column |
| `--case_group LABEL` | Case group label |
| `--control_group LABEL` | Control group label |

Note: The four arguments above are required for a full analysis run. They are not required when `--plot_only TRUE` is used.

## Optional Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `--output_dir DIR` | `output` | Output directory inside the skill root |
| `--plot_only TRUE/FALSE` | `FALSE` | Reuse an existing `rf_result.rds` file and regenerate plots only |
| `--seed VALUE` | `42` | Random seed for reproducibility |
| `--timeout_seconds VALUE` | `600` | Elapsed time limit for the run |
| `--rf_ntree VALUE` | `500` | Number of trees in the random forest |
| `--rf_mtry VALUE` | `NA` | Variables sampled at each split |
| `--rf_nodesize VALUE` | `NA` | Minimum terminal node size |
| `--rf_imp_type VALUE` | `1` | Importance metric type passed to `randomForest::importance()` |
| `--rf_imp_threshold VALUE` | `0` | Minimum importance score retained in `rf_top_features.csv` |
| `--rf_top_n VALUE` | `30` | Maximum number of rows written to `rf_top_features.csv` |
| `--rf_importance_top_n VALUE` | `10` | Maximum number of variables shown in the importance plot |

For the full parameter list, READ: `SKILL.md`.

## Complete Examples

### Example 1: Basic Analysis

```bash
Rscript scripts/main.R \
  --input_file tests/data/expression_matrix.csv \
  --group_file tests/data/group_info.csv \
  --case_group AR \
  --control_group Control \
  --output_dir tests/output/manual-test \
  --seed 42 \
  --timeout_seconds 300
```

### Output Files

| File | Size |
|------|------|
| `data/rf_result.rds` | `35.99 KB (36850 bytes)` |
| `plot/rf_error_plot.pdf` | `8.98 KB (9199 bytes)` |
| `plot/rf_importance_plot.pdf` | `5.31 KB (5439 bytes)` |
| `session_info.txt` | `1.48 KB (1515 bytes)` |
| `table/rf_feature_importance.csv` | `658 B (658 bytes)` |
| `table/rf_top_features.csv` | `609 B (609 bytes)` |

### Runtime and Resource Usage

| Metric | Value |
|--------|-------|
| Start time | `2026-04-20 15:36:40` |
| End time | `2026-04-20 15:36:41` |
| Exit code | `0` |
| Timing mode | `shell` |
| Wall-clock time | `1.543` |
| User CPU time | `1.271` |
| System CPU time | `1.211` |
| Max resident set size | `Not recorded by time tool` |
| Cgroup peak memory | `3.11 GB (3342372864 bytes)` |
| Cgroup current memory | `1.06 GB (1143218176 bytes)` |
| Cgroup peak before run | `3.11 GB (3342372864 bytes)` |
| Auxiliary logs saved | `no` |

### Example 2: Plot-Only Regeneration

Run this only after a full analysis has already created `output_dir/data/rf_result.rds`.

```bash
Rscript scripts/main.R \
  --plot_only TRUE \
  --output_dir tests/output/manual-test \
  --seed 42 \
  --timeout_seconds 300
```

### Output Files

| File | Size |
|------|------|
| `data/rf_result.rds` | `35.99 KB (36850 bytes)` |
| `plot/rf_error_plot.pdf` | `8.98 KB (9199 bytes)` |
| `plot/rf_importance_plot.pdf` | `5.31 KB (5439 bytes)` |
| `session_info.txt` | `1.48 KB (1515 bytes)` |
| `table/rf_feature_importance.csv` | `658 B (658 bytes)` |
| `table/rf_top_features.csv` | `609 B (609 bytes)` |

### Runtime and Resource Usage

| Metric | Value |
|--------|-------|
| Start time | `2026-04-20 15:38:22` |
| End time | `2026-04-20 15:38:23` |
| Exit code | `0` |
| Timing mode | `shell` |
| Wall-clock time | `1.165` |
| User CPU time | `1.160` |
| System CPU time | `1.218` |
| Max resident set size | `Not recorded by time tool` |
| Cgroup peak memory | `3.11 GB (3342372864 bytes)` |
| Cgroup current memory | `1.07 GB (1144283136 bytes)` |
| Cgroup peak before run | `3.11 GB (3342372864 bytes)` |
| Auxiliary logs saved | `no` |

### Example 3: Custom Importance Analysis

```bash
Rscript scripts/main.R \
  --input_file tests/data/expression_matrix.csv \
  --group_file tests/data/group_info.csv \
  --case_group AR \
  --control_group Control \
  --output_dir tests/output/custom-importance \
  --seed 42 \
  --rf_ntree 800 \
  --rf_mtry 4 \
  --rf_imp_type 2 \
  --rf_imp_threshold 1 \
  --rf_top_n 8 \
  --rf_importance_top_n 8 \
  --timeout_seconds 300
```

### Output Files

| File | Size |
|------|------|
| `data/rf_result.rds` | `45.98 KB (47080 bytes)` |
| `plot/rf_error_plot.pdf` | `10.32 KB (10570 bytes)` |
| `plot/rf_importance_plot.pdf` | `5.08 KB (5204 bytes)` |
| `session_info.txt` | `1.48 KB (1515 bytes)` |
| `table/rf_feature_importance.csv` | `610 B (610 bytes)` |
| `table/rf_top_features.csv` | `338 B (338 bytes)` |

### Runtime and Resource Usage

| Metric | Value |
|--------|-------|
| Start time | `2026-04-20 15:39:08` |
| End time | `2026-04-20 15:39:09` |
| Exit code | `0` |
| Timing mode | `shell` |
| Wall-clock time | `1.205` |
| User CPU time | `1.204` |
| System CPU time | `1.270` |
| Max resident set size | `Not recorded by time tool` |
| Cgroup peak memory | `3.11 GB (3342372864 bytes)` |
| Cgroup current memory | `1.07 GB (1144078336 bytes)` |
| Cgroup peak before run | `3.11 GB (3342372864 bytes)` |
| Auxiliary logs saved | `no` |

## Getting Help

```bash
Rscript scripts/main.R --help
```

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | Error |

## Expected Outputs

A successful full analysis run typically produces:

- `session_info.txt`
- `data/rf_result.rds`
- `table/rf_feature_importance.csv`
- `table/rf_top_features.csv`
- `plot/rf_error_plot.pdf`
- `plot/rf_importance_plot.pdf`
