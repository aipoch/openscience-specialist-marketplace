---
name: elastic-net-feature-selection
description: "Use when selecting predictive genes or other molecular features from bulk expression matrices for binary case-vs-control classification with elastic net logistic regression, including coefficient path and cross-validation plots. Trigger keywords: elastic net, glmnet, feature selection, binary classification, lambda.min, lambda.1se. NOT for: survival/Cox modeling, multiclass outcomes, single-cell data, or non-expression tables."
---

# Elastic Net Feature Selection

## When to Use

- Use this skill for binary case-vs-control classification on bulk expression matrices.
- Use it when you need elastic net logistic regression feature selection, coefficient paths, and `cv.glmnet`-based lambda selection.
- Use custom labels such as `Tumor` and `Normal` only when the group file still contains exactly two outcome levels.

## Out of Scope

- Survival or Cox modeling
- Multiclass outcomes
- Single-cell data
- Non-expression tables

Out-of-scope enforcement:

- If the group file contains any label outside the requested `case_group` and `control_group`, the command stops with `SKILL_INVALID_DATA` instead of silently dropping samples.
- If either requested class is missing after validation, the command stops with `SKILL_INVALID_DATA`.

## When to Read External Files

| Situation | File to Read | Purpose |
|-----------|--------------|---------|
| **Need to understand alpha, lambda choice, or feature-selection behavior** | `references/algorithm.md` | Elastic net logistic regression, penalty mixing, cross-validation, and coefficient selection assumptions |
| **Need the authoritative executable entrypoint** | `scripts/main.R` | Run: `Rscript scripts/main.R --input_file ... --group_file ... --output_dir ...` |
| **Need parameter examples, smoke-test commands, or recorded local runs** | `references/cli-guide.md` | Verified CLI examples for normal runs, conservative runs, and test-data runs |
| **Need bundled sample inputs for a first run or regression test** | `tests/data/` | Sample expression matrix, group file, and feature list |
| **Encounter errors, warnings, or timeout issues** | `references/troubleshooting.md` | Common failures, console warning interpretation, and recovery steps |

---

## Usage

```bash
Rscript scripts/main.R \
  --input_file ./expression_matrix.csv \
  --group_file ./groups.csv \
  --feature_file ./genes.csv \
  --case_group case \
  --control_group control \
  --alpha auto \
  --alpha_grid 0,0.25,0.5,0.75,1 \
  --nfolds 5 \
  --lambda_choice lambda.min \
  --standardize TRUE \
  --timeout_seconds 600 \
  --output_dir ./output/ \
  --seed 42
```

---

## Arguments

| Short | Long | Type | Default | Description |
|-------|------|------|---------|-------------|
| `-i` | `--input_file` | character | **required** | Expression matrix file (genes as rows, samples as columns) |
| `-g` | `--group_file` | character | **required** | Group information file with sample and group columns |
| `-f` | `--feature_file` | character | `NULL` | Optional feature list file; if omitted, all matrix rows are used |
| `-c` | `--case_group` | character | `case` | Positive class label in the group file |
| `-d` | `--control_group` | character | `control` | Negative class label in the group file |
| `-a` | `--alpha` | character | `0.5` | Elastic net mixing parameter: numeric `0`-`1`, or `auto` for CV-based selection |
|  | `--alpha_grid` | character | `0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1` | Comma-separated alpha candidates evaluated when `alpha=auto` |
| `-n` | `--nfolds` | integer | `5` | Cross-validation fold count; automatically reduced if a class has fewer samples |
| `-l` | `--lambda_choice` | character | `lambda.min` | Coefficient extraction rule: `lambda.min` or `lambda.1se` |
| `-z` | `--standardize` | logical | `TRUE` | Standardize features inside `glmnet` |
| `-t` | `--timeout_seconds` | integer | `600` | Elapsed timeout limit in seconds |
| `-o` | `--output_dir` | character | `./output/` | Output directory |
| `-s` | `--seed` | integer | `42` | Random seed for reproducibility |

---

## Input Format

### Expression Matrix (input_file)

Genes as rows, samples as columns, CSV format with gene IDs in the first column.

```csv
,Sample01,Sample02,Sample03
TNMD,0.0349,0.0533,1.3889
DPM1,4.8627,5.4208,5.6370
```

### Group File (group_file)

CSV with sample IDs and binary group labels.

```csv
sample,group
Sample01,case
Sample02,control
Sample03,case
```

### Feature File (feature_file)

Optional plain text or single-column CSV file with one feature per line.

```csv
TNMD
DPM1
SCYL3
```

---

## Output Files

| File | Description |
|------|-------------|
| `alpha_tuning.csv` | Cross-validated performance summary for each alpha candidate |
| `model_coefficients.csv` | Coefficients at the selected lambda, including intercept |
| `selected_features.csv` | Sparse selected features sorted by absolute effect size; written empty when the chosen `alpha` is `0` (ridge) |
| `feature_matrix.csv` | Sample-by-feature analysis matrix used for model fitting |
| `coefficient_path.pdf` | Coefficient trajectory plot across lambda values |
| `cv_curve.pdf` | Cross-validation error curve with `lambda.min` and `lambda.1se` |
| `session_info.txt` | R session and package version info |

---

## Workflow

### Step 1: Validate Input
- **WHEN preparing input files for a first run or regression test**, READ: `tests/data/`
- Check file existence
- Reject empty input files
- Detect sample and group columns in the group file
- Reject group files that contain labels outside the requested binary comparison
- Validate sample matching between expression matrix and group file

### Step 2: Prepare Modeling Matrix
- Restrict samples to the requested case and control groups
- Intersect the optional feature list with matrix row names
- Build a sample-by-feature numeric matrix for `glmnet`
- Drop zero-variance features before modeling

