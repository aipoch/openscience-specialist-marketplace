# Analysis Module Library
# two-sample-mr-exposure-screening-reference-grounded-research-planner-aligned

---

## GWAS and Instrument Architecture Modules

| Module | Purpose | When Required |
|---|---|---|
| Outcome-GWAS declaration | Define primary outcome summary statistics | Always |
| Exposure-GWAS declaration | Define one exposure or an exposure family | Always |
| Ancestry-matching review | Reduce cross-population bias | Standard+ |
| Replication-support declaration | Define secondary outcome or exposure resources | Pattern E / Advanced+ |
| Extended-causal resource declaration | Define reverse MR, MVMR, or directionality resources | Pattern D / Advanced+ |
| Instrument-strength declaration | Make SNP threshold, LD clumping, and F-statistic rules explicit | Always |

### Dataset Declaration and Reference Block

| Item | Required Content |
|---|---|
| Exposure GWAS | source, sample size, ancestry, phenotype definition |
| Outcome GWAS | source, case/control counts or trait sample size, ancestry |
| Instrument rules | p-value threshold, clumping window, LD threshold |
| Sensitivity resources | MR-Egger / weighted median / mode / leave-one-out availability |
| Replication resources | secondary GWAS or orthogonal triangulation source |

> **Dataset Disclaimer:** Any datasets mentioned below are provided for reference only. Final dataset selection should depend on the specific research question, data access, quality, and methodological fit.

---

## Core Causal-Inference Modules

| Module | Purpose | When Required |
|---|---|---|
| SNP instrument extraction | Identify usable instruments | Always |
| LD clumping and harmonization | Ensure instrument independence and allele alignment | Always |
| IVW primary MR | Provide main causal estimate | Always |
| Complementary estimators | Assess estimator coherence | Standard+ |
| Heterogeneity review | Detect unstable instrument structure | Standard+ |
| Pleiotropy review | Check directional horizontal pleiotropy | Standard+ |

## Extended Robustness Modules

| Module | Purpose | When Required |
|---|---|---|
| Leave-one-out analysis | Identify single-SNP-driven results | Standard+ |
| Reverse MR | Test directionality alternative | Pattern D / Advanced+ |
| Multivariable MR | Adjust for correlated exposures | Pattern D / Advanced+ |
| Replication branch | Re-test key hits in independent GWAS resources | Pattern E / Advanced+ |
| Claim-boundary summary | Separate causal prioritization from mechanistic proof | Always |
