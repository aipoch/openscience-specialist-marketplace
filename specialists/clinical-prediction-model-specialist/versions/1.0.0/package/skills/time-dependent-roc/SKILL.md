---
name: time-dependent-roc
description: Use when performing time-dependent ROC curve analysis for survival data with follow-up time, event status, and a numeric marker. Supports CSV/TXT/TSV/Excel input, `risk_score` as the default marker unless `--marker_col` is provided, parameter validation, standardized output directories, AUC table export, ROC point export, and PDF figure generation.
license: MIT
author: AIPOCH
---
> **Source**: [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills)

# Time-Dependent ROC Analysis

Use this skill to compute and plot time-dependent ROC curves for survival outcomes.

## Use This Skill When

- You have survival data with `futime` and `fustat` columns.
- You need time-specific ROC curves and AUC values for a numeric risk marker.
- You want a command-line workflow with parameter validation and standardized outputs.
- Your file contains a numeric marker column named `risk_score`, or you will provide another marker explicitly with `--marker_col`.

## Primary Command

```bash
Rscript scripts/main.R \
  --data_file <input_file> \
  --times <comma_separated_times> \
  --output_dir <output_dir>
```

## Prerequisites

- `Rscript` is available in the shell.
- Required R packages: `optparse`, `timeROC`, `survival`, `ggplot2`.
- Optional package for Excel input: `openxlsx`.
- Install missing packages with `Rscript -e 'install.packages(c("optparse", "timeROC", "survival", "ggplot2", "openxlsx"), repos="https://cloud.r-project.org")'`.

## Core Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `--data_file` | Yes | Input data file in CSV, TXT, TSV, TAB, XLS, or XLSX format |
| `--times` | No | Prediction time points, comma-separated. Default `1,3,5` |
| `--marker_col` | No | Marker column name. Default `risk_score`; provide this option when your file uses a different marker |
| `--output_dir` | No | Output directory, default `./TimeROC_Results` |
| `--time_unit` | No | Time unit label for plot/output: `year`, `month`, or `day`. Default `year` |
| `--auto_convert_days` | No | If `TRUE`, convert large `futime` values from days to the selected unit when appropriate. Default `TRUE` |
| `--weighting` | No | IPCW weighting method: `aalen`, `marginal`, or `cox`. Default `aalen` |
| `--cause` | No | Event code treated as the outcome of interest. Default `1` |

## Input Requirements

- The input file must contain `futime` and `fustat` columns.
- The selected marker column must exist and be numeric or coercible to numeric.
- If `--marker_col` is omitted, the input file must contain `risk_score`.
- `futime` must be numeric or coercible to numeric.
- `fustat` must be numeric or coercible to numeric.
- Rows with missing `futime`, `fustat`, or marker values are excluded.
- At least 5 complete rows and at least 1 event for the requested `cause` are required.

Example input:

```text
id	fustat	futime	risk_score	risk_group	GPR161	RIBC2
TCGA-C5-A1M5	1	5.6219	-1.1070	low	2.8252	5.3532
TCGA-EA-A5O9	0	2.1589	-0.8964	low	2.6046	4.4293
TCGA-C5-A3HL	0	1.7014	-0.9044	low	4.1248	4.9166
```

## Minimal Workflow

1. Confirm the input file exists and includes `futime`, `fustat`, and `risk_score`, or plan to pass `--marker_col`.
2. Run `scripts/main.R` with the requested time points.
3. Check the output directory for the AUC table and PDF figure.

If you omit `--data_file`, the script exits with `SKILL_MISSING_INPUT`.

## Outputs

Expected output structure:

```text
<output_dir>/
├── data/
│   └── time_roc_points.<csv|txt>
├── session_info.txt
├── figure/
│   └── time_roc.pdf
└── table/
    └── time_roc_auc.<csv|txt>
```

Primary output files:

- `data/time_roc_points.csv` or `data/time_roc_points.txt`
- `table/time_roc_auc.csv` or `table/time_roc_auc.txt`
- `figure/time_roc.pdf`
- `session_info.txt`

Exported result fields include:

- `time`
- `time_unit`
- `auc`
- `marker_col`
- `n_complete`
- `n_events`

Exported ROC point fields include:

- `false_positive_rate`
- `sensitivity`
- `time`
- `time_unit`
- `auc`
- `curve_label`

## Read These Files When Needed

| Need | File |
|------|------|
| Statistical details and assumptions | `references/algorithm.md` |
| More CLI examples | `references/cli-guide.md` |
| Error diagnosis | `references/troubleshooting.md` |
| Main execution entry point | `scripts/main.R` |
| Sample test data | `tests/data/` |

## Quick Examples

Basic analysis:

```bash
Rscript scripts/main.R \
  --data_file tests/data/time_roc_sample1.txt \
  --times 1,3,5 \
  --output_dir tests/output_basic
```

Specify marker column and plot styling:

```bash
Rscript scripts/main.R \
  --data_file tests/data/time_roc_sample2.txt \
  --marker_col GPR161 \
  --times 1,2,4 \
  --line_colors "#4DBBD5,#E64B35,#00A087" \
  --legend_position bottom \
  --output_dir tests/output_gpr161
```

## Validation

```bash
Rscript scripts/main.R --help
```

```bash
Rscript scripts/main.R \
  --data_file tests/data/time_roc_sample1.txt \
  --times 1,3,5 \
  --output_dir tests/validation_output
```

After running analysis, verify that these files exist:

- `tests/validation_output/data/time_roc_points.csv`
- `tests/validation_output/table/time_roc_auc.csv`
- `tests/validation_output/figure/time_roc.pdf`
- `tests/validation_output/session_info.txt`

## Common Errors

- `SKILL_FILE_NOT_FOUND`: Input file path is wrong or inaccessible.
- `SKILL_MISSING_COLUMNS`: `futime` or `fustat` is missing.
- `SKILL_INVALID_DATA`: The marker column is non-numeric, no complete rows remain, event coding is unsuitable, or requested time points yield unusable AUC values.
- `SKILL_INVALID_PARAMETER`: An argument value is invalid.
- `SKILL_INSUFFICIENT_DATA`: Too few complete rows or no target events remain.
- `SKILL_DEPENDENCY_MISSING`: A required R package such as `optparse`, `timeROC`, `survival`, `ggplot2`, or `openxlsx` is unavailable.

If the issue is not obvious, read `references/troubleshooting.md`.
