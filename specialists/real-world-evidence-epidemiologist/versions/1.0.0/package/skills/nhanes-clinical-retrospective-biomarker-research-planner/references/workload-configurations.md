# Workload Configurations
# nhanes-clinical-retrospective-biomarker-research-planner

---

## Lite

| Attribute | Detail |
|---|---|
| **Goal** | Rapid NHANES-style proof-of-concept biomarker association study |
| **Timeline** | 2–4 weeks |
| **Data** | One NHANES-like survey cohort with disease definition, biomarker variables, and core covariates |
| **Core Modules** | disease definition, biomarker formulas, baseline table, crude + one adjusted logistic model, limited interpretation |
| **Validation** | No retrospective validation required |
| **Figure complexity** | 4–5 figures: workflow, flowchart, baseline/distribution, main model, limited extension |
| **Strengths** | Fast, feasible, low barrier |
| **Weaknesses** | Limited robustness; no orthogonal validation |
| **Typical target** | Pilot report; early feasibility work; lower-burden observational manuscript |

---

## Standard

| Attribute | Detail |
|---|---|
| **Goal** | Complete NHANES biomarker observational paper with one coherent association story |
| **Timeline** | 1–2 months |
| **Data** | One survey cohort + full covariate set; optional small retrospective cohort |
| **Core Modules** | All Lite modules + incremental adjusted models, quantile/tertile analysis, one RCS or subgroup branch, explicit limitation control |
| **Validation** | One robustness branch; optional small retrospective direction validation |
| **Figure complexity** | 7–8 figures |
| **Strengths** | Meets typical reviewer expectation for conventional observational biomarker papers |
| **Weaknesses** | Still association-centered; limited translation |
| **Typical target** | Standard epidemiology / biomarker journals |

---

## Advanced

| Attribute | Detail |
|---|---|
| **Goal** | Stronger observational biomarker paper with richer robustness and orthogonal validation |
| **Timeline** | 2–3 months |
| **Data** | Standard data + retrospective clinical validation cohort + stronger sensitivity architecture |
| **Core Modules** | All Standard + RCS + subgroup / interaction review + replicated retrospective validation + stronger covariate and sensitivity checks |
| **Validation** | Survey robustness + orthogonal clinical direction validation |
| **Figure complexity** | 8–10 figures |
| **Strengths** | Better reviewer-proofing and stronger consistency across data sources |
| **Weaknesses** | More complexity; higher risk of overclaiming if boundaries are not controlled |
| **Typical target** | Stronger clinical epidemiology or translational observational journals |

---

## Publication+

| Attribute | Detail |
|---|---|
| **Goal** | Reviewer-facing, publication-oriented observational biomarker package |
| **Timeline** | 3–6 months |
| **Data** | Advanced data + stronger local-cohort rigor + integrated evidence and claim-boundary reporting |
| **Core Modules** | All Advanced + stronger matching logic, stricter limitation handling, integrated evidence map, more explicit ROC caveats, better reviewer-facing sensitivity architecture |
| **Validation** | Strongest observational rigor achievable without causal or predictive overreach |
| **Figure complexity** | 10–12 figures; publication-quality integrated summary figures |
| **Strengths** | Reviewer-proof structure; strongest paper logic in this family |
| **Weaknesses** | Major time investment; still not a causal or prospective design |
| **Typical target** | High-ambition observational or complication-biomarker journals |

---

## Config Selection Decision Tree

```
User wants results in < 1 month, public data only?
  → Lite (or Standard if output quality is critical)

User wants a conventional NHANES biomarker paper?
  → Standard (primary); Advanced (if retrospective validation exists)

User mentions spline / subgroup / richer validation / stronger reviewer-proofing?
  → Advanced

User mentions stronger local validation rigor, integrated evidence map, or higher publication target?
  → Publication+

User doesn't specify?
  → Default: Standard as primary, Lite as minimum, Advanced as upgrade path
```

---

## Dependency Consistency Rules

### Core Principle
A downstream step may appear **only if its prerequisite data source, evidence layer, and method family have already been explicitly included** in that same configuration.

### Mandatory Dependency Rules

1. **Retrospective-validation-dependent analyses** may appear only when the configuration explicitly includes at least one of:
   - hospital retrospective cohort
   - case–control or matched clinical cohort
   - clearly declared local validation dataset

2. If a configuration is defined as **NHANES-only / survey-only**, then downstream steps must remain limited to:
   - disease definition
   - biomarker derivation
   - logistic models
   - quantile / trend analysis
   - spline or subgroup characterization
   - descriptive and limitation analysis

   and must **not** introduce:
   - retrospective matched validation
   - ROC / AUC screening analysis
   - threshold optimization
   - claims of clinical screening utility

3. **Minimal Executable Version** must inherit only the modules declared in the Lite plan unless the skill explicitly states that this minimal version is being upgraded into a stronger variant.

4. **Publication Upgrade Version** may add new dependency-bearing modules, but each newly added module must be labeled as:
   - newly introduced
   - why it is being added
   - what new evidence tier it enables

### Required Self-Check Questions
Before finalizing any output, verify:
- Does any step require data that was never declared earlier?
- Does any ROC or threshold claim assume a validation cohort absent from the configuration?
- Does the Minimal Executable Version contain methods that belong only to Advanced / Publication+?
- Are all endpoint formulas logically valid given the available inputs?

If the answer to any of the above is yes, the plan must be revised before output.

### Intersection Formula Reference

Every endpoint-selection step must declare its exact logic formula. Valid examples:
- disease definition + biomarker formula + adjusted logistic association
- disease definition + biomarker formula + adjusted logistic association + RCS
- disease definition + biomarker formula + adjusted logistic association + subgroup stability
- disease definition + biomarker formula + adjusted logistic association + retrospective direction consistency
- disease definition + biomarker formula + adjusted logistic association + retrospective direction consistency + exploratory ROC

The skill must not switch from one formula to another silently.
