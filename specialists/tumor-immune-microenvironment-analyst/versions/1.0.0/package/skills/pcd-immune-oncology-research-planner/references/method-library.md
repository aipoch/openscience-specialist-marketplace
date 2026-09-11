# Method Library
# pcd-immune-oncology-research-planner

---

## Expression and Survival Analysis

| Task | Preferred Options | Notes |
|---|---|---|
| Differential expression | limma / DESeq2 | limma common for TCGA + GEO harmonized workflows |
| Survival screening | survival / survminer | Univariate Cox before model shrinkage |
| Penalized modeling | glmnet | Canonical LASSO-Cox framework |
| Time-dependent ROC | timeROC / survivalROC | Report 1/3/5-year AUC carefully |
| Nomogram | rms | Advanced+ only when validation depth is adequate |

## Clustering and Visualization

| Task | Preferred Options | Notes |
|---|---|---|
| Consensus clustering | ConsensusClusterPlus | Use CDF + cluster stability to justify K |
| Dimensionality reduction | PCA / t-SNE / UMAP | On samples, not cells |
| Heatmap | pheatmap / ComplexHeatmap | Clinical annotation should be explicit |

## Immune and Pathway Analysis

| Task | Preferred Options | Notes |
|---|---|---|
| Immune infiltration | ssGSEA / GSVA / xCell / TIMER / MCPcounter / CIBERSORT-style methods | Advanced plans should use more than one approach |
| Functional enrichment | clusterProfiler / fgsea | Avoid overinterpreting broad pathway hits |
| TIDE | TIDE web framework or reproduced score input | Predictive context only |
| TMB | maftools or cohort mutation burden calculation | Mutation data required |

## Mutation and Drug Sensitivity

| Task | Preferred Options | Notes |
|---|---|---|
| Mutation summary | maftools | Standard tool for waterfall and burden summaries |
| Drug prediction | oncoPredict + GDSC | Computational hypothesis only |
| Cross-database support | PRISM / CTRP | Advanced robustness only |
| Protein validation | HPA | Useful for translational plausibility |

---

## Method-Selection Rules

- Use one primary method and name backup methods only when needed.
- Do not stack multiple immune tools in Lite unless the user explicitly requests robustness.
- Do not include nomogram / calibration unless there is enough validation depth.
- Do not turn oncoPredict output into therapeutic recommendation language.
