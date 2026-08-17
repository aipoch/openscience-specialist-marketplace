# CLI Usage Guide

## Basic Syntax

```bash
Rscript scripts/main.R [OPTIONS]
```

## Required Arguments

| Argument | Description |
|----------|-------------|
| `-i FILE` | Expression matrix file |
| `-g FILE` | Group file |
| `-c LABEL` | Case-group label |
| `-t LABEL` | Control-group label |

## Optional Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `-f VALUE` | `NULL` | Feature file or comma-separated feature list |
| `-n INT` | `10` | Cross-validation folds: `3`, `5`, `7`, `10` |
| `--cv_title TEXT` | `""` | Optional title for the cross-validation plot |
| `--path_title TEXT` | `""` | Optional title for the coefficient path plot |
| `--timeout_seconds INT` | `1800` | Maximum elapsed runtime in seconds |
| `-o DIR` | `./output/` | Output directory |
| `-s INT` | `42` | Random seed |

## Complete Examples

### Example 1: Basic Analysis

```bash
Rscript scripts/main.R \
  --input_file ./expression_matrix.csv \
  --group_file ./groups.csv \
  --case_group case \
  --control_group control \
  --output_dir ./output
```

### Example 2: Restrict to a Feature Panel

```bash
Rscript scripts/main.R \
  --input_file ./expression_matrix.csv \
  --group_file ./groups.csv \
  --case_group case \
  --control_group control \
  --feature ./genes.txt \
  --output_dir ./output
```

### Example 3: Inline Feature List With Custom Timeout

```bash
Rscript scripts/main.R \
  --input_file ./expression_matrix.csv \
  --group_file ./groups.csv \
  --case_group case \
  --control_group control \
  --feature TNMD,DPM1,SCYL3 \
  --nfolds 5 \
  --timeout_seconds 900 \
  --seed 123 \
  --output_dir ./output
```

### Example 4: Add Custom Plot Titles

```bash
Rscript scripts/main.R \
  --input_file ./expression_matrix.csv \
  --group_file ./groups.csv \
  --case_group case \
  --control_group control \
  --cv_title "LASSO Cross-Validation" \
  --path_title "LASSO Coefficient Paths" \
  --timeout_seconds 1200 \
  --output_dir ./output
```

## Verified Local Run

The command below was executed locally with the packaged sample dataset.

### Actual Input Parameters

```bash
Rscript scripts/main.R \
  -i ./expression_matrix.csv \
  -g ./groups.csv \
  -c case \
  -t control \
  -f ./genes.csv \
  -n 5 \
  --timeout_seconds 120 \
  -o ./result \
  -s 42
```

### Runtime and Resource Usage

| Metric | Observed Value |
|--------|----------------|
| Elapsed time | `1.839 s` |
| User CPU time | `1.784 s` |
| System CPU time | `0.927 s` |
| Peak logged R memory | `22.00 MB` |

### Output File List

```text
coefficient.csv
feature_matrix.csv
lasso_lambda_binary_plot.pdf
lasso_var_binary_plot.pdf
selected_features.txt
session_info.txt
```

### Output Content Snapshot

`coefficient.csv`

```csv
"feature","coefficient"
"(Intercept)",-4.2825167437524
"TSPAN6",0.279753819385914
"TNMD",0
"DPM1",0
"SCYL3",0
"C1orf112",0
"FGR",0.481174547375174
"CFH",0
"FUCA2",0
"GCLC",0
"NFYA",0.644701057513403
```

`selected_features.txt`

```text
TSPAN6
FGR
NFYA
```

`feature_matrix.csv` first rows

```csv
"sample","group","event","TSPAN6","TNMD","DPM1","SCYL3","C1orf112","FGR","CFH","FUCA2","GCLC","NFYA"
"Sample01","case",1,1.847876677,0.034919984,4.862654713,1.808508617,1.020484422,1.219276961,1.617251458,3.042731877,2.116264936,4.124013752
"Sample02","control",0,1.831755661,0.053250385,5.420809117,3.437573987,1.713607843,2.065813545,2.829606046,3.940260734,2.638004308,3.339892749
"Sample03","case",1,3.827625975,1.388850793,5.636969666,1.822363055,1.505535292,2.594572435,2.721657014,3.753551055,2.217820084,3.294679558
```

`session_info.txt` summary

```text
R version 4.1.2 (2021-11-01)
Platform: x86_64-pc-linux-gnu (64-bit)
other attached packages:
[1] glmnet_4.1-10  Matrix_1.5-0   optparse_1.7.1
```

## Getting Help

```bash
Rscript scripts/main.R --help
```

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | Error |
