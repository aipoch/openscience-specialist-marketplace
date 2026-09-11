# Analysis Module Library
# tumor-immune-infiltration-diagnostic-ml-research-planner

---

## Bulk-Transcriptome Core Modules

| Module | Purpose | When Required |
|---|---|---|
| Cohort selection and case–control definition | Define disease vs control comparison and compatible metadata | Always |
| Probe annotation / matrix harmonization | Convert probe-level data and standardize expression matrices | Microarray or mixed-platform contexts |
| Batch-effect handling and QC | Reduce technical variation before downstream modeling | Multi-cohort merge |
| Tumor vs control differential expression | Identify disease-associated transcriptional changes | Always |
| DEG visualization | Volcano / heatmap / candidate summary for interpretable screening | Lite+ |
| Clinical variable harmonization | Prepare stage / subtype / treatment variables for later model interpretation | Standard+ |

## Immune-Context Modules

| Module | Purpose | When Required |
|---|---|---|
| Immune deconvolution | Estimate immune-cell composition or immune-state scores | Always for immune-linked studies |
| Immune-cell group comparison | Identify which immune cells differ between case and control | Immune-cell-first or module-first patterns |
| Immune-linked correlation screen | Connect gene expression with immune-cell abundance or immune scores | Standard+ |
| Checkpoint / immune-signature context | Add interpretive immune context around selected biomarkers | Standard+ |

## Candidate-Derivation Modules

| Module | Purpose | When Required |
|---|---|---|
| WGCNA / coexpression modules | Find modules associated with immune cells or disease state | Standard+ |
| DEG ∩ immune-linked module intersection | Compress candidates into disease-and-immune relevant genes | Standard+ |
| PPI network prioritization | Highlight tightly connected genes / biological hubs | Optional but common |
| Enrichment analysis | Summarize biology of intersected or selected genes | Lite+ |

## Machine-Learning and Modeling Modules

| Module | Purpose | When Required |
|---|---|---|
| LASSO logistic feature reduction | Reduce correlated predictors for diagnostic classification | Pattern C / D |
| SVM-RFE feature ranking | Alternative / complementary feature reduction | Standard+ |
| Random Forest importance ranking | Nonlinear feature prioritization | Standard+ |
| Consensus overlap strategy | Derive a compact diagnostic gene panel | Standard+ |
| Logistic regression classifier | Build interpretable diagnostic model | Standard+ |
| ROC / PR / calibration assessment | Evaluate diagnostic utility | Always once model exists |
| Nomogram construction | Convert predictors into clinically usable score display | Standard+ when clinically framed |
| Decision-curve analysis | Estimate clinical net benefit | Advanced+ |

## Extension Modules

| Module | Purpose | When Required |
|---|---|---|
| Survival association of selected genes | Add prognostic extension to diagnostic biomarkers | Only if survival data exist |
| Multivariable Cox follow-up | Test independent prognostic value | Advanced+ prognostic extension |
| GSEA / GSVA by high-vs-low biomarker group | Interpret biology of selected genes | Standard+ |
| HPA / protein / portal support | Add translational plausibility | Advanced+ |
| qPCR / IHC / tissue validation | Stronger reviewer-facing support | Publication+ or user requested |
