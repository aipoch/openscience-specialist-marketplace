# CLI Usage Guide

## Command Syntax

```bash
Rscript scripts/main.R [options]
```

## Required Arguments

| Short | Long | Description |
|-------|------|-------------|
| `-e` | `--expression_file` | Expression matrix in CSV/TSV format |
| `-g` | `--group_file` | Group file in CSV/TSV format |
| `-m` | `--marker_genes` | Comma-separated marker genes |
| `-c` | `--case_group` | Case group label |

## Optional Arguments

| Short | Long | Default | Description |
|-------|------|---------|-------------|
|  | `--group_col` | `NULL` | Explicit group column name |
| `-o` | `--output_dir` | `./output/` | Output directory |
|  | `--overwrite` | `FALSE` | Reuse a non-empty output directory |
| `-s` | `--seed` | `42` | Random seed |
| `-T` | `--timeout_seconds` | `0` | Elapsed time limit in seconds |
|  | `--plot_width` | `6` | Plot width in inches |
|  | `--plot_height` | `6` | Plot height in inches |
|  | `--font_family` | `sans` | PDF font family |
|  | `--line_colors` | palette string | Comma-separated ROC line colors |
|  | `--line_width` | `1.2` | ROC line width |
|  | `--show_diagonal` | `true` | Show diagonal reference line |
|  | `--diagonal_color` | `#7F7F7F` | Diagonal line color |
|  | `--diagonal_lty` | `2` | Diagonal line type |
|  | `--plot_title` | `ROC Diagnostic Performance` | Plot title |
|  | `--x_label` | `1 - Specificity` | X-axis label |
|  | `--y_label` | `Sensitivity` | Y-axis label |
|  | `--base_cex` | `0.9` | Base text-size multiplier |
|  | `--legend_position` | `bottomright` | Legend position |
|  | `--legend_cex` | `0.8` | Legend text size |

---

## Examples

### Basic Analysis

```bash
Rscript scripts/main.R \
  --expression_file expression_matrix.csv \
  --group_file group_info.csv \
  --marker_genes FOXP3,CD45,CD3E \
  --case_group Disease \
  --output_dir ./output/
```

### Explicit Group Column

```bash
Rscript scripts/main.R \
  --expression_file expression_matrix.csv \
  --group_file group_info.csv \
  --marker_genes FOXP3,CD45,CD3E \
  --case_group Disease \
  --group_col diagnosis \
  --output_dir ./output/
```

### Custom ROC Styling

```bash
Rscript scripts/main.R \
  --expression_file expression_matrix.csv \
  --group_file group_info.csv \
  --marker_genes FOXP3,CD45,CD3E \
  --case_group Disease \
  --plot_width 8 \
  --plot_height 6 \
  --plot_title "Biomarker ROC Comparison" \
  --legend_position topright \
  --output_dir ./output/
```

### Included Test Data

```bash
Rscript scripts/main.R \
  --expression_file tests/data/sample_expression_matrix.csv \
  --group_file tests/data/sample_group_info.csv \
  --marker_genes FOXP3,CD45,CD3E \
  --case_group Disease \
  --output_dir tests/expected_output/ \
  --overwrite
```

---

## Help

```bash
Rscript scripts/main.R --help
```
