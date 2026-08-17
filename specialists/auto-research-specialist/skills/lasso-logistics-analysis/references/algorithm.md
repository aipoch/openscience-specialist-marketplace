# Algorithm Details

## Statistical Method

### 1. LASSO Logistic Regression

This skill fits a binomial generalized linear model with an L1 penalty using `glmnet`.

The objective is:

```
argmin(beta0, beta) [
  - log L(beta0, beta) / n + lambda * sum(|beta_j|)
]
```

Where:
- `L` is the binomial likelihood
- `lambda` controls the amount of shrinkage
- larger `lambda` values force more coefficients to exactly zero

### 2. Why LASSO

LASSO is useful when:
- the number of candidate features is moderate or high
- many features may be weak or redundant
- you want embedded feature selection and model fitting in one step

### 3. Cross-Validation

`cv.glmnet` evaluates a sequence of lambda values across `nfolds` folds.

Important outputs:
- `lambda.min`: lambda with minimum mean cross-validated loss
- `lambda.1se`: largest lambda within one standard error of the minimum

This skill reports coefficients at `lambda.min`.

### 4. Input Representation

The expression matrix is converted from:
- rows = features
- columns = samples

Into a modeling matrix with:
- rows = samples
- columns = selected features

The outcome is encoded as:
- `1` for `case_group`
- `0` for `control_group`

### 5. Interpretation Notes

- Non-zero coefficients identify features retained by the penalized model.
- Coefficient sign indicates association direction with the case class.
- Coefficients are conditional on the full penalized model and should not be interpreted as univariate effects.

### 6. Assumptions and Limitations

- Outcome must be binary.
- Samples in the group file must match matrix column names exactly.
- Features must be numeric and free of missing values.
- LASSO performs feature selection, but selected features may vary with sample composition and random fold assignment.
