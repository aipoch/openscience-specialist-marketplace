# CLI Usage Guide

## Basic Syntax

```bash
Rscript scripts/main.R [OPTIONS]
```

## Required Arguments

| Argument | Description |
|----------|-------------|
| `-e, --exp_file FILE` | Expression matrix CSV |
| `-c, --cli_file FILE` | Clinical metadata CSV |
| `-m, --model_file FILE` | Model coefficient CSV |

## Optional Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `-o, --output_dir DIR` | `./output/` | Output directory |
| `--overwrite` | `FALSE` | Allow writing into a non-empty output directory |
| `-u, --time_unit VALUE` | `month` | Survival time unit: `day`, `month`, `year` |
| `--col_high VALUE` | `#E64B35` | High-risk color |
| `--col_low VALUE` | `#4DBBD5` | Low-risk color |
| `--roc_cols VALUE` | `#E64B35,#00A087,#3C5488` | ROC curve colors |
| `--roc_times VALUE` | `1,3,5` | ROC time points in years |
| `--roc_pos VALUE` | `bottomright` | ROC legend position |
| `--km_breaks VALUE` | `0` | KM x-axis break in years; `0` for automatic |
| `-s, --seed VALUE` | `42` | Random seed |
| `--timeout_seconds VALUE` | `3600` | Elapsed timeout limit |

## Complete Examples

### Example 1: Basic External Validation

```bash
Rscript scripts/main.R \
  --exp_file tests/data/BRCA_data.csv \
  --cli_file tests/data/BRCA_clinic.csv \
  --model_file tests/data/BRCA_coef.csv \
  --output_dir results/
```

### Example 2: Follow-up Stored in Days

```bash
Rscript scripts/main.R \
  --exp_file expression.csv \
  --cli_file clinical.csv \
  --model_file model.csv \
  --output_dir results/ \
  --time_unit day \
  --roc_times 1,2,3
```

### Example 3: Custom Plot Style

```bash
Rscript scripts/main.R \
  --exp_file expression.csv \
  --cli_file clinical.csv \
  --model_file model.csv \
  --output_dir results/ \
  --col_high '#B2182B' \
  --col_low '#2166AC' \
  --roc_cols '#B2182B,#4D9221,#2166AC' \
  --roc_pos topleft \
  --km_breaks 2
```

### Example 4: Explicit Timeout

```bash
Rscript scripts/main.R \
  --exp_file expression.csv \
  --cli_file clinical.csv \
  --model_file model.csv \
  --output_dir results/ \
  --timeout_seconds 7200
```

### Example 5: Refresh the Retained Example Output

```bash
Rscript tests/refresh_example_output.R
```

## Getting Help

```bash
Rscript scripts/main.R --help
```

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | Error such as invalid input, missing dependency, or analysis failure |

## Practical Notes

- `--roc_times` is interpreted in years after time conversion.
- `--roc_cols` can contain fewer colors than time points; colors will be recycled.
- `--km_breaks 0` lets the script infer an axis spacing from the maximum follow-up.
- Use `--overwrite` only when you intentionally want to replace files in an existing non-empty output directory.
- The script always writes `analysis.log`, `run_parameters.tsv`, and `session_info.txt` for reproducibility.
