# Algorithm Details

## Overview

This Skill performs external validation of a fixed prognostic risk signature on an independent cohort with survival outcomes. The workflow assumes the model has already been trained elsewhere and only validates its performance on new data.

## Statistical Procedure

### 1. Input Harmonization

The analysis first aligns three data sources:

1. Expression matrix with genes as rows and samples as columns.
2. Clinical metadata with sample IDs as row names.
3. Model coefficient table containing the signature genes and their coefficients.

Only samples present in both expression and clinical tables are retained.

### 2. Risk Score Calculation

For each matched sample `i`, the linear predictor is:

```text
riskScore_i = sum(x_ig * beta_g)
```

Where:

- `x_ig` is the expression value of gene `g` in sample `i`
- `beta_g` is the coefficient supplied in `model_file`

This Skill does not standardize or re-fit coefficients. It uses the supplied model exactly as given.

### 3. Follow-up Time Conversion

The clinical `OS.time` column is converted to years before survival and ROC analysis:

- `day` input: divide by `365`
- `month` input: divide by `12`
- `year` input: unchanged

This is controlled by `--time_unit`.

### 4. Risk Group Assignment

Samples are split into two strata using the median risk score:

- `high`: `riskScore > median(riskScore)`
- `low`: `riskScore <= median(riskScore)`

This produces balanced groups in many cohorts and avoids an external cutoff dependency.

### 5. Kaplan-Meier Survival Analysis

Survival curves are generated with:

- `survival::Surv(futime, fustat)`
- `survival::survfit(... ~ risk)`
- `survminer::ggsurvplot()`

The survival figure includes:

- Kaplan-Meier curves
- confidence intervals
- log-rank p-value
- risk table

## Time-Dependent ROC Analysis

The Skill computes time-dependent ROC curves with `timeROC::timeROC`.

Inputs:

- `T`: follow-up time in years
- `delta`: event indicator (`OS`, expected 0/1)
- `marker`: continuous `riskScore`
- `times`: requested ROC horizons from `--roc_times`

Constraint:

- every requested ROC time must be strictly smaller than the cohort's maximum follow-up time

## Heatmap Generation

The heatmap is drawn from model genes only.

- expression values are extracted after sample matching
- genes with zero standard deviation are removed
- retained genes are scaled by row
- columns are kept in risk-score order

If all model genes have zero variance, the heatmap is skipped and a warning is logged.

## Minimum Data Requirements

The script enforces several minimum conditions before plotting:

- at least 4 matched samples
- at least 2 observed events (`OS == 1`)
- two distinct risk groups after median split
- finite, positive follow-up times
- no missing values after the final complete-case filter

## Assumptions

- Expression matrix and model coefficients are on compatible scales.
- Clinical survival endpoints are correctly encoded in `OS` and `OS.time`.
- The supplied signature is biologically meaningful and fixed before validation.
- Time-dependent ROC interpretation is appropriate for the cohort size and event count.

## Ethics and Governance

- This workflow is intended for research validation, not direct clinical use.
- Human cohort data should be de-identified before analysis.
- Local IRB, ethics, consent, and data-use requirements remain the operator's responsibility.

## Output Interpretation

- Stronger separation in `out_varifySurv.pdf` suggests better discrimination between risk groups.
- Higher AUC values in `out_varify.ROC.pdf` indicate stronger time-specific predictive performance.
- `out_varifyRisk.txt` is the main table for downstream audit, reproducibility checks, and manual inspection.
