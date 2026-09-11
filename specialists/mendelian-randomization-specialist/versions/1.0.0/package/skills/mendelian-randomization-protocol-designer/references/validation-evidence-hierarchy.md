# Validation and Evidence Hierarchy
# mendelian-randomization-protocol-designer

---

## Evidence Tiers

### Nominal MR Signal (supportive — label explicitly as nominal)

| Evidence | Source | What It Establishes |
|---|---|---|
| IVW nominal association | Two-sample MR | Initial genetically proxied signal |
| Sparse-IV nominal signal | Limited instrument MR | Exploratory support only |

### Sensitivity-Qualified Support (stronger — label explicitly as sensitivity-qualified)

| Evidence | Source | What It Establishes |
|---|---|---|
| Weighted median consistency | Secondary robust estimator | Signal not obviously dependent on one estimator |
| MR-Egger-compatible direction | Pleiotropy-sensitive estimator | Direction not obviously reversed, with caution |
| Leave-one-out stability | SNP-level robustness | Signal is not dominated by one variant |
| Acceptable heterogeneity / pleiotropy profile | Q test / PRESSO / intercept review | No major unresolved instability |

### Robust Prioritized Signal (stronger — label explicitly as robust prioritized)

| Evidence | Source | What It Establishes |
|---|---|---|
| Main and secondary estimator direction consistency | Core MR + robustness suite | More credible causal prioritization |
| FDR-surviving result in multi-pair design | Multiplicity-controlled screen | Stronger prioritization after multiple testing |
| Reverse-direction asymmetry | Pattern B / C | One direction appears more plausible than the other |
| Colocalization-supported follow-up | Pattern E | Shared-signal support beyond simple proximity, not full mechanism proof |

### Follow-Up Priority Evidence (supportive — label explicitly as follow-up priority)

| Evidence | Source | What It Establishes |
|---|---|---|
| Biological plausibility layer | Domain literature | Better follow-up motivation |
| Subtype concentration | Pattern F | Signal may be subtype-specific |
| Translational relevance layer | target / biomarker context | Why the signal may matter downstream |

---

## Language Rules

- Use: "genetically predicted [exposure] was associated with [outcome] in MR analysis"
- Stronger but still bounded: "findings were sensitivity-qualified" or "results remained prioritized after robustness review"
- Do **not** use: "MR proved", "MR confirmed mechanism", "definitively causal", or "clinically effective"

---

## Downgrade Triggers

Downgrade claim strength when any of the following apply:
- sparse SNP count
- major heterogeneity not explained
- evidence of directional pleiotropy or unresolved outliers
- ancestry mismatch or unclear phenotype definition
- substantial sample-overlap concern
- multiple-testing burden with weak correction
