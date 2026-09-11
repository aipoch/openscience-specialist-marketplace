# Algorithm Notes

## Overview

This skill estimates relative immune infiltration from bulk RNA-seq data by scoring predefined immune-cell gene sets with `GSVA::gsva`.

## Core Method

1. Normalize gene identifiers according to `--gene_id_case`.
2. Align the expression matrix with the group file.
3. Filter immune gene sets by overlap with the expression matrix using `--min_sz`.
4. Run GSVA with the selected method:
   `ssgsea` or `gsva`.
5. Summarize immune scores by sample, compare case versus control groups, and compute immune-cell correlations.

## Statistical Summaries

- Group comparison uses the Wilcoxon rank-sum test.
- Immune-cell correlation uses Spearman correlation.
- Correlation heatmap significance markers are derived from pairwise p-values.

## Assumptions

- The input matrix contains bulk transcriptomic profiles, not single-cell counts.
- Rows are genes and columns are samples.
- Gene identifiers in the expression matrix and gene-set file refer to the same namespace after optional case normalization.
- ssGSEA scores are relative enrichment values, not absolute cell proportions.

## Interpretation

- Higher ssGSEA scores indicate stronger enrichment of the gene-set signature in a sample.
- Group-level shifts in a cell type suggest relative infiltration differences between the case and control cohorts.
- Correlation plots support hypothesis generation only; they do not establish causality.
