# Algorithm Notes

## Method Overview

This skill performs two-class SVM-RFE style feature ranking with a linear support vector machine.

The workflow is:

1. Read a sample-by-feature matrix.
2. Read a sample-to-group mapping.
3. Validate that sample IDs match exactly and that exactly two groups are present.
4. Build stratified folds for reproducible outer cross-validation.
5. Rank features within each fold by recursively eliminating the weakest linear SVM features.
6. Aggregate fold-specific rankings into a single average ranking.
7. Estimate classification error across the top `1..N` ranked features.
8. Select an optimal feature count using either the minimum error or a tolerance rule.
9. Export ranking tables and plots.

## Statistical Logic

SVM-RFE uses the linear support vector machine weight vector to assess feature importance. At each elimination step, the weakest features are removed and the model is retrained on the remaining features.

For a linear SVM decision function:

`f(x) = w^T x + b`

the magnitude of each component of `w` reflects the contribution of the corresponding feature to the separating hyperplane.

This implementation uses squared or normalized linear SVM weights to rank features. Smaller average ranks indicate higher importance.

## Ranking Procedure

- A stratified outer cross-validation split is generated from the binary group labels.
- Within each outer training fold, recursive elimination runs on the surviving feature set.
- If the surviving feature count exceeds `svm_halve_above`, half of the features are removed in one step; otherwise features are removed one at a time.
- Fold-specific feature orders are aggregated into an average-rank table.

## Error Curve and Feature Selection

After the global ranking is built, the skill evaluates cross-validated classification error for the top `1..svm_max_features_cap` ranked features.

Two feature-count rules are supported:

- `min`: choose the feature count with the minimum cross-validated error.
- `tolerance`: choose the smallest feature count whose error is within `svm_tol` of the minimum.

The selected feature count determines the rows written to `svm_rfe_features.csv`.

## Assumptions

- The task is binary classification only.
- Samples are rows and features are columns.
- Feature columns are numeric.
- The same samples must appear in both input files.
- Missing values are not supported.

## Applicability

Use this skill for:

- Binary biomarker or signature ranking
- Expression-derived classification feature selection
- Small to medium tabular datasets that fit in memory

Do not use this skill for:

- Multi-class classification
- Regression
- Time-series forecasting
- Preprocessing, normalization, or batch correction

## Result Interpretation

- Lower `AvgRank` means a feature survived elimination longer and ranked more strongly.
- `svm_rfe_features.csv` is the selected subset after applying the chosen feature-count rule.
- `svm_rfe_full_ranking.csv` is the complete ordered ranking across all features.
- The error plot helps judge whether adding more features improves or harms classification performance.
- SVM-RFE rankings are model-dependent and should not be interpreted as causal effects.

## Reproducibility Notes

- All stochastic behavior is controlled by `--seed`.
- `session_info.txt` captures the R runtime and package versions.
