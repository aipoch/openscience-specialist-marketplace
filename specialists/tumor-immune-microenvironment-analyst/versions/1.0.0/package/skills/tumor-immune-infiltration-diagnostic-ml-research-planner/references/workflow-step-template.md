# Workflow Step Template
# tumor-immune-infiltration-diagnostic-ml-research-planner

---

## 8-Field Step Template

Every step in the workflow output (Section D) must include all 8 fields. Do not omit any field. Do not replace detailed method descriptions with bare tool name lists.


## Dataset Disclaimer Rule

If any workflow step mentions a dataset, cohort, database, registry, or public resource, the workflow section must begin with the following line exactly once before the first step:

> **Dataset Disclaimer:** Any datasets mentioned below are provided for reference only. Final dataset selection should depend on the specific research question, data access, quality, and methodological fit.

This disclaimer is mandatory whenever data sources are mentioned in the workflow and must not be omitted, paraphrased away, or moved to another section.

```
Step Name:        Short descriptive label
Purpose:          What this step accomplishes in the overall pipeline
Input:            Exact data / files / outputs from prior steps needed
Method:           Specific tool(s) and algorithm(s) — explain WHY this choice
                  over the main alternative(s)
Key Parameters /
Decision Rules:   Thresholds, model settings, merge rules, exclusion rules, and branch conditions
Output:           Concrete output objects generated in this step
Why It Matters:   Why this step is necessary for the final study claim
Risks / Notes:    Likely pitfalls, hidden assumptions, and how to control them
```

---

## Step Granularity Rule

Do not collapse multiple analytical decisions into one oversized step. Use enough steps so that preprocessing, DEG, immune inference, candidate derivation, feature selection, modeling, validation, and interpretation are each understandable and auditable.
