# Algorithm Notes

## Overview

This skill normalizes gene or protein expression matrices using one of three deterministic methods:

1. `log2`: `log2(x + pseudo_count)`
2. `zscore`: centering and scaling along rows or columns
3. `minmax`: rescaling values to the interval `[0, 1]` along rows or columns

## Input Assumptions

- The first column contains feature identifiers.
- Remaining columns are numeric expression values.
- Missing values are not supported in this implementation.
- `margin=column` means sample-wise normalization.
- `margin=row` means feature-wise normalization.

## Method Details

### Log2 Transform

- Used to compress right-skewed expression ranges.
- Requires all `x + pseudo_count` values to be strictly positive.

### Z-Score Standardization

- Computes `(x - mean) / sd` along the selected margin.
- If a vector has zero variance, its standardized result is set to zero.
- `center=false` and `scale_values=true` is allowed and divides by standard deviation without mean subtraction.

### Min-Max Scaling

- Computes `(x - min) / (max - min)` along the selected margin.
- If `max == min`, the vector is returned as zeros.

## Interpretation

- `log2` is useful for visualization and variance compression.
- `zscore` emphasizes relative up/down shifts.
- `minmax` makes variables comparable on a common bounded scale.

These methods are preprocessing steps. They do not correct batch effects or replace proper count-model normalization for differential expression workflows.
