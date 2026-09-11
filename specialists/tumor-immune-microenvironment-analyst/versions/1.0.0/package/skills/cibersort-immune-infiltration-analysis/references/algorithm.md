# Algorithm Notes

## Overview

This skill implements a local CIBERSORT-style deconvolution workflow based on the HQ reference code provided for this project. It does not call the hosted CIBERSORT web service. Instead, it reconstructs the algorithm in R using:

- `preprocessCore` for optional quantile normalization
- `e1071` for linear nu-SVR fitting
- `parallel` for optional model-selection parallelism

The default signature matrix is `tests/data/LM22.txt`.

## HQ Reference Workflow

### Step 1: Load the Signature Matrix And Mixture Matrix

- `X` is the signature matrix such as LM22.
- `Y` is the bulk expression matrix to deconvolve.

### Step 2: Optional Back-Transformation

- If the expression matrix passes a conservative non-negative low-range heuristic, the workflow applies `2^Y`.
- The heuristic checks several quantiles together rather than using only `max(Y) < 50`.
- This behavior is exposed by `--auto_unlog`.

### Step 3: Optional Quantile Normalization

- If `--qn true`, the script applies `preprocessCore::normalize.quantiles(Y)`.
- This matches the HQ reference workflow but may be environment-sensitive in some containers.

### Step 4: Gene Intersection

- Both matrices are sorted by gene name.
- Repeated genes are consolidated by taking the per-column maximum before downstream processing.
- Only overlapping genes between the signature and mixture matrices are retained.

### Step 5: Signature Standardization

- The signature matrix is standardized using the global mean and standard deviation of all entries:

```text
X_standardized = (X - mean(X)) / sd(as.vector(X))
```

### Step 6: nu-SVR Model Selection

For each mixture sample:

- The sample vector is standardized.
- Three linear nu-SVR models are fit with `nu = 0.25`, `0.5`, and `0.75`.
- Negative weights are truncated to zero.
- The model with the lowest RMSE is selected.

### Step 7: Empirical Null Distribution

- A null distribution is built from random vectors sampled from the mixture matrix values.
- For each permutation, the same nu-SVR model-selection process is run.
- The null distribution stores correlation values for empirical p-value estimation.

### Step 8: Final Output

Per sample, the algorithm returns:

- immune cell weights
- empirical `P-value`
- `Correlation`
- `RMSE`

## Output Interpretation

### Immune Cell Fractions

- Fractions are relative deconvolution weights after truncating negative coefficients.
- They are normalized to sum to one unless all candidate weights collapse to zero, in which case the implementation falls back to a uniform distribution for stability.

### Quality Metrics

- `P-value`: empirical estimate derived from the permutation null distribution
- `Correlation`: correlation between the reconstructed and observed mixture profile
- `RMSE`: root mean squared error between the reconstruction and the standardized sample vector

### Group Comparison

- The skill adds a Wilcoxon case-versus-control summary table for downstream interpretation.
- This table is an extra skill-layer summary, not part of the original HQ core code block.

### Correlation Heatmap Safety Rule

- If the correlation matrix contains non-finite values, the plotting helper replaces them with `0` for heatmap rendering only.
- The original tabular outputs remain the authoritative data source for downstream interpretation.

## Plotting Notes

- `immune_cell_composition_sample.pdf` visualizes per-sample immune fractions.
- `immune_group_boxplot.pdf` compares per-cell-type distributions between the case and control groups.
- `immune_correlation_heatmap.pdf` shows immune-cell correlations across samples.

For PDF generation, the heatmap is drawn on the target device before `dev.off()` is called. This avoids accidental `Rplots.pdf` creation and corrupted output files.
