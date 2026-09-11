---
name: rf-model-importance-analysis
description: Use when you need a standardized R CLI workflow to train a two-class random forest model from an expression-like feature matrix, rank variable importance, and generate reproducible error and importance plots. NOT for regression tasks, multi-class classification, missing-value imputation, preprocessing, or remote data fetching.
license: MIT
author: AIPOCH
---
> **Source**: [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills)

# RF Model Importance Analysis

## Quick Start

Use one of these three commands first, then consult the full argument table only if you need extra tuning.

### 1. Standard Run

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

### 2. Tuned Importance Run

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

### 3. Plot-Only Rerender

Run this only after a full analysis has already created `output_dir/data/rf_result.rds`.

```bash
Rscript scripts/main.R \
  --plot_only TRUE \
  --output_dir tests/output/manual-test \
  --seed 42 \
  --timeout_seconds 300
```

## When to Read External Files

| Situation | File to Read | Purpose |
|-----------|--------------|---------|
| Need algorithm details | `references/algorithm.md` | Explain random forest modeling, importance metrics, assumptions, and result interpretation |
| Need to execute the analysis | `scripts/main.R` | Run the CLI entry point with a complete `Rscript` command |
| Encounter an error | `references/troubleshooting.md` | Map error codes to causes and fixes |
| Need CLI examples | `references/cli-guide.md` | See installation steps and runnable command examples |
| Need a runnable smoke test | `tests/data/` | Use the bundled small dataset for verification |

## Stop Conditions

Do not use this skill when any of the following is true:

- The task is regression, multiclass classification, time-series modeling, or remote data fetching.
- The input still requires imputation, normalization, batch correction, or other preprocessing.
- The feature matrix contains missing values, non-numeric feature columns, or mismatched sample IDs.

If one of those conditions applies, stop and hand off to a preprocessing or alternative modeling workflow before running this skill.

## Usage

Before running the CLI, ensure the data is already cleaned for binary classification: samples in rows, numeric feature columns only, and no missing values. Imputation, normalization, and batch correction are outside this skill's scope.

```bash
Rscript scripts/main.R \
  --input_file ./input/expression_matrix.csv \
  --group_file ./input/group_info.csv \
  --case_group Case \
  --control_group Control \
  --output_dir output/basic-run \
  --seed 42 \
  --timeout_seconds 600
```

## Arguments

| Short | Long | Type | Default | Required | Description |
|-------|------|------|---------|----------|-------------|
| `-i` | `--input_file` | character | none | yes, unless `--plot_only TRUE` | Expression matrix file with samples in rows and features in columns |
| `-g` | `--group_file` | character | none | yes, unless `--plot_only TRUE` | Group file with sample IDs in the first column |
| `-c` | `--case_group` | character | none | yes, unless `--plot_only TRUE` | Case group label |
| `-r` | `--control_group` | character | none | yes, unless `--plot_only TRUE` | Control group label |
| `-o` | `--output_dir` | character | `output` | yes | Output directory inside the skill root |
| `-p` | `--plot_only` | logical | `FALSE` | no | Reuse `output_dir/data/rf_result.rds` and regenerate plots without retraining |
| `-s` | `--seed` | integer | `42` | no | Random seed for reproducibility |
| `-t` | `--timeout_seconds` | integer | `600` | no | Elapsed time limit for the run |
|  | `--rf_ntree` | integer | `500` | no | Number of trees in the random forest |
|  | `--rf_mtry` | integer | `NA` | no | Variables sampled at each split; `NA` uses the package default |
|  | `--rf_nodesize` | integer | `NA` | no | Minimum terminal node size; `NA` uses the package default |
|  | `--rf_imp_type` | integer | `1` | no | Importance metric type passed to `randomForest::importance`; allowed values are `1` or `2` |
|  | `--rf_imp_threshold` | numeric | `0` | no | Minimum importance score retained in `rf_top_features.csv` |
|  | `--rf_top_n` | integer | `30` | no | Maximum number of rows written to `rf_top_features.csv` |
|  | `--rf_error_xlab` | character | `Number of Trees` | no | X-axis label for the RF error plot |
|  | `--rf_error_ylab` | character | `Error` | no | Y-axis label for the RF error plot |
|  | `--rf_error_line_size` | numeric | `0.6` | no | Line width for the RF error plot |
|  | `--rf_error_line_alpha` | numeric | `1` | no | Line alpha for the RF error plot |
|  | `--rf_error_line_color` | character | `#6C85F9,#D9503D,#939DE4,#DEA441,#A2C6D6,#E9B9E1,#BDD69F,#EBC98A` | no | Comma-separated line colors for non-OOB curves |
|  | `--rf_error_line_type` | character | `dashed` | no | Line type for class-specific error curves |
|  | `--rf_error_line_oob_type` | character | `solid` | no | Line type for the OOB curve |
|  | `--rf_error_legend_position` | character | `none` | no | Legend position for the RF error plot |
|  | `--rf_error_border_color` | character | `black` | no | Panel border color for the RF error plot |
|  | `--rf_error_border_fill` | character | `NA` | no | Panel fill for the RF error plot; use `NA` or `NULL` as text |
|  | `--rf_error_border_size` | numeric | `0.8` | no | Panel border width for the RF error plot |
|  | `--rf_error_base_size` | numeric | `14` | no | Base font size for the RF error plot |
|  | `--rf_error_width` | numeric | `6` | no | RF error plot width in inches |
|  | `--rf_error_height` | numeric | `5` | no | RF error plot height in inches |
|  | `--rf_importance_sort` | logical | `TRUE` | no | Sort variables in the importance plot |
|  | `--rf_importance_top_n` | integer | `10` | no | Maximum number of variables shown in the importance plot |
|  | `--rf_importance_label_x_ann` | logical | `TRUE` | no | Show x-axis tick labels in the importance plot |
|  | `--rf_importance_label_color` | character | `black` | no | Text and point outline color in the importance plot |
|  | `--rf_importance_label_cex` | numeric | `0.9` | no | Label size in the importance plot |
|  | `--rf_importance_point_cex` | numeric | `0.9` | no | Point size in the importance plot |
|  | `--rf_importance_point_shape` | integer | `23` | no | Point shape in the importance plot |
|  | `--rf_importance_point_fill` | character | `red` | no | Point fill color in the importance plot |
|  | `--rf_importance_line_color` | character | `gray` | no | Segment color in the importance plot |
|  | `--rf_importance_theme_border` | logical | `TRUE` | no | Draw panel borders in the importance plot |
|  | `--rf_importance_theme_offset` | numeric | `0.2` | no | Axis expansion factor in the importance plot |
|  | `--rf_importance_title` | character | `Variable Importance` | no | Main title for the importance plot |
|  | `--rf_importance_title_x_ann` | logical | `TRUE` | no | Show title and axis annotations in the importance plot |
|  | `--rf_importance_width` | numeric | `6` | no | RF importance plot width in inches |
|  | `--rf_importance_height` | numeric | `5` | no | RF importance plot height in inches |

