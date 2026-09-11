---
name: roc-diagnostic-performance
description: "Use when evaluating diagnostic biomarker performance from case-control expression data with logistic regression and ROC curves, exporting coefficient and AUC tables together with a ROC PDF. NOT for: survival analysis, time-to-event outcomes, multiclass classification, calibration curves, decision-curve analysis, or nomogram construction."
---

# ROC Diagnostic Performance

## When to Use

Use this skill when you need to:
- evaluate one or more diagnostic marker genes in a case-control cohort;
- build a multivariable logistic regression diagnostic model from marker expression values;
- compare the ROC performance of the full model against individual markers.

Typical user requests:
- "Use these genes to build a diagnostic ROC model for case vs control samples."
- "Evaluate the AUC of FOXP3, CD45, and CD3E and plot all ROC curves together."
- "Run logistic regression on biomarker expression and export ROC results."

## When Not to Use

Do not use this skill for:
- survival or prognostic analysis with time-to-event outcomes;
- multiclass classification tasks;
- calibration plots, nomograms, or decision-curve analysis;
- non-expression diagnostic inputs such as imaging, clinical scores, or mutation-only tables.

## When to Read External Files

| Situation | File to Read | Purpose |
|-----------|--------------|---------|
| **Need algorithm details** | `references/algorithm.md` | Logistic regression, ROC, AUC, and modeling assumptions |
| **Need to run analysis** | `scripts/main.R` | Execute `Rscript scripts/main.R --expression_file ... --group_file ...` |
| **Encounter errors** | `references/troubleshooting.md` | Common `SKILL_*` errors and solutions |
| **Need CLI examples** | `references/cli-guide.md` | Detailed command-line examples |
| **Need test data** | `tests/data/` | Example expression matrix and group file |

---

## Usage

```bash
Rscript scripts/main.R \
  --expression_file ./expression_matrix.csv \
  --group_file ./group_info.csv \
  --marker_genes FOXP3,CD45,CD3E \
  --case_group Disease \
  --output_dir ./output/ \
  --seed 42
```

---

## Arguments

| Short | Long | Type | Default | Description |
|-------|------|------|---------|-------------|
| `-e` | `--expression_file` | character | **required** | Expression matrix file in CSV/TSV format |
| `-g` | `--group_file` | character | **required** | Group file with sample IDs and labels |
| `-m` | `--marker_genes` | character | **required** | Comma-separated marker genes |
| `-c` | `--case_group` | character | **required** | Case group label in the group file |
|  | `--group_col` | character | `NULL` | Optional group column name; auto-detected if omitted |
| `-o` | `--output_dir` | character | `./output/` | Output directory |
|  | `--overwrite` | flag | `FALSE` | Allow writing into a non-empty output directory |
| `-s` | `--seed` | integer | `42` | Random seed for reproducibility |
| `-T` | `--timeout_seconds` | integer | `0` | Elapsed time limit in seconds; `0` disables timeout |
|  | `--plot_width` | double | `6` | ROC plot width in inches |
|  | `--plot_height` | double | `6` | ROC plot height in inches |
|  | `--font_family` | character | `sans` | PDF font family |
|  | `--line_colors` | character | `#E64B35,#4DBBD5,#00A087,#3C5488,#F39B7F` | Comma-separated ROC line colors |
|  | `--line_width` | double | `1.2` | ROC curve line width |
|  | `--show_diagonal` | character | `true` | Show diagonal reference line: `true` or `false` |
|  | `--diagonal_color` | character | `#7F7F7F` | Diagonal line color |
|  | `--diagonal_lty` | integer | `2` | Diagonal line type |
|  | `--plot_title` | character | `ROC Diagnostic Performance` | ROC plot title |
|  | `--x_label` | character | `1 - Specificity` | X-axis label |
|  | `--y_label` | character | `Sensitivity` | Y-axis label |
|  | `--base_cex` | double | `0.9` | Base text-size multiplier |
|  | `--legend_position` | character | `bottomright` | Legend position |
|  | `--legend_cex` | double | `0.8` | Legend text size |

---

## Input Format

### Expression Matrix (`expression_file`)

CSV or TSV file with genes as rows and samples as columns. The first column must store unique gene identifiers.

```csv
gene,Sample1,Sample2,Sample3
FOXP3,8.4,7.1,3.8
CD45,2.1,1.9,5.4
CD3E,5.8,6.2,4.0
```

**Requirements**
- File extension must be `.csv`, `.tsv`, or `.txt`.
- The first column must contain non-missing, unique gene identifiers.
- Remaining columns must be sample IDs.
- Selected marker genes must have numeric finite expression values across matched samples.

### Group File (`group_file`)

CSV or TSV file with sample IDs in the first column and at least one group-label column.

```csv
sample,group
Sample1,Disease
Sample2,Disease
Sample3,Control
```

**Requirements**
- File extension must be `.csv`, `.tsv`, or `.txt`.
- The first column must contain non-missing, unique sample IDs.
- At least one group column must be present.
- The `case_group` value must appear in the selected group column.
- At least 10 matched samples, 2 case samples, and 2 control samples are required.

