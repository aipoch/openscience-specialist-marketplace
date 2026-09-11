# Workload Configurations
# single-drug-faers-safety-profile-research-planner

---

## Lite

| Attribute | Detail |
|---|---|
| **Goal** | Rapid preliminary pharmacovigilance study; proof-of-concept FAERS safety design |
| **Timeline** | 2–4 weeks |
| **Data** | One FAERS extraction with one primary exposure definition and one primary signal route |
| **Core Modules** | Exposure definition, signal detection, one scope rule, one ranking route, one lightweight characterization branch at most |
| **Validation** | Internal consistency check only |
| **Figure complexity** | 4–5 figures: workflow, extraction logic, signal landscape, one core summary plot, limited characterization |
| **Strengths** | Executable fast; low barrier; establishes a basic safety story |
| **Weaknesses** | No strong reviewer-facing robustness; limited defensibility |
| **Typical target** | Pilot report; early feasibility work; lower-tier journal preparation |

---

## Standard

| Attribute | Detail |
|---|---|
| **Goal** | Complete conventional FAERS paper |
| **Timeline** | 1–2 months |
| **Data** | One FAERS extraction with a clearly declared exposure definition plus one extended characterization or restriction layer |
| **Core Modules** | All Lite modules + stronger restriction logic, richer signal tables, one subgroup/onset/seriousness/label-context branch, sensitivity framing |
| **Validation** | Internal robustness through alternate filters or metrics |
| **Figure complexity** | 7–8 figures (see figure plan) |
| **Strengths** | Meets typical reviewer expectation for retrospective FAERS safety papers |
| **Weaknesses** | Still spontaneous-report based; limited causal confidence |
| **Typical target** | Mid-tier journals (Frontiers, BMC, IJMS-type space) |

---

## Advanced

| Attribute | Detail |
|---|---|
| **Goal** | Competitive journals; stronger signal defensibility and interpretation depth |
| **Timeline** | 2–3 months |
| **Data** | Standard data + richer restrictions, stronger subgroup architecture, or multiple robustness routes |
| **Core Modules** | All Standard + stronger signal-compression logic, multi-metric or multi-restriction robustness, tighter claim-boundary handling |
| **Validation** | Broader cross-filter or cross-metric consistency |
| **Figure complexity** | 8–10 figures; more integrated summary figures |
| **Strengths** | Stronger reviewer-facing rigor; better translational framing |
| **Weaknesses** | More moving parts; higher risk of overclaiming if not tightly controlled |
| **Typical target** | Mid-to-high tier pharmacovigilance journals |

---

## Publication+

| Attribute | Detail |
|---|---|
| **Goal** | High-ambition manuscript with maximum reviewer defensibility |
| **Timeline** | 3–6 months |
| **Data** | Multiple restricted analyses and richer characterization branches inside the same FAERS backbone |
| **Core Modules** | All Advanced + stronger endpoint compression, tighter evidence labeling, clearer limitation handling, richer integrated reporting |
| **Validation** | Maximum within-design robustness chain |
| **Figure complexity** | 10–12 figures; publication-quality integrated evidence schematic |
| **Strengths** | Reviewer-proof structure; strongest paper logic in this family |
| **Weaknesses** | Major time investment; not suitable if the signal question is weakly motivated |
| **Typical target** | High-ambition pharmacovigilance journals |

---

## Config Selection Decision Tree

```
User wants results in < 1 month, FAERS only?
  → Lite (or Standard if output quality is critical)

User wants a conventional FAERS safety paper?
  → Standard (primary); Advanced (if timeline allows)

User mentions richer robustness, multiple restricted analyses, or stronger reviewer-proofing?
  → Advanced

User mentions stronger subgroup architecture, richer interpretation, or higher publication target?
  → Publication+

User doesn't specify?
  → Default: Standard as primary, Lite as minimum, Advanced as upgrade path
```

---

## Dependency Consistency Rules

### Core Principle
A downstream step may appear **only if its prerequisite data source, evidence layer, and method family have already been explicitly included** in that same configuration.

### Mandatory Dependency Rules

1. **Comparator-dependent analyses** may appear only when the configuration explicitly includes a comparator restriction or class-comparison design.

2. If a configuration is defined as **FAERS-only signal-detection**, then downstream steps must remain limited to:
   - exposure definition
   - signal detection
   - signal ranking / compression
   - subgroup or onset / seriousness description if those fields are declared
   - limited robustness checks

   and must **not** introduce:
   - incidence estimation
   - causal safety claims
   - clinical or regulatory recommendations
   - mechanistic interpretation unsupported by external data

3. **Minimal Executable Version** must inherit only the modules declared in the Lite plan unless the skill explicitly states that this minimal version is being upgraded into a stronger variant.

4. **Publication Upgrade Version** may add new dependency-bearing modules, but each newly added module must be labeled as:
   - newly introduced
   - why it is being added
   - what new evidence tier it enables

### Required Self-Check Questions
Before finalizing any output, verify:
- Does any step require a comparator, subgroup field, or onset variable that was never declared earlier?
- Does any signal-selection step assume evidence absent from the configuration?
- Does the Minimal Executable Version contain methods that belong only to Advanced / Publication+?
- Are all endpoint formulas logically valid given the available inputs?

If the answer to any of the above is yes, the plan must be revised before output.

### Intersection Formula Reference

Every endpoint-selection step must declare its exact logic formula. Valid examples:
- suspect-drug cases only
- suspect-drug cases ∩ fixed SOC/PT family
- suspect-drug cases ∩ fixed SOC/PT family ∩ active-comparator restriction
- suspect-drug cases ∩ signal-positive PTs ∩ robustness-stable PTs

The skill must not switch from one formula to another silently.
