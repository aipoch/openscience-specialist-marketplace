# Figure and Deliverable Plan
# tumor-immune-infiltration-diagnostic-ml-research-planner

---

## Standard Figure Set (7–8 figures)

| Figure | Content | Required From |
|---|---|---|
| **Fig 1** | Overall study workflow schematic | All configs |
| **Fig 2** | Cohort overview + preprocessing / PCA + tumor-control DEG landscape | All configs |
| **Fig 3** | Immune infiltration comparison across samples or groups | All configs |
| **Fig 4** | Immune-linked module discovery / correlation heatmap / candidate intersection funnel | Standard+ |
| **Fig 5** | Consensus ML feature-selection results (LASSO / SVM-RFE / RF / overlap) | Standard+ |
| **Fig 6** | Diagnostic utility: individual-gene ROC and/or final classifier ROC | All configs |
| **Fig 7** | Logistic model + nomogram + calibration / optional decision curve | Standard+ |
| **Fig 8** | Functional interpretation and optional prognostic extension | Standard+ |

---

## Advanced / Publication+ Extensions

| Figure | Content | Required From |
|---|---|---|
| **Fig 9** | External validation cohort performance and portability summary | Advanced+ |
| **Fig 10** | Protein / tissue / portal validation or immune-robustness comparison across tools | Advanced+ |
| **Fig 11** | Subtype / treatment-context / sensitivity analysis | Publication+ |

---

## Tables / Deliverables

| Deliverable | Minimum Requirement |
|---|---|
| Cohort table | Dataset source, platform, sample counts, case–control definition, metadata availability |
| DEG table | logFC, adjusted p-value, selection threshold |
| Immune comparison table | Immune-cell fractions or scores with significance summary |
| Candidate table | Candidate derivation logic and retained genes |
| ML feature table | Algorithm-specific retained genes and consensus result |
| Model performance table | AUC, sensitivity, specificity, calibration summary, validation cohort context |
| Risk / limitation table | Main assumptions, likely instability points, evidence tier labels |
