# Analysis Module Library
# mendelian-randomization-protocol-designer

---

## Question and Data Architecture Modules

| Module | Purpose | When Required |
|---|---|---|
| Exposure declaration | Define the exact exposure and its trait logic | Always |
| Outcome declaration | Define the exact outcome and its phenotype logic | Always |
| Directionality framing | Clarify one-way vs reverse-check vs bidirectional intent | Always |
| Ancestry alignment review | Reduce population-structure inconsistency | Always |
| Sample-overlap review | Prevent inflated precision or biased inference | Always |
| Phenotype-definition review | Avoid trait misclassification and invalid interpretation | Always |
| Subtype-resolution review | Separate biologically distinct outcome/exposure subtypes | Pattern F |

## Instrument Modules

| Module | Purpose | When Required |
|---|---|---|
| SNP thresholding | Select exposure-associated variants | Always |
| LD clumping | Ensure approximate independence | Always |
| Weak instrument review | Reduce unstable causal estimates | Always |
| Harmonization | Align effect alleles and orientations | Always |
| Palindromic SNP handling | Avoid ambiguous allele alignment | Always |
| Sparse-IV downgrade logic | Protect interpretation when SNP count is low | Always |

## Core MR Analysis Modules

| Module | Purpose | When Required |
|---|---|---|
| IVW primary analysis | Main causal estimator | Always |
| Weighted median | Robustness to some invalid IVs | Standard+ |
| MR-Egger | Directional pleiotropy-sensitive check | Standard+ when instrument count allows |
| Heterogeneity review | Detect instability across SNPs | Standard+ |
| Pleiotropy / outlier review | Flag outlier-driven or pleiotropic signals | Standard+ |
| Leave-one-out | Check single-SNP dominance | Standard+ when instrument count allows |
| Steiger directionality | Directional plausibility support | Standard+ when relevant |

## Extension Modules

| Module | Purpose | When Required |
|---|---|---|
| Reverse MR | Test reverse causal possibility as secondary check | Pattern B / C |
| Bidirectional MR | Make both directions primary | Pattern C |
| Multivariable MR | Separate correlated exposures / pathways | Pattern D |
| Colocalization follow-up | Distinguish shared-signal support from LD-confounded overlap | Pattern E |
| Phenotype panel / subtype MR | Handle related outcomes or etiologic subtypes | Pattern F |

---

## Dataset Declaration and Reference Block

| Item | Required Content |
|---|---|
| Exposure GWAS type | consortium / biobank-derived / OpenGWAS-accessible summary source |
| Outcome GWAS type | consortium / biobank-derived / OpenGWAS-accessible summary source |
| Ancestry | matched, partially matched, or uncertain |
| Sample size note | approximate scale if verified, otherwise mark unverified |
| Phenotype-definition note | case definition / trait derivation quality |
| Overlap risk | known low / possible / unclear |

> **Dataset Disclaimer:** The datasets listed below are for reference only. Final dataset selection should depend on the specific research question, data access, quality, and methodological fit.
