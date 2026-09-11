# LightGBM Algorithm Details

## What This Skill Does

This skill trains a LightGBM model on tabular data, evaluates the model on a held-out test set, and exports feature importance ranking results as a table and a plot.

## LightGBM Modeling Logic

### 1. Gradient Boosting Decision Trees

LightGBM belongs to the gradient boosting decision tree family.

- The first trees learn the rough decision pattern.
- Later trees focus on correcting earlier residual errors.
- The final model is an additive ensemble of many trees.

### 2. Leaf-Wise Tree Growth

LightGBM usually grows trees leaf-wise rather than level-wise.

- It expands the leaf that yields the largest loss reduction.
- This often improves accuracy on structured data.
- It also increases overfitting risk if `num_leaves`, `max_depth`, or `min_data_in_leaf` are not controlled.

### 3. Histogram-Based Splitting

Continuous feature values are bucketed internally into histograms.

- Training becomes faster.
- Memory use is lower.
- Split search is more efficient on large tabular datasets.

## Supported Tasks

### Regression

- Objective: `regression`
- Default metric: `rmse`
- Output metrics: `rmse`, `mae`, `r_squared`

### Binary Classification

- Objective: `binary`
- Default metric: `binary_logloss`
- Output metrics: `accuracy`, `auc`, `logloss`, `precision`, `recall`, `f1`

### Multiclass Classification

- Objective: `multiclass`
- Default metric: `multi_logloss`
- Output metrics: `accuracy`, `multi_logloss`

## Feature Importance Types

### Gain Importance

Gain importance is the total reduction in the objective loss contributed by splits using a feature.

- Better reflects actual predictive contribution.
- Usually preferred for ranking and reporting.
- More stable for interpretation than raw split counts.

### Split Importance

Split importance is the number of times a feature is used to split tree nodes.

- Useful for understanding tree usage frequency.
- Can overvalue features that are easy to split.
- Should not be interpreted as causal effect.

## Output Interpretation

### Feature Importance Table

- `feature`: feature name after selection
- `gain`: total gain from LightGBM
- `split`: split frequency from LightGBM
- `cover`: LightGBM cover statistic if returned by the package
- `importance_value`: ranking value based on `importance_type`
- `gain_share`: normalized gain share
- `split_share`: normalized split share
- `rank`: descending rank after sorting

### Feature Importance Figure

- The figure shows the top `N` features from the selected importance type.
- Default sorting uses `gain`.
- The plot is designed for direct use in reports or slides.

### Model Metrics

- Metrics are computed on the held-out test set, not on the training set.
- `best_iteration` comes from LightGBM early stopping.
- Split sizes are recorded in the metrics table for reproducibility.

## Task Inference Rules

When `--task_type auto` is used:

- Non-numeric targets are treated as classification.
- Two unique target values become `binary`.
- Integer-like numeric targets with only a small number of unique values become `multiclass`.
- Other numeric targets become `regression`.

If this heuristic does not match your dataset, set `--task_type` explicitly.

## Data Handling Rules

- Rows with missing target values are dropped.
- Missing feature values are left for LightGBM to handle.
- Character and factor features are integer-encoded.
- Identifier columns should usually be excluded with `--drop_cols`.

## Common Tuning Levers

### Model Complexity

- `num_leaves`: larger values increase model complexity.
- `max_depth`: controls tree depth and overfitting.
- `min_data_in_leaf`: larger values make the model more conservative.

### Optimization

- `learning_rate`: smaller values are usually more stable.
- `nrounds`: needs to be large enough when learning rate is small.
- `early_stopping_rounds`: stops training when validation performance no longer improves.

### Regularization and Sampling

- `feature_fraction`: randomly samples features per iteration.
- `bagging_fraction`: randomly samples rows per iteration.
- `lambda_l1` and `lambda_l2`: add regularization penalties.

## Important Limits

- Feature importance reflects model reliance, not causality.
- Correlated features may split or dilute importance.
- Integer-encoded categories are handled for LightGBM training, but interpretation should still respect the original categorical meaning.
