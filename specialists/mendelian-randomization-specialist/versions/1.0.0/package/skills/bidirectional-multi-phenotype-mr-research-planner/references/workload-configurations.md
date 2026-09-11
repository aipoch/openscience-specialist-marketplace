# Workload Configurations
# bidirectional-multi-phenotype-mr-research-planner

---

## Lite

| Attribute | Detail |
|---|---|
| **Goal** | Rapid proof-of-concept MR screen with limited phenotype breadth |
| **Timeline** | 2–4 weeks |
| **Data** | One exposure family + one outcome family from public GWAS resources; one ancestry preferred |
| **Core Modules** | trait declaration, IV extraction, IVW, one limited sensitivity set, basic result filtering |
| **Validation** | Within-study MR consistency only |
| **Figure complexity** | 4–5 figures |
| **Strengths** | Executable fast; low barrier; establishes basic causal-screening concept |
| **Weaknesses** | Limited robustness; no strong multiplicity handling if phenotype panel is large |

## Standard

| Attribute | Detail |
|---|---|
| **Goal** | Complete conventional multi-phenotype bidirectional MR paper |
| **Timeline** | 1–2 months |
| **Data** | Exposure family + outcome family + subtype GWAS where relevant; public GWAS resources; one ancestry preferred |
| **Core Modules** | All Lite modules + full bidirectional design, weighted median / MR-Egger / MR-PRESSO / leave-one-out, subtype resolution, FDR correction, robust-hit filtering |
| **Validation** | Cross-estimator MR consistency + multiplicity control |
| **Figure complexity** | 7–8 figures |
| **Strengths** | Meets typical reviewer expectation for conventional bidirectional MR papers |
| **Weaknesses** | No advanced triangulation; limited mechanism confidence |

## Advanced

| Attribute | Detail |
|---|---|
| **Goal** | Competitive MR paper with stronger robustness and signal prioritization |
| **Timeline** | 2–3 months |
| **Data** | Standard data + broader phenotype panel or better subtype resolution + stronger dataset provenance control |
| **Core Modules** | All Standard + stronger robust-hit tiering, ancestry / source consistency review, sparse-IV downgrade logic, richer follow-up-priority map |
| **Validation** | Full sensitivity suite + multiplicity-qualified robust set + stronger claim-boundary handling |
| **Figure complexity** | 8–10 figures |
| **Strengths** | Better reviewer-proofing and cleaner interpretation of broad screens |
| **Weaknesses** | More complexity; requires careful filtering to avoid nominal-hit overload |

## Publication+

| Attribute | Detail |
|---|---|
| **Goal** | High-ambition manuscript with maximum reviewer defensibility |
| **Timeline** | 3–6 months |
| **Data** | Advanced data + richer phenotype architecture + stronger source consistency or additional triangulation-ready planning |
| **Core Modules** | All Advanced + stronger downgrade map, explicit robust-hit tiers, reviewer-facing evidence map, richer follow-up prioritization and claim-boundary reporting |
| **Validation** | Maximum within standard two-sample MR scope without overclaiming mechanism |
| **Figure complexity** | 10–12 figures |
| **Strengths** | Reviewer-proof structure; strongest paper logic in this family |
| **Weaknesses** | Major time investment; still not equivalent to mechanistic or mediation proof |

---

## Dependency Consistency Rules

### Core Principle
A downstream step may appear **only if its prerequisite data source, evidence layer, and method family have already been explicitly included** in that same configuration.

### Mandatory Dependency Rules

1. **Bidirectionality-dependent analyses** may appear only when the configuration explicitly includes:
   - separate reverse-direction trait pairing
   - separate IV construction for reverse-direction MR

2. **Subtype-dependent analyses** may appear only when the configuration explicitly includes:
   - subtype-specific GWAS summary statistics
   - subtype-level phenotype declarations

3. If a configuration is defined as **basic two-sample MR only**, then downstream steps must remain limited to:
   - trait selection
   - IV extraction and clumping
   - IVW and declared sensitivity estimators
   - multiplicity control if relevant
   - cautious biological interpretation

4. **Minimal Executable Version** must inherit only the modules declared in the Lite plan unless the skill explicitly states that this minimal version is being upgraded into a stronger variant.

5. **Publication Upgrade Version** may add new dependency-bearing modules, but each newly added module must be labeled as:
   - newly introduced
   - why it is being added
   - what new evidence tier it enables
