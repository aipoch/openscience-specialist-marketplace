# CLI Guide

## Dependency Notes

This skill currently depends on public R packages rather than a private internal package:

- `optparse`
- `preprocessCore`
- `e1071`
- `ggplot2`
- `pheatmap`

Suggested installation pattern:

```r
install.packages(c("optparse", "e1071", "ggplot2", "pheatmap"))
if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager")
BiocManager::install("preprocessCore")
```

Dependency policy for this skill:

- Use public standard R repositories only for required packages in validated runs.
- The current validated dependency set is base/recommended R plus CRAN packages and Bioconductor `preprocessCore`.
- Do not add private, internal, or locally patched package dependencies.

## CLI Examples

### Example 1: Practical container-safe run

```bash
Rscript scripts/main.R \
  --input_file ./expression_matrix.csv \
  --group_file ./group_info.csv \
  --signature_file ./LM22.txt \
  --case_group treatment \
  --control_group control \
  --output_dir ./output \
  --qn false \
  --svm_cores 1
```

### Example 2: Quantile-normalized run

```bash
Rscript scripts/main.R \
  --input_file ./expression_matrix.csv \
  --group_file ./group_info.csv \
  --signature_file ./LM22.txt \
  --case_group treatment \
  --control_group control \
  --output_dir ./output \
  --perm 1000 \
  --qn true
```

### Example 3: Lightweight validation run

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

## Baseline Real-Data Execution Record

This section records the validated packaged baseline run completed in the target container.

### Environment

- Execution context: target container used for skill validation
- Command family: `Rscript scripts/main.R`, `Rscript tests/run_tests.R`, `Rscript tests/test_skill.R`
- Runtime profile: packaged validation path with `--perm 25`, `--qn false`, and `--svm_cores 1`
- Seed: `42`

### Input Files

- `tests/data/expression_matrix.csv`
- `tests/data/group_info.csv`
- `tests/data/LM22.txt`

### Input Summary

- Genes retained in the validated run: `506`
- Samples retained in the validated run: `8`
- Group sizes: `Tumor = 4`, `Healthy = 4`
- Signature genes loaded from LM22: `547`
- Overlapping genes used for deconvolution: `506`
- Immune cell types estimated: `22`

### Baseline Command

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

### Output Files

The authoritative output list is written automatically to `tests/output/output_manifest.txt`.

| File | Description | Content |
|------|-------------|---------|
| `tests/output/data/cibersort_input.rds` | Serialized aligned input matrices | Stores the standardized signature matrix, aligned mixture matrix, and overlapping genes |
| `tests/output/data/cibersort_null_distribution.rds` | Serialized null distribution | Stores the permutation-based null distribution used for empirical p-value estimation |
| `tests/output/data/cibersort_result.rds` | Serialized result object | Stores cell fractions, quality metrics, group map, signature source, runtime settings, and heatmap rendering metadata |
| `tests/output/table/CIBERSORT_Results.csv` | Full deconvolution result table | Contains 8 samples, 22 immune cell types, and `P-value`, `Correlation`, `RMSE` columns |
| `tests/output/table/CIBERSORT-Results.txt` | Tab-delimited full result table | Text export of the same result table for legacy-style downstream handling |
| `tests/output/table/cibersort_cell_fractions_wide.csv` | Wide-format cell fractions | Rows are samples and columns are immune cell types |
| `tests/output/table/cibersort_cell_fractions_long.csv` | Long-format cell fractions | One row per sample and immune cell type |
| `tests/output/table/cibersort_group_compare.csv` | Group comparison summary | 22 immune cell rows with Wilcoxon statistics and BH-adjusted p-values |
| `tests/output/table/cibersort_quality_metrics.csv` | Sample-level quality metrics | 8 rows with `P-value`, `Correlation`, and `RMSE` |
| `tests/output/table/immune_cell_correlation_matrix.csv` | Immune-cell Spearman correlation matrix | Pairwise correlation coefficients across the 22 immune cell types |
| `tests/output/table/immune_cell_correlation_pvalue.csv` | Correlation p-value matrix | Pairwise p-values aligned to the correlation matrix |
| `tests/output/plot/immune_cell_composition_sample.pdf` | Sample composition plot | Stacked bar plot of immune fractions by sample |
| `tests/output/plot/immune_group_boxplot.pdf` | Group comparison plot | Per-cell-type boxplot stratified by `Tumor` and `Healthy` |
| `tests/output/plot/immune_correlation_heatmap.pdf` | Correlation heatmap | Heatmap of immune-cell correlations; non-finite values are replaced with `0` for visualization only |
| `tests/output/session_info.txt` | Session record | `sessionInfo()` output for reproducibility |
| `tests/output/output_manifest.txt` | Auto-generated manifest | Append-only output inventory with descriptions |
| `tests/output/run_record.txt` | Auto-generated run record | Append-only run history with parameters, runtime, CPU summary, and output summary |

### Runtime And Resource Usage

| Metric | Value |
|--------|-------|
| Start time | `2026-04-16 08:32:19` |
| End time | `2026-04-16 08:32:34` |
| Elapsed time | `14.985 s` |
| User CPU time | `14.851 s` |
| System CPU time | `0.036 s` |
| Timeout setting | `0` |
| GC snapshot (Ncells) | `used 1,266,064 (67.7 Mb)` |
| GC snapshot (Vcells) | `used 2,214,049 (16.9 Mb)` |

Resource note:

- The validated packaged baseline completed successfully in the container with the lightweight test profile.
- `--qn false` was required in the validated container path to avoid the known `preprocessCore::normalize.quantiles()` threading issue.
- When `--make_plots false` is used, the standard `plot/` directory may still exist, but it is expected to remain empty.
- `--auto_unlog` now uses a conservative heuristic and may intentionally skip `2^x` if the matrix does not clearly look log-scaled.
- Failed reruns now preserve the last successful payload in `--output_dir` and append a lightweight failure block to `run_record.txt` plus `output_manifest.txt`.
- `--perm 0` is allowed for boundary testing, but it disables empirical `P-value` estimation and records `NA` in the output table.

### Recorded Result Summary

- The packaged validation run completed successfully in the target container.
- `tests/run_tests.R` completed successfully and preserved append-only sections in both `output_manifest.txt` and `run_record.txt`.
- `tests/test_skill.R` passed and confirmed that all expected scaffold outputs were present.
- The validated full result table contained `8` samples and `22` immune cell fractions plus `P-value`, `Correlation`, and `RMSE`.
- `cibersort_group_compare.csv` contained `22` immune cell rows for the `Tumor` versus `Healthy` comparison.
- `cibersort_quality_metrics.csv` contained `8` sample rows with `P-value` ranging from `0` to `0.48`, `Correlation` ranging from `0.0239` to `0.3774`, and `RMSE` ranging from `0.9301` to `1.1087`.
- The correlation heatmap rendered successfully after applying the plotting-only safeguard that replaces non-finite correlation values with `0` for visualization.

Maintenance note:

- Keep using `run_record.txt` and `output_manifest.txt` as the source of truth for future baseline refreshes.
- If a later validated environment supports `--qn true`, document that separately and note the environment difference clearly.
