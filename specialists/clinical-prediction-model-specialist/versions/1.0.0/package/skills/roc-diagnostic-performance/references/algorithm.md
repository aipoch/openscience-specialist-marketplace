# Algorithm Details

## Overview

This skill evaluates diagnostic biomarker performance from case-control expression data using:
- multivariable logistic regression for the combined diagnostic model;
- ROC curve analysis for the full model and each individual marker.

The implementation uses `stats::glm(..., family = binomial())` and `pROC::roc()`.

---

## Input Processing

### Expression Matrix

The expression matrix must contain:
- one gene identifier column;
- one column per sample;
- numeric expression values for the requested marker genes.

### Group File

The group file must contain:
- one sample ID column as the first column;
- at least one label column containing the case-control grouping.

### Sample Matching

Only the intersection of sample IDs shared by both files is retained. If unmatched samples exist, the skill warns and continues with matched samples only.

### Marker Filtering

The skill keeps only requested marker genes that exist in the expression matrix. Missing markers are reported as warnings. If none of the requested markers are found, the run stops.

---

## Logistic Regression Model

### Model Formula

For marker genes `x1, x2, ..., xp`, the skill fits:

```text
logit(P(Y = 1)) = beta0 + beta1*x1 + beta2*x2 + ... + betap*xp
```

Where:
- `Y = 1` indicates the case group;
- `Y = 0` indicates the control group.

### Odds Ratio

For each coefficient `beta`:

```text
OR = exp(beta)
```

The coefficient table also reports Wald-test standard errors, z statistics, p-values, and 95% confidence intervals for the odds ratio.

---

## ROC Analysis

### Full Model ROC

The full-model ROC curve is built from the fitted logistic regression probabilities:

```text
score_full = predict(glm_fit, type = "response")
```

### Single-Marker ROC

For each marker gene, the skill builds an ROC curve directly from that gene's expression values across matched samples.

### AUC

For every ROC curve, the skill reports the area under the curve (AUC):

```text
AUC = integral of sensitivity over 1 - specificity
```

Interpretation:
- `AUC = 0.5`: no diagnostic discrimination;
- `AUC = 1.0`: perfect discrimination.

---

## Assumptions And Scope

This implementation assumes:
- the data represent a binary case-control problem;
- marker values are measured on a comparable numeric scale;
- sample IDs are already harmonized across files;
- logistic regression is appropriate for the diagnostic question.

This skill does **not** perform:
- multiclass ROC analysis;
- calibration analysis;
- decision-curve analysis;
- feature selection or penalized logistic regression.

---

## References

1. Hosmer DW, Lemeshow S, Sturdivant RX (2013). *Applied Logistic Regression*.
2. Fawcett T (2006). An Introduction to ROC Analysis. *Pattern Recognition Letters*.
3. Robin X et al. (2011). pROC: an open-source package for R and S+ to analyze and compare ROC curves. *BMC Bioinformatics*.
