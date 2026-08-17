# Statistics and Model Risk Rules
# result-reliability-checker

---

## Goal

This module prevents the skill from mistaking attractive metrics or significant p-values for robust evidence.

---

## Required Audit Areas

### 1. Sample Size vs Analytical Burden
Check whether the sample size, event count, feature count, subgroup count, or model complexity are proportionate.

### 2. Multiple Testing / Search Burden
Check whether many hypotheses, features, thresholds, models, or subgroup scans were tried.
If yes, determine whether the paper controlled or acknowledged the resulting optimism risk.

### 3. Effect Size and Precision
Check whether the paper reports only significance or also interpretable effect sizes and uncertainty.
Wide intervals, unstable coefficients, or shifting estimates should lower confidence.

### 4. Model Stability and Overfitting
For predictive or classification work, check:
- training/test separation quality
- cross-validation discipline
- hyperparameter tuning isolation
- calibration reporting when relevant
- whether performance is suspiciously high relative to sample size and design

### 5. Metric Interpretation
Check whether the chosen metric actually supports the claim.
Examples:
- AUROC alone does not prove calibration or clinical usefulness.
- Accuracy can be misleading in imbalanced data.
- Small p-values do not rescue poor design.

---

## Strong Rules

- Statistical significance alone never earns a high reliability judgment.
- Small samples with complex models require explicit caution.
- Internal resampling does not erase overfitting risk by itself.
- If the metric does not match the claim, downgrade confidence.
