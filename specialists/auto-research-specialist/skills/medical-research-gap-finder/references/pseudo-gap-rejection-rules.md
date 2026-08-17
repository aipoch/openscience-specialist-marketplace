# Pseudo-Gap Rejection Rules
# medical-research-gap-finder

---

## Goal

This module prevents the skill from mistaking generic research-upgrade ideas for real research gaps.

---

## Common Pseudo-Gap Classes

### 1. Generic Upgrade Pseudo-Gap
Examples:
- add single-cell
- add spatial transcriptomics
- add clinical validation
- add multi-omics integration
- increase sample size

These are not real gaps unless tied to a demonstrated unresolved scientific question in the retrieved literature.

### 2. Template-Reuse Pseudo-Gap
The proposed “gap” is just a standard paper template transplanted into a new disease or pathway.

### 3. Pseudo-Firstness
The claim depends only on “few or no studies found,” without showing why the unanswered question matters.

### 4. Non-Closable Gap
The claim is so broad that no coherent study could actually answer it.

### 5. Low-Value Replication Gap
The gap is only a small repetition of what has already been shown, without a strong reproducibility, generalizability, or contradictory-evidence rationale.

---

## Mandatory Rejection Check

For every candidate gap, ask:
1. Would this statement still sound true if I replaced the disease with another one?
2. Is this mostly a request for “more methods / more validation / more omics” rather than a real unanswered question?
3. Can I point to what the field has already done and what exact part remains unresolved?
4. Can one coherent study actually answer it?
5. Does the missing answer materially change biology, translation, or implementation understanding?

If the answer pattern is weak, reject or downgrade the item.

---

## Output Requirement

The final report must contain a section called **Pseudo-Gaps Rejected**.
Each rejected item should include:
- candidate pseudo-gap
- why it looked plausible
- why it was rejected
- whether it remains an optional upgrade module rather than a real gap

---

## Strong Rule

Generic upgrade suggestions must never appear in Top Priority Opportunities unless they have first survived the pseudo-gap rejection check and been rewritten into a topic-specific unresolved question.
