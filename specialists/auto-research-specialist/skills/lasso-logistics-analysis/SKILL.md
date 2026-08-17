---
name: lasso-logistics-analysis
description: "Use when building a binary classification model from an expression matrix or other omics feature matrix with LASSO logistic regression, cross-validation, and coefficient path visualization. NOT for: multiclass classification, survival/Cox models, or ordinary linear regression."
---

# LASSO Logistic Regression Analysis

## When to Read External Files

| Situation | File to Read | Purpose |
|-----------|--------------|---------|
| **Need algorithm details** | `references/algorithm.md` | LASSO objective function, cross-validation, and interpretation |
| **Need to run analysis** | `scripts/main.R` | Execute: `Rscript scripts/main.R --input_file ... --group_file ...` |
| **Encounter errors** | `references/troubleshooting.md` | Common errors and solutions |
| **Need CLI examples** | `references/cli-guide.md` | Detailed CLI usage examples |
| **Need test data** | `tests/data/` | Sample input files for testing |
| **Need workflow implementation details** | `scripts/run_analysis.R` | Inspect orchestration, outputs, and file-writing behavior |
| **Need input-validation or error-handling details** | `scripts/utils.R`, `scripts/io.R` | Inspect validation, parsing, logging, and standardized safeguards |

---

## Usage

```bash
Rscript scripts/main.R \
  --input_file ./expression_matrix.csv \
  --group_file ./groups.csv \
  --case_group case \
  --control_group control \
  --output_dir ./output/ \
  --nfolds 10 \
  --timeout_seconds 1800 \
  --seed 42
```

---

## Arguments

| Short | Long | Type | Default | Description |
|-------|------|------|---------|-------------|
| `-i` | `--input_file` | character | **required** | Expression matrix file (features as rows, samples as columns) |
| `-g` | `--group_file` | character | **required** | Group file with sample and group columns |
| `-c` | `--case_group` | character | **required** | Case class label encoded as `1` |
| `-t` | `--control_group` | character | **required** | Control class label encoded as `0` |
| `-f` | `--feature` | character | `NULL` | Optional feature list file or comma-separated feature names |
| `-n` | `--nfolds` | integer | `10` | Cross-validation folds: `3`, `5`, `7`, `10` |
|  | `--cv_title` | character | `""` | Optional title for the cross-validation plot |
|  | `--path_title` | character | `""` | Optional title for the coefficient path plot |
|  | `--timeout_seconds` | integer | `1800` | Maximum elapsed runtime in seconds |
| `-o` | `--output_dir` | character | `./output/` | Output directory |
| `-s` | `--seed` | integer | `42` | Random seed for reproducibility |

---

## Input Format

### Expression Matrix (`input_file`)

Features as rows, samples as columns, CSV or TSV format with feature IDs in the first column.

```csv
,Sample01,Sample02,Sample03
TSPAN6,1.8479,1.8318,3.8276
TNMD,0.0349,0.0533,1.3889
```

### Group File (`group_file`)

CSV or TSV with sample IDs and binary-group labels.

```csv
sample,group
Sample01,case
Sample02,control
Sample03,case
```

### Optional Feature File (`feature`)

One feature per line, or pass a comma-separated feature list directly on the CLI.

```text
TNMD
DPM1
SCYL3
```

---

## Output Files

| File | Description |
|------|-------------|
| `coefficient.csv` | All coefficients at `lambda.min` |
| `feature_matrix.csv` | Sample-level matrix with original group labels and binary event column |
| `selected_features.txt` | Non-zero features at `lambda.min` excluding the intercept, when available |
| `missing_features.txt` | Requested features not found in the matrix, when applicable |
| `lasso_lambda_binary_plot.pdf` | Cross-validation curve |
| `lasso_var_binary_plot.pdf` | Coefficient path plot |
| `session_info.txt` | R session and package version info |

---

## Workflow

### Step 1: Validate Input
**WHEN checking validation rules or parsing behavior**, READ: `scripts/utils.R` and `scripts/io.R`

- Check file existence
- Read expression matrix and group file
- Verify samples match between files
- Ensure both classes are present with at least 2 samples per class

### Step 2: Prepare Modeling Matrix
**WHEN checking class encoding or feature filtering behavior**, READ: `scripts/modeling.R`

- Encode `case_group` as `1` and `control_group` as `0`
- Optionally restrict to a user-supplied feature panel
- Transpose expression data to sample-by-feature format

### Step 3: Fit LASSO Logistic Regression
**WHEN understanding the statistical method or lambda selection**, READ: `references/algorithm.md`

- Train a binomial `glmnet` model with `alpha = 1`
- Run `cv.glmnet` to select the optimal lambda
- Extract coefficients at `lambda.min`

