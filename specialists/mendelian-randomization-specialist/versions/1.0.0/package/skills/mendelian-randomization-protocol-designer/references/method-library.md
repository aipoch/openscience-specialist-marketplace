# Method Library
# mendelian-randomization-protocol-designer

---

## Primary Analysis Environment

| Tool | Language | Use Case |
|---|---|---|
| TwoSampleMR | R | Core two-sample MR workflow, harmonization, IVW, weighted median, MR-Egger |
| MRPRESSO | R | Pleiotropy and outlier review when appropriate |
| MendelianRandomization | R | Cross-check estimators and alternative implementation |
| ieugwasr | R | Programmatic GWAS retrieval from IEU-compatible resources |
| data.table / tidyverse | R | Result management, filtering, export, reproducible reporting |
| coloc | R | Colocalization follow-up when Pattern E is justified |
| MVMR | R | Multivariable MR implementation when Pattern D is justified |

## Default Estimator Stack

| Method | Role |
|---|---|
| IVW | Default primary estimator |
| Weighted median | Default secondary robustness estimator |
| MR-Egger | Directional pleiotropy-sensitive estimator |
| MR-PRESSO | Outlier/pleiotropy review |
| Leave-one-out | Single-SNP dominance review |
| Cochran's Q | Heterogeneity testing |
| Steiger directionality | Directional plausibility support |

## Parameter Defaults and Decision Rules

| Item | Default / Rule |
|---|---|
| SNP significance threshold | Prefer genome-wide-significant instruments when feasible |
| LD clumping | Use standard independence-oriented clumping; report chosen threshold explicitly |
| Weak instrument control | Explicit F-statistic review or equivalent weak-IV screening |
| Palindromic SNPs | Remove or handle conservatively if allele-frequency ambiguity cannot be resolved |
| Sparse-IV design | Downgrade claims; consider reduced sensitivity suite rather than overclaiming |
| Multiple testing | Use FDR or another explicit correction if many trait pairs are tested |

## Selection Rule

Use the **simplest method stack that is adequate for the design**.
Do not stack advanced methods just because they are available.
