# CLI Usage Guide

## Command Syntax

```bash
Rscript scripts/main.R [options]
```

## Required Arguments

| Short | Long | Description |
|-------|------|-------------|
| `-d` | `--data_file` | Clinical CSV file |
| `-f` | `--features` | Comma-separated model features |

## Optional Arguments

| Short | Long | Default | Description |
|-------|------|---------|-------------|
| `-t` | `--time_col` | `futime` | Survival time column |
| `-e` | `--event_col` | `fustat` | Event indicator column |
| `-y` | `--years` | `1,2,3` | Prediction horizons |
| `-b` | `--bootstrap_reps` | `1000` | Bootstrap replications |
| `-o` | `--output_dir` | `./output/` | Output directory |
|  | `--overwrite` | `FALSE` | Reuse a non-empty output directory |
| `-s` | `--seed` | `42` | Random seed |
| `-T` | `--timeout_seconds` | `0` | Elapsed time limit in seconds |
|  | `--plot_width` | `6` | Plot width in inches |
|  | `--plot_height` | `6` | Plot height in inches |
|  | `--font_family` | `sans` | PDF font family |
|  | `--line_width` | `1.5` | Curve line width |
|  | `--colors` | palette string | Comma-separated curve colors |
|  | `--plot_title` | `Calibration Curve` | Plot title |
|  | `--base_cex` | `0.9` | Base text-size multiplier |

---

## Examples

### Basic Analysis

```bash
Rscript scripts/main.R \
  --data_file clinical_data.csv \
  --features age,stage,risk \
  --output_dir ./output/
```

### Custom Horizons And Bootstrap Count

```bash
Rscript scripts/main.R \
  --data_file clinical_data.csv \
  --features age,gender,risk \
  --years 1,3,5 \
  --bootstrap_reps 1500 \
  --output_dir ./custom_output/
```

### Custom Plot Styling

```bash
Rscript scripts/main.R \
  --data_file clinical_data.csv \
  --features age,stage,risk \
  --plot_width 7 \
  --plot_height 6 \
  --line_width 2 \
  --colors "#1B9E77,#D95F02,#7570B3" \
  --plot_title "Three-Horizon Calibration" \
  --output_dir ./styled_output/
```

### Included Test Data

```bash
Rscript scripts/main.R \
  --data_file tests/data/sample_clinical_survival_data.csv \
  --features age,gender,risk \
  --bootstrap_reps 20 \
  --output_dir tests/output/ \
  --overwrite
```

## Help

```bash
Rscript scripts/main.R --help
```
