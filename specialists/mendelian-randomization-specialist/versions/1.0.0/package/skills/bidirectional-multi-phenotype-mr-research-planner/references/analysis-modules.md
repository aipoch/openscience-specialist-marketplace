# Analysis Module Library
# bidirectional-multi-phenotype-mr-research-planner

---

## GWAS Resource and Trait Architecture Modules

| Module | Purpose | When Required |
|---|---|---|
| Exposure-family trait selection | Define which traits / diseases belong to the exposure side | Always |
| Outcome-family trait selection | Define which traits / diseases belong to the outcome side | Always |
| Trait-subtype resolution | Prevent aggregation of etiologically distinct subtypes | Standard+ |
| Ancestry alignment review | Reduce population-structure inconsistency across datasets | Standard+ |
| Dataset-source harmonization | Track OpenGWAS / FinnGen / consortia provenance | Always |
| Bidirectional pairing matrix | Make exposure→outcome and outcome→exposure directions explicit | Pattern A / D |

### Trait Declaration Requirement

| Item | Required Content |
|---|---|
| Trait family | e.g., eye diseases, stroke and stroke subtypes |
| Trait count | Number of exposures and number of outcomes |
| Trait definitions | ICD-based, consortium-defined, or resource-defined phenotype logic |
| Directionality | one-way or bidirectional |
| Subtype rule | whether aggregate and subtype outcomes are both included |

### Dataset Declaration and Reference Block

| Item | Required Content |
|---|---|
| Exposure GWAS source | IEU OpenGWAS / FinnGen / consortium / UKB-derived source |
| Outcome GWAS source | IEU OpenGWAS / FinnGen / consortium / UKB-derived source |
| Ancestry | European-only, multi-ancestry, or mixed |
| Sample size note | approximate case/control or total sample scale |
| Phenotype definition note | how the trait was defined in the source dataset |

> **Dataset Disclaimer:** The datasets listed below are for reference only. Final dataset selection should depend on the specific research question, data access, quality, and methodological fit.

---

## Instrumental Variable Modules

| Module | Purpose | When Required |
|---|---|---|
| Genome-wide association thresholding | Select exposure-associated SNPs | Always |
| LD clumping | Ensure approximate SNP independence | Always |
| F-statistic filtering | Remove weak instruments | Always |
| Confounder exclusion logic | State instrument assumptions and exclusion rationale | Always |
| Harmonization of exposure and outcome alleles | Prevent strand / effect-direction errors | Always |
| SNP count tracking | Keep per-trait instrument quality transparent | Lite+ |

---

## Core MR Estimation Modules

| Module | Purpose | When Required |
|---|---|---|
| IVW main estimator | Primary causal estimate | Always |
| Weighted median | Robustness to some invalid instruments | Standard+ |
| MR-Egger | Directional pleiotropy-sensitive sensitivity analysis | Standard+ |
| MR-PRESSO | Outlier and pleiotropy review | Standard+ |
| Leave-one-out | Detect single-SNP dominance | Standard+ |
| Direction-consistency comparison across estimators | Reduce false-confidence from one method | Standard+ |

### Multi-Pair Screening Support

| Module | Purpose | When Required |
|---|---|---|
| Pairwise MR matrix | Organize all tested exposure–outcome combinations | Pattern B / D |
| Forest summary of robust hits | Summarize prioritized causal signals | Standard+ |
| Heatmap / p-value map | Show broad screening landscape | Pattern B / D |
| FDR correction across tested pairs | Control false positive rate | Pattern B / D, Standard+ |

---

## Robustness and Filtering Modules

| Module | Purpose | When Required |
|---|---|---|
| Heterogeneity testing | Detect inconsistent SNP-level effects | Standard+ |
| Horizontal pleiotropy testing | Detect invalid-IV directional bias | Standard+ |
| Sensitivity-qualified hit filtering | Remove unstable nominal hits | Standard+ |
| FDR-surviving robust-set construction | Prioritize strongest signals after multiplicity control | Advanced+ |
| Outlier review | Prevent single-SNP driven claims | Standard+ |
| Sparse-instrument caution layer | Prevent overstatement when SNP count is low | Always when needed |

---

## Interpretation and Follow-Up Modules

| Module | Purpose | When Required |
|---|---|---|
| Bidirectional asymmetry interpretation | Clarify whether signals are one-way or both-way | Pattern A / D |
| Subtype-specific interpretation | Prevent overgeneralization from one subtype | Pattern C / D |
| Biological plausibility layer | Frame possible mechanism without overclaiming | Standard+ |
| Follow-up prioritization ladder | Rank which trait pairs deserve deeper validation | Pattern E / Advanced+ |
| Claim-boundary summary | Explicitly separate genetic causal support from mechanism proof | Always |
| Triangulation wishlist | Note future colocalization / MVMR / lab follow-up possibilities | Advanced+ |
