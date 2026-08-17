# Reliability Audit Framework
# result-reliability-checker

---

## Goal

This module forces the skill to audit **whether results deserve trust**, not merely whether they look interesting.

---

## Required Reliability Table

| Main Claim / Result | Evidence Chain | Main Strengths | Main Fragility Points | Validation Status | Reliability Judgment |
|---|---|---|---|---|---|

---

## Reliability Judgment Levels

### 1. High Reliability
Use only when the result is supported by:
- an appropriate design for the claim,
- credible statistical handling,
- low or well-managed major bias risk,
- and convincing validation or replication for the relevant claim type.

### 2. Moderate Reliability
Use when the result is plausible and usable with caution, but one or more important weaknesses remain.
Examples:
- modest sample limitations,
- residual confounding,
- external validation still limited,
- incomplete robustness checks.

### 3. Limited Reliability
Use when the signal may be real but the support chain is notably weak.
Examples:
- small sample,
- unstable subgroup findings,
- many variables relative to sample size,
- internal validation only,
- heavy dependence on one dataset or one pipeline.

### 4. Low Reliability / Strongly Cautionary
Use when the result is highly vulnerable to bias, instability, leakage, overfitting, or overclaiming.
Examples:
- no meaningful validation,
- major confounding not controlled,
- multiple-testing burden not addressed,
- design cannot support the claimed interpretation.

---

## Use Rule

If different claims in one paper land at different levels, report them separately.
Do not flatten the entire paper into one label if the evidence chain is mixed.
