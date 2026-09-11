# Workload Configurations
# two-sample-mr-exposure-screening-reference-grounded-research-planner-aligned

---

## Lite

| Attribute | Detail |
|---|---|
| **Goal** | Rapid proof-of-concept two-sample MR study |
| **Timeline** | 2–4 weeks |
| **Data** | One outcome GWAS + one exposure or small exposure set |
| **Core Modules** | instrument extraction, harmonization, IVW, one basic sensitivity branch |
| **Validation** | discovery-level robustness only |
| **Figure complexity** | 4–5 figures |
| **Strengths** | Fast, executable, keeps causal-prioritization focus |
| **Weaknesses** | Limited robustness depth and no replication |

## Standard

| Attribute | Detail |
|---|---|
| **Goal** | Complete conventional two-sample MR paper |
| **Timeline** | 1–2 months |
| **Data** | One main outcome GWAS + one or more exposure GWAS + declared sensitivity resources |
| **Core Modules** | All Lite modules + complementary estimators, heterogeneity, pleiotropy, leave-one-out, conservative hit triage |
| **Validation** | within-MR robustness support |
| **Figure complexity** | 7–8 figures |
| **Strengths** | Meets typical reviewer expectation for standard MR manuscripts |
| **Weaknesses** | Limited triangulation and mechanistic depth |

## Advanced

| Attribute | Detail |
|---|---|
| **Goal** | Competitive multi-layer MR paper |
| **Timeline** | 2–3 months |
| **Data** | Standard data + reverse MR or MVMR resources + stronger replication structure |
| **Core Modules** | All Standard + directionality extension, MVMR or reverse MR, replication branch |
| **Validation** | Multi-layer robustness and richer reviewer-proofing |
| **Figure complexity** | 8–10 figures |
| **Strengths** | Better reviewer-proofing and stronger causal architecture |
| **Weaknesses** | More complexity; more assumptions to defend |

## Publication+

| Attribute | Detail |
|---|---|
| **Goal** | High-ambition manuscript with maximum reviewer defensibility |
| **Timeline** | 3–6 months |
| **Data** | Advanced data + triangulation coherence + reviewer-facing downgrade logic |
| **Core Modules** | All Advanced + richer evidence layering, clearer claim-boundary map, stronger hit-prioritization structure |
| **Validation** | Maximum within summary-statistics MR scope without overclaiming mechanism or intervention effect |
| **Figure complexity** | 10–12 figures |
| **Strengths** | Reviewer-proof structure; strongest paper logic in this family |
| **Weaknesses** | Major time investment; still not equivalent to interventional evidence |

---

## Dependency Consistency Rules

### Core Principle
A downstream step may appear **only if its prerequisite data source, evidence layer, and method family have already been explicitly included** in that same configuration.

### Mandatory Dependency Rules

1. **Sensitivity-dependent interpretations** may appear only when heterogeneity, pleiotropy, and leave-one-out logic are explicitly included.
2. **Reverse-MR- or MVMR-dependent claims** may appear only when those modules are explicitly declared.
3. **Replication-dependent analyses** may appear only when a second GWAS resource or triangulation source is declared.
4. **Panel-screening conclusions** may appear only when exposure-panel definitions and multiple-testing logic are declared.
5. **Minimal Executable Version** must inherit only the modules declared in the Lite plan unless the skill explicitly states that this minimal version is being upgraded into a stronger variant.
6. **All interpretations** must remain within genetically informed causal-prioritization scope.
