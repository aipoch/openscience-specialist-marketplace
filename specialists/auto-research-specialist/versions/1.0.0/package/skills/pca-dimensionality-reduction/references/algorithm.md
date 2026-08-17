# PCA Algorithm Details

## What PCA Does

Principal component analysis transforms a set of correlated numeric variables into a smaller set of orthogonal components. Each principal component is a linear combination of the original variables.

- `PC1` captures the largest possible variance.
- `PC2` captures the next largest variance under the constraint of being orthogonal to `PC1`.
- Later components continue the same pattern.

This skill uses base R `prcomp()`, which performs PCA through singular value decomposition for numerical stability.

## Mathematical Formulation

Given a centered data matrix `X` with `n` samples and `p` features:

```text
X = UDV^T
```

Where:

- `U` contains left singular vectors
- `D` contains singular values
- `V` contains right singular vectors

The principal component scores are:

```text
Scores = XV
```

The loading of feature `j` on component `k` is the coefficient from `V[j, k]`.

## Variance Metrics

For each component `k`:

```text
variance_k = sdev_k^2
proportion_k = variance_k / sum(all variances)
cumulative_k = sum(proportion_1 ... proportion_k)
```

These values are exported in the summary result file.

## Centering and Scaling

### Centering

If `--center_data true`, each selected feature is transformed by subtracting its mean:

```text
x_centered = x - mean(x)
```

Centering is usually recommended for PCA because it makes the analysis focus on variation rather than absolute magnitude.

### Scaling

If `--scale_data true`, each centered feature is divided by its standard deviation:

```text
x_scaled = (x - mean(x)) / sd(x)
```

Scaling is recommended when variables are measured on different ranges or units.

## Input Rules Used by This Skill

1. Rows are treated as samples.
2. Columns are treated as candidate features.
3. If `--feature_columns` is omitted, all numeric columns are used except the resolved sample ID column and optional group column.
4. Rows with missing or non-finite values in selected feature columns are removed before PCA.
5. Feature columns with zero variance are rejected because they do not contribute to PCA and can break scaling.

## Output Interpretation

### Summary Table

- `standard_deviation`: square root of component variance
- `variance`: variance explained by each component
- `proportion_variance`: fraction of total variance explained by each component
- `cumulative_variance`: running total of explained variance

### Scores Table

Each row is a sample projected into PCA space.

- Samples close together have similar multivariate profiles.
- Samples far apart differ across the selected features.
- Group separation in `PC1` and `PC2` can indicate structured differences.

### Loadings Table

Loadings show how strongly each original variable contributes to each component.

- Large positive or negative absolute values indicate strong influence.
- Features with similar sign on a component tend to increase together along that axis.
- Opposite signs suggest tradeoff patterns on that component.

### Top Loadings Table

This is a simplified ranking view of the most influential features per component, sorted by absolute loading value.

## Choosing the Number of Components

Common practical rules:

- Retain enough components to explain a high cumulative variance, often 70% to 90%.
- Inspect the scree plot for an elbow where explained variance begins to flatten.
- Keep the number of components aligned with the downstream task, such as clustering or visualization.

## Typical Use Cases

- Reduce feature dimensionality before clustering or modeling.
- Identify major axes of variation in transcriptomic, proteomic, or metabolomic data.
- Visualize sample similarity with `PC1` and `PC2`.
- Detect outliers or batch-like structure.

## Limitations

- PCA is linear and may miss nonlinear structure.
- Results can be sensitive to scaling choices.
- Missing values are handled by row removal in this skill, which can reduce sample size.
- PCA does not use class labels, so group separation in the score plot is descriptive rather than inferential.
