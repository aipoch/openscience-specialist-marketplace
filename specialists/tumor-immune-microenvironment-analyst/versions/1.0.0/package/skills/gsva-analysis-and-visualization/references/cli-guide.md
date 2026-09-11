# CLI Guide

## Install Dependencies

```r
install.packages(c("optparse", "pheatmap"))
if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager")
BiocManager::install(c("GSVA", "limma", "msigdbr"))
```

## Example 1: Full Workflow

```bash
Rscript scripts/main.R \
  --mode full \
  --input_file tests/data/expr_matrix.csv \
  --group_file tests/data/group.csv \
  --case_group Tumor \
  --control_group Healthy \
  --species "Homo sapiens" \
  --category C2 \
  --subcategory KEGG \
  --output_dir ./output \
  --seed 42
```

## Example 2: Analysis Only

```bash
Rscript scripts/main.R \
  --mode analyze \
  --input_file tests/data/expr_matrix.csv \
  --group_file tests/data/group.csv \
  --case_group Tumor \
  --control_group Healthy \
  --species "Homo sapiens" \
  --category C2 \
  --subcategory KEGG \
  --top_n 30 \
  --fdr_threshold 0.1 \
  --output_dir ./analysis_only \
  --seed 42
```

## Example 3: Visualization Only

```bash
Rscript scripts/main.R \
  --mode visualize \
  --output_dir ./analysis_only \
  --plot_file custom_heatmap.pdf \
  --top_up 10 \
  --top_down 10 \
  --top_mode both \
  --append_stats TRUE \
  --width 16 \
  --height 10
```

## Example 4: ssGSEA Variant

```bash
Rscript scripts/main.R \
  --mode analyze \
  --input_file tests/data/expr_matrix.csv \
  --group_file tests/data/group.csv \
  --case_group Tumor \
  --control_group Healthy \
  --species "Homo sapiens" \
  --category C2 \
  --subcategory KEGG \
  --method ssgsea \
  --output_dir ./ssgsea_output
```

## Baseline Execution Record

This section records the completed real-data validation run that was used as the current delivery baseline.

### Environment

- Execution context: target container used for acceptance testing
- Command family: `Rscript scripts/main.R`, `Rscript tests/run_tests.R`, `Rscript tests/test_skill.R`
- Seed: `42`

### Input Files

- Public source series: `GSE44076`
- Expression matrix: `tests/data/expr_matrix.csv`
- Group file: `tests/data/group.csv`
- Matrix preparation: Affymetrix probe IDs were collapsed to gene symbols before the final baseline run
- Species/category/subcategory: `Homo sapiens`, `C2`, `KEGG`
- Comparison: `Tumor` vs `Healthy`

### Input Summary

- Sample groups: `Tumor` and `Healthy`
- Group sizes in the recorded baseline run: `Tumor = 98`, `Healthy = 50`
- Matrix type: gene-level expression matrix converted from the public `GSE44076` Affymetrix series matrix
- Gene count in the recorded baseline run: `19,440`
- Sample count in the recorded baseline run: `148`

### Baseline Command

```bash
Rscript scripts/main.R \
  --mode full \
  --input_file tests/data/expr_matrix.csv \
  --group_file tests/data/group.csv \
  --case_group Tumor \
  --control_group Healthy \
  --species "Homo sapiens" \
  --category C2 \
  --subcategory KEGG \
  --output_dir tests/output \
  --seed 42
```

### Output Files

| File | Description | Content |
|------|-------------|---------|
| `tests/output/table/GSVA_diff.csv` | Pathway-level differential results | Includes columns such as `geneset`, `logFC`, `P.Value`, `adj.P.Val`, `t`, and `B` |
| `tests/output/table/GSVA_enrichment_results.csv` | Full GSVA score matrix | Rows are pathways and columns are samples |
| `tests/output/table/GSVA_enrichment_results_topN.csv` | Top-pathway GSVA score matrix | Subset of pathways selected by `--top_n` and `--fdr_threshold` |
| `tests/output/data/GSVA_list.rda` | Serialized analysis object | Saved `gsva_result` object for visualization-only reuse |
| `tests/output/plot/GSVA_heatmap.pdf` | GSVA heatmap | Heatmap comparing pathway scores between `Tumor` and `Healthy` samples |
| `tests/output/session_info.txt` | Session record | `sessionInfo()` output with R and package versions |
| `tests/output/output_manifest.txt` | Auto-generated manifest | Append-only output list with one section per invocation in the same `output_dir` |
| `tests/output/run_record.txt` | Auto-generated run record | Append-only run history with parameters, runtime, CPU time, GC snapshot, and output summary |

### Runtime And Resource Usage

| Metric | Value |
|--------|-------|
| Start time | `2026-04-15 02:06:49` |
| End time | `2026-04-15 02:07:05` |
| Elapsed time | `16.250 s` |
| User CPU time | `14.078 s` |
| System CPU time | `0.727 s` |
| Timeout setting | `0` |
| GC snapshot (Ncells) | `used 8,317,763 (444.3 Mb)` |
| GC snapshot (Vcells) | `used 21,764,035 (166.1 Mb)` |

Resource note:

- The recorded baseline run completed without timeout, out-of-memory, or abnormal resource pressure in the target container environment.

### Recorded Result Summary

- The full workflow completed successfully in the container.
- `tests/test_skill.R` confirmed that all expected output files were present.
- The baseline used the `Tumor` and `Healthy` subset from `GSE44076` (`98` tumor samples and `50` healthy samples).
- The probe-level series matrix was converted to a gene-level matrix before running the GSVA skill.
- The generated `GSVA_diff.csv` contained pathway-level differential results for the `Tumor` versus `Healthy` comparison.
- `run_record.txt` and `output_manifest.txt` were generated successfully and used as the source of the baseline record above.
- Re-running `visualize` in the same `output_dir` appends a new section to both files instead of replacing the earlier full-workflow provenance.

### Maintenance Note

- If a later delivery uses a different real dataset, replace this record with the new command, input summary, output list, and result summary.
- If external datasets must be downloaded before running the skill, keep the acquisition procedure outside the script and document it here for delivery review.
- For future updates, do not paste the full terminal log into this file. Instead, copy the key fields from `run_record.txt` and `output_manifest.txt`, then summarize them into the sections above.
