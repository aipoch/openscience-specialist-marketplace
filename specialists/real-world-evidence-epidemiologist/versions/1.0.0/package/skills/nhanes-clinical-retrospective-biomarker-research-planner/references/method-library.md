# Method Library
# nhanes-clinical-retrospective-biomarker-research-planner

---

## Survey and Observational Analysis Tools

### Primary Analysis Environments
| Tool | Language | Use Case |
|---|---|---|
| R | R | Preferred for NHANES data cleaning, logistic models, RCS, forest plots |
| Stata | Stata | Common alternative for survey-weighted epidemiology |
| SPSS | GUI-based | Acceptable for basic descriptive and logistic analysis, less flexible for advanced reproducible workflows |

### Descriptive and Baseline Comparison
| Tool | Purpose |
|---|---|
| tableone / gtsummary | Baseline table generation and descriptive summaries |
| ggplot2 | Distribution plots, forest plots, figure assembly |
| survey | Weighted descriptive summaries and weighted models |

### Regression and Model Building
| Tool | Approach |
|---|---|
| glm | Crude and multivariable logistic regression |
| survey::svyglm | Weighted logistic regression for NHANES-style analyses |
| rms | Regression modeling support, restricted cubic splines |
| splines / rms | Flexible spline modeling |
| broom | Clean coefficient table export for reproducible reporting |

### Subgroup and Interaction
| Tool | Strength |
|---|---|
| glm / svyglm with interaction terms | Formal effect-modification testing |
| forestplot / ggplot2 | Subgroup forest visualization |
| gtsummary | Clear subgroup result tabulation |

### ROC and Validation
| Tool | Strength |
|---|---|
| pROC | ROC curves and AUC estimation |
| timeROC | Not primary here; avoid unless true time-to-event design exists |
| MatchIt | Optional matching workflow for retrospective validation cohort |
| cobalt | Balance diagnostics if matching is used |

---

## Data Resources

### Survey and Public Population Datasets
| Resource | Coverage |
|---|---|
| NHANES / NCHS / CDC | Nationally representative U.S. health and nutrition survey data |
| UK Biobank / similar population cohorts | Optional non-NHANES expansion if explicitly requested |
| Other national health surveys | Use only if clearly compatible with the design |

### Clinical Validation Sources
| Resource | Content |
|---|---|
| Single-center hospital EHR / lab cohort | Small retrospective case–control validation |
| Institutional clinical database | Optional case ascertainment and lab extraction |
| Local diabetes or complication registry | Possible validation source if explicitly available |

### Reporting and Reference Frameworks
| Resource | Content |
|---|---|
| STROBE | Observational study reporting guidance |
| ADA / WHO / disease-specific definitions | Outcome-definition anchors when needed |

---

## Parameter Defaults and Decision Rules

| Parameter | Default | Notes |
|---|---|---|
| Biomarker transformation | log-transform if strongly right-skewed | Declare transformation explicitly |
| Quantile strategy | tertiles or quartiles | Choose based on sample size and interpretability |
| Main model type | logistic regression | Use weighted version only when national representativeness is part of the claim |
| Covariate minimum set | demographics + key disease-relevant confounders | Predeclare before modeling |
| Interaction testing | prespecified only | Avoid fishing across many strata |
| RCS knot strategy | 3–5 knots | Use only when continuous exposure and sample support it |
| ROC role | exploratory secondary endpoint | Do not upgrade to true prediction model without appropriate design |
| Matching ratio | 1:1 or 1:2 | Depends on retrospective cohort size |
