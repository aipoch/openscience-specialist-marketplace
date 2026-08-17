# Gap Taxonomy and Audit Standard
# medical-research-gap-finder

---

## Goal

This module forces the agent to produce **evidence-audited, topic-specific gaps** instead of generic “more research is needed” statements.

---

## Approved Gap Types

### 1. Knowledge Gap
A biologically or clinically important question remains unresolved.

### 2. Evidence Gap
The available evidence is sparse, low-level, indirect, or poorly validated.

### 3. Consistency Gap
Studies disagree, and the source of inconsistency is not well explained.

### 4. Population Gap
Important populations, subgroups, or real-world contexts are underrepresented.

### 5. Stage / Context Gap
Disease stage, treatment phase, tissue context, or temporal state is insufficiently resolved.

### 6. Method-Resolution Gap
Existing methods are too coarse to answer the actual question.

### 7. Validation Gap
Discovery exists, but external, functional, or clinically relevant validation is weak.

### 8. Mechanism-to-Translation Gap
Mechanistic findings are not linked to clinically useful stratification, prediction, or intervention logic.

### 9. Implementation Gap
A potentially useful finding exists, but real-world adoption, workflow integration, or operational utility is not demonstrated.

---

## Final Gap Table — Required Columns

Use this exact logic in the final Structured Gap Map:

| Gap ID | Gap Type | Gap Statement | Audit Basis | Why This Is a Real Gap | Why It Matters | Minimal Study That Can Answer It | Confidence |
|---|---|---|---|---|---|---|---|

---

## How to Write Each Column

### Gap Statement
Must be specific enough to become a research question.
Avoid label-style statements like “lack of validation” or “need more omics.”

### Audit Basis
Must summarize what the retrieved literature already covers.
Examples:
- most studies stop at computational prediction
- only one small external cohort exists
- direct gastric-cancer evidence is scarce while adjacent evidence exists in CRC/HCC
- studies focus on tumor bulk expression and do not resolve cell-state localization

### Why This Is a Real Gap
Must explain why this is not just a generic upgrade wish.
A valid explanation often includes:
- topic-specific unresolved question
- demonstrated blind spot in the field
- practical consequence of not knowing the answer

### Minimal Study That Can Answer It
Must state one coherent study style capable of addressing the gap.
If no plausible study can answer it, the item should not be a priority gap.

### Confidence
Use only:
- **High**: strong direct audit basis and low ambiguity
- **Medium**: reasonable basis, but some dependence on adjacent evidence or incomplete indexing
- **Low**: weakly supported, highly inferential, or overly broad

Low-confidence items should usually be excluded from Top Priority Opportunities.

---

## High-Credibility Gap Criteria

A gap should enter the final map only if it satisfies at least 4 of the following:
1. Explicit retrieved literature base exists
2. Current coverage has been summarized
3. The gap is topic-specific
4. The gap is not merely a generic upgrade suggestion
5. The gap can be converted into a clear research question
6. A plausible study design can answer it
7. The gap has scientific, translational, or implementation importance

---

## Low-Credibility Signals

If any item shows two or more of the following, downgrade or reject it:
- the statement would fit almost any disease area
- it simply says “more validation,” “more multi-omics,” or “larger cohorts”
- it has no explicit audit basis
- it cannot be converted into a clear study question
- it sounds like technology stacking instead of scientific reasoning
- it does not explain why the missing answer matters

---

## Prohibited Output Style

Do not write gaps like:
- “There is a lack of multi-omics integration.”
- “Clinical validation is insufficient.”
- “Dynamic changes are underexplored.”
- “Single-cell studies are needed.”

Unless rewritten into an audited, topic-specific, question-like form.
