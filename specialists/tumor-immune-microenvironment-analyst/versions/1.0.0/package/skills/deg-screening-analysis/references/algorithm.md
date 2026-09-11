# Algorithm Details

## Overview

Differential Expression Gene Screening Analysis (Volcano Plot & Clustered Heatmap) performs a two-group comparison on an expression matrix and produces:
- a full differential expression table
- a screened DEG table
- a volcano plot
- a clustered heatmap of top upregulated and downregulated genes

The current implementation supports **limma** only.

## Statistical Method

### limma Two-Group Model

The workflow fits a linear model to each gene:

```text
Y = Xβ + ε
```

Where:
- `Y` is the expression value vector for one gene across samples
- `X` is the design matrix built from the two selected groups
- `β` is the coefficient vector
- `ε` is the residual error

The contrast is defined as:

```text
case - control
```

The script then applies empirical Bayes moderation through limma to stabilize variance estimates across genes.

## Output Statistics

For each gene, the full differential table includes:
- `logFC`: estimated log fold change for `case - control`
- `Pvalue`: raw p-value
- `Padj`: Benjamini-Hochberg adjusted p-value

The exported `table/Diffanalysis.csv` currently contains four columns:
- `name`
- `logFC`
- `P.value`
- `P.adj`

## DEG Screening Rule

A gene is classified as:
- `up` if `logFC > logfc_threshold` and selected p-value `< p_threshold`
- `down` if `logFC < -logfc_threshold` and selected p-value `< p_threshold`
- `no` otherwise

The selected p-value field depends on `--p_type`:
- `p` uses `Pvalue`
- `p.adj` uses `Padj`

## Volcano Plot Rule

The volcano plot is generated directly from the full differential table in memory.

For each gene:
- x-axis: `logFC`
- y-axis: `-log10(p_value)` using the same p-value mode selected by `--p_type`

The plot draws threshold lines at:
- `x = ±logfc_threshold`
- `y = -log10(p_threshold)`

Genes are displayed as:
- `Up` if significantly upregulated
- `Down` if significantly downregulated
- `Not` if not significant

## Clustered Heatmap Rule

The clustered heatmap uses the top `N` upregulated genes and top `N` downregulated genes ranked by the selected p-value.

Selection logic:
1. Keep genes with DEG class not equal to `no`
2. Rank `up` genes by p-value and keep the best `top_n`
3. Rank `down` genes by p-value and keep the best `top_n`
4. Extract their expression matrix from the original input
5. Order samples by case group first, then control group
6. Apply row scaling for the heatmap rendering step

If fewer than two genes remain after top-gene selection, the workflow skips heatmap rendering instead of treating the run as a failure.

## Input Assumptions

- The expression matrix is already normalized to a scale suitable for limma
- The analysis is strictly a **two-group comparison**
- Missing values are not allowed
- Each selected group must have at least two samples
- Sample IDs in the group file must overlap with expression matrix column names

## Current Scope and Limitations

Supported:
- bulk expression matrix DEG screening
- limma-based pairwise comparison
- volcano plot generation
- clustered heatmap generation
- auto-detection of sample and group columns in the group file

Not supported in the current code:
- multi-group contrasts
- DESeq2 / edgeR count-based modeling
- batch correction
- covariate-adjusted models
- single-cell workflows
