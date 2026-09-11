# CLI Guide

## Install Dependencies

```r
install.packages("optparse")
install.packages(c("ggplot2", "ggpubr", "tidyr", "dplyr", "pheatmap"))
if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager")
BiocManager::install("estimate")
```

If your container uses a different internal package mirror policy, install `estimate` through the approved mirror for that environment before running the skill.

Public package note:

- `optparse`, `pheatmap`, `ggplot2`, `ggpubr`, `tidyr`, and `dplyr` are installed from CRAN
- `estimate` is installed from the public Bioconductor repository

## CLI Examples

### Example 1: Basic Run

```bash
Rscript scripts/main.R \
  --input_file ./expression_matrix.csv \
  --output_dir ./output \
  --gene_id_type GeneSymbol \
  --platform affymetrix \
  --seed 42
```

### Example 2: TSV Input

```bash
Rscript scripts/main.R \
  --input_file ./expression_matrix.tsv \
  --input_delimiter tsv \
  --output_dir ./tsv_output \
  --gene_id_type GeneSymbol \
  --platform affymetrix
```

### Example 3: Group-Wise ESTIMATE Boxplot

```bash
Rscript scripts/main.R \
  --input_file ./expression_matrix.csv \
  --group_file ./group_info.csv \
  --sample_column sample \
  --group_column group \
  --output_dir ./group_compare_output \
  --plot_file estimate_scores_boxplot.pdf \
  --heatmap_file estimate_scores_heatmap.pdf
```

### Example 4: Entrez ID Input

```bash
Rscript scripts/main.R \
  --input_file ./expression_matrix.csv \
  --output_dir ./entrez_output \
  --gene_id_type EntrezID \
  --platform illumina
```

## Baseline Real-Data Execution Record

This section records the completed container validation run used as the current delivery baseline.

### Environment

- Execution context: acceptance container at `/work/.opencode/skills/estimate-immune-score-analysis`
- Command family: `Rscript scripts/main.R`, `Rscript tests/run_tests.R`, `Rscript tests/test_skill.R`
- Seed: `42`

### Input Files

- Baseline matrix: `tests/data/expression_matrix.csv`
- Source of baseline matrix: copied from `cibersort-immune-infiltration-analysis/tests/data/expression_matrix.csv`
- Gene identifier type used in the baseline run: `GeneSymbol`
- Platform used in the baseline run: `affymetrix`

### Input Summary

- Input gene column: `gene`
- Gene count in the baseline run: `506`
- Sample count in the baseline run: `8`
- Matrix format: first column = gene identifiers, remaining columns = samples

### Baseline Command

```bash
Rscript scripts/main.R \
  --input_file tests/data/expression_matrix.csv \
  --output_dir tests/output \
  --gene_id_type GeneSymbol \
  --platform affymetrix \
  --seed 42
```

### Output Files

| File | Description | Content |
|------|-------------|---------|
| `tests/output/data/expression_input.tsv` | Prepared ESTIMATE input table | Tab-delimited matrix used by `filterCommonGenes()` |
| `tests/output/data/estimate_input.gct` | Filtered ESTIMATE input GCT | Gene-filtered matrix for ESTIMATE |
| `tests/output/data/estimate_score.gct` | Raw ESTIMATE score GCT | Score rows emitted by `estimateScore()` |
| `tests/output/table/estimate_scores.tsv` | Reformatted score table | One row per sample with score columns such as `ImmuneScore` |
| `tests/output/session_info.txt` | Session record | `sessionInfo()` output |
| `tests/output/output_manifest.txt` | Auto-generated manifest | Output list and descriptions |
| `tests/output/run_record.txt` | Auto-generated run record | Parameters, runtime, CPU time, GC snapshot, and output summary |

### Runtime And Resource Usage

| Metric | Value |
|--------|-------|
| Start time | `2026-04-17 03:07:28` |
| End time | `2026-04-17 03:07:28` |
| Elapsed time | `0.147 s` |
| User CPU time | `0.071 s` |
| System CPU time | `0.009 s` |
| Timeout setting | `0` |
| GC snapshot (Ncells) | `used 427,092 (22.9 Mb)` |
| GC snapshot (Vcells) | `used 893,126 (6.9 Mb)` |

Resource note:

- The baseline run completed without timeout, crash, or abnormal memory pressure in the container.

### Recorded Result Summary

- The baseline workflow completed successfully in the container.
- `Rscript tests/run_tests.R` passed end-to-end.
- `Rscript tests/test_skill.R tests/output` confirmed that all expected output files were present.
- `tests/output/table/estimate_scores.tsv` was generated successfully and the validation script confirmed that it contains the required `sample` and `ImmuneScore` columns.
- `tests/output/output_manifest.txt` and `tests/output/run_record.txt` were generated successfully and captured the baseline execution metadata.
- The ESTIMATE package log reported that the merged dataset included `435` genes, with overlap messages for `StromalSignature` and `ImmuneSignature`.

## Extended Visualization Validation

The current codebase was additionally validated with a sample group file to confirm ESTIMATE-specific plotting outputs.

```bash
Rscript scripts/main.R \
  --input_file tests/data/expression_matrix.csv \
  --group_file tests/data/group_info.csv \
  --output_dir tests/output \
  --gene_id_type GeneSymbol \
  --platform affymetrix \
  --seed 42
```

Validated additional outputs:

- `tests/output/plot/estimate_scores_heatmap.pdf`
- `tests/output/table/estimate_score_group_stats.csv`
- `tests/output/plot/estimate_scores_boxplot.pdf`

Observed result summary from the validated grouped run:

- The ESTIMATE score heatmap was generated successfully with `Healthy` and `Tumor` annotations.
- The ESTIMATE score boxplot was generated successfully for `ESTIMATEScore`, `ImmuneScore`, and `StromalScore`.
- `estimate_score_group_stats.csv` was generated successfully with columns `category`, `p.value`, and `up_group`.
- In the bundled test dataset, all three tested categories reported `p.value = 0.685714285714286`, so no category reached conventional statistical significance.
- The reported higher-median group for `ESTIMATEScore`, `ImmuneScore`, and `StromalScore` in this test run was `Healthy`.

### Maintenance Note

- For future delivery updates, replace this record with the new container run facts copied from `run_record.txt` and `output_manifest.txt`.
- Keep `SKILL.md` examples generic; place real delivery-specific execution facts here only.
