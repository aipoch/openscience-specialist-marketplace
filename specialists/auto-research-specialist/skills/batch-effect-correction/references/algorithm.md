# Algorithm Details

## Statistical Workflow

### 1. Input Validation and Alignment

The batch-correction workflow begins by validating both input files:

1. Confirming that the expression matrix and metadata files exist and are non-empty
2. Checking that gene IDs and sample IDs are non-empty and unique
3. Verifying that expression values are numeric and finite
4. Confirming that metadata contains sample, group, and batch information
5. Reordering expression columns to match metadata sample order
6. Dropping expression columns not listed in metadata, with a warning so the user can confirm the intended cohort subset

**Assumptions:**
- The first column of the expression matrix contains feature IDs
- Sample columns in the expression matrix correspond to metadata sample IDs
- Metadata may define the full cohort or a deliberate subset of the expression matrix
- At least 4 total samples are present
- At least 2 biological groups and 2 batches are present
- Each group and each batch contains at least 2 samples

### 2. Log Transformation Heuristic

The skill supports three transformation modes:

1. `yes`: always apply `log2(x + 1)`
2. `no`: keep the matrix unchanged
3. `auto`: infer whether transformation is needed

For `auto`, the current rule is:

```r
max(expr) > 50 || quantile(expr, 0.99) > 16
```

**Purpose:**
- Apply log transformation to large-scale raw-like values
- Avoid double-transforming already normalized microarray or log-scale matrices
- Reject negative values when forced log transformation is requested

### 3. ComBat Design Matrix

Batch correction is performed while preserving biological group structure using:

```r
model.matrix(~ group, data = metadata)
```

This design matrix provides ComBat with the biological grouping variable so that batch adjustment does not remove the main group-related signal of interest.

**Assumptions:**
- Group labels represent the biological factor to preserve
- Batch labels represent technical sources of variation to remove
- The design matrix is estimable because each group has at least 2 samples

### 4. Empirical Bayes Batch Correction

The core correction step uses `sva::ComBat`:

```r
sva::ComBat(
  dat = expr_mat,
  batch = metadata$batch,
  mod = build_combat_design(metadata),
  par.prior = TRUE,
  prior.plots = FALSE
)
```

ComBat works by:

1. Estimating batch-specific additive and multiplicative effects
2. Borrowing information across genes through empirical Bayes shrinkage
3. Removing technical batch structure while retaining modeled biological effects

### 5. Post-correction Normalization

After ComBat, the corrected matrix is normalized using:

```r
limma::normalizeBetweenArrays(corrected)
```

**Purpose:**
- Reduce residual cross-sample distribution differences
- Improve comparability across corrected samples
- Standardize the output matrix before downstream analysis

## Quality Control Outputs

The workflow generates paired diagnostics before and after correction:

1. Boxplots for sample-level distribution shifts
2. PCA scatter plots with batch-colored points; batch ellipses are added when batch size/covariance supports stable fitting
3. Hierarchical clustering plots for sample-level grouping structure

Ellipse overlays are drawn only for batches whose PCA coordinates have enough samples and a positive-definite covariance estimate. When those assumptions are not met, the scatter plot is still produced without ellipses so QC generation remains stable.

**Interpretation:**
- Effective correction should usually reduce separation driven primarily by batch
- Biological group structure should remain interpretable after correction
- QC plots should be reviewed before downstream differential expression or clustering analysis
