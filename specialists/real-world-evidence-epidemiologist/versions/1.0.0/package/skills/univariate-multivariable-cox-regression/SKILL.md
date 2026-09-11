---
name: univariate-multivariable-cox-regression
description: "Use when running prognostic survival analysis on a clinical cohort with time-to-event data to estimate univariate and multivariable Cox proportional hazards models, export result tables, and generate forest plots. NOT for: nomogram construction, calibration curves, time-dependent ROC analysis, or model training/feature selection beyond the built-in univariate screening rule."
---

# Univariate and Multivariable Cox Regression

## When to Use

Use this skill when you need to:
- run univariate and multivariable Cox regression on a clinical survival cohort;
- identify prognostic clinical variables associated with time-to-event outcomes;
- export hazard-ratio tables and then render forest plots from those results.

Typical user requests:
- "Run single-factor and multi-factor Cox regression on this survival dataset."
- "Find prognostic variables from my clinical cohort and give me forest plots."
- "Use futime and fustat to do Cox regression for age, stage, and risk."

## When Not to Use

Do not use this skill for:
- nomogram construction or calibration analysis;
- time-dependent ROC analysis or external prognostic model validation;
- feature discovery pipelines beyond the built-in univariate screening rule;
- non-survival outcomes such as binary diagnosis or differential expression.

## When to Read External Files

| Situation | File to Read | Purpose |
|-----------|--------------|---------|
| **Need algorithm details** | `references/algorithm.md` | Statistical workflow, assumptions, and feature-selection rule |
| **Need to run analysis** | `scripts/main.R` | Execute `Rscript scripts/main.R <command> [options]` |
| **Encounter errors** | `references/troubleshooting.md` | Common `SKILL_*` errors and fixes |
| **Need CLI examples** | `references/cli-guide.md` | Command-specific argument examples |
| **Need test data** | `tests/data/` | Minimal runnable cohort for smoke testing |

---

## Usage

### 1. Run Cox Analysis

```bash
Rscript scripts/main.R analyze \
  --data_file ./clinical_data.csv \
  --features age,gender,stage,risk \
  --time_col futime \
  --event_col fustat \
  --output_dir ./output/ \
  --seed 42
```

### 2. Generate Univariate Forest Plot

```bash
Rscript scripts/main.R forest-plot \
  --data_file ./output/table/prognosis_uni_cox_results.xlsx \
  --plot_save ./output/plot/uni_forest_plot.pdf
```

### 3. Generate Multivariable Forest Plot

```bash
Rscript scripts/main.R multi-forest-plot \
  --data_file ./output/table/prognosis_multi_cox_results.xlsx \
  --plot_save ./output/plot/multi_forest_plot.pdf
```

---

## Arguments

### Analyze Command

| Short | Long | Type | Default | Description |
|-------|------|------|---------|-------------|
| `-d` | `--data_file` | character | **required** | Clinical CSV file with sample IDs as row names |
| `-f` | `--features` | character | `age,gender,stage,Tstage,Nstage,Mstage,risk` | Comma-separated features for Cox analysis |
| `-t` | `--time_col` | character | `futime` | Survival time column |
| `-e` | `--event_col` | character | `fustat` | Event column encoded as `1=event`, `0=censored` |
| `-u` | `--skip_univariate` | character | `false` | Skip univariate screening and fit multivariable model on all requested features |
| `-o` | `--output_dir` | character | `./output/` | Output directory |
|  | `--overwrite` | flag | `FALSE` | Allow writing into a non-empty output directory |
| `-s` | `--seed` | integer | `42` | Random seed for reproducibility |
| `-T` | `--timeout_seconds` | integer | `0` | Elapsed time limit in seconds; `0` disables timeout |

### Forest Plot Commands

These arguments apply to both `forest-plot` and `multi-forest-plot`.

| Short | Long | Type | Default | Description |
|-------|------|------|---------|-------------|
| `-d` | `--data_file` | character | **required** | Cox result table in `.xlsx`, `.xls`, or `.csv` format |
| `-p` | `--plot_save` | character | **required** | Output PDF path |
| `-w` | `--width` | double | `8` | Plot width in inches |
| `-H` | `--height` | double | `6` | Plot height in inches |
| `-F` | `--font_size` | double | `11` | Font size for forest-plot labels |
| `-s` | `--seed` | integer | `42` | Random seed for reproducibility |
| `-T` | `--timeout_seconds` | integer | `0` | Elapsed time limit in seconds; `0` disables timeout |

---

## Input Format

### Clinical Data (`--data_file` for `analyze`)

CSV file with sample IDs as row names and one column per feature/end-point variable.

```csv
",age,gender,stage,futime,fustat,risk
SAMPLE_001,65,Male,StageIII,365,1,high
SAMPLE_002,52,Female,StageII,730,0,low
SAMPLE_003,78,Male,StageIV,180,1,high
```

**Requirements**
- The file must be CSV.
- Sample IDs must be stored in the first column as row names.
- `time_col` must contain finite numeric values greater than `0`.
- `event_col` must contain only `0` and `1`.
- All requested `features`, `time_col`, and `event_col` must exist.
- At least 10 complete samples and at least 2 events are required after filtering incomplete rows.

### Cox Result Table (`--data_file` for plot commands)

The plotting commands read the output table created by `analyze`.

Required columns:
- `Characteristics`
- `Total(N)`
- `HR (95% CI)`
- `P value`

