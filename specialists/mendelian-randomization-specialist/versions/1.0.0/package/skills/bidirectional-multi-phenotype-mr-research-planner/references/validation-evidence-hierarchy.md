# Validation and Evidence Hierarchy
# bidirectional-multi-phenotype-mr-research-planner

---

## Evidence Tiers

### MR Signal-Level Evidence (supportive — label explicitly as MR signal)

| Evidence | Source | What It Establishes |
|---|---|---|
| IVW nominal signal | Two-sample MR | Initial genetically proxied association |
| Broad direction consistency | IVW + weighted median | Signal not driven by one estimator alone |
| Sparse-IV nominal signal | MR with limited SNP count | Exploratory only; strong caution required |

### Sensitivity-Qualified Causal Support (stronger — label explicitly as sensitivity-qualified)

| Evidence | Source | What It Establishes |
|---|---|---|
| Weighted median consistency | Robustness to some invalid instruments | More credible causal support |
| MR-Egger direction consistency | Directional robustness, with caveats | Not obviously reversed by pleiotropy-sensitive estimator |
| Leave-one-out stability | Single SNP not dominating | Signal is not obviously one-variant-driven |
| Acceptable heterogeneity / pleiotropy profile | Q test / Egger intercept / MR-PRESSO | No major unresolved instability |

### Multiplicity-Controlled Robust Signal (stronger — label explicitly as robust post-FDR)

| Evidence | Source | What It Establishes |
|---|---|---|
| FDR-surviving hit | Multi-pair screen with FDR | Signal remains prioritized after multiple-testing correction |
| Direction-specific robust hit | Forward or reverse direction only | More credible one-way causal support |
| Subtype-specific robust hit | Subtype-resolved MR | Signal appears concentrated in one etiologic subtype |

### Follow-Up Priority Evidence (supportive — label explicitly as follow-up priority)

| Evidence | Source | What It Establishes |
|---|---|---|
| Bidirectional asymmetry | forward vs reverse comparison | Which direction is more plausible for follow-up |
| Phenotype-family convergence | several related traits show similar direction | Stronger prioritization rationale |
| Biological plausibility layer | disease-domain literature support | Better follow-up motivation, not proof of mechanism |

---

## Language Rules

- MR findings: "genetically predicted [exposure] was associated with [outcome]", "supports genetically proxied causal relevance", "sensitivity-qualified support"
- Robust findings: "survived FDR correction", "remained directionally consistent across estimators"
- Follow-up findings: "prioritized for follow-up", "supports deeper biological investigation"

- **NEVER use:** "proves mechanism", "confirms therapeutic target", "establishes pathway mediation" from standard two-sample MR alone
