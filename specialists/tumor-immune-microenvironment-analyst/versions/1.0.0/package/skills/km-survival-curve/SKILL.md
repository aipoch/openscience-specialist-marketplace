---
name: km-survival-curve
description: Use when generating Kaplan-Meier survival curves from tabular survival data containing time, event status, and a precomputed risk group. Supports command-line parameter input, parameter validation, automatic time-unit handling, single-file PDF figure export, and session metadata capture.
license: MIT
author: AIPOCH
---
> **Source**: [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills)

# Kaplan-Meier Survival Curve Analysis

Use this skill to run Kaplan-Meier survival analysis on a tabular dataset and export a single PDF survival figure.

## Use This Skill When

- You need a Kaplan-Meier survival curve from a table containing time, status, and group columns.
- You need a command-line survival workflow with parameter validation.
- You need a single Kaplan-Meier plot as the final analysis result.

## Primary Command

```bash
Rscript scripts/main.R \
  --input_file <input_file> \
  --output_dir <output_dir> \
  --time_col <time_column> \
  --status_col <status_column> \
  --risk_col <group_column>
```

## Prerequisites

- `Rscript` is available in the shell.
- Required R packages: `optparse`, `data.table`, `survival`, `survminer`, `ggplot2`.
- Install missing packages with `Rscript -e 'install.packages(c("optparse", "data.table", "survival", "survminer", "ggplot2"), repos="https://cloud.r-project.org")'`.

## Core Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `--input_file` | Yes | Input data file in CSV or tab-delimited TXT/TSV format |
| `--output_dir` | No | Output directory, default `./KM_Results` |
| `--time_col` | No | Survival time column, default `futime` |
| `--status_col` | No | Event status column, default `fustat` |
| `--risk_col` | No | Risk group column, default `risk_group` |
| `--time_unit` | No | Time unit label: `year`, `month`, or `day`, default `year` |
| `--auto_convert_days` | No | Heuristically convert large time values from days when `time_unit` is `year` or `month`, default `true` |
| `--statistics_method` | No | `logrank` or `wald`, default `logrank` |

## Plot Customization Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `--figure_width` | `10` | Figure width in inches |
| `--figure_height` | `7` | Figure height in inches |
| `--figure_family` | `sans` | Font family |
| `--title_x` | `Time` | X-axis title. If left as default, the script renders `Time (<time_unit>)` |
| `--title_y` | `Survival probability` | Y-axis title |
| `--title_main` | empty | Plot title |
| `--legend_position` | `top` | `top`, `bottom`, `left`, `right`, `none` |
| `--legend_show` | `true` | Whether to show legend |
| `--legend_title` | empty | Legend title |
| `--line_type` | `solid` | Survival line type: `solid`, `dashed`, `dotted`, `dotdash`, `longdash`, `twodash` |
| `--line_size` | `1` | Survival line width |
| `--line_colors` | `#4DBBD5,#E64B35,#00A087,#3C5488,#F39B7F,#8491B4,#91D1C2,#DC0000` | Comma-separated group colors |
| `--censor_show` | `true` | Whether to show censor markers |
| `--censor_size` | `7` | Censor marker size |
| `--confidence_show` | `true` | Whether to show confidence interval |
| `--confidence_alpha` | `0.2` | Confidence band transparency |
| `--risk_table_show` | `true` | Whether to show the risk table |
| `--risk_table_border` | `true` | Whether to show the risk table border |
| `--risk_table_panel` | `false` | Whether to show the risk table panel background |
| `--risk_table_size` | `6` | Risk table font size |
| `--axis_title_size` | `12` | Axis title font size |
| `--axis_text_size` | `10` | Axis tick-label font size |
| `--legend_text_size` | `11` | Legend text font size |

## Input Requirements

- The input file must contain the requested time, status, and group columns.
- `.txt` inputs must be tab-delimited.
- `time` must contain finite non-negative numeric values.
- `status` must be coded as `0` for censored and `1` for event.
- The risk group column must be a precomputed categorical grouping variable, not a continuous score column.
- The risk group column must contain at least 2 groups after filtering.
- `--line_colors` must provide at least one color per retained group when you override the default palette.
- Rows with missing time, status, or group values are removed before analysis.
- At least 2 complete observations must remain after filtering.
- Near-unique or continuous-looking grouping columns are rejected before model fitting.
- If `--auto_convert_days true` and `max(time) > 365`, the script assumes the retained time values are in days and converts them to the requested `--time_unit` when `time_unit` is `year` or `month`.
- Only use `--auto_convert_days true` when the source time column is known to be in days.
- If your source data are already in years or months, disable `--auto_convert_days` to avoid incorrect conversion.
- `--statistics_method wald` only supports exactly 2 retained groups; use `logrank` for multi-group comparisons.
- Invalid plotting parameters such as unsupported `--line_type` values are rejected before plotting.

