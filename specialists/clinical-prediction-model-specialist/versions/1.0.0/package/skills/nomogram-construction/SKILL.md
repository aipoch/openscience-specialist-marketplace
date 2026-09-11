---
name: nomogram-construction
description: "Use when constructing a prognosis nomogram from survival-related clinical predictors, exporting the nomogram bundle and C-index table, and optionally rendering the final nomogram PDF. NOT for: univariate/multivariable Cox feature screening, calibration curves, ROC analysis, decision-curve analysis, or non-survival outcomes."
license: MIT
skill-author: AIPOCH
---

# Nomogram Construction

## When to Use

Use this skill when you need to:
- build a prognosis nomogram from already selected clinical prognostic variables;
- estimate model discrimination with a C-index table;
- export a nomogram bundle and generate a publication-ready nomogram PDF.

Typical user requests:
- "Build a prognosis nomogram from age, stage, and risk score."
- "Use these Cox-selected predictors to construct a nomogram and calculate the C-index."
- "Generate a nomogram PDF from a survival prediction model."

## When Not to Use

Do not use this skill for:
- screening prognostic variables from scratch with Cox regression;
- ROC curves, calibration curves, or decision-curve analysis;
- diagnosis models, binary classification, or non-survival outcomes;
- single-cell, differential-expression, or pathway analysis.

## When to Read External Files

| Situation | File to Read | Purpose |
|-----------|--------------|---------|
| **Need algorithm details** | `references/algorithm.md` | Cox-based nomogram workflow, C-index, and assumptions |
| **Need to run analysis** | `scripts/main.R` | Execute `Rscript scripts/main.R --mode build ...` or `--mode plot ...` |
| **Encounter errors** | `references/troubleshooting.md` | Common `SKILL_*` errors and solutions |
| **Need CLI examples** | `references/cli-guide.md` | Detailed command-line examples |
| **Need test data** | `tests/data/` | Example clinical CSV for smoke testing |

## Input Validation

This skill accepts:

- A clinical CSV file with survival time, event indicator, and pre-selected prognostic features
- Requests to build a Cox-based prognostic nomogram and compute the C-index
- Requests to re-render a nomogram PDF from an existing `.qs` bundle (plot mode)

If the user's request does not involve nomogram construction from survival data — for example, asking to screen features with Cox regression, generate calibration curves, perform ROC analysis, or analyze non-survival binary outcomes — do not proceed with this workflow. Instead respond:

> "nomogram-construction is designed to build a prognosis nomogram from pre-selected survival predictors and export the nomogram bundle with C-index table. Your request appears to be outside this scope. Please use a Cox feature-screening skill for variable selection, or a calibration-curve/ROC skill for model validation."

---

## Prerequisites

R packages required: `rms`, `openxlsx`, `qs`, `optparse`.

Install with:
```r
install.packages(c("rms", "openxlsx", "qs", "optparse"), repos = "https://cloud.r-project.org")
```

Or run the bootstrap installer:
```bash
Rscript scripts/install_dependencies.R
```

> Note: `--help` requires `optparse` to be loaded. If the package check fires before option parsing, install `optparse` first, then run `--help`.

---

## Usage

### Build Nomogram Bundle

```bash
Rscript scripts/main.R \
  --mode build \
  --data_file ./clinical_data.csv \
  --features age,stage,risk \
  --time_col futime \
  --event_col fustat \
  --years 1,2,3 \
  --output_dir ./output/ \
  --seed 42
```

### Render Nomogram Plot

```bash
Rscript scripts/main.R \
  --mode plot \
  --nomo_data_file ./output/data/Nomogram_list.qs \
  --plot_save ./output/plot/nomogram_plot.pdf
```

---

## Arguments

| Short | Long | Type | Default | Description |
|-------|------|------|---------|-------------|
| `-m` | `--mode` | character | `build` | Execution mode: `build` or `plot` |
| `-d` | `--data_file` | character | **required for build** | Clinical CSV file with sample IDs as row names |
| `-f` | `--features` | character | **required for build** | Comma-separated prognostic features |
| `-t` | `--time_col` | character | `futime` | Survival time column |
| `-e` | `--event_col` | character | `fustat` | Event column encoded as `1=event`, `0=censored` |
| `-y` | `--years` | character | `1,2,3` | Prediction time points in years |
| `-o` | `--output_dir` | character | `./output/` | Output directory for build mode |
|  | `--overwrite` | flag | `FALSE` | Allow writing into a non-empty output directory |
| `-n` | `--nomo_data_file` | character | **required for plot** | Nomogram bundle in `.qs` format |
| `-p` | `--plot_save` | character | **required for plot** | Output PDF path |
| `-w` | `--plot_width` | double | `11` | Plot width in inches |
| `-H` | `--plot_height` | double | `8` | Plot height in inches |
| `-F` | `--font_size` | double | `8` | Plot font size |
| `-l` | `--line_width` | double | `5` | Plot line width |
|  | `--font_family` | character | `sans` | Font family for PDF output |
| `-s` | `--seed` | integer | `42` | Random seed for reproducibility |
| `-T` | `--timeout_seconds` | integer | `0` | Elapsed time limit in seconds; `0` disables timeout |

---

## Input Format

### Clinical Data (`data_file`)

CSV file with sample IDs as row names and one column per feature/end-point variable.

```csv
",age,stage,risk,futime,fustat
SAMPLE_001,65,StageIII,high,365,1
SAMPLE_002,52,StageII,low,730,0
SAMPLE_003,78,StageIV,high,180,1
```

