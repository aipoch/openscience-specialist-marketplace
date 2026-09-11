# CLI Usage Guide

## Install Dependencies

Install the required CRAN packages before running the skill:

```r
install.packages(c("optparse", "e1071", "ggplot2"))
```

## Before You Run

- Input data must already be cleaned.
- Samples must be rows and features must be numeric columns.
- Missing values, imputation, normalization, and batch correction are outside this skill's scope.
- Only two-class classification is supported.
- In plot-only mode, `output_dir/data/svm_result.rds` must already exist.

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
| `--plot_only TRUE/FALSE` | `FALSE` | Reuse an existing `data/svm_result.rds` file and regenerate plots only |
| `--seed VALUE` | `42` | Random seed for reproducibility |
| `--timeout_seconds VALUE` | `600` | Elapsed time limit for the run |
| `--svm_k VALUE` | `10` | Number of stratified outer folds |
| `--svm_halve_above VALUE` | `50` | If surviving features exceed this count, remove half per iteration |
| `--svm_max_features_cap VALUE` | `30` | Maximum feature count evaluated on the error curve |
| `--svm_select_rule VALUE` | `min` | Feature-count rule: `min` or `tolerance` |
| `--svm_tol VALUE` | `0.01` | Tolerance used with `--svm_select_rule tolerance` |
| `--svm_rank_top_n VALUE` | `20` | Maximum number of ranked features shown in the ranking plot |

For the full parameter list, READ: `SKILL.md`.

## Complete Examples

### Example 1: Basic Analysis

```bash
Rscript scripts/main.R \
  --input_file tests/data/expression_matrix.csv \
  --group_file tests/data/group_info.csv \
  --case_group AR \
  --control_group Control \
  --output_dir tests/output/basic-run \
  --seed 42 \
  --timeout_seconds 300
```

### Output Files

| File | Size |
|------|------|
| `data/svm_result.rds` | `802 B (802 bytes)` |
| `plot/svm_rfe_error_plot.pdf` | `4.49 KB (4601 bytes)` |
| `plot/svm_rfe_ranking_plot.pdf` | `4.84 KB (4961 bytes)` |
| `session_info.txt` | `1.37 KB (1407 bytes)` |
| `table/svm_rfe_features.csv` | `185 B (185 bytes)` |
| `table/svm_rfe_full_ranking.csv` | `255 B (255 bytes)` |

### Runtime and Resource Usage

| Metric | Value |
|--------|-------|
| Start time | `2026-04-20 15:46:17` |
| End time | `2026-04-20 15:46:21` |
| Exit code | `0` |
| Timing mode | `shell` |
| Wall-clock time | `3.344` |
| User CPU time | `2.899` |
| System CPU time | `1.281` |
| Max resident set size | `Not recorded by time tool` |
| Cgroup peak memory | `3.11 GB (3342372864 bytes)` |
| Cgroup current memory | `1.46 GB (1569624064 bytes)` |
| Cgroup peak before run | `3.11 GB (3342372864 bytes)` |
| Auxiliary logs saved | `no` |

### Example 2: Plot-Only Regeneration

Run this only after a full analysis has already created `output_dir/data/svm_result.rds`.

```bash
Rscript scripts/main.R \
  --plot_only TRUE \
  --output_dir tests/output/basic-run \
  --seed 42 \
  --timeout_seconds 300
```

### Output Files

| File | Size |
|------|------|
| `data/svm_result.rds` | `802 B (802 bytes)` |
| `plot/svm_rfe_error_plot.pdf` | `4.49 KB (4601 bytes)` |
| `plot/svm_rfe_ranking_plot.pdf` | `4.84 KB (4961 bytes)` |
| `session_info.txt` | `1.37 KB (1407 bytes)` |
| `table/svm_rfe_features.csv` | `185 B (185 bytes)` |
| `table/svm_rfe_full_ranking.csv` | `255 B (255 bytes)` |

### Runtime and Resource Usage

| Metric | Value |
|--------|-------|
| Start time | `2026-04-20 15:47:50` |
| End time | `2026-04-20 15:47:51` |
| Exit code | `0` |
| Timing mode | `shell` |
| Wall-clock time | `1.503` |
| User CPU time | `1.189` |
| System CPU time | `1.214` |
| Max resident set size | `Not recorded by time tool` |
| Cgroup peak memory | `3.11 GB (3342372864 bytes)` |
| Cgroup current memory | `1.45 GB (1552224256 bytes)` |
| Cgroup peak before run | `3.11 GB (3342372864 bytes)` |
| Auxiliary logs saved | `no` |

### Example 3: Custom Feature-Selection Settings

```bash
Rscript scripts/main.R \
  --input_file tests/data/expression_matrix.csv \
  --group_file tests/data/group_info.csv \
  --case_group AR \
  --control_group Control \
  --output_dir tests/output/custom-run \
  --seed 42 \
  --svm_k 4 \
  --svm_halve_above 20 \
  --svm_max_features_cap 10 \
  --svm_select_rule tolerance \
  --svm_tol 0.02 \
  --svm_rank_top_n 10 \
  --timeout_seconds 300
```

### Output Files

| File | Size |
|------|------|
| `data/svm_result.rds` | `772 B (772 bytes)` |
| `plot/svm_rfe_error_plot.pdf` | `4.46 KB (4570 bytes)` |
| `plot/svm_rfe_ranking_plot.pdf` | `4.71 KB (4827 bytes)` |
| `session_info.txt` | `1.37 KB (1407 bytes)` |
| `table/svm_rfe_features.csv` | `69 B (69 bytes)` |
| `table/svm_rfe_full_ranking.csv` | `252 B (252 bytes)` |

### Runtime and Resource Usage

| Metric | Value |
|--------|-------|
| Start time | `2026-04-20 15:48:39` |
| End time | `2026-04-20 15:48:41` |
| Exit code | `0` |
| Timing mode | `shell` |
| Wall-clock time | `1.826` |
| User CPU time | `1.531` |
| System CPU time | `1.298` |
| Max resident set size | `Not recorded by time tool` |
| Cgroup peak memory | `3.11 GB (3342372864 bytes)` |
| Cgroup current memory | `1.45 GB (1552850944 bytes)` |
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

- `data/svm_result.rds`
- `table/svm_rfe_features.csv`
- `table/svm_rfe_full_ranking.csv`
- `plot/svm_rfe_error_plot.pdf`
- `plot/svm_rfe_ranking_plot.pdf`
- `session_info.txt`
