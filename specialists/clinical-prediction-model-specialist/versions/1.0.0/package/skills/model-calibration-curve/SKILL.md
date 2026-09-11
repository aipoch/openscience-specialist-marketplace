---
name: model-calibration-curve
description: "Use when assessing how well a survival model's predicted probabilities agree with observed outcomes by fitting a Cox model and generating bootstrap calibration curves at one or more prediction horizons from a clinical CSV file. NOT for: nomogram construction, univariate Cox screening, ROC analysis, or decision-curve analysis."
license: MIT
skill-author: AIPOCH
---

# Model Calibration Curve

## When to Use

Use this skill when you need to:
- validate a survival model with bootstrap calibration curves;
- compare predicted and observed survival probabilities at multiple horizons;
- export calibration statistics together with a PDF visualization.

Typical user requests:
- "Generate 1-, 2-, and 3-year calibration curves for this prognosis model."
- "Check whether the Cox model built from age, gender, and risk is well calibrated."
- "Export calibration statistics and a calibration PDF from this clinical cohort."

## When Not to Use

Do not use this skill for:
- nomogram construction;
- univariate or multivariable Cox feature screening;
- ROC, calibration-free discrimination, or decision-curve analysis;
- non-survival endpoints or multiclass classification tasks.

## When to Read External Files

| Situation | File to Read | Purpose |
|-----------|--------------|---------|
| Need algorithm details | `references/algorithm.md` | Statistical method and formulas |
| Need to run analysis | `scripts/main.R` | Get the complete command |
| Encounter errors | `references/troubleshooting.md` | Find solutions |
| Need CLI examples | `references/cli-guide.md` | Parameter usage examples |

## Input Validation

This skill accepts:

- A clinical CSV file with sample IDs as row names, survival time, event indicator, and pre-selected prognostic features
- Requests to assess calibration of a survival (Cox) model via bootstrap resampling at one or more prediction horizons

If the user's request does not involve survival model calibration from a clinical CSV file — for example, asking to construct a nomogram, screen Cox features, generate an ROC curve, analyze a decision curve, or work with non-survival outcomes — do not proceed with this workflow. Instead respond:

> "model-calibration-curve is designed to validate survival model calibration by generating bootstrap calibration curves from a clinical CSV file. Your request appears to be outside this scope. Please use a nomogram-construction skill for nomogram building, a roc-diagnostic-performance skill for ROC analysis, or a decision-curve-analysis skill for DCA."

---

## Prerequisites

R packages required: `rms`, `qs`, `openxlsx`, `optparse`.

Install with:
```r
install.packages(c("rms", "qs", "openxlsx", "optparse"), repos = "https://cloud.r-project.org")
```

Or run the bootstrap installer:
```bash
Rscript scripts/install_dependencies.R
```

> Note: `--help` requires `optparse` to be loaded. If the package check fires before option parsing, install `optparse` first, then run `--help`. The root fix (deferring heavy package checks until after argument parsing) must be applied in `scripts/main.R`.

---

## Usage

```bash
Rscript scripts/main.R \
  --data_file ./clinical_data.csv \
  --features age,stage,risk \
  --years 1,2,3 \
  --output_dir ./output/
```

---

## Arguments

| Short | Long | Type | Default | Description |
|-------|------|------|---------|-------------|
| `-d` | `--data_file` | character | **required** | Clinical CSV file with sample IDs as row names |
| `-f` | `--features` | character | **required** | Comma-separated model features used in the Cox model |
| `-t` | `--time_col` | character | `futime` | Survival time column |
| `-e` | `--event_col` | character | `fustat` | Event indicator column using 0/1 encoding |
| `-y` | `--years` | character | `1,2,3` | Prediction horizons in the same units as `time_col` |
| `-b` | `--bootstrap_reps` | integer | `1000` | Bootstrap replications for `rms::calibrate()` |
| `-o` | `--output_dir` | character | `./output/` | Output directory |
|  | `--overwrite` | flag | `FALSE` | Allow writing into a non-empty output directory |
| `-s` | `--seed` | integer | `42` | Random seed for reproducibility |
| `-T` | `--timeout_seconds` | integer | `0` | Elapsed time limit in seconds; `0` disables timeout |
|  | `--plot_width` | double | `6` | PDF width in inches |
|  | `--plot_height` | double | `6` | PDF height in inches |
|  | `--font_family` | character | `sans` | PDF font family |
|  | `--line_width` | double | `1.5` | Calibration curve line width |
|  | `--colors` | character | `#0073C2,#EFC000,#868686,#CD534C,#7AA6DD` | Comma-separated colors for time-point curves |
|  | `--plot_title` | character | `Calibration Curve` | Plot title |
|  | `--base_cex` | double | `0.9` | Base text-size multiplier |

---

## Input Format

### Clinical Data (`--data_file`)

CSV file with row names as sample IDs and columns for model features, survival time, and event indicator.

```csv
"",age,gender,stage,futime,fustat,risk
"SAMPLE_001",">65","Female","StageI&II",1.12,0,"high"
"SAMPLE_002","<=65","Male","StageIII&IV",1.92,1,"high"
"SAMPLE_003",">65","Male","StageI&II",4.47,1,"low"
```

