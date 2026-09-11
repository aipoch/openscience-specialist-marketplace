# Algorithm Details

## Overview

This skill evaluates the clinical utility of a binary prediction model by:
- fitting a logistic decision-curve model with `rmda::decision_curve()`;
- estimating net benefit across a threshold-probability grid;
- exporting both a decision curve and a clinical-impact curve.

---

## Input Requirements

The workflow expects a single clinical CSV file with:
- one binary outcome column encoded as `0/1`;
- one numeric predictor column used in the logistic DCA model;
- row names representing unique sample IDs.

The predictor can be a continuous score, linear predictor, or model-derived risk score. It does not have to be restricted to the `[0, 1]` range because `rmda::decision_curve()` internally fits a logistic model.

---

## Decision Curve Model

For outcome `Y` and predictor `X`, the skill fits:

```text
logit(P(Y = 1 | X)) = beta0 + beta1 * X
```

It then estimates net benefit across threshold probabilities `pt` from `0` to `1` using the user-defined step size `threshold_by`.

---

## Net Benefit

Decision-curve analysis compares the prediction model against default strategies such as treating all or treating none.

For threshold probability `pt`, net benefit is conceptually:

```text
NB(pt) = (TP / N) - (FP / N) * (pt / (1 - pt))
```

Where:
- `TP` = true positives;
- `FP` = false positives;
- `N` = total sample size.

If `--standardize_net_benefit` is enabled, the summary uses standardized net benefit (`sNB`) instead of raw net benefit (`NB`).

---

## Study Design Handling

### Cohort Design

For `study_design = cohort`, the observed outcome frequency in the dataset is used directly.

### Case-Control Design

For `study_design = case-control`, the skill requires `population_prevalence` so that net benefit can be adjusted to the target population prevalence.

---

## Clinical-Impact Curve

The clinical-impact curve visualizes:
- how many patients would be classified as high risk at each threshold;
- how many of those high-risk patients would truly experience the outcome.

The plot uses `population_size` and `n_cost_benefits` to control the visualization scale.

---

## Assumptions And Limits

This workflow assumes:
- the endpoint is binary rather than time-to-event;
- the predictor is numeric and informative enough to support logistic modeling;
- the selected study design matches the dataset context;
- the provided prevalence is appropriate when using a case-control design.

This skill does **not** perform:
- survival decision-curve analysis;
- multiclass decision analysis;
- external validation across multiple files;
- feature selection or multivariable model training from multiple predictors.
