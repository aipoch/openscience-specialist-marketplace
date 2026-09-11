# Algorithm

## Overview

This skill performs immune pathway enrichment analysis from a bulk expression matrix with either GSVA or ssGSEA and then applies `limma` to compare two sample groups.

## Inputs

- Gene expression matrix with genes as rows and samples as columns
- Sample group file with one row per sample
- Local immune gene-set table in long format with one pathway-gene mapping per row

## Gene-Set Construction

The workflow reads a local long-format table and converts it to a named list:

```r
gene_sets <- split(geneset_df$gene_symbol, geneset_df$gs_name)
```

Each list element corresponds to one immune pathway and contains the member genes used by `GSVA::gsva()`. Duplicate genes within the same pathway are removed before scoring.

## GSVA Or ssGSEA Scoring

GSVA transforms a gene-by-sample matrix into a pathway-by-sample matrix. For a gene set `S` and sample `j`, the method estimates a pathway activity score:

```text
score(S, j) = enrichment of the empirical expression distribution of genes in S relative to genes not in S
```

Key assumptions:

- Expression values are already normalized and comparable across samples
- Gene identifiers in the matrix and gene-set table use the same symbol namespace
- The pathway activity signal is better represented at the gene-set level than by single genes

`ssgsea` is supported through the same CLI with `--method ssgsea`.

## Differential Analysis

After scoring, the workflow fits a two-group linear model:

```text
score_pathway ~ 0 + group
```

The contrast is defined as:

```text
case_group - control_group
```

`limma` computes moderated statistics for each pathway and returns:

- `logFC`
- `t`
- `P.Value`
- `adj.P.Val`
- `B`

## Top Pathway Selection

Top pathways are selected in this order:

1. Keep pathways with `adj.P.Val <= fdr_threshold`
2. Rank by ascending `adj.P.Val` and descending `abs(logFC)`
3. Keep up to `top_n`
4. If no pathway passes the threshold, fall back to the top pathways ranked by `abs(t)`

## Heatmap Logic

The heatmap is generated from the saved result object.

- Default color palette is a three-color diverging gradient
- Samples are ordered with `case_group` first, then `control_group`
- Optional row labels may include `logFC` and `adj.P.Val`
- PDF output is written only inside the validated output directory
- The graphics device is explicitly closed to prevent stray `Rplots.pdf` files

## Scope And Applicability

This workflow is appropriate for:

- Bulk RNA-seq pathway scoring
- Microarray-like expression matrices
- Immune pathway comparison between two predefined groups

This workflow is not appropriate for:

- Single-cell data without aggregation
- Immune cell deconvolution
- Clinical diagnosis
- Survival modeling without a predefined two-group comparison

## Result Interpretation

- Positive `logFC` means the pathway is more active in `case_group`
- Negative `logFC` means the pathway is more active in `control_group`
- `adj.P.Val` controls the false discovery rate across pathways
- Heatmap clusters reveal sample-level pathway activity patterns, not direct causal mechanisms

## Recommended Gene-Set Source

For production use, prepare the immune Reactome table outside the main analysis script. A common approach is:

1. Download all human Reactome pathways from `msigdbr`
2. Filter pathway names with immune-related keywords
3. Export the filtered table as CSV

This preprocessing must stay outside the main skill workflow so the analysis script remains offline and auditable.
