# Analysis Module Library
# nhanes-clinical-retrospective-biomarker-research-planner

---

## Epidemiology Core Modules

| Module | Purpose | When Required |
|---|---|---|
| Cohort selection and exclusion logic | Define valid NHANES/survey participants and analytic sample | Always |
| Disease / complication definition | Ensure outcome definition is explicit and reproducible | Always |
| Biomarker formula derivation | Prevent ambiguous biomarker construction | Always |
| Covariate architecture | Predefine confounders and avoid post hoc adjustment drift | Always |
| Missingness review | Detect bias from excluded or imputed variables | Lite+ |
| Baseline characteristics table | Describe disease vs non-disease differences | Lite+ |
| Exposure distribution review | Check biomarker distribution, skewness, and need for log-transform | Lite+ |
| Weighted survey declaration | Decide whether national representativeness is a formal claim | Advanced+ |

### Biomarker Formula Declaration Requirement

| Item | Required Content |
|---|---|
| Biomarker name | e.g., SIRI, SII, AISI, NLR, PLR |
| Formula | Explicit numerator / denominator formula |
| Transformation | Raw, log-transformed, quantiles, or standardized |
| Rationale | Why this biomarker family is appropriate for the disease context |

---

## Association Modeling Modules

| Module | Purpose | When Required |
|---|---|---|
| Crude logistic regression | Describe unadjusted biomarker–disease association | Always |
| Incremental adjusted models | Show confounder robustness across covariate sets | Standard+ |
| Quantile / tertile analysis | Improve clinical interpretability of association gradients | Standard+ |
| Trend testing | Support ordered-biomarker interpretation | Standard+ |
| Sensitivity covariate review | Test robustness to adjustment choices | Advanced+ |
| Weighted logistic modeling | Support nationally representative interpretation if declared | Advanced+ |

### Logistic Model Layering

| Model Layer | Typical Use |
|---|---|
| Crude | Initial association signal |
| Partially adjusted | Age / sex / race / core demographics |
| Fully adjusted | Demographics + key clinical confounders |
| Sensitivity model | Add or remove one confounder block to test robustness |

---

## Dose-Response and Heterogeneity Modules

| Module | Purpose | When Required |
|---|---|---|
| Restricted cubic spline (RCS) | Evaluate nonlinear biomarker-outcome relationship | Pattern B / D, Standard+ |
| Nonlinearity testing | Prevent overstatement of threshold effects | Standard+ |
| Prespecified subgroup analysis | Test stability across clinically relevant strata | Pattern C / D, Standard+ |
| Interaction testing | Distinguish visual subgroup drift from real effect modification | Advanced+ |
| Sparse-strata review | Prevent invalid subgroup interpretation | Standard+ |

### Preferred Subgroup Dimensions

| Subgroup | Why Commonly Used |
|---|---|
| Age | Baseline risk and biomarker distribution often differ |
| Sex | Inflammation and metabolic profiles may differ |
| Race / ethnicity | Survey-based epidemiology often requires heterogeneity review |
| BMI | Strong metabolic confounding risk |
| Smoking | Important inflammatory confounder |
| Hypertension / comorbidity | Frequent modifier in chronic-disease observational studies |

---

## Retrospective Clinical Validation Modules

| Module | Purpose | When Required |
|---|---|---|
| Single-center retrospective cohort | Provide orthogonal validation outside survey data | Pattern D |
| Matched case–control design | Reduce major imbalance in small clinical cohorts | Standard+ when retrospective cohort exists |
| Replicated multivariable logistic regression | Test directional and magnitude consistency | Pattern D |
| Preliminary ROC analysis | Explore discrimination as a secondary endpoint | Pattern E / D |
| Small-sample caution layer | Prevent overclaiming from unstable effect sizes or AUCs | Always when retrospective cohort exists |
| Albumin / disease-duration adjustment or equivalent | Improve clinical plausibility in validation cohort | Standard+ when relevant variables exist |

### Retrospective Validation Design Notes

| Design Choice | Why It Matters |
|---|---|
| Matching on age / duration or equivalent | Reduces obvious selection bias |
| Same-center case and control source | Improves internal consistency |
| Explicit exclusion criteria | Prevents etiologic mixing |
| ROC as secondary only | Avoids upgrading to a true prediction paper |

---

## Integration and Reporting Modules

| Module | Purpose | When Required |
|---|---|---|
| Evidence-label matrix | Separate association, validation, and screening-performance evidence | Always |
| Figure dependency map | Ensure logic flows from cohort definition to final endpoint | Standard+ |
| Risk and downgrade review | Control overclaiming and infeasible validation plans | Always |
| Literature support layer | Justify disease context, biomarker rationale, and methods | Always |
| Claim-boundary summary | Explicitly state what the paper can and cannot claim | Always |
