---
name: gene-protein-expression-matrix-normalization
description: Use when normalizing bulk gene or protein expression matrices with log2 transform, z-score standardization, or min-max scaling before downstream visualization or exploratory analysis. NOT for count-model normalization such as TPM/DESeq2 size factors, batch correction, or single-cell preprocessing.
license: MIT
author: AIPOCH
---
> **Source**: [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills)

# Gene Protein Expression Matrix Normalization

## When to Use

Use this skill when the user wants to normalize a numeric expression matrix before plotting, clustering, or exploratory comparison.

Typical requests:

- "Normalize this gene expression matrix with log2"
- "Do z-score scaling across samples"
- "Map protein abundance values into 0 to 1"

## When Not to Use

Do not use this skill for:

- Count-model normalization such as CPM, TPM, TMM, or DESeq2 size factors
- Batch correction or covariate adjustment
- Single-cell preprocessing workflows
- Matrices that contain missing, `Inf`, or `NaN` values unless they are cleaned first

## When to Read External Files

When executing the analysis, run:

```bash
Rscript scripts/main.R --input_file <matrix.csv> --output_dir <output_dir> --method <log2|zscore|minmax>
```

| Situation | File to Read | Purpose |
|-----------|--------------|---------|
| Need to execute the workflow | `scripts/main.R` | CLI entry point |
| Need algorithm details | `references/algorithm.md` | Method definitions and assumptions |
| Encounter an error | `references/troubleshooting.md` | Standard error codes and fixes |
| Need examples or baseline run details | `references/cli-guide.md` | Ready-to-run commands and test record |
| Need dependency declarations | `DESCRIPTION` | Runtime package list |

## Usage

```bash
Rscript scripts/main.R \
  --input_file tests/data/expression_matrix.csv \
  --output_dir ./output \
  --method log2 \
  --pseudo_count 1 \
  --seed 42
```

## Arguments

| Short | Long | Type | Default | Description |
|-------|------|------|---------|-------------|
| `-i` | `--input_file` | file | required | Expression matrix in CSV or TSV format |
| `-o` | `--output_dir` | dir | `./output` | Output directory |
| `-m` | `--method` | string | `log2` | Normalization method: `log2`, `zscore`, `minmax` |
| `-r` | `--margin` | string | `column` | Apply normalization by `row` or `column` |
| `-p` | `--pseudo_count` | numeric | `1` | Added before log2 transformation |
| `-c` | `--center` | boolean | `true` | Center values for z-score |
| `-s` | `--scale_values` | boolean | `true` | Scale values for z-score |
| `-t` | `--timeout_seconds` | integer | `0` | Optional timeout; `0` disables it |
| `-d` | `--delimiter` | string | `auto` | Input delimiter: `auto`, `csv`, or `tsv` |
|  | `--seed` | integer | `42` | Random seed |
|  | `--verbose` | boolean | `true` | Print progress logs |

## Input Format

The first column must contain feature identifiers. Remaining columns must be finite numeric sample values.

Missing values and non-finite values such as `NA`, `NaN`, `Inf`, and `-Inf` are rejected.

```csv
feature,S1,S2,S3
TP53,10,20,30
EGFR,3,5,9
```

This skill accepts gene or protein expression matrices. It does not infer count-model normalization such as CPM, TPM, TMM, or DESeq2 size factors.

## Output Files

If `--output_dir` already exists, result files with the same names are overwritten. When `--verbose=true`, the workflow prints a warning before writing into a non-empty output directory.

For single-sample inputs, `feature_summary.csv` reports per-feature standard deviations as `0` by design because each feature contributes one observed value.

| File | Description |
|------|-------------|
| `table/normalized_matrix.csv` | Normalized matrix with the original feature column preserved |
| `table/feature_summary.csv` | Per-feature min, max, mean, and SD before and after normalization |
| `table/sample_summary.csv` | Per-sample min, max, mean, and SD before and after normalization |
| `data/normalized_matrix.rds` | Serialized normalized matrix and run metadata |
| `run_record.txt` | Structured execution record |
| `output_manifest.txt` | Output file manifest |
| `session_info.txt` | R session information |

## Methods

### `log2`

Computes `log2(x + pseudo_count)` for each numeric value.

### `zscore`

Centers and scales along the selected margin. `margin=column` standardizes each sample; `margin=row` standardizes each feature.

When `center=false` and `scale_values=true`, the workflow divides by standard deviation without subtracting the mean first.

### `minmax`

Rescales values to `[0, 1]` along the selected margin. Constant vectors are returned as zeros to avoid division-by-zero errors.

## Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| `SKILL_FILE_NOT_FOUND` | Input file path is invalid | Check the input path |
| `SKILL_MISSING_COLUMNS` | Matrix has fewer than two columns | Provide one feature column and at least one sample column |
| `SKILL_INVALID_PARAMETER` | CLI value is unsupported or malformed, or the matrix contains non-finite values | Review the argument table and inspect the matrix values |
| `SKILL_TIMEOUT` | The run exceeded `--timeout_seconds` | Increase the timeout or simplify the input size |
| `SKILL_EMPTY_DATA` | No usable rows or columns remain | Check the input matrix |

## Testing

```bash
Rscript scripts/main.R --help

Rscript tests/run_tests.R

Rscript tests/run_tests.R audit_output_check

Rscript tests/test_skill.R

Rscript tests/test_skill.R audit_output_check --skip-prepare
```

`tests/run_tests.R` executes bundled `log2`, `zscore`, and `minmax` runs and writes their outputs under `tests/output/`.

When you pass a relative directory name such as `audit_output_check`, the test runner writes outputs under `tests/output/audit_output_check/`.

Run `tests/run_tests.R` before `tests/test_skill.R` when you want to validate pre-generated outputs explicitly. The validation script can also prepare missing outputs on its own.
