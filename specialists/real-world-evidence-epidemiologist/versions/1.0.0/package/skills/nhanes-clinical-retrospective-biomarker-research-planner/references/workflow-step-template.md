# Workflow Step Template
# nhanes-clinical-retrospective-biomarker-research-planner

---

## 8-Field Step Template

Every step in the workflow output (Section D) must include all 8 fields. Do not omit any field. Do not replace detailed method descriptions with bare tool name lists.


## Dataset Disclaimer Rule

If any workflow step mentions a dataset, cohort, database, registry, GWAS source, or public resource, the workflow section must begin with the following line exactly once before the first step:

> **Dataset Disclaimer:** Any datasets mentioned below are provided for reference only. Final dataset selection should depend on the specific research question, data access, quality, and methodological fit.

This disclaimer is mandatory whenever data sources are mentioned in the workflow and must not be omitted, paraphrased away, or moved to another section.

```
Step Name:        Short descriptive label
Purpose:          What this step accomplishes in the overall pipeline
Input:            Exact data / variables / formulas / outputs from prior steps needed
Method:           Specific tool(s) and model(s) — explain WHY this choice
                  over the main alternative(s)
Key Parameters /
Decision Rules:   Thresholds, cutoffs, acceptance criteria — be specific
Expected Output:  File format + content description + what "success" looks like
Failure Points:   What could go wrong; how to detect it; what it looks like
Alternative
Approaches:       Backup tool/method if primary fails or data doesn't support it
```

---

## Standard Step Sequence (adapt to selected pattern and config)

### Survey Definition and Main Association Block

1. **Survey Cohort Selection and Exclusion Logic**
2. **Disease Definition and Biomarker Formula Specification**
3. **Baseline Characteristics and Biomarker Distribution Review**
4. **Crude and Adjusted Logistic Regression**
5. **Quantile / Tertile Analysis**
6. **Restricted Cubic Spline Analysis** (Pattern B / D)
7. **Subgroup and Interaction Analysis** (Pattern C / D)

### Retrospective Validation Block

8. **Retrospective Cohort Assembly and Matching Logic** (Pattern D)
9. **Replicated Logistic Validation in Clinical Cohort** (Pattern D)
10. **Preliminary ROC Analysis** (Pattern E / D)

### Integration Block

11. **Integrated Evidence, Limitations, and Claim-Boundary Summary**

---

## Step Ordering Rules

- Disease definition and biomarker formulas must be declared before any model.
- Main adjusted models must precede spline and subgroup interpretation.
- ROC must be downstream of the retrospective cohort, not the survey cohort.
- Retrospective validation claims must be clearly separated from main survey claims.
- If the plan is NHANES-only, retrospective steps must be omitted.
- If weighted analysis is not declared, do not imply national-representativeness claims beyond the chosen approach.

---

## Intersection Formula Requirement

Every endpoint-selection step must explicitly declare its logic formula. Do not omit this or switch formulas silently between configurations.

```
Intersection Formula: [e.g., disease definition + biomarker formula + adjusted logistic association]
Dependency Check:     [list what data/analyses this formula requires]
```

If a formula requires a resource not declared in the configuration (for example retrospective validation or ROC), use the reduced formula and note the limitation.

---

## Upgrade-Only Module Labeling

When the Step-by-Step Workflow for Advanced or Publication+ introduces a module not present in Lite/Standard, label it explicitly:

```
[UPGRADE-ONLY — Advanced+]
Module: e.g., Retrospective matched validation
Newly Introduced: Yes
Reason for Addition: Strengthens orthogonal consistency and reviewer defensibility
New Evidence Tier Enabled: Orthogonal validation evidence
```

Do not back-propagate upgrade-only modules into the Lite or Standard sections.
