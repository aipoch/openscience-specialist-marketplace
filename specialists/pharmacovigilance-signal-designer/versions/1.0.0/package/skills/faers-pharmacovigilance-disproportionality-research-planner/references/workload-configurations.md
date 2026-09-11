# Workload Configurations
# faers-pharmacovigilance-disproportionality-research-planner

---

## Lite

| Attribute | Detail |
|---|---|
| **Goal** | Rapid proof-of-concept FAERS signal screen |
| **Timeline** | 2–4 weeks |
| **Data** | One database source, one product set, one comparator, one AE domain |
| **Core Modules** | extraction, product normalization, PT shortlist, basic ROR + CI |
| **Validation** | Within-study comparator-qualified signal only |
| **Figure complexity** | 4–5 figures |
| **Strengths** | Executable fast; low barrier; establishes signal-screening concept |
| **Weaknesses** | Limited subgroup depth and comparator robustness |

## Standard

| Attribute | Detail |
|---|---|
| **Goal** | Complete conventional FAERS disproportionality paper |
| **Timeline** | 1–2 months |
| **Data** | One pharmacovigilance database + multi-product set + therapeutic comparators + subgroup fields |
| **Core Modules** | All Lite modules + indication stratification, multiple comparators, cross-drug comparison, strong-signal thresholding |
| **Validation** | Comparator-qualified signal consistency |
| **Figure complexity** | 7–8 figures |
| **Strengths** | Meets typical reviewer expectation for conventional pharmacovigilance signal papers |
| **Weaknesses** | No utilization-based denominator; limited causal interpretability |

## Advanced

| Attribute | Detail |
|---|---|
| **Goal** | Competitive signal paper with stronger filtering and interpretation discipline |
| **Timeline** | 2–3 months |
| **Data** | Standard data + richer PT coverage + stronger subgroup logic + more comparator structure |
| **Core Modules** | All Standard + stronger signal-priority rules, severity grouping, richer limitations and downgrade logic |
| **Validation** | More stable within-database signal hierarchy |
| **Figure complexity** | 8–10 figures |
| **Strengths** | Better reviewer-proofing and cleaner signal prioritization |
| **Weaknesses** | More complexity; still spontaneous-report limited |

## Publication+

| Attribute | Detail |
|---|---|
| **Goal** | High-ambition manuscript with maximum reviewer defensibility |
| **Timeline** | 3–6 months |
| **Data** | Advanced data + richer comparator architecture + stronger claim-boundary map |
| **Core Modules** | All Advanced + reviewer-facing bias-control map, richer follow-up framework, explicit downgrade structure |
| **Validation** | Maximum within spontaneous-report disproportionality scope without overclaiming causality |
| **Figure complexity** | 10–12 figures |
| **Strengths** | Reviewer-proof structure; strongest paper logic in this family |
| **Weaknesses** | Major time investment; still not incidence or causal evidence |

---

## Dependency Consistency Rules

### Core Principle
A downstream step may appear **only if its prerequisite data source, evidence layer, and method family have already been explicitly included** in that same configuration.

### Mandatory Dependency Rules

1. **Comparator-dependent analyses** may appear only when the configuration explicitly includes comparator products and comparator rationale.
2. **Indication-stratified analyses** may appear only when the configuration explicitly includes reason-for-use or subgroup-definition logic.
3. If a configuration is defined as **basic FAERS disproportionality only**, then downstream steps must remain limited to extraction, PT coding, ROR, comparator benchmarking, and cautious signal interpretation.
4. **Minimal Executable Version** must inherit only the modules declared in the Lite plan unless the skill explicitly states that this minimal version is being upgraded into a stronger variant.
5. **Publication Upgrade Version** may add new dependency-bearing modules, but each newly added module must be labeled as:
   - newly introduced
   - why it is being added
   - what new evidence tier it enables
