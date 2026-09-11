# Method Library
# two-sample-mr-exposure-screening-reference-grounded-research-planner-aligned

---

## Core Causal-Inference Tooling

### Primary Analysis Environments
| Tool | Language | Use Case |
|---|---|---|
| TwoSampleMR | R | instrument extraction, harmonization, IVW, sensitivity |
| ieugwasr / OpenGWAS-compatible tools | R / web | GWAS discovery and retrieval |
| MendelianRandomization | R | estimator cross-checking |
| MR-PRESSO or equivalent | R | outlier / pleiotropy review when justified |
| custom QC summaries | R | instrument-count and assumption tracking |

### Extended Robustness Tools
| Tool / Resource | Use Case |
|---|---|
| reverse-MR framework | directionality review |
| MVMR packages | correlated-exposure adjustment |
| Steiger-style directionality review | orientation support |
| visualization packages | scatter, funnel, forest, leave-one-out plots |

---

## Data Resources

### Common Public Resources
| Resource | Coverage |
|---|---|
| OpenGWAS / IEU | exposure and outcome summary statistics |
| GWAS Catalog / consortium pages | phenotype and dataset discovery |
| UK Biobank-derived GWAS resources | common exposure / outcome coverage |
| FinnGen / disease consortia | replication or alternative outcome sources |

### Dataset Planning Requirement

| Item | What to Declare |
|---|---|
| Exposure GWAS | source, sample size, ancestry, phenotype definition |
| Outcome GWAS | source, sample size or case/control counts, ancestry |
| Instrument rules | p threshold, clumping, F-statistic |
| Sensitivity tools | which estimators and robustness checks are used |
| Replication / extension resources | reverse MR, MVMR, or second GWAS source |

> **Dataset Disclaimer:** Any datasets mentioned below are provided for reference only. Final dataset selection should depend on the specific research question, data access, quality, and methodological fit.

---

## Parameter Defaults and Decision Rules

| Parameter | Default | Notes |
|---|---|---|
| Instrument threshold | genome-wide significance unless justified otherwise | declare exact p threshold |
| LD clumping | strict independence rule declared explicitly | report r² and window |
| Primary estimator | IVW | always state why it is primary |
| Sensitivity set | MR-Egger + weighted median + leave-one-out at minimum for Standard+ | avoid incomplete robustness claims |
| Pleiotropy review | explicit test or justified omission | do not imply without calculation |
| MVMR / reverse MR | optional upgrade only | cannot appear silently |
| Interpretation | causal prioritization only | avoid intervention claims |
