# GSVA Algorithm Notes

## Overview

This skill performs pathway-level differential analysis in two stages:

1. Gene Set Variation Analysis (GSVA or ssGSEA) converts a gene-by-sample expression matrix into a pathway-by-sample enrichment score matrix.
2. limma fits a linear model on the pathway score matrix to estimate pathway-level differences between `case_group` and `control_group`.

## Input Assumptions

- The expression matrix has genes as rows and samples as columns.
- The matrix contains normalized continuous values for the default `gsva` method with `kcdf=Gaussian`.
- The group file contains at least two samples in each comparison group.

## GSVA Stage

The GSVA stage maps each pathway to the genes present in the input matrix and computes an enrichment score for every sample-pathway pair.

- `--method gsva` uses the standard GSVA enrichment score.
- `--method ssgsea` switches to single-sample GSEA style scoring.
- `--min_sz` and `--max_sz` control the pathway size bounds.
- `--kcdf` selects the kernel used when estimating expression-level statistics.

The gene sets are downloaded from `msigdbr` according to:

- `--species`
- `--category`
- `--subcategory`

## Differential Analysis Stage

After scoring, the skill builds a design matrix with:

- control group as the reference
- case group as the comparison level

limma then applies:

1. `lmFit()`
2. `makeContrasts(case - control)`
3. `contrasts.fit()`
4. `eBayes()`
5. `topTable()`

The resulting table includes:

- `logFC`: pathway score difference between case and control
- `P.Value`: raw p-value
- `adj.P.Val`: Benjamini-Hochberg adjusted p-value
- `t`, `B`, and other limma statistics

## Top Pathway Export

`table/GSVA_enrichment_results_topN.csv` is created by:

1. Filtering `GSVA_diff.csv` at `adj.P.Val <= --fdr_threshold`
2. Ranking significant pathways by adjusted p-value, then by absolute `logFC`
3. Falling back to the top pathways ranked by absolute `t` when no pathway passes the threshold

## Heatmap Generation

The heatmap is generated from `data/GSVA_list.rda`, which stores the `gsva_result` object.

- Samples are grouped by `case_group` and `control_group`
- Pathway labels are formatted for readability
- Optional subsetting can retain only top up-regulated or down-regulated pathways
- The color scale is centered around zero using symmetric breaks

## Reproducibility

- `set.seed(--seed)` is applied in the main entry script
- `session_info.txt` is written after analysis mode completes
- The heatmap reads the saved `gsva_result` object instead of recomputing analysis
