# Workflow Step Template
# two-sample-mr-exposure-screening-reference-grounded-research-planner-aligned

---

## 8-Field Step Template

Every step in the workflow output (Section D) must include all 8 fields. Do not omit any field. Do not replace detailed method descriptions with bare tool name lists.

## Dataset Disclaimer Rule

If any workflow step mentions a dataset, cohort, database, consortium, registry, GWAS source, or public resource, the workflow section must begin with the following line exactly once before the first step:

> **Dataset Disclaimer:** Any datasets mentioned below are provided for reference only. Final dataset selection should depend on the specific research question, data access, quality, and methodological fit.

This disclaimer is mandatory whenever data sources are mentioned in the workflow and must not be omitted, paraphrased away, or moved to another section.

```
Step Name:        Short descriptive label
Purpose:          What this step accomplishes in the overall pipeline
Input:            Exact GWAS datasets / exposures / outputs from prior steps needed
Method:           Specific tool(s) and calculation logic — explain WHY this choice over the main alternative(s)
Key Parameters / Decision Rules:   Thresholds, cutoffs, acceptance criteria — be specific
Expected Output:  File format + content description + what "success" looks like
Failure Points:   What could go wrong; how to detect it; what it looks like
Alternative Approaches:       Backup tool/method if primary fails or data doesn't support it
```

---

## Standard Step Sequence (adapt to selected pattern and config)

1. **Outcome and Exposure GWAS Selection**
2. **Instrument Extraction and LD Clumping**
3. **Harmonization and QC Review**
4. **IVW Primary MR Estimation**
5. **Complementary Estimator and Sensitivity Analysis**
6. **Reverse MR or MVMR Extension**
7. **Replication / Triangulation Review**
8. **Integrated Evidence, Limitations, and Claim-Boundary Summary**
