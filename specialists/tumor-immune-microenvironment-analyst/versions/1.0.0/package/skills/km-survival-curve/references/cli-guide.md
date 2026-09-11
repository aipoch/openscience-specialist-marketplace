# CLI Usage Guide

## Basic Syntax

```bash
Rscript scripts/main.R [OPTIONS]
```

## Core Arguments

| Argument | Description |
|----------|-------------|
| `-d FILE` or `--input_file FILE` | Input data file (CSV or tab-delimited TXT/TSV). Required |
| `-t COL` or `--time_col COL` | Survival time column |
| `-s COL` or `--status_col COL` | Event status column |
| `-r COL` or `--risk_col COL` | Risk group column |
| `-u UNIT` or `--time_unit UNIT` | Time unit label: year, month, day |

## Optional Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `-o DIR` | `./KM_Results` | Output directory |
| `-m METHOD` | `logrank` | Statistical method: logrank, wald |
| `--auto_convert_days BOOL` | `true` | Heuristically convert large time values from days when `time_unit` is `year` or `month` |

## Plot Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `--figure_width` | `10` | Figure width in inches |
| `--figure_height` | `7` | Figure height in inches |
| `--figure_family` | `sans` | Font family |
| `--title_x` | `Time` | X-axis title. Default renders as `Time (<time_unit>)` |
| `--title_y` | `Survival probability` | Y-axis title |
| `--title_main` | empty | Main plot title |
| `--legend_position` | `top` | Legend position |
| `--legend_show` | `true` | Show legend |
| `--legend_title` | empty | Legend title |
| `--line_type` | `solid` | Survival line type: solid, dashed, dotted, dotdash, longdash, twodash |
| `--line_size` | `1` | Survival line width |
| `--line_colors` | `#4DBBD5,#E64B35,#00A087,#3C5488,#F39B7F,#8491B4,#91D1C2,#DC0000` | Comma-separated group colors |
| `--censor_show` | `true` | Show censor markers |
| `--censor_size` | `7` | Censor marker size |
| `--confidence_show` | `true` | Show confidence interval |
| `--confidence_alpha` | `0.2` | Confidence band transparency |
| `--risk_table_show` | `true` | Show risk table |
| `--risk_table_border` | `true` | Show risk table border |
| `--risk_table_panel` | `false` | Show risk table panel background |
| `--risk_table_size` | `6` | Risk table font size |
| `--axis_title_size` | `12` | Axis title font size |
| `--axis_text_size` | `10` | Axis tick-label font size |
| `--legend_text_size` | `11` | Legend text font size |

## Complete Examples

### Example 1: Basic Kaplan-Meier Analysis

```bash
Rscript scripts/main.R \
  --input_file tests/data/km_sample1.txt \
  --output_dir ./km_results
```

### Example 2: Custom Column Names

```bash
Rscript scripts/main.R \
  --input_file data/my_survival_table.tsv \
  --time_col OS_time \
  --status_col OS_event \
  --risk_col signature_group \
  --output_dir ./custom_results
```

### Example 3: Custom Plot Title

```bash
Rscript scripts/main.R \
  --input_file tests/data/km_sample2.txt \
  --title_main "Study KM Curve" \
  --output_dir ./title_results
```

### Example 4: Month-Based Time Axis Label

```bash
Rscript scripts/main.R \
  --input_file tests/data/km_sample2.txt \
  --time_unit month \
  --output_dir ./month_results
```

Use this only when the source time column is known to be in days. If the source file is already in months, add `--auto_convert_days false`.

### Example 5: Disable Confidence Interval and Risk Table

```bash
Rscript scripts/main.R \
  --input_file tests/data/km_sample3.txt \
  --confidence_show false \
  --risk_table_show false \
  --output_dir ./simple_results
```

### Example 6: Use the Cox-Based p-value Route

```bash
Rscript scripts/main.R \
  --input_file tests/data/km_sample2.txt \
  --statistics_method wald \
  --output_dir ./wald_results
```

## Input Layout

A recommended input layout is:

```text
id	fustat	futime	risk_score	risk_group	GPR161	RIBC2
TCGA-C5-A1M5	1	5.62191780821918	-1.10702407761445	low	2.82521576230566	5.35318564979635
TCGA-VS-A94W	0	3.40547945205479	-0.671246677921865	high	4.26241812321536	4.00802068790173
```

Notes:

- `.txt` inputs must be tab-delimited.
- `futime` should be numeric.
- `fustat` should be coded as `0` or `1`.
- `risk_group` should already exist in the file.
- Extra columns such as `risk_score` or gene-expression values are allowed and ignored unless selected elsewhere.
- Rows with missing time, status, or group values are removed before analysis.
- If you pass `--line_colors`, provide at least one color per retained group.

## Getting Help

```bash
Rscript scripts/main.R --help
```

## Output Directory Structure

```text
KM_Results/
├── km-plot.pdf
└── session_info.txt
```

## Common Usage Patterns

### Quick Run

```bash
Rscript scripts/main.R -d data.csv -t futime -s fustat -r risk_group
```

### Set Time Unit Explicitly

```bash
Rscript scripts/main.R \
  -d data.csv \
  -u month
```

### Customize Appearance

```bash
Rscript scripts/main.R \
  -d data.csv \
  --title_main "Overall Survival" \
  --legend_position bottom \
  --line_colors "#1F77B4,#D62728"
```

## Tips

1. The saved outputs are `km-plot.pdf` and `session_info.txt` in the requested output directory.
2. The bundled test datasets `km_sample1.txt`, `km_sample2.txt`, and `km_sample3.txt` are tab-delimited and can be used directly in the example commands.
3. The default x-axis title automatically becomes `Time (year)`, `Time (month)`, or `Time (day)` based on `time_unit`.
4. Prefer `logrank` unless you specifically need the Cox-model p-value route.
5. `--auto_convert_days` is a heuristic based on `max(time) > 365`; disable it when the source time unit is already years or months.
6. `km-plot.pdf` may differ at the byte level across repeated runs even when the analytical result is unchanged.
7. If you customize `--line_type`, use one of: `solid`, `dashed`, `dotted`, `dotdash`, `longdash`, `twodash`.
