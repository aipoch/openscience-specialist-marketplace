# Algorithm Details

## Method Overview

This skill fits a two-class random forest classifier with `randomForest::randomForest()` and reports feature importance for each variable.

The workflow is:

1. Read an expression-like feature matrix with samples in rows and features in columns.
2. Read a group file and identify the case/control labels.
3. Validate that the two files contain the same sample IDs.
4. Train a random forest classifier with a fixed random seed.
5. Rank variables by importance.
6. Export tables and plots.

## Statistical Logic

Random forest is an ensemble of classification trees trained on bootstrap samples of the input data.
At each split, the algorithm evaluates only a random subset of variables, which reduces tree-to-tree correlation and improves generalization.

For a feature matrix `X` and binary group labels `Y`, the fitted classifier aggregates predictions from many trees:

`f(x) = majority_vote(T1(x), T2(x), ..., Tntree(x))`

The skill uses the formula `Group ~ .`, where `Group` is a two-level factor built from the case and control labels.
The model is trained with:

- `ntree = --rf_ntree`
- `mtry = --rf_mtry` when provided
- `nodesize = --rf_nodesize` when provided
- `importance = TRUE`
- `na.action = stats::na.fail`

## Out-of-Bag Error

The random forest model records out-of-bag (OOB) error across trees.
Each sample is predicted only by trees that did not include that sample in their bootstrap draw.
This provides an internal estimate of classification error without requiring a separate validation split.

The skill exports the OOB and class-specific error curves to `plot/rf_error_plot.pdf`.

## Importance Metrics

The skill computes feature importance with `randomForest::importance()` using `type = --rf_imp_type`.

Supported values are:

- `type = 1`: Mean decrease in accuracy after permuting a feature
- `type = 2`: Mean decrease in node impurity (typically Gini decrease for classification)

After computing the importance matrix, the skill selects the reporting metric in this order:

1. `MeanDecreaseAccuracy`
2. `MeanDecreaseGini`
3. The first available importance column

The ranked export table contains:

- `Feature`
- `Importance`
- `Metric`

`rf_top_features.csv` is derived from the ranked table by:

- keeping only rows where `Importance > --rf_imp_threshold`
- retaining at most `--rf_top_n` rows

## Input Assumptions

This skill assumes:

- binary classification only
- samples are rows and features are columns
- the first column of each input file contains sample IDs
- all feature columns are numeric
- missing values are not allowed
- sample IDs must match exactly between the expression matrix and the group file
- each group must contain at least two samples

## Plot Generation

The skill creates two plots:

### 1. RF Error Plot

`plot/rf_error_plot.pdf` is generated from the model's error-rate matrix.
It shows the OOB curve together with class-specific error curves across the number of trees.
Most visual settings are exposed as CLI arguments, including axis labels, line size, alpha, colors, border style, and figure size.

### 2. RF Importance Plot

`plot/rf_importance_plot.pdf` is generated with `randomForest::varImpPlot()`.
The plot can be customized with CLI options controlling:

- sorting
- top-N variables shown
- label display
- point size and shape
- line color
- border display
- title and annotation display
- figure width and height

## Applicability

Use this skill for:

- biomarker-style feature ranking from a binary phenotype
- expression-derived classification features
- small to medium tabular datasets that fit comfortably in memory
- rapid screening of variables that contribute to a two-class classifier

Do not use this skill for:

- multi-class classification
- regression
- time-series modeling
- missing-value imputation
- normalization or batch correction
- remote data fetching

## Result Interpretation

- Higher importance values indicate features that contribute more strongly to the fitted classifier.
- OOB error is a useful internal estimate, but it is not a substitute for external validation.
- Importance values are model-dependent and should not be interpreted as causal effects.
- Features with low or negative permutation importance may contribute little signal or add noise under the fitted model.

## Reproducibility Notes

- All stochastic behavior is controlled by `--seed`.
- The session environment is recorded in `session_info.txt`.
- Output paths are constrained to remain inside the skill root.
- Plot-only mode reuses the existing `data/rf_result.rds` model bundle and regenerates the plots without retraining.
