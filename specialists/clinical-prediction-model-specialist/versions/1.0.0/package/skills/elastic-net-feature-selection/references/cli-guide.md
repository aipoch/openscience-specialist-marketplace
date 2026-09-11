# CLI Usage Guide

## Basic Syntax

```bash
Rscript scripts/main.R [OPTIONS]
```

## Required Arguments

| Argument | Description |
|----------|-------------|
| `-i FILE` | Expression matrix file (CSV) |
| `-g FILE` | Group information file (CSV) |

## Optional Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `-f FILE` | `NULL` | Optional feature list file |
| `-c VALUE` | `case` | Positive class label |
| `-d VALUE` | `control` | Negative class label |
| `-a VALUE` | `0.5` | Elastic net alpha, or `auto` |
| `--alpha_grid VALUES` | `0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1` | Alpha candidates used when `--alpha auto` |
| `-n VALUE` | `5` | Cross-validation folds |
| `-l VALUE` | `lambda.min` | Lambda rule: `lambda.min` or `lambda.1se` |
| `-z VALUE` | `TRUE` | Whether to standardize features in `glmnet` |
| `-t VALUE` | `600` | Timeout in seconds |
| `-o DIR` | `./output/` | Output directory |
| `-s VALUE` | `42` | Random seed |

## Complete Examples

### Example 1: Recommended First Run

```bash
Rscript scripts/main.R \
  --input_file expression_matrix.csv \
  --group_file groups.csv \
  --feature_file genes.csv \
  --output_dir ./results \
  --alpha auto \
  --alpha_grid 0,0.25,0.5,0.75,1
```

### Example 2: Fixed-Alpha Baseline

```bash
Rscript scripts/main.R \
  --input_file expression_matrix.csv \
  --group_file groups.csv \
  --feature_file genes.csv \
  --output_dir ./results \
  --alpha 0.5
```

### Example 3: More Conservative Lambda Choice

```bash
Rscript scripts/main.R \
  --input_file expression_matrix.csv \
  --group_file groups.csv \
  --feature_file genes.csv \
  --output_dir ./results \
  --alpha 0.5 \
  --lambda_choice lambda.1se
```

### Example 4: Custom Group Labels

```bash
Rscript scripts/main.R \
  --input_file expression_matrix.csv \
  --group_file groups.csv \
  --output_dir ./results \
  --case_group Tumor \
  --control_group Normal
```

## Actual Baseline Run

### Input Parameters

```bash
Rscript scripts/main.R \
  --input_file tests/data/expression_matrix.csv \
  --group_file tests/data/groups.csv \
  --feature_file tests/data/genes.csv \
  --alpha auto \
  --alpha_grid 0,0.25,0.5,0.75,1 \
  --nfolds 5 \
  --lambda_choice lambda.min \
  --standardize TRUE \
  --timeout_seconds 600 \
  --output_dir tests/output-cli-auto \
  --seed 42
```

### Output Files

| File | Description |
|------|-------------|
| `alpha_tuning.csv` | Cross-validated performance summary for each alpha candidate |
| `model_coefficients.csv` | Coefficients at the selected lambda, including the intercept |
| `selected_features.csv` | Sparse selected features sorted by absolute magnitude; written empty when the chosen `alpha` is `0` (ridge) |
| `feature_matrix.csv` | Sample-by-feature matrix used for fitting |
| `coefficient_path.pdf` | Coefficient path plot across lambda values |
| `cv_curve.pdf` | Cross-validation curve with `lambda.min` and `lambda.1se` |
| `session_info.txt` | R version and loaded package versions |

### Output Directory Listing

```text
alpha_tuning.csv
coefficient_path.pdf
cv_curve.pdf
feature_matrix.csv
model_coefficients.csv
selected_features.csv
session_info.txt
```

### Output Content Preview

For the bundled auto-alpha baseline below, cross-validation selected `alpha = 0`, so `selected_features.csv` is header-only and `model_coefficients.csv` contains the coefficient ranking.

#### alpha_tuning.csv

```csv
"alpha","cvm_min","lambda_min","lambda_1se","nzero_min","selected"
0,1.45687097829956,161.249803956778,176.971460778561,8,TRUE
0.25,1.47428513611601,0.707885843114244,0.707885843114244,0,FALSE
0.5,1.48961242922418,0.353942921557122,0.353942921557122,0,FALSE
```

#### selected_features.csv

```csv
"feature","coefficient"
```

#### feature_matrix.csv

```csv
"sample","group","TNMD","DPM1","SCYL3","C1orf112","FGR","CFH","FUCA2","GCLC"
"Sample01","case",0.034919984,4.862654713,1.808508617,1.020484422,1.219276961,1.617251458,3.042731877,2.116264936
"Sample02","control",0.053250385,5.420809117,3.437573987,1.713607843,2.065813545,2.829606046,3.940260734,2.638004308
```

#### session_info.txt

```text
R version 4.1.2 (2021-11-01)
Platform: x86_64-pc-linux-gnu (64-bit)
Running under: Ubuntu 20.04.5 LTS
other attached packages:
[1] glmnet_4.1-10  Matrix_1.5-0   optparse_1.7.1
```

### Runtime And Resource Usage

The following metrics were captured from a local baseline run of the command above, using shell-level timing around the `Rscript` invocation plus the GC snapshot emitted by the script itself.

| Metric | Value |
|--------|-------|
| Start time | `2026-04-20 11:02:03` |
| End time | `2026-04-20 11:02:05` |
| Elapsed time | `2.567 s` |
| User CPU time | `2.252 s` |
| System CPU time | `0.416 s` |
| Timeout setting | `600` |
| GC snapshot (Ncells) | `used 1,643,961 (87.8 Mb)` |
| GC snapshot (Vcells) | `used 2,863,653 (21.9 Mb)` |

Resource note:

- The recorded baseline run completed without timeout, out-of-memory, or abnormal resource pressure in the target container environment.

## Getting Help

```bash
Rscript scripts/main.R --help
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Error (file not found, invalid parameter, timeout, etc.) |
