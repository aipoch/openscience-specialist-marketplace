---
name: tooluniverse-clinical-trial-design
description: Strategic clinical trial design feasibility assessment using ToolUniverse. Evaluates patient population sizing, biomarker prevalence, endpoint selection, comparator analysis, safety monitoring, and regulatory pathways. Creates comprehensive feasibility reports with evidence gr...
license: MIT
author: AIPOCH
---
> **Source**: [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills)


# Clinical Trial Design Feasibility Assessment

Systematically assess clinical trial feasibility by analyzing 6 research dimensions. Produces comprehensive feasibility reports with quantitative enrollment projections, endpoint recommendations, and regulatory pathway analysis.

**IMPORTANT**: Always use English terms in tool calls (drug names, disease names, biomarker names), even if the user writes in another language. Only try original-language terms as a fallback if English returns no results. Respond in the user's language.

## Core Principles

### 1. Report-First Approach (MANDATORY)
**DO NOT** show tool outputs to user. Instead:
1. Create `[INDICATION]_trial_feasibility_report.md` FIRST
2. Initialize with all section headers
3. Progressively update as data arrives
4. Present only the final report

### 2. Evidence Grading System

| Grade | Symbol | Criteria | Examples |
|-------|--------|----------|----------|
| **A** | ★★★ | Regulatory acceptance, multiple precedents | FDA-approved endpoint in same indication |
| **B** | ★★☆ | Clinical validation, single precedent | Phase 3 trial in related indication |
| **C** | ★☆☆ | Preclinical or exploratory | Phase 1 use, biomarker validation ongoing |
| **D** | ☆☆☆ | Proposed, no validation | Novel endpoint, no precedent |

### 3. Feasibility Score (0-100)
Weighted composite score:
- **Patient Availability** (30%): Population size × biomarker prevalence × geography
- **Endpoint Precedent** (25%): Historical use, regulatory acceptance
- **Regulatory Clarity** (20%): Pathway defined, precedents exist
- **Comparator Feasibility** (15%): Standard of care availability
- **Safety Monitoring** (10%): Known risks, monitoring established

**Interpretation**: ≥75 = HIGH (proceed) | 50-74 = MODERATE (validate) | <50 = LOW (de-risk)

→ Detailed scoring rules: [references/scoring_and_endpoints.md](references/scoring_and_endpoints.md)

---

## When to Use This Skill

Apply when users:
- Plan early-phase trials (Phase 1/2 emphasis)
- Need enrollment feasibility assessment
- Design biomarker-selected trials
- Evaluate endpoint strategies
- Assess regulatory pathways
- Compare trial design options
- Need safety monitoring plans

**Trigger phrases**: "clinical trial design", "trial feasibility", "enrollment projections", "endpoint selection", "trial planning", "Phase 1/2 design", "basket trial", "biomarker trial"

**NOT for**:
- Patient-to-trial matching → use `tooluniverse-clinical-trial-matching`
- Phase 3/4 confirmatory trial design → needs specialized biostatistics consultation
- Post-market surveillance or pharmacovigilance → use `tooluniverse-adverse-event-detection`
- Regulatory submission document preparation → use specialized regulatory affairs tools

---

## Quick Start

```python
from tooluniverse import ToolUniverse

tu = ToolUniverse(use_cache=True)
tu.load_tools()

# Example: EGFR+ NSCLC trial feasibility
indication = "EGFR-mutant non-small cell lung cancer"
biomarker = "EGFR L858R"

# Step 1: Get disease prevalence
disease_info = tu.tools.OpenTargets_get_disease_id_description_by_name(
    diseaseName="non-small cell lung cancer"
)

# Step 2: Estimate biomarker prevalence
variants = tu.tools.ClinVar_search_variants(gene="EGFR", significance="pathogenic")

# Step 3: Find precedent trials
trials = tu.tools.search_clinical_trials(
    condition="EGFR positive non-small cell lung cancer",
    status="completed", phase="2"
)

# Step 4: Identify standard of care comparator
soc_drugs = tu.tools.FDA_OrangeBook_search_drugs(ingredient="osimertinib")

# Compile into feasibility report...
```

---

## Core Strategy: 6 Research Paths

Execute 6 parallel research dimensions:

```
Trial Design Query (e.g., "EGFR+ NSCLC trial, Phase 2, ORR endpoint")
│
├─ PATH 1: Patient Population Sizing
│   Disease prevalence → Biomarker prevalence → Eligibility funnel → Enrollment projection
│
├─ PATH 2: Biomarker Prevalence & Testing
│   Mutation frequency → CDx availability → Turnaround time → Alternative biomarkers
│
├─ PATH 3: Comparator Selection
│   Standard of care → Approved comparators → Historical controls → Placebo appropriateness
│
├─ PATH 4: Endpoint Selection
│   Primary endpoint precedents → FDA acceptance → Measurement feasibility → Surrogate vs clinical
│
├─ PATH 5: Safety Endpoints & Monitoring
│   Mechanism-based toxicity → Class effects → Organ monitoring → SMC plan
│
└─ PATH 6: Regulatory Pathway
    Regulatory precedents → Breakthrough potential → Orphan designation → FDA guidance
```

→ Detailed execution instructions & tool calls: [references/research_paths_detail.md](references/research_paths_detail.md)

---

## Report Structure (14 Sections)

Create `[INDICATION]_trial_feasibility_report.md` with:

