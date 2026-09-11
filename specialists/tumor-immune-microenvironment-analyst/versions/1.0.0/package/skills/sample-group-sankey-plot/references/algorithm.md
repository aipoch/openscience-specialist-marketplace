# Algorithm — Sample Group Sankey Plot

## Overview

This skill uses the **ggalluvial** package (Brunson 2020) to build Sankey/alluvial diagrams from categorical sample annotation tables.

## Alluvial Transformation

1. **Input:** A wide-format annotation table where each row is a sample and each selected column is a categorical stage.
2. **Missing value normalisation:** Blank strings and `NA` values are replaced with the `--missing_label` value (default: `"Missing"`) to ensure all strata are named.
3. **Row identifier:** A synthetic `sample_id` column (`sample_1`, `sample_2`, …) is added as the alluvium key — it traces each sample's path across stages.
4. **Lodes conversion:** `ggalluvial::to_lodes_form()` converts the wide table to long format, producing one row per (sample × stage) combination with columns `sample_id`, `x` (stage name), and `stratum` (category value).

## Plotting Choices

- `geom_flow()` draws the ribbons connecting strata across stages (transparency controlled by `--alpha`).
- `geom_stratum()` draws the stacked bars at each stage.
- `stat_stratum()` renders stratum labels (size controlled by `--label_size`).
- `theme_void()` removes axis clutter; the legend is suppressed because labels are rendered inline.
- Output is written as a PDF using `ggplot2::ggsave()`.

## Readability Assumptions

- **Stages:** Fewer than 5 stages produce a readable flow diagram. At 5 stages the plot fills the default width; beyond 5, readability degrades.
- **Unique values per stage:** Fewer than 8 unique values per stage prevent colour overload. When a stage has more than 8 unique values the ribbons become visually indistinguishable.

## Reproducibility

`--seed` is passed to `set.seed()` before analysis. Because ggalluvial's alluvial transformation is deterministic (no random component), the seed mainly ensures that any downstream operations relying on random state remain reproducible.

## Citation

Brunson JC (2020) ggalluvial: Layered Grammar for Alluvial Plots. *Journal of Open Source Software*. doi:10.21105/joss.02017
