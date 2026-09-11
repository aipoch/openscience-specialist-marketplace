# Algorithm Details

## Statistical Methods

### 1. Elastic Net Logistic Regression

Elastic net combines lasso and ridge penalties for binary classification. It works by:

1. Encoding the response as `0` (control) and `1` (case)
2. Building a sample-by-feature matrix from the input expression data
3. Fitting a penalized logistic regression model with `glmnet`
4. Shrinking coefficients toward zero as `lambda` increases

The objective function is:

```text
argmin_beta [-log L(beta) + lambda * ((1 - alpha) / 2 * ||beta||_2^2 + alpha * ||beta||_1)]
```

**Penalty meaning:**
- `alpha = 1`: lasso behavior
- `alpha = 0`: ridge behavior
- `0 < alpha < 1`: elastic net mixture

**Assumptions:**
- Input data is numeric
- Outcome is binary
- Samples in the group file match columns in the expression matrix

### 2. Cross-Validation

The skill uses `cv.glmnet` to select the regularization strength:

1. Splitting samples into cross-validation folds
2. Fitting the model repeatedly across a lambda path
3. Computing mean cross-validated loss (`cvm`)
4. Selecting lambda based on one of two rules

**Lambda rules:**
- `lambda.min`: lambda with minimum mean cross-validated loss
- `lambda.1se`: largest lambda within one standard error of the minimum loss

`lambda.1se` usually gives a sparser and more conservative model.

### 3. Automatic Alpha Selection

When `--alpha auto` is used, the skill evaluates multiple alpha values:

1. Parsing the candidate values from `--alpha_grid`
2. Reusing the same fold assignment across all alpha candidates
3. Running `cv.glmnet` once per alpha candidate
4. Comparing the minimum cross-validated loss for each candidate
5. Selecting the alpha with the best cross-validated performance

**Advantages:**
- Avoids manually choosing alpha in advance
- Keeps the comparison fair by reusing the same folds
- Works well for small-to-moderate sample sizes

**Important caveat:**
- `alpha = 0` is ridge, which does not produce sparse feature selection
- When the chosen alpha is `0`, this skill writes an empty `selected_features.csv` and keeps the full coefficient ranking in `model_coefficients.csv`

### 4. Feature Selection Rule

Selected features are defined as coefficients whose absolute value exceeds a small numerical tolerance at the chosen lambda, excluding the intercept.

If the chosen `alpha` is `0`, the workflow does not report selected features because ridge coefficients are dense by design.

The workflow:

1. Extracting coefficients from the fitted cross-validated model
2. Removing the intercept term
3. Keeping only coefficients whose absolute value exceeds a small numerical tolerance
4. Sorting selected features by absolute coefficient magnitude

If the chosen `alpha` is `0`, the workflow writes an empty `selected_features.csv` because ridge coefficients are dense by design.

**Interpretation notes:**
- Larger absolute coefficients indicate stronger contribution to the classifier
- Correlated features may enter or leave the model together
- Selected features are predictive, not necessarily causal

## Practical Considerations

### Standardization

If `--standardize TRUE`, `glmnet` standardizes features internally before fitting. This is usually recommended when features have different scales.

### Small Sample Sizes

With very small class sizes, elastic net can still run but model selection may be unstable. In these cases:

- Use caution when interpreting selected features
- Compare `lambda.min` and `lambda.1se`
- Consider repeated or nested resampling outside this skill if final performance estimation is critical