**Requirements**
- File format must be CSV.
- Sample IDs must be stored in the first column as row names.
- At least 3 prognostic features are required.
- `time_col` must contain finite numeric values greater than `0`.
- `event_col` must contain only `0` and `1`.
- At least 20 complete samples and at least 10 events are required after filtering incomplete rows.

### Nomogram Bundle (`nomo_data_file`)

The plot mode reads the `.qs` bundle produced by build mode.

Required bundle objects:
- `nomogram`
- `c_index`
- `model`
- `data`
- `features`
- `time_points`

---

## Output Files

### Build Mode

| File | Description |
|------|-------------|
| `data/Nomogram_list.qs` | Serialized nomogram bundle |
| `data/analysis_data.rds` | Complete-case dataset used for modeling |
| `table/nomogram_c_index.xlsx` | Nomogram discrimination summary |
| `session_info.txt` | Session information and build parameters |

### Plot Mode

| File | Description |
|------|-------------|
| `plot/nomogram_plot.pdf` | Rendered nomogram PDF |
| `plot/session_info.txt` | Plotting session information and parameters |

### `nomogram_c_index.xlsx`

| Column | Description |
|--------|-------------|
| `metric` | Reported metric name |
| `value` | Metric value |

---

## Workflow

### Step 1: Validate Input
- Check file existence and CSV format.
- Validate required feature, time, and event columns.
- Validate time/event values and minimum sample/event counts.

### Step 2: Prepare Modeling Dataset
- Keep only requested features and outcome columns.
- Convert character predictors to factors.
- Remove incomplete rows across model variables.

### Step 3: Fit Cox-Based Nomogram Model
- Fit an `rms::cph` survival model.
- Build survival functions at requested time points.
- Construct the nomogram object.

### Step 4: Evaluate Performance
- Compute the model C-index.
- Save a compact discrimination summary table.

### Step 5: Save And Plot
- Save the nomogram bundle and analysis dataset.
- Render the nomogram PDF in plot mode.

---

## Examples

### Basic Build

```bash
Rscript scripts/main.R \
  --mode build \
  -d clinical_data.csv \
  -f age,stage,risk \
  -o ./output/
```

### Custom Prediction Horizons

```bash
Rscript scripts/main.R \
  --mode build \
  -d clinical_data.csv \
  -f age,stage,risk,treatment \
  -y 1,3,5 \
  -o ./output/
```

### Plot Existing Bundle

```bash
Rscript scripts/main.R \
  --mode plot \
  -n ./output/data/Nomogram_list.qs \
  -p ./output/plot/nomogram_plot.pdf \
  -w 12 -H 9 -F 10
```

---

## Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| `SKILL_FILE_NOT_FOUND` | Input file does not exist | Verify the file path |
| `SKILL_EMPTY_DATA` | Input file is empty or has no usable rows and columns | Re-export the input file with valid rows and columns |
| `SKILL_MISSING_COLUMNS` | Required columns are absent from the clinical data | Check column names and spelling |
| `SKILL_INVALID_DATA` | Invalid time/event encoding, malformed bundle, or unreadable CSV/QS file | Check input values and file integrity |
| `SKILL_INSUFFICIENT_DATA` | Too few features, complete samples, or events | Provide more valid predictors or samples |
| `SKILL_ANALYSIS_ERROR` | `cph()` fitting, nomogram construction, or output writing failed | Check data quality, factor levels, and event distribution |
| `SKILL_INVALID_PARAMETER` | Missing required CLI value, invalid mode, invalid years, or overwrite conflict | Review command-line arguments |
| `SKILL_PACKAGE_NOT_FOUND` | Required R package is not installed | Install with: `Rscript -e "install.packages(c('rms', 'openxlsx', 'qs'), repos='https://cloud.r-project.org')"` |
| `SKILL_TIMEOUT` | The configured timeout was exceeded | Increase `--timeout_seconds` or reduce workload |

**IF error persists**, READ: `references/troubleshooting.md`

---

## Testing

### Smoke Test With Included Data

```bash
Rscript scripts/main.R --help

Rscript scripts/main.R \
  --mode build \
  -d tests/data/yuhou_cli_data.csv \
  -f age,gender,risk \
  -o tests/expected_output/ \
  --overwrite

Rscript scripts/main.R \
  --mode plot \
  -n tests/expected_output/data/Nomogram_list.qs \
  -p tests/expected_output/plot/nomogram_plot.pdf
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
tests/expected_output/
|-- data/analysis_data.rds
|-- data/Nomogram_list.qs
|-- plot/nomogram_plot.pdf
|-- plot/session_info.txt
|-- session_info.txt
`-- table/nomogram_c_index.xlsx
```

Historical development artifacts may still exist in `tests/output/`, but standardized validation uses `tests/expected_output/`.

---

## References

1. Harrell FE (2015). *Regression Modeling Strategies*.
2. Iasonos A et al. (2008). How to build and interpret a nomogram for cancer prognosis. *Journal of Clinical Oncology*.
3. Balachandran VP et al. (2015). Nomograms in oncology: more than meets the eye. *The Lancet Oncology*.

**For detailed algorithm**, READ: `references/algorithm.md`

---

## Implementation Checklist

- [x] CLI parsing with `optparse`
- [x] `set.seed()` for reproducibility
- [x] `requireNamespace()` dependency checks
- [x] Session info recording
- [x] Timeout parameter exposed as CLI option
- [x] File reading instructions in `SKILL.md`
- [x] Modular script structure in `scripts/`
- [x] Test data provided in `tests/data/`
- [x] Error handling with `SKILL_*` codes
- [x] References documented in `references/`

---

*Last updated: 2026-04-27 | Version: 2.1.0*