## Input Format

### Expression Matrix

- CSV or TSV.
- First column: sample IDs.
- Remaining columns: numeric features.
- Samples must be rows.
- Missing or non-numeric feature values are not allowed.

Example:

```csv
sample,HIF1A,NR4A1,SOCS1
S1,6.21,-1.34,2.01
S2,6.57,0.37,3.62
S3,7.05,2.12,5.01
```

### Group File

- CSV or TSV.
- First column: sample IDs.
- One additional column must contain both the case and control labels.
- Exactly two groups are supported.

Example:

```csv
sample,group
S1,Case
S2,Case
S3,Control
```

## Output Files

| File | Format | Description |
|------|--------|-------------|
| `data/rf_result.rds` | RDS | Serialized model bundle with the trained random forest and metadata |
| `table/rf_feature_importance.csv` | CSV | Full ranked feature-importance table using the selected importance metric |
| `table/rf_top_features.csv` | CSV | Filtered top feature table after applying `--rf_imp_threshold` and `--rf_top_n` |
| `plot/rf_error_plot.pdf` | PDF | Error curves across trees for OOB and class-specific classification error |
| `plot/rf_importance_plot.pdf` | PDF | Variable-importance plot generated by `randomForest::varImpPlot()` |
| `session_info.txt` | TXT | R version, platform, and package version information |

## Error Handling

- Successful runs exit with status code `0`.
- Failed runs exit with status code `1`.
- Error messages use standardized names such as `SKILL_FILE_NOT_FOUND` and `SKILL_INVALID_PARAMETER`.
- Output paths are validated so that `--output_dir` cannot write outside the skill root.
- The analysis never performs network requests and never executes user input through `eval()`, `exec()`, or `system()`.

Common codes:

| Error Code | Meaning |
|------------|---------|
| `SKILL_FILE_NOT_FOUND` | An input file or required plot-only artifact does not exist |
| `SKILL_MISSING_COLUMNS` | The input file does not contain the required columns |
| `SKILL_EMPTY_DATA` | An input file is empty or a required model table is unavailable |
| `SKILL_INVALID_PARAMETER` | A CLI argument, group setting, numeric constraint, or path is invalid |
| `SKILL_SAMPLE_MISMATCH` | Sample IDs do not match between the expression matrix and group file |
| `SKILL_PACKAGE_NOT_FOUND` | One or more required CRAN packages are missing |

For detailed fixes, READ: `references/troubleshooting.md`

## Testing

### Help Check

```bash
Rscript scripts/main.R --help
```

### Full Test Run

```bash
Rscript tests/run_tests.R
```

### Direct Test Command

```bash
Rscript scripts/main.R \
  --input_file tests/data/expression_matrix.csv \
  --group_file tests/data/group_info.csv \
  --case_group AR \
  --control_group Control \
  --output_dir tests/output/manual-test \
  --seed 42 \
  --rf_ntree 200 \
  --rf_top_n 5 \
  --rf_importance_top_n 5 \
  --timeout_seconds 300
```
