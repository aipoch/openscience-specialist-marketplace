# CLI Guide

## Dependencies

Dependency declarations are listed in the repository `DESCRIPTION` file. Runtime installation requires CRAN packages plus the Bioconductor package `GSVA`:

```r
install.packages(c("optparse", "dplyr", "tidyr", "tibble", "ggplot2", "jsonlite", "RColorBrewer", "pheatmap"))
if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager")
BiocManager::install("GSVA")
```

Notes:

- `GSVA` is obtained from Bioconductor rather than CRAN.
- `DESCRIPTION` documents both the package list and the additional repository used for installation.
- For the current skill release, `gsva` is documented with validated kernels only. `Gaussian` is the confirmed baseline in the audited environment.

## CLI Examples

### Example 1: Basic analysis

```bash
Rscript scripts/main.R \
  --input_file ./expression_matrix.csv \
  --group_file ./group_info.csv \
  --gene_set ./immune_gene_sets.csv \
  --case_group treatment \
  --control_group control \
  --output_dir ./output
```

### Example 2: Disable plot generation

```bash
Rscript scripts/main.R \
  --input_file ./expression_matrix.csv \
  --group_file ./group_info.csv \
  --gene_set ./immune_gene_sets.csv \
  --case_group treatment \
  --control_group control \
  --output_dir ./output \
  --make_plots false
```

When `--make_plots=false`, CSV outputs, `run_record.txt`, `output_manifest.txt`, `session_info.txt`, and `ssgsea_list.rds` are still produced, but PDF plot files are intentionally omitted.

### Example 3: Explicit column selection

```bash
Rscript scripts/main.R \
  --input_file ./expression_matrix.csv \
  --group_file ./group_info.tsv \
  --gene_set ./immune_gene_sets.csv \
  --case_group treatment \
  --control_group control \
  --sample_col sample_id \
  --group_col class \
  --output_dir ./output
```

### Example 4: Validated GSVA baseline

```bash
Rscript scripts/main.R \
  --input_file ./expression_matrix.csv \
  --group_file ./group_info.csv \
  --gene_set ./immune_gene_sets.csv \
  --case_group treatment \
  --control_group control \
  --output_dir ./output \
  --method gsva \
  --kcdf Gaussian \
  --make_plots false
```

Do not assume every GSVA kernel behaves identically across package versions. In the current audited environment, `Gaussian` is the confirmed GSVA baseline.

## Baseline Real-Data Execution Record

This section records the real-data baseline used for delivery validation. The current baseline uses the packaged real dataset copied from the validated GSVA skill and should be refreshed whenever the baseline dataset changes.

### Environment

- Execution context: target container used for acceptance testing
- Command family: `Rscript scripts/main.R`, `Rscript tests/run_tests.R`, `Rscript tests/test_skill.R`
- Seed: `42`
- R runtime: recorded in `tests/output/session_info.txt` after a successful run
- Key packages: `GSVA`, `optparse`, `ggplot2`, `pheatmap`

### Input Files

- Public source series: `GSE44076`
- `tests/data/expression_matrix.csv`
- `tests/data/group_info.csv`
- `tests/data/immune_gene_sets.csv`
- Comparison: `Tumor` vs `Healthy`

### Input Summary

- Matrix type: gene-level expression matrix prepared from the public `GSE44076` source used by the validated GSVA skill
- Gene count in the recorded baseline run: `19,440`
- 148 samples total
- Two groups: `Tumor` (98) and `Healthy` (50)
- Immune gene sets derived from the Charoentong 2017 28-cell reference

### Baseline Command

```bash
Rscript scripts/main.R \
  --input_file tests/data/expression_matrix.csv \
  --group_file tests/data/group_info.csv \
  --gene_set tests/data/immune_gene_sets.csv \
  --case_group Tumor \
  --control_group Healthy \
  --output_dir tests/output \
  --seed 42
```

### Output Files

The authoritative output list is written automatically to `tests/output/output_manifest.txt`.

| File | Description | Content |
|------|-------------|---------|
| `tests/output/data/ssgsea_list.rds` | Serialized immune infiltration result object | Stores scores, aligned groups, selected case/control labels, retained expression matrix, cell annotations, and gene-set overlap summary |
| `tests/output/table/ssgsea_scores_long.csv` | Long-format immune infiltration scores | One row per cell type and sample with `ssgsea_score`, `group`, and annotation columns |
| `tests/output/table/ssgsea_scores_wide.csv` | Wide-format immune infiltration score matrix | Rows are immune cell types and columns are samples |
| `tests/output/table/ssgsea_group_compare.csv` | Group comparison summary | Includes `case_n`, `control_n`, `case_mean`, `control_mean`, `delta_mean`, `p_value`, `p_adj`, and `test_method` |
| `tests/output/table/immune_cell_correlation_matrix.csv` | Spearman correlation matrix | Pairwise immune-cell correlation coefficients |
| `tests/output/table/immune_cell_correlation_pvalue.csv` | Correlation p-value matrix | Pairwise p-values aligned to the correlation matrix |
| `tests/output/plot/immune_cell_composition_sample.pdf` | Sample-level composition plot | Stacked relative composition view across samples |
| `tests/output/plot/immune_group_boxplot.pdf` | Group comparison boxplot | Per-cell-type distribution plot comparing `Tumor` and `Healthy` |
| `tests/output/plot/immune_correlation_heatmap.pdf` | Correlation heatmap | Heatmap of immune-cell Spearman correlations with significance marks |
| `tests/output/plot/gene_immune_correlation_scatter_*.pdf` | Auto-selected scatter plot | Gene-versus-immune-cell association plot generated from the recorded baseline run |
| `tests/output/session_info.txt` | Session record | `sessionInfo()` output with R and package versions |
| `tests/output/output_manifest.txt` | Auto-generated manifest | Output inventory with descriptions |
| `tests/output/run_record.txt` | Auto-generated run record | Input parameters, runtime, CPU summary, GC note, and output summary |

### Runtime And Resource Usage

| Metric | Value |
|--------|-------|
| Recorded at | `2026-04-15 09:40:41` |
| Runtime seconds | `65.536` |
| CPU summary | `Requested parallel_sz=2; actual_parallel_sz=2.` |
| GC note | `GC used cells: Ncells=467.2, Vcells=161.9.` |
| Timeout setting | `0` |

Resource note:

- The recorded baseline run completed successfully in the container without timeout or abnormal failure.

### Recorded Result Summary

- The baseline run completed successfully on the packaged real dataset.
- `run_record.txt` captured the exact input parameters, including `method=ssgsea`, `kcdf=Gaussian`, `case_group=Tumor`, `control_group=Healthy`, and `seed=42`.
- `output_manifest.txt` confirmed the complete output inventory for the plotted baseline run, including data, tables, plots, and reproducibility files.
- The baseline recorded `19,440` genes, `148` samples, and `28` immune gene sets kept.
- `ssgsea_group_compare.csv` provided the documented Wilcoxon comparison fields for all retained immune cell types.
- The plotted baseline generated the expected composition, boxplot, heatmap, and one auto-selected scatter PDF.

Maintenance note:

- If `tests/run_tests.R` is used to validate output-directory reuse, an extra file named `plot/reused_heatmap.pdf` may appear in `tests/output/`; that file is expected in the test context and is not part of the primary workflow output set.

`Rscript tests/test_skill.R` can also be run directly. If the baseline outputs are missing, it automatically invokes `tests/run_tests.R` before validating the result files and their core structure.