---

## Output Files

### Analyze Command

| File | Description |
|------|-------------|
| `table/prognosis_uni_cox_results.xlsx` | Univariate Cox result table. Present unless `--skip_univariate true` |
| `table/prognosis_multi_cox_results.xlsx` | Multivariable Cox result table |
| `data/analysis_data.rds` | Serialized complete-case dataset used for Cox fitting |
| `session_info.txt` | Session info and recorded run parameters |

### Plot Commands

| File | Description |
|------|-------------|
| `plot/uni_forest_plot.pdf` | PDF forest plot generated by `forest-plot` |
| `plot/multi_forest_plot.pdf` | PDF forest plot generated by `multi-forest-plot` |
| `plot/session_info.txt` | Session info and plotting parameters written beside the PDF |

### Result Table Columns

| Column | Description |
|--------|-------------|
| `Characteristics` | Variable name for continuous terms, or level label for categorical terms |
| `Total(N)` | Number of complete-case samples used for modeling |
| `HR (95% CI)` | Hazard ratio with 95% confidence interval |
| `P value` | Wald-test p-value formatted to three decimals or `<0.001` |
| `feature` | Source feature corresponding to each row |

---

## Workflow

### Step 1: Validate and Prepare Data
- Read the clinical CSV.
- Check required columns and data types.
- Convert character predictors to factors.
- Remove rows with missing values across requested model variables.

### Step 2: Run Univariate Cox Models
- Fit one Cox model per feature when `--skip_univariate false`.
- Export hazard ratios, confidence intervals, and p-values.

### Step 3: Run Multivariable Cox Model
- Use all significant univariate features with `p < 0.05`.
- If fewer than 3 significant features are found, fall back to all requested features.
- Export adjusted hazard ratios, confidence intervals, and p-values.

### Step 4: Generate Forest Plots
- Read the result table.
- Parse `HR (95% CI)` values.
- Render a one-page PDF forest plot.

---

## Examples

### Basic Analysis

```bash
Rscript scripts/main.R analyze \
  -d tests/data/sample_clinical_survival_data.csv \
  -o tests/expected_output/ \
  --overwrite
```

### Analysis With Selected Features and Overwrite

```bash
Rscript scripts/main.R analyze \
  -d clinical_data.csv \
  -f age,gender,stage,risk \
  -o ./results/ \
  --overwrite \
  -T 600
```

### Direct Multivariable Fit Without Univariate Screening

```bash
Rscript scripts/main.R analyze \
  -d clinical_data.csv \
  -f age,stage,risk \
  -u true \
  -o ./results/
```

### Plot Generation

```bash
Rscript scripts/main.R forest-plot \
  -d ./results/table/prognosis_uni_cox_results.xlsx \
  -p ./results/plot/uni_forest_plot.pdf \
  -w 10 -H 7 -F 12

Rscript scripts/main.R multi-forest-plot \
  -d ./results/table/prognosis_multi_cox_results.xlsx \
  -p ./results/plot/multi_forest_plot.pdf \
  -w 10 -H 7 -F 12
```

---

## Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| `SKILL_INVALID_PARAMETER` | Missing required CLI value, invalid extension, unknown command, unreadable CSV input, invalid clinical values, too few complete samples/events, or Cox model fitting failure caused by unsupported input data | Check argument names, file types, clinical value constraints, and model input suitability |
| `SKILL_FILE_NOT_FOUND` | Input file path does not exist | Verify the input path |
| `SKILL_MISSING_COLUMNS` | Required columns are absent from the clinical file or plot table | Check column names and spelling |
| `SKILL_EMPTY_DATA` | Input file or plot table contains no usable rows | Verify file content and export process |
| `SKILL_PACKAGE_NOT_FOUND` | Required R package is missing | Install the listed CRAN package(s) |

**IF error persists**, READ: `references/troubleshooting.md`

---

## Testing

### Smoke Test With Included Data

```bash
Rscript scripts/main.R --help

Rscript scripts/main.R analyze \
  -d tests/data/sample_clinical_survival_data.csv \
  -o tests/expected_output/ \
  --overwrite

Rscript scripts/main.R forest-plot \
  -d tests/expected_output/table/prognosis_uni_cox_results.xlsx \
  -p tests/expected_output/plot/uni_forest_plot.pdf

Rscript scripts/main.R multi-forest-plot \
  -d tests/expected_output/table/prognosis_multi_cox_results.xlsx \
  -p tests/expected_output/plot/multi_forest_plot.pdf
```

### Automated Smoke Test Script

```bash
Rscript tests/run_smoke_test.R
```

Optional shell wrapper:

```bash
bash tests/run_smoke_test.sh
```

### Expected Outputs

```text
tests/expected_output/
|-- data/analysis_data.rds
|-- plot/multi_forest_plot.pdf
|-- plot/session_info.txt
|-- plot/uni_forest_plot.pdf
|-- session_info.txt
|-- table/prognosis_multi_cox_results.xlsx
`-- table/prognosis_uni_cox_results.xlsx
```

---

## References

1. Cox DR (1972). Regression Models and Life-Tables. *Journal of the Royal Statistical Society: Series B*.
2. Therneau TM, Grambsch PM (2000). *Modeling Survival Data: Extending the Cox Model*.
3. Harrell FE (2015). *Regression Modeling Strategies*.

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

*Last updated: 2026-04-16 | Version: 1.1.0*