**Requirements**
- File extension must be `.csv`.
- Row names must be unique sample IDs.
- All requested features plus `time_col` and `event_col` must exist.
- Survival time values must be finite numbers greater than `0`.
- Event values must use `0/1` encoding.
- Complete-case filtering must leave at least 30 samples and at least 10 events.

### Feature Selection (`--features`)

- Comma-separated without line breaks: `age,gender,risk`
- Character predictors are converted to factors before Cox fitting.
- If every requested feature is absent after validation, the run stops.

---

## Output Files

| File | Format | Description |
|------|--------|-------------|
| `data/calibration_data.qs` | QS serialized object | Serialized calibration result bundle, including calibration objects and summary metadata |
| `table/calibration_statistics.xlsx` | Excel workbook (`.xlsx`) | Per-time-point means and overall model summary |
| `plot/calibration_curve.pdf` | PDF (`.pdf`) | Combined calibration curve visualization |
| `session_info.txt` | Plain text (`.txt`) | Session information and run parameters |

### `calibration_statistics.xlsx`

Workbook sheets:
- `Time_Point_Stats`: predicted mean, observed mean, and bias-corrected mean for each calibration horizon.
- `Model_Summary`: overall C-index, sample count, event count, selected features, and fitted formula.

---

## Workflow

### Step 1: Validate Input
- Confirm the clinical CSV exists and is readable.
- Check that requested features, survival time, and event columns are present.
- Remove incomplete rows across all required columns.

### Step 2: Prepare Survival Modeling Data
- Convert survival time and event columns to numeric.
- Convert character predictors to factors.
- Reject data with non-positive follow-up times, invalid event coding, too few samples, or too few events.

### Step 3: Build Calibration Models
- Fit a Cox proportional hazards model with the requested features.
- Run `rms::calibrate()` for each prediction horizon using bootstrap resampling.
- Compute the concordance index for the fitted model.

### Step 4: Save Outputs
- Serialize the calibration result bundle as `.qs`.
- Export statistics to Excel.
- Render a combined calibration PDF.
- Record session metadata for reproducibility.

---

## Examples

### Basic Calibration Analysis

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

### With Bundled Test Data

```bash
Rscript scripts/main.R \
  --data_file tests/data/sample_clinical_survival_data.csv \
  --features age,gender,risk \
  --bootstrap_reps 20 \
  --output_dir tests/output/ \
  --overwrite
```

---

## Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| `SKILL_INVALID_PARAMETER` | Missing required argument, invalid numeric values, invalid event coding, insufficient complete cases, insufficient events, or failed model fitting | Check argument values, data validity, and event/sample counts |
| `SKILL_FILE_NOT_FOUND` | Input CSV does not exist | Verify the path |
| `SKILL_MISSING_COLUMNS` | Required feature/time/event columns are absent | Check column names and spelling |
| `SKILL_EMPTY_DATA` | Input file is empty, complete-case filtering removed all rows, or no requested features remained | Check file content and requested feature names |
| `SKILL_SAMPLE_MISMATCH` | Reserved for cross-file sample mismatch scenarios | Not expected for this single-file workflow |
| `SKILL_PACKAGE_NOT_FOUND` | Required R package is missing | Install with: `Rscript -e "install.packages(c('rms', 'qs', 'openxlsx'), repos='https://cloud.r-project.org')"` |

**IF error persists**, READ: `references/troubleshooting.md`

---

## Testing

### Smoke Test With Included Data

```bash
Rscript scripts/main.R --help

Rscript scripts/main.R \
  --data_file tests/data/sample_clinical_survival_data.csv \
  --features age,gender,risk \
  --bootstrap_reps 20 \
  --output_dir tests/output/ \
  --overwrite
```

### Automated Smoke Test Script

```bash
Rscript tests/run_smoke_test.R
```

Optional shell wrapper:

```bash
bash tests/run_smoke_test.sh
```

### Expected Output

```text
tests/output/
|-- data/calibration_data.qs
|-- plot/calibration_curve.pdf
|-- session_info.txt
`-- table/calibration_statistics.xlsx
```

---

## References

1. Harrell FE. *Regression Modeling Strategies*.
2. Steyerberg EW et al. Assessing the performance of prediction models.
3. Austin PC, Steyerberg EW. Graphical assessment of calibration for survival models.

**For detailed algorithm**, READ: `references/algorithm.md`

---

## Implementation Checklist

- [x] CLI parsing with `optparse`
- [x] `set.seed()` for reproducibility
- [x] Top-level CRAN dependency checks
- [x] Session info recording
- [x] Timeout parameter exposed as CLI option
- [x] Relative-path `source()` usage via `get_script_dir()`
- [x] Modular script structure in `scripts/`
- [x] Test data provided in `tests/data/`
- [x] Error handling with `SKILL_*` codes
- [x] Reference docs provided in `references/`

---

*Last updated: 2026-04-27 | Version: 2.1.0*