### Step 4: Save Results and Visualizations
**WHEN checking output generation or plot behavior**, READ: `scripts/run_analysis.R` and `scripts/plotting.R`

- Save flat output files directly into `output_dir`
- Generate cross-validation and coefficient path PDF plots
- Leave plot titles empty by default unless the user provides custom titles

---

## Methods

### LASSO Logistic Regression
The model minimizes binomial deviance with an L1 penalty, shrinking weak coefficients to zero and performing embedded feature selection.

### Cross-Validation
`cv.glmnet` evaluates candidate lambda values across `nfolds` folds and reports `lambda.min` and `lambda.1se`.

---

## Examples

### Basic Usage
```bash
Rscript scripts/main.R \
  -i ./expression_matrix.csv \
  -g ./groups.csv \
  -c case \
  -t control \
  -o ./output
```

### Use a Feature Panel
```bash
Rscript scripts/main.R \
  -i ./expression_matrix.csv \
  -g ./groups.csv \
  -c case \
  -t control \
  -f ./genes.txt \
  -o ./output
```

### Custom Folds and Seed
```bash
Rscript scripts/main.R \
  -i ./expression_matrix.csv \
  -g ./groups.csv \
  -c case \
  -t control \
  -n 5 \
  --timeout_seconds 900 \
  -s 123 \
  -o ./output
```

### Custom Plot Titles
```bash
Rscript scripts/main.R \
  -i ./expression_matrix.csv \
  -g ./groups.csv \
  -c case \
  -t control \
  --cv_title "LASSO Cross-Validation" \
  --path_title "LASSO Coefficient Paths" \
  --timeout_seconds 1200 \
  -o ./output
```

---

## Error Handling

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `SKILL_FILE_NOT_FOUND` | Input file does not exist | Check file path |
| `SKILL_EMPTY_FILE` | An input file exists but contains no data | Verify the file is not empty |
| `SKILL_PARSE_ERROR` | The input file cannot be parsed as CSV or TSV | Check delimiters, headers, and encoding |
| `SKILL_FILE_WRITE_ERROR` | The output directory cannot be created or written | Check output path and permissions |
| `SKILL_EMPTY_DATA` | The loaded table has no usable rows or columns | Verify that the input file contains valid data |
| `SKILL_MISSING_COLUMNS` | The group file does not provide the required columns | Provide sample and group columns |
| `SKILL_INVALID_TYPE` | A parameter or data field has the wrong type | Ensure numeric fields are numeric and strings are valid |
| `SKILL_SAMPLE_MISMATCH` | Sample IDs differ between matrix and group file | Make names match exactly |
| `SKILL_INVALID_GROUP` | Case/control labels not found in group file | Check `--case_group` and `--control_group` |
| `SKILL_INVALID_DATA` | Too few classes, samples, or valid features | Review input structure and feature list |
| `SKILL_INVALID_PARAMETER` | Unsupported `nfolds` or empty parameter | Use documented argument values |
| `SKILL_DEPENDENCY_MISSING` | Required R package not installed | Install missing CRAN package |
| `SKILL_TIMEOUT` | Analysis exceeded the configured time limit | Reduce feature count or increase `--timeout_seconds` |
| `SKILL_MEMORY_ERROR` | The runtime environment cannot allocate enough memory | Reduce matrix size or available workload |
| `SKILL_RUNTIME_ERROR` | An unexpected runtime error occurred | Review the exact console error and retry |

**IF error persists**, READ: `references/troubleshooting.md`

---

## Testing

### Test with Sample Data

```bash
# Check help
Rscript scripts/main.R --help

# Run with sample data
Rscript scripts/main.R \
  -i tests/data/expression_matrix.csv \
  -g tests/data/groups.csv \
  -c case \
  -t control \
  -f tests/data/genes.csv \
  --timeout_seconds 1800 \
  -o tests/output
```

### Validation Commands

```bash
# Check coefficient output
ls -la tests/output/coefficient.csv

# Check plots exist
ls -la tests/output/lasso_lambda_binary_plot.pdf
ls -la tests/output/lasso_var_binary_plot.pdf
```

---

## Implementation Checklist

- [x] CLI parsing with `optparse`
- [x] `set.seed()` for reproducibility
- [x] `requireNamespace()` dependency checks
- [x] Session info recording
- [x] Timeout control with `--timeout_seconds`
- [x] Temp file cleanup
- [x] File reading instructions in SKILL.md
- [x] Modular script structure (<150 lines per file)
- [x] Test data provided
- [x] Error handling with SKILL_* codes
- [x] Scripts in `scripts/` directory
- [x] References in `references/` directory

---

*Last updated: 2026-04-17 | Version: 1.0.0*
