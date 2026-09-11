# Validation and Evidence Hierarchy
# pcd-immune-oncology-research-planner

---

## Evidence Tiers

### Tier 1 — Association-Level
Includes:
- DEG results
- pathway enrichment
- checkpoint expression differences
- cluster vs stage / grade associations

**What it supports:** biological plausibility and descriptive heterogeneity
**What it does not support:** causality, treatment benefit, mechanistic proof

### Tier 2 — Prognostic-Level
Includes:
- survival differences across clusters
- LASSO-Cox risk score
- KM / ROC / C-index / external validation

**What it supports:** outcome stratification
**What it does not support:** biological mechanism truth or treatment efficacy

### Tier 3 — Predictive-Context Level
Includes:
- immune deconvolution
- checkpoint panel differences
- TIDE / TMB context
- computational drug sensitivity prediction

**What it supports:** hypothesis generation about response context
**What it does not support:** real patient response, prescribing, or clinical benefit claims

### Tier 4 — Translational Support Level
Includes:
- external cohort replication
- HPA / tissue plausibility
- subtype anchoring to established classifications
- cross-database drug support

**What it supports:** stronger reviewer defensibility and translational plausibility
**What it does not support:** direct clinical implementation without further validation

---

## Mandatory Validation Statements

Every plan must explicitly state:
1. what is association only
2. what is prognostic only
3. what is predictive context only
4. what is still missing for mechanistic or clinical interpretation

---

## Common Reviewer Criticisms to Preempt

- gene-set curation is arbitrary
- clustering is unstable or overfit
- risk signature lacks true external validation
- immune results depend on one algorithm only
- TIDE / TMB are overinterpreted as response truth
- drug sensitivity predictions are presented too strongly
- no anchoring to known gastric / pan-cancer molecular classifications
