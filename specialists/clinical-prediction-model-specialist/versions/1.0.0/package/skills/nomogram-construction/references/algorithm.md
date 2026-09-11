# Algorithm Details

## Overview

This skill builds a prognosis nomogram from survival-related clinical predictors using:
- an `rms::cph` Cox proportional hazards model;
- `rms::nomogram` to convert the fitted model into a point-based nomogram;
- a C-index to summarize model discrimination.

---

## Input Processing

### Clinical Cohort Requirements

The build mode expects a CSV file with:
- sample IDs as row names;
- one survival time column;
- one binary event column;
- at least 3 prognostic feature columns.

### Complete-Case Filtering

The script keeps only complete cases across requested features plus the time and event columns.

The filtered dataset is saved as `data/analysis_data.rds`.

### Basic Validation

Before fitting the model, the script checks:
- required columns exist;
- survival time is numeric, finite, and greater than `0`;
- event coding is restricted to `0` and `1`;
- at least 20 complete samples remain;
- at least 10 events are present.

---

## Cox-Based Nomogram Workflow

### 1. Fit The Survival Model

For predictors `x1, x2, ..., xp`, the skill fits:

```text
h(t | x) = h0(t) * exp(beta1*x1 + beta2*x2 + ... + betap*xp)
```

using `rms::cph()` with `x = TRUE`, `y = TRUE`, and `surv = TRUE`.

### 2. Define Survival Functions

For each requested prediction horizon `tp`, the skill constructs a survival mapping from the fitted model:

```text
S(tp | lp)
```

where `lp` is the linear predictor from the Cox model.

### 3. Build The Nomogram

`rms::nomogram()` converts the fitted model into a point-based scoring object:
- each predictor receives a points axis;
- total points map to survival probabilities at the requested time points.

---

## C-index

Model discrimination is summarized by the concordance index:

```text
C-index = P(predicted risk and observed event order are concordant)
```

The implementation uses `survival::concordance(..., reverse = TRUE)` because a larger Cox linear predictor implies higher risk and shorter survival.

Interpretation:
- `0.5`: no better than random ranking;
- `0.7+`: acceptable discrimination;
- `0.8+`: strong discrimination.

---

## Plotting Workflow

Plot mode reads the saved `.qs` bundle and renders the stored nomogram object to PDF.

The plotting step does not refit the survival model; it only visualizes the saved bundle.

---

## Assumptions And Scope

This skill assumes:
- proportional hazards is appropriate for the clinical question;
- predictors were selected before nomogram construction;
- time and event variables are already curated;
- the requested prediction horizons are clinically meaningful.

This skill does **not** perform:
- variable screening or feature selection from raw candidates;
- calibration analysis;
- ROC analysis;
- decision-curve analysis;
- external validation.

---

## References

1. Harrell FE (2015). *Regression Modeling Strategies*.
2. Iasonos A et al. (2008). How to build and interpret a nomogram for cancer prognosis. *Journal of Clinical Oncology*.
3. Balachandran VP et al. (2015). Nomograms in oncology: more than meets the eye. *The Lancet Oncology*.
