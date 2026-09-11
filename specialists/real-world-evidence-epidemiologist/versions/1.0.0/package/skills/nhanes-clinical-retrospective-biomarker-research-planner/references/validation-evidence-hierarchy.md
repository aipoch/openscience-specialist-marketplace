# Validation and Evidence Hierarchy
# nhanes-clinical-retrospective-biomarker-research-planner

---

## Evidence Tiers

### Association-Level Evidence (supportive — label explicitly as associative)

| Evidence | Source | What It Establishes |
|---|---|---|
| Crude biomarker–disease association | logistic regression | Initial prevalence association |
| Adjusted logistic association | multivariable model | Confounder-robust association under measured covariates |
| Quantile / tertile trend | ordered biomarker groups | Gradient-like prevalence association |
| Baseline group difference | descriptive comparison | Group-level difference, not independent association |

### Shape-Characterization Evidence (supportive — label explicitly as shape analysis)

| Evidence | Source | What It Establishes |
|---|---|---|
| Restricted cubic spline | rms / spline model | Whether adjusted association appears linear or nonlinear |
| Nonlinearity test | spline comparison | Whether nonlinearity is statistically supported |

### Orthogonal Validation Evidence (stronger — label explicitly as orthogonal validation)

| Evidence | Source | What It Establishes |
|---|---|---|
| Retrospective case–control replication | hospital cohort | Directional and magnitude consistency outside survey data |
| Matched validation design | matched retrospective cohort | Better control of gross imbalance in small validation cohorts |
| Repeated adjusted association | replicated multivariable model | More credible local clinical consistency |

### Preliminary Screening-Performance Evidence (exploratory — label explicitly as preliminary)

| Evidence | Source | What It Establishes |
|---|---|---|
| ROC / AUC | retrospective cohort | Exploratory discrimination signal |
| Threshold comparison | ROC-derived cut points | Preliminary reference only, not final clinical threshold |

---

## Validation Coverage by Config

| Validation Layer | Lite | Standard | Advanced | Publication+ |
|---|---|---|---|---|
| Within-survey association coherence | ✅ | ✅ | ✅ | ✅ |
| Quantile / trend or one robustness branch | Optional | ✅ | ✅ | ✅ |
| RCS or subgroup branch | — | Optional | ✅ | ✅ |
| Retrospective orthogonal validation | — | Optional | ✅ | ✅ |
| Matching / stronger local validation rigor | — | — | Optional | ✅ |
| Exploratory ROC | — | Optional | Optional | ✅ |
| Strong reviewer-facing limitation handling | — | ✅ | ✅ | ✅ |

---

## Article Coverage Matrix

| Pattern | Minimum Required Modules | Recommended Additional |
|---|---|---|
| Cross-sectional association | disease definition, biomarker formula, crude + adjusted logistic model | quantiles / trend |
| Dose-response / RCS | main adjusted model + continuous biomarker + spline analysis | sensitivity review |
| Subgroup-stability | prespecified subgroup models | interaction testing |
| NHANES + retrospective validation | main survey association + second cohort replication | matching logic + stronger caveats |
| Preliminary screening-performance | validation cohort + exploratory ROC | comparison across biomarkers |

---

## Self-Critical Risk Review Template

Every output plan must include a risk review covering:

1. **Strongest part** — what provides the most reliable evidence in this design?
2. **Most assumption-dependent part** — what assumption, if wrong, weakens the story most?
3. **Most likely bias source** — where do residual confounding or selection bias most easily enter?
4. **Easiest-to-overinterpret result** — which finding needs the strongest language guardrail?
5. **Likely reviewer criticisms** — what will reviewers challenge first?
6. **Fallback plan** — if association weakens after full adjustment or validation is unstable, what is the alternative design?

---

## Language Rules

- Association findings: "associated with prevalence", "supports an adjusted association", "shows a directionally consistent relationship"
- Shape findings: "supports a linear/nonlinear pattern", "suggests shape heterogeneity"
- Validation findings: "supports orthogonal consistency", "remains directionally consistent in retrospective validation"
- Screening findings: "shows preliminary discrimination signal", "exploratory ROC"

- **NEVER use:** "proves causality", "predicts future disease", "establishes screening utility", "confirms threshold" for observational cross-sectional evidence
- **ALWAYS state:** which evidence tier each claim belongs to

---

## Dependency-Aware Validation Rules

Every validation step must declare:
1. **What it proves** — be specific and bounded
2. **What it does not prove** — state the limitation explicitly
3. **What it depends on** — list the required upstream data or analysis

If the declared dependency is absent from the configuration, that validation step **cannot appear** in the plan.

### Examples

| Validation Step | Proves | Does Not Prove | Depends On |
|---|---|---|---|
| Adjusted logistic model | Confounder-robust prevalence association | Causality or prognosis | Disease definition + biomarker formula + covariates |
| RCS | Shape of association | True biologic threshold | Continuous biomarker + adjusted model |
| Retrospective replication | Orthogonal direction consistency | Population generalizability | Independent clinical cohort |
| ROC / AUC | Exploratory discrimination signal | Stable screening model | Validation cohort + binary outcome |

### Forbidden Combinations (without declared dependency)

- ROC or threshold claims without a retrospective validation cohort → **forbidden**
- Nonlinearity claims without continuous biomarker modeling → **forbidden**
- Strong subgroup conclusions without prespecified strata → **forbidden**
- Predictive or causal language from cross-sectional association alone → **forbidden**
