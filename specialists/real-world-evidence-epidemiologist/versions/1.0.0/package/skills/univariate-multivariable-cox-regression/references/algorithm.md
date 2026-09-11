# Algorithm Details

## Overview

This skill performs two related tasks:
- fit univariate and multivariable Cox proportional hazards models from a clinical cohort;
- render forest plots from the exported result tables.

The implementation is based on `survival::coxph` for regression and `forestplot::forestplot` for visualization.

---

## Input Processing

### Clinical Cohort Requirements

The analysis command expects a CSV file with sample IDs as row names and the following variable types:
- predictor columns listed in `--features`;
- one survival time column;
- one binary event column.

### Complete-Case Filtering

The script keeps only complete cases across all requested features plus the time and event columns.

If incomplete rows are removed:
- the filtered dataset is saved as `data/analysis_data.rds`;
- the modeled sample size is reported as `Total(N)` in the exported tables.

### Basic Validation

Before modeling, the script checks:
- required columns exist;
- survival time is numeric, finite, and greater than `0`;
- event coding is restricted to `0` and `1`;
- at least 10 complete samples remain;
- at least 2 events are present.

---

## Cox Regression Workflow

### 1. Univariate Analysis

For each requested feature, the skill fits:

```text
Surv(time_col, event_col) ~ feature
```

For every fitted term, the output table includes:
- hazard ratio `exp(coef)`;
- 95% confidence interval;
- Wald-test p-value.

For categorical predictors:
- the reference level is added as a row with empty HR and p-value fields;
- non-reference levels are reported as effect rows.

### 2. Multivariable Analysis

The multivariable model uses one of two feature sets:
- all univariate features with `p < 0.05`, if at least 3 such features exist;
- otherwise, all requested features.

The fitted model is:

```text
Surv(time_col, event_col) ~ feature_1 + feature_2 + ... + feature_k
```

The exported table reports:
- one row per fitted coefficient;
- `feature` as the source predictor name;
- `Characteristics` as the variable name for continuous terms or the level label for categorical terms.

---

## Statistical Formulas

### Cox Proportional Hazards Model

```text
h(t | x) = h0(t) * exp(beta1*x1 + beta2*x2 + ... + betap*xp)
```

Where:
- `h(t | x)` is the hazard at time `t` given covariates `x`;
- `h0(t)` is the baseline hazard;
- `beta` values are regression coefficients.

### Hazard Ratio

```text
HR = exp(beta)
```

Interpretation:
- `HR > 1`: higher hazard;
- `HR < 1`: lower hazard;
- `HR = 1`: no association.

### 95% Confidence Interval

```text
95% CI = exp(beta +/- 1.96 * SE(beta))
```

### P-value

P-values are taken from the Wald test reported by `summary(coxph_fit)`.

---

## Forest Plot Workflow

The plot commands do not refit Cox models. They read the exported result table and:
- parse the `HR (95% CI)` string into `mean`, `lower`, and `upper` values;
- prepend a table header row;
- render a one-page PDF forest plot.

Rows without effect estimates, such as categorical reference levels, remain in the label table but have no plotted confidence interval.

---

## Assumptions And Scope

This skill assumes:
- proportional hazards is appropriate for the clinical question;
- observations are independent;
- survival end points are already curated;
- feature coding is clinically meaningful.

This implementation does **not** automatically test proportional hazards assumptions, perform penalized Cox regression, or run stepwise variable selection.

---

## References

1. Cox DR (1972). Regression Models and Life-Tables. *Journal of the Royal Statistical Society: Series B*.
2. Therneau TM, Grambsch PM (2000). *Modeling Survival Data: Extending the Cox Model*.
3. Harrell FE (2015). *Regression Modeling Strategies*.