### 1. Executive Summary
```markdown
# Clinical Trial Feasibility Report: [INDICATION]
**Date**: [YYYY-MM-DD] | **Trial Type**: [Phase 1/2] | **Primary Endpoint**: [ORR]
**Feasibility Score**: [0-100] - [LOW/MODERATE/HIGH]

## Key Findings
- **Patient Availability**: [Est. enrollable patients/year]
- **Enrollment Timeline**: [Months to target N]
- **Endpoint Precedent**: [Grade A/B/C/D]
- **Regulatory Pathway**: [505(b)(1), breakthrough, orphan]
- **Critical Risks**: [Top 3]

## Go/No-Go Recommendation
[RECOMMEND PROCEED / ADDITIONAL VALIDATION / DO NOT RECOMMEND]
```

### 2. Disease Background — Indication, prevalence, SOC, unmet need
### 3. Patient Population Analysis — Funnel model with enrollment projections
### 4. Biomarker Strategy — Prevalence, CDx, logistics
### 5. Endpoint Selection & Justification — Primary/secondary/exploratory with evidence grades
### 6. Comparator Analysis — SOC, design options, drug sourcing
### 7. Safety Endpoints & Monitoring Plan — DLT, toxicities, organ monitoring, SMC
### 8. Study Design Recommendations — Phase, schema, eligibility, treatment plan, schedule
### 9. Enrollment & Site Strategy — Site selection, projections, recruitment
### 10. Regulatory Pathway — FDA pathway, precedents, pre-IND, IND timeline
### 11. Budget & Resource Considerations — Cost drivers, FTE requirements
### 12. Risk Assessment — Feasibility risks, scientific risks, mitigation
### 13. Success Criteria & Go/No-Go Decision — Phase 1/2 criteria, scorecard
### 14. Recommendations & Next Steps — Final recommendation, critical path, alternatives

→ Detailed section templates: [references/research_paths_detail.md](references/research_paths_detail.md)

---

## Feasibility Scorecard Template

```markdown
| Dimension | Weight | Score (0-10) | Weighted | Grade |
|-----------|--------|--------------|----------|-------|
| Patient Availability | 30% | [X] | [0.30×X] | [★★☆] |
| Endpoint Precedent | 25% | [X] | [0.25×X] | [★★★] |
| Regulatory Clarity | 20% | [X] | [0.20×X] | [★★☆] |
| Comparator Feasibility | 15% | [X] | [0.15×X] | [★★★] |
| Safety Monitoring | 10% | [X] | [0.10×X] | [★★☆] |
| **TOTAL** | **100%** | - | **[XX/100]** | - |
```

→ Full scoring algorithm & dimension guides: [references/scoring_and_endpoints.md](references/scoring_and_endpoints.md)

---

## Output Format Requirements

### Report File Naming
- `[INDICATION]_trial_feasibility_report.md`
- Example: `EGFR_L858R_NSCLC_trial_feasibility_report.md`

### Section Completeness
All 14 sections MUST be present (listed above).

### Evidence Grading Required In
Sections 1, 4, 5, 6, 7, 10, 13 — all key claims must carry evidence grades (★★★/★★☆/★☆☆/☆☆☆).

### Feasibility Score Transparency
Show calculation with raw scores, weights, and evidence sources.

---

## Tool Quick Reference

| Path | Primary Tools |
|------|--------------|
| PATH 1 | `OpenTargets_get_disease_id_description_by_name`, `OpenTargets_get_diseases_phenotypes`, `ClinVar_search_variants`, `gnomAD_search_gene_variants` |
| PATH 2 | `ClinVar_get_variant_details`, `COSMIC_search_mutations`, `gnomAD_get_variant_details` |
| PATH 3 | `drugbank_get_drug_basic_info_by_drug_name_or_id`, `FDA_OrangeBook_search_drugs`, `FDA_get_drug_approval_history` |
| PATH 4 | `search_clinical_trials`, `PubMed_search_articles`, `FDA_get_drug_approval_history` |
| PATH 5 | `drugbank_get_pharmacology_by_drug_name_or_drugbank_id`, `FAERS_search_reports_by_drug_and_reaction`, `FAERS_count_reactions_by_drug_event` |
| PATH 6 | `FDA_get_drug_approval_history`, `PubMed_search_articles`, `search_clinical_trials` |

All tools accessed via `tu.tools.<tool_name>(<params>)`. Use English for all query parameters.

---


## Input Validation

This skill accepts requests that match the documented purpose of `tooluniverse-clinical-trial-design` and include enough context to complete the workflow safely.

Do not continue the workflow when the request is out of scope, missing a critical input, or would require unsupported assumptions. Instead respond:

> `tooluniverse-clinical-trial-design` only handles its documented workflow. Please provide the missing required inputs or switch to a more suitable skill.

## References

| File | Content |
|------|---------|
| [references/research_paths_detail.md](references/research_paths_detail.md) | 6 Research Path detailed execution instructions, step-by-step code, report templates, tool references |
| [references/scoring_and_endpoints.md](references/scoring_and_endpoints.md) | Feasibility Score complete algorithm, dimension scoring criteria, endpoint selection decision tree, success criteria definitions |
| [references/examples_and_troubleshooting.md](references/examples_and_troubleshooting.md) | Complete EGFR L858R example, 5 use cases, common pitfalls, best practices, integration guide |

## Error Handling

- If required inputs are missing, state exactly which fields are missing and request only the minimum additional information.
- If the task goes outside the documented scope, stop instead of guessing or silently widening the assignment.
- If execution fails, report the failure point, summarize what can still be completed safely, and provide a manual fallback.
- Do not fabricate files, citations, data, search results, or execution outcomes.
