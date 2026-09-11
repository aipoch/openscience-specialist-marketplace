---
name: decision-curve-analysis
description: "Use when evaluating the clinical utility of a binary prediction model from a single clinical CSV file by fitting a logistic decision-curve model, plotting decision and clinical-impact curves, and exporting summary outputs. NOT for: survival calibration, ROC-only discrimination analysis, nomogram construction, or time-to-event outcomes."
license: MIT
skill-author: AIPOCH
---

# Decision Curve Analysis

## When to Use

Use this skill when you need to:
- evaluate whether a binary prediction model adds clinical net benefit across threshold probabilities;
- visualize decision curves and clinical-impact curves from a clinical cohort;
- export an auditable DCA model object together with summary text and PDFs.

Typical user requests:
- "Run decision-curve analysis on this binary outcome and risk-score dataset."
- "Generate DCA and clinical-impact plots for this prediction model."
- "Compare net benefit across thresholds for this case-control cohort."

## When Not to Use

Do not use this skill for:
- time-to-event or survival outcomes;
- ROC-only discrimination analysis without decision-curve outputs;
- nomogram construction or calibration-curve analysis;
- multiclass outcomes or non-binary endpoints.

## When to Read External Files

| Situation | File to Read | Purpose |
|-----------|--------------|---------|
| Need algorithm details | `references/algorithm.md` | Statistical methods and formulas |
| Need to run analysis | `scripts/main.R` | Get the complete command |
| Encounter errors | `references/troubleshooting.md` | Find solutions |
| Need CLI examples | `references/cli-guide.md` | Parameter usage examples |

---

## Usage

```bash
Rscript scripts/main.R \
  --data_file ./clinical_dca_data.csv \
  --outcome_col fustat \
  --predictor_col riskScore \
  --output_dir ./output/
```

---

## Arguments

| Short | Long | Type | Default | Description |
|-------|------|------|---------|-------------|
| `-d` | `--data_file` | character | **required** | Clinical CSV file with row names as sample IDs |
|  | `--outcome_col` | character | `fustat` | Binary outcome column encoded as `0/1` |
|  | `--predictor_col` | character | `riskScore` | Numeric predictor column used in the logistic DCA model |
|  | `--study_design` | character | `case-control` | Study design: `case-control` or `cohort` |
|  | `--population_prevalence` | double | `0.3` | Population prevalence for case-control DCA (ignored for cohort design) |
|  | `--threshold_by` | double | `0.01` | Threshold step size; values below 0.005 significantly increase computation time |
|  | `--confidence_level` | double | `0.95` | Confidence level passed to `rmda::decision_curve()` |
|  | `--population_size` | integer | `1000` | Population size used in the clinical-impact plot |
|  | `--n_cost_benefits` | integer | `8` | Number of cost-benefit labels in the clinical-impact plot |
|  | `--show_confidence_intervals` | flag | `FALSE` | Show confidence intervals on the decision curve |
|  | `--standardize_net_benefit` | flag | `FALSE` | Report standardized net benefit (`sNB`) instead of raw net benefit (`NB`) |
|  | `--decision_curve_color` | character | `#E64B35` | Decision-curve line color |
|  | `--impact_colors` | character | `#E64B35,#4DBBD5` | Two comma-separated colors for the clinical-impact plot |
|  | `--plot_width` | double | `6` | PDF width in inches |
|  | `--plot_height` | double | `5.5` | PDF height in inches |
|  | `--font_family` | character | `sans` | PDF font family |
|  | `--plot_title` | character | `Decision Curve Analysis` | Decision-curve plot title |
|  | `--base_cex` | double | `0.9` | Base text-size multiplier |
| `-o` | `--output_dir` | character | `./output/` | Output directory |
|  | `--overwrite` | flag | `FALSE` | Allow writing into a non-empty output directory |
| `-s` | `--seed` | integer | `42` | Random seed for reproducibility |
| `-T` | `--timeout_seconds` | integer | `0` | Elapsed time limit in seconds; `0` disables timeout |

---

## Input Format

### Clinical Data (`--data_file`)

CSV file with row names as sample IDs. The dataset must contain at least one binary outcome column and one numeric predictor column.

```csv
,fustat,riskScore,FOXP3,CD45
Patient_1,1,0.630147268229631,5.7783584300481,3.5407433709834
Patient_2,0,0.23007730941193,6.70308857663772,3.11795942819676
Patient_3,1,0.534809528754818,5.46860669585825,3.40086667402884
```

**Requirements**
- File extension must be `.csv`.
- Row names must be non-missing, unique sample IDs.
- `outcome_col` and `predictor_col` must exist.
- Outcome values must use `0/1` encoding. Outcome values are coerced to numeric before validation; logical `TRUE`/`FALSE` are converted to `1`/`0`. Factor or character values will produce `SKILL_INVALID_PARAMETER`.
- Predictor values must be finite numeric values.
- At least 20 rows, 5 positive outcomes, and 5 negative outcomes are required.

**Design note:** When `--study_design cohort` is selected, `--population_prevalence` has no statistical effect; the raw observed event rate is used instead. A warning is emitted if you set a non-default `population_prevalence` with cohort design.

---

## Output Files

