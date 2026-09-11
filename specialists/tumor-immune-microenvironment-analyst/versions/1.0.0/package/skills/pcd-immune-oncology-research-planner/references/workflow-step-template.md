# Workflow Step Template
# pcd-immune-oncology-research-planner

---

## Mandatory 8-Field Format for Every Step


## Dataset Disclaimer Rule

If any workflow step mentions a dataset, cohort, database, registry, GWAS source, or public resource, the workflow section must begin with the following line exactly once before the first step:

> **Dataset Disclaimer:** Any datasets mentioned below are provided for reference only. Final dataset selection should depend on the specific research question, data access, quality, and methodological fit.

This disclaimer is mandatory whenever data sources are mentioned in the workflow and must not be omitted, paraphrased away, or moved to another section.

```
Step Name:          Concise step title
Goal:               What this step is trying to establish
Input Required:     Exact data / metadata / gene set / model inputs needed
Method:             Primary method(s) and why they fit here
Decision Logic:     Why this step comes now; what threshold / branch determines next move
Output:             File / figure / table / object produced and what success looks like
Failure Points:     What can go wrong; how to detect it
Alternative Approaches: Backup method if primary approach fails
```

---

## Standard Step Sequence (adapt to selected pattern and config)

1. **Disease Cohort Selection and Harmonization**
2. **Curated PCD Gene-Set Assembly**
3. **Differential Expression and Survival Screening**
4. **Mechanism-Gene Correlation / CNV Context**
5. **Consensus Clustering**
6. **Subtype Survival and Clinical Comparison**
7. **Immune Infiltration and GSVA / ssGSEA**
8. **Cluster-Level Pathway Interpretation**
9. **Train / Test Split and Feature Shrinkage**
10. **LASSO + Multivariable Cox Risk Model**
11. **KM / ROC / External Validation**
12. **GO / KEGG / Hallmark Interpretation of Risk Groups**
13. **Mutation Landscape Profiling**
14. **Checkpoint / TIDE / TMB Context** *[Advanced+]*
15. **Computational Drug Sensitivity Prediction**
16. **Protein / Tissue Validation**
17. **Integrated Mechanistic and Translational Summary Figure**

---

## Step Ordering Rules

- Mechanism-gene selection must occur before clustering or model building.
- Clustering should generally precede final risk modeling when subtype discovery is a core aim.
- Risk modeling must be split from external validation.
- Immune and drug layers must be interpreted downstream of subtype or risk grouping.
- TIDE / TMB and drug outputs must be framed as context / hypothesis modules, not endpoint truth.

---

## Evidence-Claim Formula Requirement

Every step that makes an interpretive claim must explicitly declare its formula.

Examples:
- `Subtype survival difference only`
- `Risk score + external validation`
- `Immune infiltration + checkpoint panel`
- `Immune infiltration + TIDE/TMB predictive context`
- `Transcriptomic drug sensitivity hypothesis only`

Do not switch claim strength silently between sections.
