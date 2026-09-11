# Algorithm Details

## Core Method

### 1. ConsensusClusterPlus

Consensus clustering estimates how stable sample partitions remain under repeated subsampling. For each candidate setting, the workflow:

1. Subsamples samples by `p_item`
2. Subsamples genes by `p_feature`
3. Clusters the subsampled matrix
4. Repeats the process for `reps` iterations
5. Aggregates co-clustering frequencies into a consensus matrix

The analysis evaluates these combinations:

- Distance metrics: `pearson`, `spearman`, `euclidean`, `maximum`, `canberra`, `minkowski`
- Clustering algorithms: `hc`, `pam`, `km`

Unsupported combinations are skipped automatically:

- `km` is only used with `euclidean`
- `hc` is not used with `maximum` or `minkowski`

## Gene Selection

### 2. Highly Variable Genes

Genes are ranked by median absolute deviation:

```text
MAD_i = median(|x_ij - median(x_i)|)
```

The top `top_n` genes are retained for clustering.

### 3. Custom Gene List

When `gene_selection=custom`, the provided gene list is intersected with the matrix row names. Only matched genes are retained.

## Data Transformation

### 4. Median Centering

If `center_data=TRUE`, each gene is transformed as:

```text
x'_ij = x_ij - median(x_i)
```

This emphasizes relative sample differences rather than absolute expression magnitude.

## Model Selection

### 5. PAC Score

The proportion of ambiguous clustering is computed from the empirical CDF of lower-triangle consensus values:

```text
PAC = CDF(0.9) - CDF(0.1)
```

Interpretation:

- Lower PAC: more stable clustering
- Higher PAC: more ambiguous clustering

The workflow selects the distance/algorithm/K combination with the minimum PAC.

## Outputs Used for Selection

- `Cluster_res.csv`: best K and minimum PAC for each method pair, with `is_best=TRUE` for the selected model
- `Consensus Matrix Plot.pdf`: heatmap for the selected K
- `CDF curve Plot.pdf`: CDF curves for the selected method

## Assumptions

- Expression matrix is genes x samples
- Disease-group samples are biologically comparable
- At least 3 disease-group samples are available
- The number of disease-group samples is not smaller than `max_k`
- Stability, not phenotype association, is the model selection criterion
