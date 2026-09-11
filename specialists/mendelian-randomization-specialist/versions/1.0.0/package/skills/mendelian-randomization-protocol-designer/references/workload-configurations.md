# Workload Configurations
# mendelian-randomization-protocol-designer

---

## Lite

| Attribute | Detail |
|---|---|
| **Goal** | Fast proof-of-concept two-sample MR for one exposure–outcome pair |
| **Timeline** | 1–3 weeks |
| **Data** | One exposure GWAS + one outcome GWAS; one ancestry preferred; public data |
| **Core Modules** | trait declaration, GWAS source framing, IV extraction, harmonization, IVW primary analysis, one limited sensitivity tier |
| **Validation** | Basic within-study consistency only |
| **Figure complexity** | 4–5 figures |
| **Strengths** | Rapid and executable; suitable for first-pass causal screening |
| **Weaknesses** | Limited robustness; weaker reviewer resistance if instrument count is low |

## Standard

| Attribute | Detail |
|---|---|
| **Goal** | Conventional reviewer-ready two-sample MR study for one main causal question |
| **Timeline** | 1–2 months |
| **Data** | One exposure + one outcome, ancestry-aligned when possible, better phenotype-definition review |
| **Core Modules** | All Lite modules + weighted median, MR-Egger, heterogeneity review, pleiotropy review, leave-one-out, Steiger directionality, explicit downgrade logic |
| **Validation** | Sensitivity-qualified causal support |
| **Figure complexity** | 6–8 figures |
| **Strengths** | Matches common MR reviewer expectations |
| **Weaknesses** | Still limited if data quality or IV count are weak |

## Advanced

| Attribute | Detail |
|---|---|
| **Goal** | Stronger MR protocol with justified extensions and cleaner claim control |
| **Timeline** | 2–3 months |
| **Data** | Standard data + subtype or comparator datasets where justified + stronger source-quality review |
| **Core Modules** | All Standard modules + one justified extension (reverse MR, bidirectional MR, MVMR, colocalization follow-up, or subtype analysis) + stronger instability mapping |
| **Validation** | Sensitivity-qualified support plus extension-aware robustness review |
| **Figure complexity** | 8–10 figures |
| **Strengths** | More competitive and reviewer-aware |
| **Weaknesses** | More assumptions; extension misuse can weaken the study |

## Publication+

| Attribute | Detail |
|---|---|
| **Goal** | Publication-oriented MR paper with explicit prioritization, downgrade logic, and translational framing |
| **Timeline** | 3–5 months |
| **Data** | Advanced data architecture plus stronger precedent search, richer phenotype-definition review, and optional orthogonal follow-up planning |
| **Core Modules** | All Advanced modules + stronger evidence map, claim-boundary map, minimal translational follow-up plan, and reviewer-facing limitation handling |
| **Validation** | Best achievable robustness within summary-statistic MR limits |
| **Figure complexity** | 10–12 figures |
| **Strengths** | Best full-story structure and reviewer-proofing |
| **Weaknesses** | Highest workload; still cannot overcome fundamental GWAS limitations |
