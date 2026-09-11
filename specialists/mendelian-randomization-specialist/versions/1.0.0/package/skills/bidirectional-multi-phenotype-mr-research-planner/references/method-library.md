# Method Library
# bidirectional-multi-phenotype-mr-research-planner

---

## Core MR Tooling

### Primary Analysis Environments
| Tool | Language | Use Case |
|---|---|---|
| TwoSampleMR | R | Core two-sample MR workflow, harmonization, IVW, weighted median, MR-Egger |
| MRPRESSO | R | Horizontal pleiotropy and outlier review |
| MendelianRandomization | R | Alternative MR estimators and method cross-check |
| data.table / tidyverse | R | Large pairwise result organization and export |

### GWAS Resource Access
| Tool / Resource | Use Case |
|---|---|
| IEU OpenGWAS | Public GWAS summary retrieval and harmonized access |
| FinnGen | Disease-rich summary statistics with broad phenotype coverage |
| MR-Base-compatible endpoints | Convenient trait pairing and reproducible querying |
| Consortium summary statistics | Outcome-specific or subtype-specific datasets when needed |

### Estimation and Sensitivity
| Method | Role |
|---|---|
| IVW | Primary causal estimator |
| Weighted median | Robustness estimator |
| MR-Egger | Directional pleiotropy-sensitive estimator |
| MR-PRESSO | Outlier / pleiotropy review |
| Leave-one-out | Single-SNP dominance review |
| Cochran's Q | Heterogeneity testing |
| Steiger directionality | Directional plausibility support when used |

---

## Data Resources

### Common GWAS Platforms
| Resource | Coverage |
|---|---|
| IEU OpenGWAS | Broad public GWAS catalog |
| FinnGen | Large disease phenotype resource |
| UK Biobank-derived GWAS | Broad quantitative and disease traits |
| Disease consortia GWAS | Outcome-family or subtype-specific high-priority datasets |

### Dataset Planning Requirement

| Item | What to Declare |
|---|---|
| Exposure GWAS | source, ancestry, sample size, phenotype definition |
| Outcome GWAS | source, ancestry, sample size, phenotype definition |
| Subtypes | whether subtype-specific GWAS are separate or nested |
| Overlap risk | whether sample overlap is known or uncertain |

> **Dataset Disclaimer:** The datasets listed below are for reference only. Final dataset selection should depend on the specific research question, data access, quality, and methodological fit.

---

## Parameter Defaults and Decision Rules

| Parameter | Default | Notes |
|---|---|---|
| Instrument p-threshold | genome-wide significance | relax only if justified by sparse trait architecture |
| LD clumping | strict independence rule | declare r² and kb window explicitly |
| F-statistic cutoff | > 10 | mandatory weak-IV guardrail |
| Main estimator | IVW | always primary unless explicitly justified otherwise |
| Sensitivity minimum set | weighted median + MR-Egger + leave-one-out | Lite may simplify but must stay transparent |
| Multiple-testing rule | FDR for multi-pair screens | mandatory for broad phenotype matrices |
| Reverse-direction MR | only if biologically and dataset-wise justified | declare separate IV construction |
| Subtype handling | separate from aggregate endpoint | do not merge silently |
