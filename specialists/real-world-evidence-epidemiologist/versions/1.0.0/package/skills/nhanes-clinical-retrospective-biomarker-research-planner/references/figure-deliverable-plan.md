# Figure and Deliverable Plan
# nhanes-clinical-retrospective-biomarker-research-planner

---

## Standard Figure Set (7–9 figures)

| Figure | Content | Required From |
|---|---|---|
| **Fig 1** | Overall workflow schematic: survey cohort → biomarker derivation → logistic models / RCS / subgroup → retrospective validation | All configs |
| **Fig 2** | Participant selection flowchart and exclusions | All configs |
| **Fig 3** | Baseline characteristics + biomarker distribution summary | Lite+ |
| **Fig 4** | Main logistic regression results: crude and adjusted OR summary | Standard+ |
| **Fig 5** | Quantile / tertile trend analysis and/or ordered-risk display | Standard+ |
| **Fig 6** | RCS dose-response plot | Pattern B / D, Standard+ |
| **Fig 7** | Subgroup / interaction forest plot | Pattern C / D, Standard+ |
| **Fig 8** | Retrospective validation association results | Pattern D / Standard+ |
| **Fig 9** | ROC curves for exploratory discrimination in retrospective cohort | Pattern E / D |

---

## Advanced / Publication+ Extensions

| Figure | Content | Required From |
|---|---|---|
| **Fig 10** | Weighted vs unweighted / sensitivity-model comparison | Advanced+ |
| **Fig 11** | Integrated evidence map / claim-boundary summary | Publication+ |
| **Fig 12** | Reviewer-facing methods and bias-control schematic | Publication+ |

---

## Supplementary Figure Expectations

| Supplementary Content | Notes |
|---|---|
| Full variable definitions and codebook mapping | Important for reproducibility |
| Full regression tables | Prevent selective reporting |
| All subgroup estimates and interaction p-values | Required when subgroup claims are made |
| Additional spline sensitivity outputs | Useful for reviewer robustness questions |
| Missingness summary and exclusion details | Important for survey-data transparency |
| ROC threshold table and uncertainty notes | Required when exploratory discrimination is reported |
| Matching details for retrospective controls | Important for Publication+ rigor |

---

## Intermediate Deliverable Checklist

**Phase 1 — Cohort and Variable Definition**
- [ ] Survey cycles selected
- [ ] Disease definition fixed
- [ ] Biomarker formulas fixed
- [ ] Covariate architecture fixed

**Phase 2 — Main Association Analysis**
- [ ] Baseline table complete
- [ ] Crude model complete
- [ ] Adjusted model set complete
- [ ] Quantile / trend analysis complete if used

**Phase 3 — Shape and Heterogeneity**
- [ ] RCS complete if used
- [ ] Subgroup analyses complete if used
- [ ] Interaction tests complete if used
- [ ] Claim-boundary notes drafted

**Phase 4 — Retrospective Validation**
- [ ] Cohort inclusion / exclusion logic complete
- [ ] Matching logic complete if used
- [ ] Replicated adjusted model complete
- [ ] ROC complete if used with preliminary framing

**Phase 5 — Manuscript Assembly**
- [ ] Figure order matches results logic
- [ ] Limitation language drafted
- [ ] Reference pack supports all used modules
- [ ] Evidence hierarchy labeled clearly

---

## Dependency Map Deliverable (mandatory)

Every final output must include a **Dependency Map / Evidence Map** as part of Section C.5. This is not a figure but a structured checklist that must appear before the step-by-step workflow.

### Required Format

```
Evidence Map — [Config Name]

PRESENT evidence layers:
- [list each declared data source and analysis method]

ABSENT evidence layers:
- [list what is NOT included in this configuration]

THEREFORE FORBIDDEN steps:
- [list downstream steps that cannot appear due to absent dependencies]

Endpoint formula used:
- [state the exact dependency formula]
```

This section must be generated for:
1. The recommended primary plan
2. The Minimal Executable Version (Section G)

If the two plans use different formulas, both must be stated separately.
