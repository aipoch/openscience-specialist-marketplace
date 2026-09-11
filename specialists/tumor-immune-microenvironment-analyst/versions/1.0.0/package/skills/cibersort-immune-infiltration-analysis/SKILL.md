---
name: cibersort-immune-infiltration-analysis
description: Use when estimating relative immune cell infiltration from a bulk expression matrix with a CIBERSORT-style nu-SVR deconvolution workflow based on an LM22 signature matrix, comparing one case group against one control group, and generating structured tables plus immune-fraction plots. NOT for single-cell RNA-seq, spatial data, clinical diagnosis, or workflows that require the original hosted CIBERSORT web service.
license: MIT
author: AIPOCH
---
> **Source**: [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills)

# CIBERSORT Immune Infiltration Analysis

## When to Use

- Estimate relative immune cell fractions from a bulk expression matrix.
- Compare one case group against one control group after deconvolution.
- Generate structured tables, a serialized result object, and optional PDF plots.

## When Not to Use

- Single-cell RNA-seq, spatial transcriptomics, or clustering tasks.
- Absolute clinical interpretation or treatment recommendation.
- Workflows that require the original online CIBERSORT service instead of a local R implementation.

## Workflow

1. Confirm that the expression matrix, group file, and signature matrix are available.
2. Run `scripts/main.R` with the case and control groups.
3. Review the full result table, derived summary tables, and optional plots.
4. Inspect `run_record.txt` and `output_manifest.txt` after each run, including failed validation attempts.

## When to Read External Files

| Situation | File to Read | Purpose |
|-----------|--------------|---------|
| Need to run the analysis | `scripts/main.R` | CLI entry point |
| Need algorithm details | `references/algorithm.md` | HQ reference workflow and result interpretation |
| Encounter an error | `references/troubleshooting.md` | Error codes and environment fixes |
| Need CLI examples or the baseline record | `references/cli-guide.md` | Example commands and validation notes |
| Need packaged test inputs | `tests/data/` | Demo expression matrix, group file, and LM22 file |

## Usage

```bash
Rscript scripts/main.R \
  --input_file ./expression_matrix.csv \
  --group_file ./group_info.csv \
  --signature_file ./LM22.txt \
  --case_group treatment \
  --control_group control \
  --output_dir ./output \
  --qn false \
  --seed 42
```

## Arguments

| Short | Long | Type | Default | Description |
|-------|------|------|---------|-------------|
| `-i` | `--input_file` | file | required | Expression matrix with genes as rows and samples as columns |
| `-g` | `--group_file` | file | required | Group annotation table |
| `-a` | `--case_group` | string | required | Case group label |
| `-b` | `--control_group` | string | required | Control group label |
| `-o` | `--output_dir` | dir | `./output` | Output directory |
|  | `--signature_file` | file | `tests/data/LM22.txt` when present | Signature matrix file |
|  | `--sample_col` | string/int | none | Optional sample column name or 1-based index |
|  | `--group_col` | string/int | none | Optional group column name or 1-based index |
|  | `--gene_id_case` | string | `upper` | Gene ID normalization: `asis`, `upper`, or `lower` |
|  | `--auto_unlog` | boolean | `true` | Apply `2^x` only if the expression matrix passes a conservative log-scale heuristic |
|  | `--min_mean_expression` | numeric | `1` | Minimum mean expression before deconvolution |
|  | `--perm` | integer | `1000` | Permutation count for empirical p-value estimation; `0` keeps the run lightweight but records `P-value` as `NA` |
|  | `--qn` | boolean | `true` | Apply quantile normalization to the mixture matrix |
|  | `--svm_cores` | integer | `1` | Worker count for the nu-SVR model selection step |
|  | `--make_plots` | boolean | `true` | Generate PDF plots |
|  | `--plot_width` | numeric | `16` | Default plot width in inches |
|  | `--plot_height` | numeric | `10` | Default plot height in inches |
| `-s` | `--seed` | integer | `42` | Random seed |
| `-t` | `--timeout_seconds` | integer | `0` | Optional timeout in seconds; `0` disables it |
|  | `--verbose` | boolean | `true` | Print progress logs |

## Input Format

### Expression Matrix

CSV or TSV. The first column must contain gene identifiers. Remaining columns must be numeric sample-level expression values.

When `--auto_unlog=true`, the workflow reports summary statistics and applies `2^x` only if the matrix passes a conservative log-scale heuristic. If the matrix is ambiguous, the values are left unchanged and the startup log explains why.

If duplicate gene identifiers are present, they are consolidated after gene-ID normalization by taking the per-sample maximum before downstream filtering and deconvolution.

```csv
gene,Sample1,Sample2,Sample3
TP53,10.2,8.5,9.1
CXCL9,4.3,6.1,5.7
```

### Group File

CSV or TSV with one sample column and one group column.

```csv
sample,group
Sample1,control
Sample2,treatment
Sample3,treatment
```

### Signature Matrix

The packaged default is `tests/data/LM22.txt`. A custom signature matrix must contain one gene column followed by immune-cell signature columns.