---

## Output Files

| File | Description |
|------|-------------|
| `data/analysis_data.rds` | Matched sample-level analysis dataset used for model fitting |
| `data/roc_model.rds` | Saved logistic regression model bundle with data and selected genes |
| `table/model_coefficients.csv` | Logistic regression coefficients, z statistics, p-values, and odds ratios |
| `table/roc_auc_summary.csv` | AUC values for the full model and each marker |
| `plot/roc_curve.pdf` | ROC curves for the full model and individual markers |
| `session_info.txt` | Session information and run parameters |

### model_coefficients.csv

| Column | Description |
|--------|-------------|
| `term` | Model term name |
| `estimate` | Logistic regression coefficient |
| `std_error` | Standard error of the coefficient |
| `z_value` | Wald z statistic |
| `p_value` | Wald test p-value |
| `odds_ratio` | Exponentiated coefficient |
| `odds_ratio_95_ci` | Odds ratio with 95% confidence interval |

### roc_auc_summary.csv

| Column | Description |
|--------|-------------|
| `model` | Full model or marker name |
| `auc` | Area under the ROC curve |

---

## Workflow

### Step 1: Validate Input
- Check that the expression matrix and group file exist and have supported formats.
- Validate unique gene identifiers and sample IDs.
- Match samples shared by both files.

### Step 2: Prepare Analysis Dataset
- Keep only the requested marker genes that exist in the expression matrix.
- Merge matched expression values with group labels.
- Convert the selected case group to binary outcome labels.

### Step 3: Fit Logistic Regression
- Fit a multivariable logistic regression model using the selected markers.
- Extract coefficient estimates, standard errors, p-values, and odds ratios.

### Step 4: Compute ROC Performance
- Generate the ROC curve of the full logistic model.
- Generate ROC curves for each individual marker.
- Calculate AUC values for the full model and each marker.

### Step 5: Save Outputs
- Save the matched analysis dataset and model bundle as `.rds` files.
- Save coefficient and AUC summary tables as `.csv` files.
- Save the combined ROC plot as a PDF.

---

## Examples

### Basic Usage

```bash
Rscript scripts/main.R \
  -e expression_matrix.csv \
  -g group_info.csv \
  -m FOXP3,CD45,CD3E \
  -c Disease \
  -o ./output/
```

### With Explicit Group Column and Custom Plot

```bash
Rscript scripts/main.R \
  -e expression_matrix.csv \
  -g group_info.csv \
  -m FOXP3,CD45,CD3E \
  -c Disease \
  --group_col diagnosis \
  --plot_width 8 \
  --plot_height 6 \
  --plot_title "Biomarker ROC Comparison" \
  --legend_position topright \
  -o ./output/
```

### With Test Data

```bash
Rscript scripts/main.R \
  -e tests/data/sample_expression_matrix.csv \
  -g tests/data/sample_group_info.csv \
  -m FOXP3,CD45,CD3E \
  -c Disease \
  -o tests/expected_output/ \
  --overwrite
```

---

## Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| `SKILL_INVALID_PARAMETER` | Missing required argument, invalid option value, invalid matrix/group structure, invalid case label, insufficient case-control counts, or logistic fitting failure | Check argument names, input content, class balance, and model stability |
| `SKILL_FILE_NOT_FOUND` | Input file does not exist | Verify the file path |
| `SKILL_EMPTY_DATA` | Input file contains no usable rows, or no requested markers remain after filtering | Check file content, delimiter, and marker names |
| `SKILL_MISSING_COLUMNS` | Requested group column is absent | Verify `--group_col` and the group file header |
| `SKILL_SAMPLE_MISMATCH` | Expression matrix and group file do not share sample IDs | Verify that sample IDs match exactly between files |
| `SKILL_PACKAGE_NOT_FOUND` | Required R package is not installed | Install the missing CRAN package |

**IF error persists**, READ: `references/troubleshooting.md`

---

## Testing

### Smoke Test With Included Data

```bash
Rscript scripts/main.R --help

Rscript scripts/main.R \
  -e tests/data/sample_expression_matrix.csv \
  -g tests/data/sample_group_info.csv \
  -m FOXP3,CD45,CD3E \
  -c Disease \
  -o tests/expected_output/ \
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
tests/expected_output/
|-- data/analysis_data.rds
|-- data/roc_model.rds
|-- plot/roc_curve.pdf
|-- session_info.txt
|-- table/model_coefficients.csv
`-- table/roc_auc_summary.csv
```

---

## References

1. Hosmer DW, Lemeshow S, Sturdivant RX (2013). *Applied Logistic Regression*.
2. Fawcett T (2006). An Introduction to ROC Analysis. *Pattern Recognition Letters*.
3. Robin X et al. (2011). pROC: an open-source package for R and S+ to analyze and compare ROC curves. *BMC Bioinformatics*.

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

*Last updated: 2026-04-17 | Version: 2.1.0*