### Step 3: Run Elastic Net
- **WHEN deciding between `alpha`, `lambda.min`, and `lambda.1se`**, READ: `references/algorithm.md`
- If `alpha=auto`, evaluate the candidate `alpha_grid` with the same cross-validation folds
- Fit the regularization path with `glmnet`
- Run `cv.glmnet` to estimate the optimal lambda
- Extract coefficients at `lambda.min` or `lambda.1se`
- Apply runtime timeout and capture non-fatal warnings

### Step 4: Export Results
- **WHEN you need exact invocation patterns or output inspection commands**, READ: `references/cli-guide.md`
- Save tuning tables and selected features
- Generate coefficient path and cross-validation plots
- Record session information for reproducibility

---

## Methods

### Elastic Net Logistic Regression
Elastic net combines lasso (`L1`) and ridge (`L2`) penalties through `alpha`, enabling sparse feature selection while stabilizing correlated predictors.

### Cross-Validation
`cv.glmnet` evaluates the lambda path and reports both `lambda.min` and the more conservative `lambda.1se`.

### Automatic Alpha Selection
When `alpha=auto`, the skill reuses the same cross-validation folds across all values in `alpha_grid`, compares the minimum cross-validated error for each candidate, and selects the best alpha before reporting coefficients and lambda-based outputs.

If the chosen `alpha` is `0`, the model is ridge rather than sparse elastic net. In that case, `selected_features.csv` is written empty to avoid mislabeling dense ridge coefficients as selected features; use `model_coefficients.csv` for coefficient ranking instead.

### Feature Selection Rule
Selected features are the coefficients whose absolute value exceeds a small numerical tolerance at the chosen lambda, excluding the intercept term.

If the chosen `alpha` is `0`, the workflow writes an empty `selected_features.csv` because ridge coefficients are dense by design and should not be mislabeled as sparse selected features.

---

## Examples

### Recommended First Run
```bash
Rscript scripts/main.R \
  -i expression_matrix.csv \
  -g groups.csv \
  -f genes.csv \
  -a auto \
  --alpha_grid 0,0.25,0.5,0.75,1 \
  -o output/first_run
```

### Fixed-Alpha Baseline
```bash
Rscript scripts/main.R \
  -i expression_matrix.csv \
  -g groups.csv \
  -f genes.csv \
  -a 0.5 \
  -o output/fixed_alpha
```

### More Conservative Selection
```bash
Rscript scripts/main.R \
  -i expression_matrix.csv \
  -g groups.csv \
  -l lambda.1se \
  -o output/lambda_1se
```

---

## Error Handling

### Common Errors

| Error | Cause | Solution | Read More |
|-------|-------|----------|-----------|
| `SKILL_FILE_NOT_FOUND` | Input file does not exist | Check file path and permissions | `references/troubleshooting.md#skill_file_not_found` |
| `SKILL_EMPTY_DATA` | Input file exists but is empty | Re-export the input file with data rows | `references/troubleshooting.md#skill_empty_data` |
| `SKILL_MISSING_COLUMNS` | Group file lacks sample/group columns | Verify the group file structure | `references/troubleshooting.md#skill_missing_columns` |
| `SKILL_SAMPLE_MISMATCH` | Sample IDs do not overlap between files | Ensure matrix column names match the group file | `references/troubleshooting.md#skill_sample_mismatch` |
| `SKILL_INVALID_PARAMETER` | CLI parameter is invalid | Check allowed values and ranges | `references/troubleshooting.md#skill_invalid_parameter` |
| `SKILL_INVALID_DATA` | Too few samples or usable features remain | Review filtering choices and input data | `references/troubleshooting.md#skill_invalid_data` |
| `SKILL_DEPENDENCY_MISSING` | Required R package is not installed | Install missing packages before rerunning | `references/troubleshooting.md#skill_dependency_missing` |
| `SKILL_PKG_VERSION` | Installed package is too old | Upgrade the required package | `references/troubleshooting.md#skill_pkg_version` |
| `SKILL_TIMEOUT` | Run exceeded the configured time limit | Increase `timeout_seconds` or reduce data size | `references/troubleshooting.md#skill_timeout` |
| `SKILL_RUNTIME_ERROR` | An unexpected runtime or output-write failure occurred | Check output path permissions, free space, and the last console message | `references/troubleshooting.md#skill_runtime_error` |

**IF error persists**, READ: `references/troubleshooting.md`

---

## Testing

### Test with Sample Data

```bash
# Check help
Rscript scripts/main.R --help

# Run with bundled test data
Rscript scripts/main.R \
  -i tests/data/expression_matrix.csv \
  -g tests/data/groups.csv \
  -f tests/data/genes.csv \
  -a auto \
  --alpha_grid 0,0.5,1 \
  -o tests/output \
  -n 5 \
  -t 600
```

### Validation Commands

```bash
# Inspect selected features (may be header-only if auto-alpha selects ridge)
cat tests/output/selected_features.csv

# Check plots exist
ls -la tests/output
```

---

## Implementation Checklist

- [x] CLI parsing with `optparse`
- [x] `set.seed()` for reproducibility
- [x] `requireNamespace()` dependency checks
- [x] Runtime package loading with `library()`
- [x] Session info recording
- [x] Timeout control with `setTimeLimit()`
- [x] Console warning handling
- [x] Out-of-scope label enforcement
- [x] `gc()` snapshot reporting
- [x] File reading instructions in `SKILL.md`
- [x] Modular script structure
- [x] Test data provided
- [x] Error handling with `SKILL_*` codes
- [x] Scripts in `scripts/` directory
- [x] References in `references/` directory

---

*Last updated: 2026-04-20 | Version: 1.0.0*
