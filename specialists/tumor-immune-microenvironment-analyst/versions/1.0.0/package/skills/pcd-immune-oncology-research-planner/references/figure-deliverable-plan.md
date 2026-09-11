# Figure and Deliverable Plan
# pcd-immune-oncology-research-planner

---

## Standard Figure Set (7–9 figures)

| Figure | Content | Required From |
|---|---|---|
| **Fig 1** | Overall workflow schematic: curated mechanism genes → clustering → risk model → immune / mutation / drug modules | All configs |
| **Fig 2** | Differential expression and mechanism-gene landscape: volcano, correlation network, CNV summary | Lite+ |
| **Fig 3** | Consensus clustering outputs: CDF / consensus matrix / PCA-tSNE-UMAP / cluster heatmap | Standard+ |
| **Fig 4** | Cluster survival and immune/pathway differences | Standard+ |
| **Fig 5** | LASSO-Cox construction and Kaplan–Meier risk stratification | Standard+ |
| **Fig 6** | ROC / C-index / nomogram / external validation | Standard+ (C-index/nomogram Advanced+) |
| **Fig 7** | GO/KEGG or hallmark pathway results + mutation waterfall | Standard+ |
| **Fig 8** | Immune landscape: infiltration, checkpoint expression, TIDE/TMB context | Advanced+ |
| **Fig 9** | Drug sensitivity hypotheses + integrated mechanism model | Standard+ |

---

## Advanced / Publication+ Extensions

| Figure | Content | Required From |
|---|---|---|
| **Fig 10** | Multi-tool immune robustness comparison | Advanced+ |
| **Fig 11** | Subtype anchoring vs TCGA / ACRG / MSI / EBV / HER2 / Lauren classes | Advanced+ |
| **Fig 12** | Pan-cancer context or multi-cohort replication summary | Publication+ |

---

## Supplementary Figure Expectations

| Supplementary Content | Notes |
|---|---|
| Full gene list curation flow and source table | Critical for mechanism transparency |
| All Cox coefficients and shrinkage diagnostics | Reviewer expectation |
| Full immune panel results | Avoids cherry-picking |
| Complete mutation and pathway tables | Supplementary tables |
| Drug sensitivity complete ranking + uncertainty notes | Required if drug module used |
| Calibration / decision curve plots | Advanced+ translational claims |

---

## Intermediate Deliverable Checklist

**Phase 1 — Dataset and Gene-Set Preparation**
- [ ] Disease cohort selected and clinical endpoints confirmed
- [ ] Curated PCD gene set assembled from verified sources
- [ ] Expression matrix normalized and sample inclusion/exclusion recorded
- [ ] Tumor / normal and survival metadata harmonized

**Phase 2 — Core Mechanism and Clustering**
- [ ] Differential expression complete
- [ ] Survival-associated mechanism genes identified
- [ ] Consensus clustering complete with chosen K justified
- [ ] Cluster survival, heatmap, and dimensionality reduction figures ready

**Phase 3 — Risk Model**
- [ ] Train/test split or cross-validation plan declared
- [ ] LASSO and multivariable Cox complete
- [ ] Risk score formula explicitly documented
- [ ] KM + ROC complete
- [ ] External validation complete (Standard+)

**Phase 4 — Immune / Mutation / Pathway**
- [ ] ssGSEA / GSVA complete
- [ ] Checkpoint panel complete
- [ ] TIDE/TMB complete if declared
- [ ] Mutation waterfall complete if mutation data available
- [ ] GO/KEGG / hallmark interpretation complete

**Phase 5 — Translational Layer**
- [ ] Drug sensitivity prediction complete if declared
- [ ] Drug hypotheses framed as computational only
- [ ] HPA / tissue validation complete if declared
- [ ] Integrated model figure drafted

---

## Dependency Map Deliverable (mandatory)

Every output must include a **Dependency Map / Evidence Map** as part of Section C.5.

### Required Format

```
Evidence Map — [Config Name]

PRESENT evidence layers:
- [list each declared data source and analysis method]

ABSENT evidence layers:
- [list what is NOT included in this configuration]

THEREFORE FORBIDDEN steps:
- [list downstream steps that cannot appear due to absent dependencies]

Evidence-claim formula used:
- [state the exact claim formula, e.g. prognosis + immune context only / computational drug sensitivity only]
```
