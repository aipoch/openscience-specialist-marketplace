# Gap-to-Design Traceability Rules
# medical-research-gap-to-study-planner

---

## Core Principle

Every part of the proposed protocol must be traceable back to the stated gap.
If a module, assay, dataset, or analysis does not directly help close the gap, it should not be included in the primary plan.

---

## Mandatory Traceability Questions

Before finalizing any protocol, verify:

1. **What exactly is missing in the current evidence chain?**
2. **Which aim addresses that missing piece?**
3. **What evidence will that aim generate?**
4. **Is that evidence actually sufficient to narrow or close the gap?**
5. **What will still remain unresolved even after the study is completed?**

If any aim cannot be mapped to one of these questions, the plan is too generic and must be revised.

---

## Required Dependency Map Format

| Gap Component | Why It Exists | Which Aim Addresses It | Evidence Generated | What This Still Cannot Prove |
|---|---|---|---|---|

This map is mandatory. Do not omit it.

---

## Forbidden Drift Patterns

The following are common design failures and must be rejected:

1. **Generic workflow drift**
   - replacing a specific gap with a standard DEG/survival/enrichment workflow that does not directly answer the question.

2. **Fashion-module drift**
   - adding scRNA, spatial, MR, machine learning, or wet-lab modules only because they are publishable, not because they are necessary.

3. **Claim inflation drift**
   - using association-level evidence to support mechanism, causality, or clinical utility claims.

4. **Minimal-plan collapse**
   - shrinking the study so far that it no longer closes the core gap.

---

## Resource Consistency Rules

A downstream module may appear only if its prerequisites are explicitly available.

Examples:
- scRNA/spatial localization requires appropriate single-cell or spatial data, or a clearly declared and limited projection strategy
- treatment-response prediction requires meaningful treatment and outcome labels
- protein-level conclusions require protein-support evidence
- causal claims require valid causal-support data or assumptions that are openly defended

If a resource is absent, downgrade the claim or redesign the plan.

---

## Necessary / Recommended / Optional Discipline

Every major module must be labeled:
- **Necessary**: essential for closing the core gap
- **Recommended**: substantially strengthens the claim but not strictly required
- **Optional**: helpful extension or publication upgrade only

Do not allow optional modules to dominate the minimal executable version.
