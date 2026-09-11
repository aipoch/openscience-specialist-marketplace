# Method Library
# tumor-immune-infiltration-diagnostic-ml-research-planner

---

## Bulk Transcriptome Analysis Tools

### Primary Differential Expression Pipelines
| Tool | Language | Use Case |
|---|---|---|
| DESeq2 | R | **Recommended for count-based RNA-seq differential expression** |
| limma | R | **Recommended for non-count normalized matrices, microarray-like matrices, and voom-transformed counts** |
| edgeR | R | Alternative count-based DEG pipeline; useful in some small-sample contexts |
| sva / ComBat | R | Batch-effect handling for merged public datasets |

### Immune Infiltration / Immune Context
| Tool | Strength |
|---|---|
| CIBERSORT | Cell-fraction estimation for immune-cell composition |
| ssGSEA / GSVA | Gene-set / immune-program scoring across samples |
| xCell | Broader cell-type enrichment context |
| MCP-counter | Robust score-based immune / stromal quantification |

### Coexpression and Candidate Compression
| Tool | Use |
|---|---|
| WGCNA | Module detection linked to immune-cell abundance or phenotype |
| STRING | PPI support for intersected candidates |
| Cytoscape / cytoHubba | Network visualization and hub prioritization |
| clusterProfiler | GO / KEGG enrichment for candidate genes |

### Diagnostic Modeling and Feature Selection
| Tool | Approach |
|---|---|
| glmnet | LASSO / elastic-net feature reduction |
| e1071 / caret | SVM-RFE and modeling workflows |
| randomForest | Nonlinear importance ranking |
| glm | Logistic regression classifier |
| pROC / ROCR | ROC, AUC, cutoff optimization |
| rms | Nomogram and calibration support |
| rmda / dcurves | Decision-curve analysis |

### Prognostic Extension (Optional)
| Tool | Approach |
|---|---|
| survival | Cox regression, Kaplan–Meier |
| survminer | KM visualization |
| timeROC | Time-dependent ROC for prognostic follow-up |
