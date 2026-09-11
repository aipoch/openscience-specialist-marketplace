# Validation and Evidence Hierarchy
# mr-scrna-research-planner

---

## Evidence Tiers

### Causal-Level Evidence (stronger — label explicitly as causal)

| Evidence | Source | What It Establishes |
|---|---|---|
| IVW MR (p < 0.05, consistent direction) | TwoSampleMR | Association between genetically-proxied exposure and outcome |
| Multivariable MR (independent effect) | MVMR package | Causal effect robust to correlated exposures |
| Colocalization (PP.H4 > 0.75) | coloc R | Same causal variant drives eQTL and GWAS signals — rules out LD confounding |
| SMR + HEIDI (p.HEIDI > 0.05) | SMR software | Gene expression mediates the causal path; rejects pleiotropy |
| Steiger-confirmed direction | TwoSampleMR | Confirms the hypothesized causal direction |

### Correlation-Level Evidence (supportive — label explicitly as associative)

| Evidence | Source | What It Establishes |
|---|---|---|
| DEG between high/low score groups | scRNA FindMarkers | Differential expression — not mechanism |
| Module scoring patterns | AUCell / UCell | Cell-level activity — not causality |
| Pathway enrichment results | clusterProfiler, GSEA | Functional annotation — not mechanism |
| Cell communication inferences | CellChat / NicheNet | Predicted signaling — not confirmed interaction |
| Pseudotime associations | Monocle3 / Slingshot | Trajectory ordering — not temporal causality |
| Bulk expression in independent cohort | GEO / TCGA | Replication of association — not causal replication |

---

## Validation Coverage by Config

| Validation Layer | Lite | Standard | Advanced | Publication+ |
|---|---|---|---|---|
| Within-dataset consistency | ✅ | ✅ | ✅ | ✅ |
| Cross-method MR consistency | — | ✅ | ✅ | ✅ |
| Independent bulk cohort | — | ✅ | ✅ | ✅ |
| Tissue-level expression (GTEx/HPA) | — | ✅ | ✅ | ✅ |
| Second independent scRNA dataset | — | — | ✅ | ✅ |
| Disease subgroup stratification | — | — | ✅ | ✅ |
| Colocalization / SMR | — | — | ✅ | ✅ |
| Multi-ancestry replication | — | — | — | ✅ |
| Independent cohort replication | — | — | — | ✅ |

---

## Article Coverage Matrix

| Pattern | Minimum Required Modules | Recommended Additional |
|---|---|---|
| Mechanism gene set → score → DEG → MR | Scoring, DEG, univariable MR, sensitivity | External validation, pathway, pseudotime |
| Key cell → cell-specific DEG → MR | Cell annotation, composition, DEG, MR | Communication, trajectory, second dataset |
| Candidate genes → MR → scRNA localization | MR (full sensitivity), localization | Pathway, trajectory |
| Exposure → disease → cell | Exposure MR, outcome MR, cell localization | Mediation, colocalization |
| MR-prioritized genes → mechanism | MR results, scRNA DEG, pathway | SCENIC, communication, pseudotime |
| Full sensitivity set | Heterogeneity, pleiotropy, LOO, Steiger | Bidirectional (if biologically justified) |
| External bulk validation | ≥ 1 GEO/TCGA cohort | Second independent cohort |

---

## Self-Critical Risk Review Template

Every output plan must include a risk review covering:

1. **Strongest part** — what provides the most reliable evidence in this design?
2. **Most assumption-dependent part** — what assumption, if wrong, collapses the story?
3. **Most likely false-positive source** — where does spurious signal most easily enter?
4. **Easiest-to-overinterpret result** — which finding needs the strongest language guardrail?
5. **Likely reviewer criticisms** — what will reviewers challenge first?
6. **Fallback plan** — if first-pass MR is null or scRNA signal is weak, what's the alternative design?

---

## Language Rules

- MR findings: "provides causal evidence for", "causally associated with", "genetically predicted"
- Correlation findings: "associated with", "differentially expressed in", "enriched in"
- **NEVER use:** "proves", "demonstrates causality", "confirms the mechanism" for correlation-level evidence
- **ALWAYS state:** which evidence tier each claim belongs to

---

## Dependency-Aware Validation Rules

Every validation step must declare:
1. **What it proves** — be specific and bounded
2. **What it does not prove** — state the limitation explicitly
3. **What it depends on** — list the required upstream data or analysis

If the declared dependency is absent from the configuration, that validation step **cannot appear** in the plan.

### Examples

| Validation Step | Proves | Does Not Prove | Depends On |
|---|---|---|---|
| Univariable MR (IVW p < 0.05) | Genetically-proxied causal association | Cellular mechanism; experimental causality | Outcome GWAS + instruments |
| Colocalization (PP.H4 > 0.75) | Same causal variant drives eQTL + GWAS | Protein-level mechanism | eQTL/pQTL data explicitly declared |
| Independent bulk cohort expression | Replication of association in a second dataset | Causal replication | ≥1 independent GEO/TCGA cohort |
| Pseudotime trajectory | Ordered cell-state transition | Temporal causality | scRNA dataset with sufficient cell-state diversity |
| CellChat communication | Predicted ligand-receptor signaling | Confirmed intercellular interaction | Advanced+ config; second cell type present |

### Forbidden Combinations (without declared dependency)

- Colocalization results without declared eQTL/pQTL source → **forbidden**
- SMR / HEIDI without declared eQTL instrument source → **forbidden**
- DEG ∩ QTL intersection without declared QTL resource → **forbidden**
- Pseudobulk validation without per-sample metadata in scRNA dataset → **forbidden**
