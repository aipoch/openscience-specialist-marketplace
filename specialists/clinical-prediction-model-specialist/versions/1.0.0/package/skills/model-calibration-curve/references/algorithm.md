# Algorithm Details

## Overview

This skill evaluates calibration for a survival model by:
- fitting a Cox proportional hazards model with the requested predictors;
- generating bootstrap calibration curves at one or more prediction horizons;
- summarizing mean predicted and observed survival probabilities together with a concordance index.

The implementation uses:
- `survival::Surv()` for time-to-event outcomes;
- `rms::cph()` for Cox model fitting;
- `rms::calibrate()` for bootstrap calibration;
- `survival::concordance()` for the C-index.

---

## Data Preparation

### Required Columns

The input CSV must contain:
- all requested predictor columns;
- one survival time column;
- one event indicator column encoded as `0/1`.

### Complete-Case Filtering

Calibration is performed on complete cases across all required columns. Rows with missing values are removed before model fitting.

### Predictor Handling

- numeric predictors are kept as numeric;
- character predictors are converted to factors;
- survival time is coerced to numeric and must be strictly positive.

---

## Cox Model

For predictors `x1, x2, ..., xp`, the fitted model is:

```text
h(t | x) = h0(t) * exp(beta1*x1 + beta2*x2 + ... + betap*xp)
```

The skill builds a single Cox formula from the requested features and reuses that formula across calibration horizons.

---

## Bootstrap Calibration

For each requested horizon `u` in `--years`, the skill runs:

```r
rms::calibrate(
  fit,
  cmethod = "KM",
  method = "boot",
  u = u,
  m = group_size,
  B = bootstrap_reps
)
```

Where:
- `cmethod = "KM"` uses Kaplan-Meier estimation for observed survival;
- `method = "boot"` performs non-parametric bootstrap correction;
- `u` is the target prediction horizon in the same unit as the time column;
- `m` is a grouping size derived from the available sample count;
- `B` is the bootstrap replication count.

---

## Calibration Statistics

For each horizon, the skill records:
- `predicted_mean`: mean of the calibration object's predicted probabilities;
- `observed_mean`: mean observed survival estimate;
- `bias_corrected_mean`: mean bias-corrected observed survival estimate.

The skill also reports overall model metadata:
- selected features;
- fitted model formula;
- sample count;
- event count;
- C-index.

---

## Concordance Index

The concordance index is computed from the Cox linear predictor:

```r
lp <- predict(fit, type = "lp")
survival::concordance(Surv(time, event) ~ lp)$concordance
```

Interpretation:
- `0.5`: no discrimination;
- `0.6-0.7`: weak discrimination;
- `0.7-0.8`: acceptable discrimination;
- `>0.8`: strong discrimination.

---

## Assumptions And Limits

This workflow assumes:
- the survival endpoint is right-censored time-to-event data;
- predictors are already chosen and clinically meaningful;
- sample size and event count are adequate for bootstrap calibration;
- prediction horizons are expressed in the same units as the time column.

This skill does **not** perform:
- feature selection;
- nomogram construction;
- external recalibration;
- decision-curve or ROC analysis.
