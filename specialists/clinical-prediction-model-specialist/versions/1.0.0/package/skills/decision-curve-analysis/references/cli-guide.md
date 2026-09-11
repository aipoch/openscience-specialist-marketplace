# CLI Usage Guide

## Command Syntax

```bash
Rscript scripts/main.R [options]
```

## Required Arguments

| Short | Long | Description |
|-------|------|-------------|
| `-d` | `--data_file` | Clinical CSV file |

## Optional Arguments

| Short | Long | Default | Description |
|-------|------|---------|-------------|
|  | `--outcome_col` | `fustat` | Binary outcome column |
|  | `--predictor_col` | `riskScore` | Numeric predictor column |
|  | `--study_design` | `case-control` | Study design |
|  | `--population_prevalence` | `0.3` | Population prevalence for case-control analysis |
|  | `--threshold_by` | `0.01` | Threshold step size |
|  | `--confidence_level` | `0.95` | Confidence level for DCA |
|  | `--population_size` | `1000` | Population size for the clinical-impact plot |
|  | `--n_cost_benefits` | `8` | Number of cost-benefit labels |
|  | `--show_confidence_intervals` | `FALSE` | Show confidence intervals on the decision curve |
|  | `--standardize_net_benefit` | `FALSE` | Use standardized net benefit in the summary |
|  | `--decision_curve_color` | `#E64B35` | Decision-curve line color |
|  | `--impact_colors` | `#E64B35,#4DBBD5` | Two clinical-impact colors |
|  | `--plot_width` | `6` | PDF width in inches |
|  | `--plot_height` | `5.5` | PDF height in inches |
|  | `--font_family` | `sans` | PDF font family |
|  | `--plot_title` | `Decision Curve Analysis` | Decision-curve plot title |
|  | `--base_cex` | `0.9` | Base text-size multiplier |
| `-o` | `--output_dir` | `./output/` | Output directory |
|  | `--overwrite` | `FALSE` | Reuse a non-empty output directory |
| `-s` | `--seed` | `42` | Random seed |
| `-T` | `--timeout_seconds` | `0` | Elapsed time limit in seconds |

---

## Examples

### Basic Analysis

```bash
Rscript scripts/main.R \
  --data_file clinical_dca_data.csv \
  --outcome_col fustat \
  --predictor_col riskScore \
  --output_dir ./output/
```

### Cohort Design With Confidence Intervals

```bash
Rscript scripts/main.R \
  --data_file clinical_dca_data.csv \
  --study_design cohort \
  --show_confidence_intervals \
  --output_dir ./cohort_output/
```

### Custom Thresholding And Plot Styling

```bash
Rscript scripts/main.R \
  --data_file clinical_dca_data.csv \
  --threshold_by 0.02 \
  --decision_curve_color "#3C5488" \
  --impact_colors "#3C5488,#00A087" \
  --plot_title "Custom DCA" \
  --output_dir ./styled_output/
```

### Included Test Data

```bash
Rscript scripts/main.R \
  --data_file tests/data/dca_data.csv \
  --outcome_col fustat \
  --predictor_col riskScore \
  --output_dir tests/output/ \
  --overwrite
```

## Help

```bash
Rscript scripts/main.R --help
```
