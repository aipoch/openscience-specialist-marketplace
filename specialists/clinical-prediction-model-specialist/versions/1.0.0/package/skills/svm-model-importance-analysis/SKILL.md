---
name: svm-model-importance-analysis
description: Use when you need a standardized R CLI workflow to run two-class SVM-RFE feature ranking on an expression-like matrix, choose an informative feature count from cross-validated error, and generate reproducible ranking and error plots. NOT for regression, multi-class classification, missing-value imputation, or remote data fetching.
license: MIT
author: AIPOCH
---
> **Source**: [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills)

# SVM Model Importance Analysis

## When to Read External Files

| Situation | File to Read | Purpose |
|-----------|--------------|---------|
| Need algorithm details | `references/algorithm.md` | Explain SVM-RFE ranking, cross-validation logic, assumptions, and interpretation |
| Need to execute the analysis | `scripts/main.R` | Run the CLI entry point with a complete `Rscript` command |
| Encounter an error | `references/troubleshooting.md` | Map standardized error codes to causes and fixes |
| Need CLI examples | `references/cli-guide.md` | Review installation steps and runnable CLI examples |
| Need a runnable smoke test | `tests/data/` | Use the bundled small dataset for verification |

## Usage

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
| `-p` | `--plot_only` | logical | `FALSE` | no | Reuse `output_dir/data/svm_result.rds` and regenerate plots without rerunning SVM-RFE |
| `-s` | `--seed` | integer | `42` | no | Random seed for reproducibility |
| `-t` | `--timeout_seconds` | integer | `600` | no | Elapsed time limit for the run |
|  | `--svm_k` | integer | `10` | no | Number of stratified outer folds used for SVM-RFE and validation |
|  | `--svm_halve_above` | integer | `50` | no | If surviving features exceed this count, remove half per iteration |
|  | `--svm_max_features_cap` | integer | `30` | no | Maximum feature count evaluated on the error curve |
|  | `--svm_select_rule` | character | `min` | no | Feature-count rule: `min` or `tolerance` |
|  | `--svm_tol` | numeric | `0.01` | no | Tolerance used when `--svm_select_rule tolerance` is selected |
|  | `--svm_error_height` | numeric | `5` | no | SVM error plot height in inches |
|  | `--svm_error_width` | numeric | `6` | no | SVM error plot width in inches |
|  | `--svm_error_xlab` | character | `Number of Features` | no | X-axis label for the SVM error plot |
|  | `--svm_error_ylab` | character | `Classification Error Rate` | no | Y-axis label for the SVM error plot |
|  | `--svm_error_main_line_color` | character | `black` | no | Main line color for the SVM error plot |
|  | `--svm_error_second_line_color` | character | `#2BA2DE` | no | Baseline line color for the SVM error plot |
|  | `--svm_error_best_point_color` | character | `red` | no | Highlight color for the best feature-count point |
|  | `--svm_error_noinfo_lty` | integer | `3` | no | Line type for the no-information baseline |
|  | `--svm_error_label_cex` | numeric | `0.75` | no | Label size for the best-point annotation |
|  | `--svm_error_label_pos` | integer | `4` | no | Label position for the best-point annotation |
|  | `--svm_rank_top_n` | integer | `20` | no | Maximum number of ranked features shown in the ranking plot |
|  | `--svm_rank_width` | numeric | `7` | no | Ranking plot width in inches |
|  | `--svm_rank_height` | numeric | `6` | no | Ranking plot height in inches |
|  | `--svm_rank_color` | character | `#2BA2DE` | no | Bar color for the ranking plot |
|  | `--svm_rank_title` | character | `SVM-RFE Feature Ranking` | no | Title for the ranking plot |

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
| `data/svm_result.rds` | RDS | Serialized SVM-RFE bundle with ranking results and metadata |
| `table/svm_rfe_features.csv` | CSV | Selected ranked features using the chosen feature-count rule |
| `table/svm_rfe_full_ranking.csv` | CSV | Full ranking table across all input features |
| `plot/svm_rfe_error_plot.pdf` | PDF | Cross-validated classification error across feature counts |
| `plot/svm_rfe_ranking_plot.pdf` | PDF | Bar plot of the highest-ranked SVM-RFE features |
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
| `SKILL_EMPTY_DATA` | An input file is empty or a required ranking table is unavailable |
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
  --svm_k 4 \
  --svm_max_features_cap 6 \
  --svm_rank_top_n 6 \
  --timeout_seconds 300
```
