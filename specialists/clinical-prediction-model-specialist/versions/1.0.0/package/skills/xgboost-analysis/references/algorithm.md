# XGBoost Modeling And Feature Importance Details

## Method Overview

XGBoost is an implementation of gradient boosted decision trees. The final prediction is the sum of predictions from many trees:

```
y_hat_i = sum_k f_k(x_i)
```

Each new tree is trained to reduce the current loss while regularization penalizes overly complex trees.

## Objective Function

The optimization target is:

```
Obj = sum_i l(y_i, y_hat_i) + sum_k Omega(f_k)
```

Where:

- `l(y_i, y_hat_i)` is the training loss.
- `Omega(f_k)` penalizes tree complexity.

This skill relies on the `xgboost` R package and uses:

- `binary:logistic` for binary classification
- `reg:squarederror` for regression

## Task Detection

When `--task_type auto` is used, the script applies these rules:

1. If the target is numeric and has more than 10 unique values, treat it as regression.
2. Otherwise treat it as classification.

If this heuristic does not match the intended task, set `--task_type` explicitly.

## Data Handling

### Predictors

- Numeric predictors are used directly.
- Character and factor predictors are converted to factors.
- Missing categorical values are replaced with a sentinel level before one-hot encoding.
- One-hot encoding is performed with `Matrix::sparse.model.matrix`, which keeps memory use lower than a dense design matrix.
- If the first column is an unnamed identifier column such as `V1` and all values are unique sample IDs, it is automatically excluded from predictors.

### Target

- Rows with missing target values are removed.
- Regression requires a numeric target.
- Classification supports exactly 2 target classes.
- For binary classification, `--positive_class` can set which label maps to class `1`.

## Train-Test Split

- `--test_size` controls the holdout proportion.
- Classification uses a stratified split so each class is represented in both training and test sets when possible.
- Regression uses a random split.

## Performance Metrics

### Regression

- `rmse`: Root mean squared error
- `mae`: Mean absolute error
- `rsquared`: Coefficient of determination

### Binary Classification

- `accuracy`: Fraction of correct class predictions
- `logloss`: Binary cross-entropy
- `auc`: Area under the ROC curve

## Feature Importance

The skill exports aggregated original-feature importance in `table/<output_prefix>_feature_importance.*`.

Internally, categorical predictors may expand to several one-hot encoded columns, and the skill sums them back to the original feature before saving the final ranking table.

### Gain

`Gain` measures how much a feature improves the model objective when used for a split. This is usually the most informative ranking metric.

### Cover

`Cover` reflects the relative number of observations affected by splits using that feature.

### Frequency

`Frequency` counts how often a feature is used in splits.

## Interpretation Guidance

- High importance means the model relies on that feature, not that the feature is causal.
- Correlated predictors can split importance across multiple features.
- Categorical predictors may look weak at the encoded-column level but strong after aggregation.
- Importance rankings can shift with different random splits or tuning parameters.

## Recommended Reading Order

1. Run the skill with default settings.
2. Inspect `table/<output_prefix>_model_performance.*`.
3. Inspect `table/<output_prefix>_feature_importance.*`.
4. Open `figure/<output_prefix>_feature_importance_<metric>.png` for the ranking plot.
