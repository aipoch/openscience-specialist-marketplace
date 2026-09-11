# Algorithm Notes

## Overview

This skill runs the ESTIMATE workflow on a bulk expression matrix to derive immune-related tumor microenvironment scores for each sample.

The core pipeline is:

1. Convert the input expression matrix into the tab-delimited format expected by `estimate::filterCommonGenes()`.
2. Filter the matrix to the common gene set used by ESTIMATE and save the result as `estimate_input.gct`.
3. Run `estimate::estimateScore()` to compute ESTIMATE-derived scores and save the result as `estimate_score.gct`.
4. Reformat the score matrix into a sample-by-score table for downstream inspection.

## Method Summary

`estimate` is designed to infer stromal and immune content from bulk tumor expression profiles using predefined gene signatures. The package reports score rows such as:

- `StromalScore`
- `ImmuneScore`
- `ESTIMATEScore`

Depending on the package version and downstream processing, related purity-derived metrics may also be present in the raw GCT output.

## Input Assumptions

- The first column contains gene identifiers.
- Remaining columns are sample-level expression values.
- Expression values are numeric and contain no missing values.
- Gene identifiers are consistent with the selected `--gene_id_type`.

## Platform Parameter

The `--platform` argument is passed directly to `estimate::estimateScore()`.

Supported values in this skill:

- `affymetrix`
- `agilent`
- `illumina`

Choose the platform that best matches the preprocessing assumptions of your expression matrix.

## Result Interpretation

- Higher `ImmuneScore` suggests stronger immune-related transcriptomic signal.
- Higher `StromalScore` suggests stronger stromal-related transcriptomic signal.
- `ESTIMATEScore` summarizes microenvironment-related signal captured by the ESTIMATE model.

These scores are descriptive and should not be treated as clinical diagnostics.

## Scope Boundary

This skill performs ESTIMATE score generation only.

With an optional sample group file, the skill also performs score-level group comparison for:

- `StromalScore`
- `ImmuneScore`
- `ESTIMATEScore`

It reports p-values and the group with the higher median score, and renders a boxplot summary.

The skill also renders a score heatmap across samples using the ESTIMATE-derived score table. When a group file is supplied, the heatmap uses the group assignments as column annotations.

It does not:

- perform differential testing between groups
- perform single-cell analysis
- estimate immune cell subtype fractions
- provide clinical decision support