All immune-cell signature columns must be numeric and finite. If duplicate gene identifiers are present, they are consolidated by taking the per-cell-type maximum before gene intersection.

## Output Files

| File | Description |
|------|-------------|
| `data/cibersort_input.rds` | Serialized aligned input matrices used by the local algorithm |
| `data/cibersort_null_distribution.rds` | Serialized permutation null distribution |
| `data/cibersort_result.rds` | Serialized result object with cell fractions, metrics, runtime settings, and heatmap rendering metadata |
| `table/CIBERSORT_Results.csv` | Full result table in CSV format |
| `table/CIBERSORT-Results.txt` | Full result table in tab-delimited text format |
| `table/cibersort_cell_fractions_wide.csv` | Wide-format immune cell fraction table |
| `table/cibersort_cell_fractions_long.csv` | Long-format immune cell fraction table |
| `table/cibersort_group_compare.csv` | Case-vs-control comparison summary |
| `table/cibersort_quality_metrics.csv` | Sample-level `P-value`, `Correlation`, and `RMSE` table |
| `table/immune_cell_correlation_matrix.csv` | Spearman correlation matrix across immune cell types |
| `table/immune_cell_correlation_pvalue.csv` | P-value matrix aligned to the correlation matrix |
| `plot/immune_cell_composition_sample.pdf` | Sample-level stacked composition plot when `--make_plots=true` |
| `plot/immune_group_boxplot.pdf` | Group comparison boxplot when `--make_plots=true` |
| `plot/immune_correlation_heatmap.pdf` | Immune-cell correlation heatmap when `--make_plots=true` |
| `session_info.txt` | R session information |
| `output_manifest.txt` | Append-only output manifest for successful and failed runs |
| `run_record.txt` | Append-only structured run record, including runtime notes and failed-run summaries |

When `--make_plots=false`, the `plot/` directory may still exist as part of the standard output layout, but no PDF plot files are written.

When `--perm=0`, the workflow logs a warning and completes without empirical permutation testing, so the `P-value` column is recorded as `NA`.

When a rerun targets an existing `--output_dir` and then fails validation or execution, the previous successful payload is preserved and the failure is appended to `run_record.txt` and `output_manifest.txt`.

## Error Handling

| Error Code | Meaning | Solution |
|------------|---------|----------|
| `SKILL_FILE_NOT_FOUND` | An input file or signature matrix was not found | Check the file path and rerun |
| `SKILL_MISSING_COLUMNS` | A required column is missing | Fix the input schema |
| `SKILL_EMPTY_DATA` | No usable genes, samples, or deconvolution outputs remain | Check the data, filtering, or signature overlap |
| `SKILL_INVALID_PARAMETER` | A CLI parameter is missing or invalid | Review the argument table and input values |
| `SKILL_SAMPLE_MISMATCH` | Expression samples and group annotations do not align | Harmonize sample identifiers |
| `SKILL_PACKAGE_NOT_FOUND` | A required R package is missing | Install the missing package |
| `SKILL_TIMEOUT` | The configured time limit was exceeded | Increase `--timeout_seconds` or set it to `0` |

If the error persists, READ: `references/troubleshooting.md`

## Input Validation

This skill accepts:

- A bulk expression matrix file in CSV or TSV format with one gene column and numeric sample columns.
- A group annotation file in CSV or TSV format with one sample column and one group column.
- Exactly one case group label and one control group label for comparison.
- An optional custom signature matrix compatible with the documented LM22-style schema.

Do not use this skill for:

- Single-cell RNA-seq, spatial transcriptomics, or cell clustering workflows.
- Clinical diagnosis, treatment recommendation, or patient-level medical decision making.
- Requests that need the hosted CIBERSORT web service rather than this local R implementation.
- Multi-group study designs that require more than one case group versus one control group in a single run.

If the user's request is outside this scope, do not proceed with the workflow. Instead respond:

> "cibersort-immune-infiltration-analysis is designed for local CIBERSORT-style immune deconvolution from a bulk expression matrix with one case group and one control group. Your request appears to be outside this scope. Please provide compatible bulk-expression inputs and group labels, or use a more appropriate tool for your task."

## Testing

```bash
Rscript scripts/main.R --help

Rscript tests/run_tests.R

Rscript tests/test_skill.R
```

Validated packaged test path:

```bash
Rscript scripts/main.R \
  --input_file tests/data/expression_matrix.csv \
  --group_file tests/data/group_info.csv \
  --signature_file tests/data/LM22.txt \
  --case_group Tumor \
  --control_group Healthy \
  --output_dir tests/output \
  --perm 25 \
  --qn false \
  --svm_cores 1 \
  --seed 42
```

Container note:

- The packaged test path uses `--qn false` because `preprocessCore::normalize.quantiles()` may trigger environment-level thread failures in some containers.
- If you need a quantile-normalized run, validate that environment first and record the result in `references/cli-guide.md`.
- `tests/run_tests.R` also checks that a failed rerun does not erase an existing successful payload directory.
