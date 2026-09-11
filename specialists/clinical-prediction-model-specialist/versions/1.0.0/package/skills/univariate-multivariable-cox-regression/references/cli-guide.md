# CLI Usage Guide

## Command Syntax

```bash
Rscript scripts/main.R <command> [options]
```

Available commands:
- `analyze`
- `forest-plot`
- `multi-forest-plot`

---

## Analyze Command

### Required Argument

| Short | Long | Description |
|-------|------|-------------|
| `-d` | `--data_file` | Clinical CSV file |

### Optional Arguments

| Short | Long | Default | Description |
|-------|------|---------|-------------|
| `-f` | `--features` | `age,gender,stage,Tstage,Nstage,Mstage,risk` | Comma-separated model features |
| `-t` | `--time_col` | `futime` | Survival time column |
| `-e` | `--event_col` | `fustat` | Event column |
| `-u` | `--skip_univariate` | `false` | Skip univariate screening |
| `-o` | `--output_dir` | `./output/` | Output directory |
|  | `--overwrite` | `FALSE` | Reuse a non-empty output directory |
| `-s` | `--seed` | `42` | Random seed |
| `-T` | `--timeout_seconds` | `0` | Elapsed time limit in seconds |

### Examples

```bash
Rscript scripts/main.R analyze \
  --data_file tests/data/sample_clinical_survival_data.csv \
  --output_dir tests/expected_output/ \
  --overwrite
```

```bash
Rscript scripts/main.R analyze \
  --data_file clinical_data.csv \
  --features age,gender,stage,risk \
  --time_col futime \
  --event_col fustat \
  --output_dir ./results/ \
  --timeout_seconds 600
```

```bash
Rscript scripts/main.R analyze \
  --data_file clinical_data.csv \
  --features age,stage,risk \
  --skip_univariate true \
  --output_dir ./direct_multi/
```

---

## Forest Plot Commands

The same plotting options are used by `forest-plot` and `multi-forest-plot`.

### Required Arguments

| Short | Long | Description |
|-------|------|-------------|
| `-d` | `--data_file` | Cox result table in `.xlsx`, `.xls`, or `.csv` format |
| `-p` | `--plot_save` | Output PDF path |

### Optional Arguments

| Short | Long | Default | Description |
|-------|------|---------|-------------|
| `-w` | `--width` | `8` | Plot width in inches |
| `-H` | `--height` | `6` | Plot height in inches |
| `-F` | `--font_size` | `11` | Plot label font size |
| `-s` | `--seed` | `42` | Random seed |
| `-T` | `--timeout_seconds` | `0` | Elapsed time limit in seconds |

### Examples

```bash
Rscript scripts/main.R forest-plot \
  --data_file ./results/table/prognosis_uni_cox_results.xlsx \
  --plot_save ./results/plot/uni_forest_plot.pdf
```

```bash
Rscript scripts/main.R multi-forest-plot \
  --data_file ./results/table/prognosis_multi_cox_results.xlsx \
  --plot_save ./results/plot/multi_forest_plot.pdf \
  --width 10 \
  --height 7 \
  --font_size 12
```

---

## Command Help

```bash
Rscript scripts/main.R --help
Rscript scripts/main.R analyze --help
Rscript scripts/main.R forest-plot --help
Rscript scripts/main.R multi-forest-plot --help
```

---

## Output Layout

### After `analyze`

```text
output_dir/
|-- data/
|   `-- analysis_data.rds
|-- table/
|   |-- prognosis_multi_cox_results.xlsx
|   `-- prognosis_uni_cox_results.xlsx
`-- session_info.txt
```

### After plot commands

```text
output_dir/
`-- plot/
    |-- multi_forest_plot.pdf
    |-- session_info.txt
    `-- uni_forest_plot.pdf
```

---

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | Error |
