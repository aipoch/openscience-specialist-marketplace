# Algorithm Details

## Overview

This skill performs weighted gene co-expression network analysis (WGCNA) on a bulk expression matrix. The workflow filters variable genes, builds a co-expression network, detects modules, correlates modules with traits derived from the group file, and exports module-level summaries.

## Method Steps

### 1. Expression filtering by MAD

The script computes the median absolute deviation (MAD) for each gene:

```text
MAD_i = mad(x_i1, x_i2, ..., x_in)
```

Where `x_i*` are the expression values of gene `i` across samples.

Genes are retained when:

- their MAD is finite
- their MAD is greater than or equal to `max(quantile(MAD, mad_quantile), min_mad)`
- if `max_genes > 0`, only the top `max_genes` genes ranked by MAD are kept

This step reduces noise and focuses the network on variable genes.

### 2. Sample and gene QC

After filtering, the matrix is transposed into WGCNA format: rows are samples and columns are genes. The script then runs `WGCNA::goodSamplesGenes()` to detect problematic genes or samples. Flagged rows or columns are removed before network construction.

The filtered matrix must remain large enough for WGCNA. In the current implementation, the analysis stops if fewer than 4 samples or fewer than 20 genes remain.

### 3. Soft-threshold power selection

The script evaluates candidate powers:

```text
1, 2, ..., 10, 12, 14, ..., 30
```

using `WGCNA::pickSoftThreshold()`.

The chosen power is the first value that satisfies the requested scale-free topology fit threshold `soft_r2_cutoff`. If no power reaches the cutoff, a fallback power is selected according to sample size and `network_type`.

### 4. Network construction and module detection

Modules are built with `WGCNA::blockwiseModules()` using:

- `networkType = network_type`
- `TOMType = network_type`
- `minModuleSize = min_module_size`
- `mergeCutHeight = merge_cut_height`
- `corType = cor_type`

The adjacency concept in WGCNA is based on a soft-thresholded correlation:

```text
a_ij = |cor(x_i, x_j)|^beta
```

for unsigned networks, where `beta` is the chosen soft-threshold power.

The topological overlap matrix (TOM) is then used to cluster genes and define modules.

### 5. Trait encoding

The group column from the sample annotation file is converted into a one-hot encoded trait matrix:

```text
trait_data = model.matrix(~0 + group)
```

Each level of the group factor becomes one binary trait column.

### 6. Module-trait and gene-trait statistics

Two correlation modes are supported:

#### Pearson mode

- module-trait correlation: `cor(module eigengenes, trait_data)`
- gene-module membership: `cor(gene expression, module eigengenes)`
- gene-trait correlation: `cor(gene expression, trait_data)`
- p-values: `WGCNA::corPvalueStudent()`

#### Bicor mode

- robust biweight midcorrelation using `WGCNA::bicorAndPvalue()`
- preferred when outliers may distort Pearson correlation

### 7. Module ranking and export

Modules are ranked by the absolute value of their correlation with the selected trait:

```text
rank = order(|module_trait_cor|, decreasing = TRUE)
```

The `grey` module is excluded from ranking. The skill then exports either:

- user-requested module colors from `module_of_interest`, or
- the top `top_modules` ranked modules when `module_of_interest=auto`

For each exported module, the skill saves:

- a module membership vs trait significance scatter plot
- a gene table containing gene-trait correlation, p-value, module membership, and module membership p-value

## Key Assumptions

- The expression matrix is already normalized and suitable for correlation-based analysis.
- Rows are genes and columns are samples in the input file.
- The group file correctly maps all samples to biological groups.
- The retained gene set is large enough to support stable network construction.
- WGCNA is more appropriate for bulk expression profiling than for sparse single-cell matrices.

## Interpretation Notes

- Strong positive or negative module-trait correlations indicate modules associated with the encoded trait.
- `module_genes_<module>.csv` helps prioritize genes with both high module membership and strong trait association.
- TOM heatmaps are based on a sampled subset of genes when `tom_sample_size` is smaller than the retained gene count.
