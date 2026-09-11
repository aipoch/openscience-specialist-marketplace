# CLI Usage Guide

## Command Syntax

```bash
Rscript scripts/main.R [options]
```

The workflow is controlled by `--mode`:
- `build`
- `plot`

---

## Build Mode

### Required Arguments

| Short | Long | Description |
|-------|------|-------------|
| `-m` | `--mode build` | Build nomogram bundle |
| `-d` | `--data_file` | Clinical CSV file |
| `-f` | `--features` | Comma-separated prognostic features |

### Optional Arguments

| Short | Long | Default | Description |
|-------|------|---------|-------------|
| `-t` | `--time_col` | `futime` | Survival time column |
| `-e` | `--event_col` | `fustat` | Event column |
| `-y` | `--years` | `1,2,3` | Prediction horizons |
| `-o` | `--output_dir` | `./output/` | Output directory |
|  | `--overwrite` | `FALSE` | Reuse a non-empty output directory |
| `-s` | `--seed` | `42` | Random seed |
| `-T` | `--timeout_seconds` | `0` | Elapsed time limit in seconds |

### Example

```bash
Rscript scripts/main.R \
  --mode build \
  --data_file tests/data/yuhou_cli_data.csv \
  --features age,gender,risk \
  --output_dir tests/expected_output/ \
  --overwrite
```

### Example: Custom Prediction Horizons

```bash
Rscript scripts/main.R \
  --mode build \
  --data_file tests/data/yuhou_cli_data.csv \
  --features age,gender,stage,risk \
  --years 1,3,5 \
  --output_dir tests/expected_output_custom/ \
  --overwrite \
  --timeout_seconds 60
```

---

## Plot Mode

### Required Arguments

| Short | Long | Description |
|-------|------|-------------|
| `-m` | `--mode plot` | Render nomogram PDF |
| `-n` | `--nomo_data_file` | Nomogram `.qs` bundle |
| `-p` | `--plot_save` | Output PDF path |

### Optional Arguments

| Short | Long | Default | Description |
|-------|------|---------|-------------|
| `-w` | `--plot_width` | `11` | Plot width in inches |
| `-H` | `--plot_height` | `8` | Plot height in inches |
| `-F` | `--font_size` | `8` | Plot font size |
| `-l` | `--line_width` | `5` | Plot line width |
|  | `--font_family` | `sans` | Font family |
| `-s` | `--seed` | `42` | Random seed |
| `-T` | `--timeout_seconds` | `0` | Elapsed time limit in seconds |

### Example

```bash
Rscript scripts/main.R \
  --mode plot \
  --nomo_data_file tests/expected_output/data/Nomogram_list.qs \
  --plot_save tests/expected_output/plot/nomogram_plot.pdf
```

### Example: Styled Plot Rendering

```bash
Rscript scripts/main.R \
  --mode plot \
  --nomo_data_file tests/expected_output_custom/data/Nomogram_list.qs \
  --plot_save tests/expected_output_custom/plot/nomogram_plot.pdf \
  --plot_width 12 \
  --plot_height 9 \
  --font_size 9 \
  --line_width 4 \
  --font_family serif
```

---

## Help

```bash
Rscript scripts/main.R --help
```
