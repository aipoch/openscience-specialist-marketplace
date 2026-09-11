# Workload Configurations
# mr-scrna-research-planner

---

## Lite

| Attribute | Detail |
|---|---|
| **Goal** | Rapid preliminary study; proof-of-concept; feasibility check |
| **Timeline** | 2–4 weeks |
| **Data** | 1 public scRNA dataset (GEO) + 1 outcome GWAS (IEU OpenGWAS) |
| **Core Modules** | QC + annotation, module scoring (1 mechanism), basic DEG, univariable MR only |
| **MR** | IVW primary; Weighted Median + MR-Egger as secondary; basic sensitivity |
| **Validation** | Within-dataset consistency check only |
| **Figure complexity** | 4–5 figures: UMAP, scoring heatmap, DEG volcano, MR forest plot, localization |
| **Strengths** | Executable fast; low barrier; establishes basic concept |
| **Weaknesses** | No multivariable MR; no external validation; unlikely to pass competitive journals alone |
| **Typical target** | Preliminary data for grant; pilot report; early submission to lower-tier journals |

---

## Standard

| Attribute | Detail |
|---|---|
| **Goal** | Complete conventional bioinformatics paper |
| **Timeline** | 1–2 months |
| **Data** | 1–2 scRNA datasets + outcome GWAS + 1 independent bulk GEO/TCGA validation cohort |
| **Core Modules** | All Lite modules + multivariable MR, sensitivity suite, Steiger, key-cell prioritization, GSVA/ssGSEA pathway scoring, pseudotime (Monocle3/Slingshot), bulk transcriptomic validation |
| **MR** | IVW + full sensitivity (heterogeneity, pleiotropy, leave-one-out, Steiger) |
| **Validation** | Cross-method MR consistency + independent bulk cohort expression validation |
| **Figure complexity** | 7–8 figures (see figure plan) |
| **Strengths** | Meets typical reviewer expectation for bioinformatics mechanism papers |
| **Weaknesses** | No colocalization; limited multi-population generalizability |
| **Typical target** | Mid-tier journals (Frontiers, IJMS, BMC Genomics, etc.) |

---

## Advanced

| Attribute | Detail |
|---|---|
| **Goal** | Competitive journals; stronger causal and mechanistic evidence |
| **Timeline** | 2–3 months |
| **Data** | 2+ scRNA datasets (ideally different cohorts) + GWAS + bulk validation + GTEx/HPA |
| **Core Modules** | All Standard + pseudobulk DEG (edgeR/DESeq2), CellChat/NicheNet (cell communication), SCENIC/pySCENIC (regulon), colocalization (coloc R) or SMR + HEIDI, disease-subgroup stratification |
| **MR** | Standard suite + colocalization for top hits + SMR HEIDI test |
| **Validation** | Multi-dataset scRNA consistency + multi-bulk-cohort + tissue-level (GTEx/HPA) |
| **Figure complexity** | 8–10 figures; complex network and trajectory figures |
| **Strengths** | Substantially stronger causal evidence; mechanism depth satisfies rigorous reviewers |
| **Weaknesses** | Higher computational demand; colocalization requires aligned GWAS/eQTL loci |
| **Typical target** | Mid-to-high tier (Theranostics, JHematol Oncol, Aging, etc.) |

---

## Publication+

| Attribute | Detail |
|---|---|
| **Goal** | High-ambition manuscript with maximum reviewer defensibility |
| **Timeline** | 3–6 months |
| **Data** | Multi-ancestry GWAS + multiple scRNA datasets + bulk cohorts + clinical data if possible |
| **Core Modules** | All Advanced + bidirectional MR (where biologically justified), multi-ancestry/ethnic stratification, stratified MR (by sex, age, disease subtype), translational enhancement (ROC, prediction model, drug target annotation), manuscript-level figure logic with integrated mechanistic model |
| **MR** | Full suite + bidirectional + stratified + replication in second GWAS population |
| **Validation** | Maximum: multi-cohort, multi-ancestry, cross-tissue, functional if possible |
| **Figure complexity** | 10–12 figures; publication-quality integrated mechanistic schematic |
| **Strengths** | Reviewer-proof structure; suitable for top-tier submission |
| **Weaknesses** | Major time investment; requires high-quality multi-ancestry GWAS availability |
| **Typical target** | High-tier (iScience, Cell Reports, EBioMedicine, eLife, etc.) |

---

## Config Selection Decision Tree

```
User wants results in < 1 month, public data only?
  → Lite (or Standard if output quality is critical)

User wants a conventional bioinformatics mechanism paper?
  → Standard (primary); Advanced (if timeline allows)

User mentions colocalization, SCENIC, multi-dataset, or competitive journal?
  → Advanced

User mentions bidirectional MR, multi-ancestry, translational angle, or top-tier journal?
  → Publication+

User doesn't specify?
  → Default: Standard as primary, Lite as minimum, Advanced as upgrade path
```

---

## Dependency Consistency Rules

### Core Principle
A downstream step may appear **only if its prerequisite data source, evidence layer, and method family have already been explicitly included** in that same configuration.

### Mandatory Dependency Rules

1. **QTL-dependent analyses** may appear only when the configuration explicitly includes at least one of:
   - eQTL
   - pQTL
   - sQTL
   - colocalization
   - SMR / HEIDI
   - QTL-based MR

2. If a configuration is defined as **MR + scRNA only**, then downstream steps must remain limited to:
   - exposure/outcome MR
   - scRNA QC / annotation / scoring / DEG / pseudotime / communication / regulon
   - bulk or cross-dataset validation

   and must **not** introduce:
   - DEG ∩ QTL intersection
   - colocalization
   - SMR / HEIDI
   - QTL-prioritized gene ranking
   - transcriptome-wide Mendelian randomization expansions

3. **Minimal Executable Version** must inherit only the modules declared in the Lite plan unless the skill explicitly states that this minimal version is being upgraded into a QTL-enabled variant.

4. **Publication Upgrade Version** may add new dependency-bearing modules, but each newly added module must be labeled as:
   - newly introduced
   - why it is being added
   - what new evidence tier it enables

### Required Self-Check Questions
Before finalizing any output, verify:
- Does any step require data that was never declared earlier?
- Does any gene prioritization step assume QTL evidence absent from the configuration?
- Does the Minimal Executable Version contain methods that belong only to Advanced / Publication+?
- Are all intersections logically valid given the available inputs?

If the answer to any of the above is yes, the plan must be revised before output.

### Intersection Formula Reference

Every gene prioritization step must declare its exact logic formula. Valid examples:
- DEG only
- DEG ∩ MR-supported genes
- DEG ∩ QTL genes *(requires QTL declared)*
- DEG ∩ MR-supported genes ∩ colocalized genes *(requires coloc declared)*

The skill must not switch from one formula to another silently.