Example input:

```text
id	fustat	futime	risk_score	risk_group	GPR161	RIBC2
TCGA-C5-A1M5	1	5.62191780821918	-1.10702407761445	low	2.82521576230566	5.35318564979635
TCGA-VS-A94W	0	3.40547945205479	-0.671246677921865	high	4.26241812321536	4.00802068790173
```

Bundled test datasets:

- `tests/data/km_sample1.txt`: baseline KM example with `risk_group`
- `tests/data/km_sample2.txt`: alternate cohort for plotting and statistics examples
- `tests/data/km_sample3.txt`: additional cohort for validation and repeated testing

## Minimal Workflow

1. Confirm the input file exists and identify the time, status, and group columns.
2. Run `scripts/main.R` with the requested output directory and any optional plot parameters.
3. Check the output directory for `km-plot.pdf`.

If you omit `--input_file`, the script exits with `SKILL_MISSING_INPUT`.

## Outputs

Expected output:

```text
<output_dir>/
├── km-plot.pdf
└── session_info.txt
```

## Interpretation Guide

- Use the survival figure to inspect separation between groups over time.
- Use the p-value annotation, confidence interval, and risk table in the figure to interpret group separation.

## Time Conversion Caution

- Automatic conversion is a convenience heuristic, not a unit detector.
- The script only checks whether `max(time) > 365`; it does not infer the true source unit from metadata.
- If the input time column is already expressed in years or months, run with `--auto_convert_days false`.
- Review the console log for the conversion warning whenever `time_unit` is `year` or `month`.

## Reproducibility Note

- Repeated runs on identical input should be analytically consistent.
- The exported `km-plot.pdf` may not be byte-identical across repeated runs because PDF metadata and graphics-device output can vary.
- If you need byte-stable artifacts, add a deterministic PDF post-processing step outside this skill.

## Do Not Use This Skill When

- You need this tool to derive a cutoff or split a continuous score into risk groups.
- You need multivariable Cox regression, covariate adjustment, or hazard-ratio modeling beyond the p-value route already exposed here.
- You need a broader survival-analysis workflow with upstream feature engineering, biomarker selection, or data harmonization.
- You need multiple plots, report generation, or downstream interpretation beyond producing one Kaplan-Meier figure and session metadata.

## Read These Files When Needed

| Need | File |
|------|------|
| Kaplan-Meier method details and interpretation | `references/algorithm.md` |
| More CLI examples | `references/cli-guide.md` |
| Error diagnosis | `references/troubleshooting.md` |
| Main execution entry point | `scripts/main.R` |
| Sample test data | `tests/data/km_sample1.txt`, `tests/data/km_sample2.txt`, `tests/data/km_sample3.txt` |

## Quick Examples

Basic Kaplan-Meier analysis:

```bash
Rscript scripts/main.R \
  --input_file tests/data/km_sample1.txt \
  --output_dir tests/output_basic
```

Custom column names:

```bash
Rscript scripts/main.R \
  --input_file tests/data/km_sample1.txt \
  --time_col futime \
  --status_col fustat \
  --risk_col risk_group \
  --output_dir tests/output_custom_columns
```

Custom plot title:

```bash
Rscript scripts/main.R \
  --input_file tests/data/km_sample2.txt \
  --title_main "Study KM Curve" \
  --output_dir tests/output_title
```

Hide confidence interval and risk table:

```bash
Rscript scripts/main.R \
  --input_file tests/data/km_sample3.txt \
  --confidence_show false \
  --risk_table_show false \
  --output_dir tests/output_simple
```

## Validation

```bash
Rscript scripts/main.R --help
```

```bash
Rscript scripts/main.R \
  --input_file tests/data/km_sample1.txt \
  --output_dir tests/validation_output
```

After running analysis, verify that `tests/validation_output/km-plot.pdf` exists.

## Common Errors

- `SKILL_FILE_NOT_FOUND`: Input file path is wrong or inaccessible.
- `SKILL_MISSING_COLUMNS`: A requested time, status, or risk group column is missing.
- `SKILL_INVALID_DATA`: Input data is malformed or unsuitable for survival analysis.
- `SKILL_INVALID_DATA`: A continuous or near-unique risk column was supplied where a categorical group column is required.
- `SKILL_INVALID_PARAMETER`: An argument value is invalid.
- `SKILL_INVALID_PARAMETER`: Plotting options such as `--line_type` or `--line_colors` are incompatible with the retained groups.
- `SKILL_INSUFFICIENT_DATA`: Too few complete observations remain after filtering.
- `SKILL_DEPENDENCY_MISSING`: A required R package such as `optparse` or `survival` is unavailable.

If the issue is not obvious, read `references/troubleshooting.md`.