| File | Format | Description |
|------|--------|-------------|
| `data/dca_model.rds` | RDS | Saved `rmda::decision_curve()` result object |
| `table/dca_summary.txt` | Plain text | Text summary of decision-curve net benefit statistics |
| `plot/decision_curve.pdf` | PDF | Decision-curve plot |
| `plot/clinical_impact_curve.pdf` | PDF | Clinical-impact plot |
| `session_info.txt` | Plain text | Session information and run parameters |

### `dca_summary.txt`

Summary fields include:
- threshold-specific net benefit statistics from `summary(dca_model)`;
- the selected measure (`NB` or `sNB`);
- the fitted formula and study-design context recorded in `session_info.txt`.

---

## Workflow

### Step 1: Validate Input
- Confirm the clinical CSV exists and is readable.
- Check that the requested outcome and predictor columns are present.
- Validate sample IDs, binary outcome coding, and numeric predictor values.
- Emit warning if `population_prevalence` is non-default and `study_design` is `cohort`.

### Step 2: Prepare Analysis Dataset
- Keep only the outcome and predictor columns required for DCA.
- Coerce outcome and predictor values to numeric.
- Reject cohorts with too few rows or too few events/non-events.

### Step 3: Fit Decision-Curve Model
- Fit a logistic decision-curve model with `rmda::decision_curve()`.
- Build a threshold grid from `0` to `1` using `threshold_by`.
- Apply `population_prevalence` when `study_design` is `case-control`.

### Step 4: Save Outputs
- Save the fitted DCA object as `.rds`.
- Export the text summary as `.txt`.
- Render the decision curve and clinical-impact curve as PDFs.
- Record session metadata for reproducibility.

---

## Agent Response Contract

After a successful run, report:

1. **Study design and predictor** used (e.g., case-control, riskScore)
2. **Net benefit metric** reported (NB or sNB)
3. **Threshold range and step** used for the grid
4. **Key finding**: net benefit at clinically relevant threshold(s) from `dca_summary.txt`
5. **Artifact paths**: `plot/decision_curve.pdf`, `plot/clinical_impact_curve.pdf`, `data/dca_model.rds`

---

## Examples

### Basic Usage

```bash
Rscript scripts/main.R \
  --data_file clinical_dca_data.csv \
  --outcome_col fustat \
  --predictor_col riskScore \
  --output_dir ./output/
```

### Cohort Design With Custom Plotting

```bash
Rscript scripts/main.R \
  --data_file clinical_dca_data.csv \
  --study_design cohort \
  --outcome_col fustat \
  --predictor_col riskScore \
  --plot_title "Cohort DCA" \
  --decision_curve_color "#3C5488" \
  --impact_colors "#3C5488,#00A087" \
  --show_confidence_intervals \
  --output_dir ./cohort_output/
```

### With Bundled Test Data

```bash
Rscript scripts/main.R \
  --data_file tests/data/dca_data.csv \
  --outcome_col fustat \
  --predictor_col riskScore \
  --output_dir tests/output/ \
  --overwrite
```

---

## Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| `SKILL_INVALID_PARAMETER` | Invalid design, invalid numeric range, invalid outcome coding, insufficient rows/class counts, or failed model fitting | Check arguments, data ranges, and binary outcome coding |
| `SKILL_FILE_NOT_FOUND` | Input CSV does not exist | Verify the input path |
| `SKILL_MISSING_COLUMNS` | Required columns are absent | Check `outcome_col` and `predictor_col` names |
| `SKILL_EMPTY_DATA` | Input file is empty or contains no usable rows/columns | Check the CSV content |
| `SKILL_SAMPLE_MISMATCH` | Reserved for cross-file sample mismatch scenarios | Not expected for this single-file workflow |
| `SKILL_PACKAGE_NOT_FOUND` | Required R package is missing | Install with: `Rscript -e "install.packages('rmda', repos='https://cloud.r-project.org')"` |

**IF error persists**, READ: `references/troubleshooting.md`

---

## Input Validation

This skill accepts: a single clinical CSV file with a binary outcome column (0/1 encoded) and a numeric predictor column, for decision curve analysis of a binary prediction model.

If the user's request does not involve decision curve analysis of a binary prediction model — for example, asking to run survival analysis, build ROC curves only, construct a nomogram, or analyze multiclass outcomes — do not proceed with the workflow. Instead respond:

> "Decision Curve Analysis is designed to evaluate the clinical utility of binary prediction models by computing net benefit across decision thresholds. Your request appears to be outside this scope. Please provide a binary outcome dataset for DCA, or use a more appropriate tool for survival analysis, ROC analysis, or nomogram construction."

---

## Testing

### Smoke Test With Included Data

```bash
Rscript scripts/main.R --help

Rscript scripts/main.R \
  --data_file tests/data/dca_data.csv \
  --outcome_col fustat \
  --predictor_col riskScore \
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
|-- data/dca_model.rds
|-- plot/clinical_impact_curve.pdf
|-- plot/decision_curve.pdf
|-- session_info.txt
`-- table/dca_summary.txt
```

---

## References

1. Vickers AJ, Elkin EB. Decision curve analysis: a novel method for evaluating prediction models.
2. rmda package documentation for clinical decision-curve analysis.

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

*Last updated: 2026-04-27 | Version: 1.1.0*
