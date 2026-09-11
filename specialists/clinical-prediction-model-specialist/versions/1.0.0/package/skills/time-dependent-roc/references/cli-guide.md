# CLI Usage Guide

## Basic Syntax

```bash
Rscript scripts/main.R [OPTIONS]
```

## Core Arguments

| Argument | Description |
|----------|-------------|
| `-d FILE` or `--data_file FILE` | Input data file. Required |
| `-t LIST` or `--times LIST` | Prediction time points, comma-separated |
| `-m COL` or `--marker_col COL` | Marker column name |

## Optional Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `-o DIR` | `./TimeROC_Results` | Output directory |
| `-m COL` | `risk_score` | Marker column name |
| `-u UNIT` | `year` | Time unit label: `year`, `month`, `day` |
| `--auto_convert_days` | `TRUE` | Convert large `futime` values from days when appropriate |
| `-c VALUE` | `1` | Event code of interest |
| `-w METHOD` | `aalen` | Weighting method: `aalen`, `marginal`, `cox` |
| `--output_format` | `csv` | Tabular output format: `csv`, `txt` |

## Figure Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `--width` | `6` | Figure width in inches |
| `--height` | `6` | Figure height in inches |
| `--line_colors` | palette | Comma-separated curve colors |
| `--line_type` | `solid` | ROC line type |
| `--line_size` | `0.8` | ROC line size |
| `--line_alpha` | `1` | ROC line alpha |
| `--area_show` | `FALSE` | Fill area under curves |
| `--area_alpha` | `0.1` | Curve fill alpha |
| `--diagonal_show` | `TRUE` | Show diagonal reference line |
| `--legend_position` | `bottomright` | Legend placement |

## Complete Examples

### Example 1: Minimal Run

```bash
Rscript scripts/main.R \
  --data_file tests/data/time_roc_sample1.txt \
  --times 1,3,5
```

### Example 2: Explicit Marker Column

```bash
Rscript scripts/main.R \
  --data_file tests/data/time_roc_sample1.txt \
  --marker_col risk_score \
  --times 1,2,4 \
  --output_dir ./results_risk_score
```

### Example 3: Alternative Marker and TXT Output

```bash
Rscript scripts/main.R \
  --data_file tests/data/time_roc_sample2.txt \
  --marker_col GPR161 \
  --times 1,3,5 \
  --output_format txt \
  --output_dir ./results_gpr161
```

### Example 4: Monthly Label and Styled Plot

```bash
Rscript scripts/main.R \
  --data_file data/survival.csv \
  --marker_col model_score \
  --times 6,12,24 \
  --time_unit month \
  --line_colors "#4DBBD5,#E64B35,#00A087" \
  --area_show TRUE \
  --legend_position bottom \
  --plot_title "Model ROC over time" \
  --output_dir ./results_months
```

### Example 5: Excel Input

```bash
Rscript scripts/main.R \
  --data_file data/survival.xlsx \
  --marker_col signature_score \
  --times 1,3,5 \
  --output_dir ./results_excel
```

## Output File Structure

```text
TimeROC_Results/
├── data/
│   └── time_roc_points.csv
├── session_info.txt
├── figure/
│   └── time_roc.pdf
└── table/
    └── time_roc_auc.csv
```

If `--marker_col` is omitted, the skill uses `risk_score` by default. Provide `--marker_col` to analyze a different numeric marker column.

## Getting Help

```bash
Rscript scripts/main.R --help
```

## Validation Example

```bash
Rscript scripts/main.R \
  --data_file tests/data/time_roc_sample1.txt \
  --times 1,3,5 \
  --output_dir ./validation_output
```

Then confirm that:

- `validation_output/data/time_roc_points.csv` exists
- `validation_output/table/time_roc_auc.csv` exists
- `validation_output/figure/time_roc.pdf` exists
- `validation_output/session_info.txt` exists
