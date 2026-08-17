# Method Selection Rules
# medical-research-gap-to-study-planner

---

## General Rule

Choose methods because they are logically required by the gap and the available data.
Do not choose methods just because they are common, fashionable, or publication-friendly.

---

## Example Fit Rules

### Reproducibility / Evidence Density Gap
Prefer:
- independent validation cohorts
- sensitivity analyses
- reproducibility-focused statistics

Avoid replacing this with unrelated omics expansion unless clearly justified.

### Cell-State / Microenvironment Gap
Prefer:
- scRNA-seq
- spatial transcriptomics
- carefully justified deconvolution / projection

Avoid claiming cell-specific conclusions from bulk data alone.

### Translation / Utility Gap
Prefer:
- clinically interpretable endpoints
- subgroup or response analyses
- independent utility validation

Avoid implementation language if there is no real clinical bridge.

### Causality Gap
Prefer:
- MR, QTL, mediation, perturbation, or longitudinal structure only when assumptions are supportable

Avoid causal language if data only support association.

---

## Transcriptomic Differential Analysis Rule

When transcriptomic differential analysis is involved:
- **count data → DESeq2 preferred**
- **non-count normalized expression data → limma**

This rule must be stated explicitly whenever such analyses appear in the workflow.
