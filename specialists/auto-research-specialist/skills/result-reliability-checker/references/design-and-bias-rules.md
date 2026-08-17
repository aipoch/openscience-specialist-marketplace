# Design and Bias Rules
# result-reliability-checker

---

## Goal

This module checks whether the result-producing design is fit for purpose and whether major bias sources were controlled, ignored, or worsened by analysis choices.

---

## Core Audit Questions

### 1. Design Fit
- Can this design answer the stated question?
- Is the claim observational, predictive, causal, diagnostic, prognostic, mechanistic, or implementation-oriented?
- Does the design match that claim family?

### 2. Sample Construction
- How were participants, samples, datasets, or experiments selected?
- Are inclusion and exclusion choices likely to distort the result?
- Is there case-control imbalance, survivorship bias, referral bias, or convenience sampling risk?

### 3. Group Comparability / Confounding
- Are the compared groups meaningfully comparable?
- Were important confounders measured and adjusted when needed?
- Is residual confounding likely to remain large?

### 4. Timing and Leakage
- Does any variable use future information or post-outcome information?
- Could temporal leakage or information leakage inflate the result?
- Is model development separated cleanly from evaluation?

### 5. Missingness / Attrition / Selection Processes
- Were missing data and exclusions handled transparently?
- Could drop-out, filtering, QC thresholds, or sample attrition change the conclusion materially?

---

## Strong Rules

- A design mismatch is a major reliability downgrade.
- Uncontrolled major confounding must not be described as a minor caveat.
- Leakage risk must always be treated as a potentially severe flaw for predictive work.
- Convenience cohorts with narrow sampling frames require caution even if the statistics look strong.
