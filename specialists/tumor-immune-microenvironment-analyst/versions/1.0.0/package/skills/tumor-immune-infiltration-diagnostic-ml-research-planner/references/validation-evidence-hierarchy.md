# Validation and Evidence Hierarchy
# tumor-immune-infiltration-diagnostic-ml-research-planner

---

## Evidence Tiers

### Association-Level Evidence (supportive — label explicitly as associative)

| Evidence | Source | What It Establishes |
|---|---|---|
| Tumor vs control DEG | DESeq2 / limma / edgeR | Differential expression — not diagnosis by itself |
| Immune infiltration correlation | CIBERSORT / ssGSEA / xCell / MCP-counter | Immune-context association — not mechanism |
| WGCNA module–trait association | WGCNA | Coexpression relevance — not causality |
| Enrichment / pathway results | clusterProfiler / GSEA / GSVA | Functional annotation — not proof of mechanism |
| PPI hub prioritization | STRING / Cytoscape | Network context — not validated centrality in vivo |

### Diagnostic-Level Evidence (stronger — label explicitly as diagnostic)

| Evidence | Source | What It Establishes |
|---|---|---|
| Single-gene ROC | pROC / ROCR | Screening-level diagnostic discrimination |
| Multi-gene classifier | glm / ML pipeline | Model-based diagnostic utility in the tested cohort |
| External validation ROC | independent cohort | Generalizability stronger than internal-only performance |
| Calibration / decision-curve analysis | rms / rmda | Clinical-model behavior beyond discrimination |

### Prognostic-Level Evidence (optional extension — label separately)

| Evidence | Source | What It Establishes |
|---|---|---|
| Kaplan–Meier split | survival / survminer | Survival separation for selected biomarker or score |
| Univariate Cox | survival | Survival association |
| Multivariable Cox | survival / rms | Independent prognostic contribution relative to included covariates |

### Mechanistic / Translational Support (supportive — not automatic proof)

| Evidence | Source | What It Establishes |
|---|---|---|
| HPA / protein expression | HPA | Protein-level plausibility |
| Small qPCR / IHC validation | in-house or external tissue set | Translational support |
| Immune-treatment response cohort | actual response-labeled dataset | Treatment-response relevance only if directly tested |

---

## Reviewer-Facing Rule

Do not collapse diagnostic evidence, prognostic evidence, immune-context evidence, and mechanism into one undifferentiated claim. Label each separately.
