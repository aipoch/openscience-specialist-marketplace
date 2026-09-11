# CLI Guide

## Install Dependencies

```r
install.packages(c("optparse", "pheatmap"))
if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager")
BiocManager::install(c("GSVA", "limma"))
```

## Validated Compatibility

The current validated container uses the following package combination:

- `R 4.1.2`
- `GSVA 1.42.0`
- `matrixStats 1.1.0`
- `Matrix 1.5.1`

Compatibility note:

- `GSVA 1.42.0` may fail with a `useNames` error when paired with newer `matrixStats` releases such as `1.5.0`.
- For the validated `R 4.1.x` environment, keep `matrixStats` pinned to `1.1.0`.

Recommended installation for the validated container:

```r
install.packages("remotes")
remotes::install_version("matrixStats", version = "1.1.0")
```

Version check:

```r
packageVersion("GSVA")
packageVersion("matrixStats")
packageVersion("Matrix")
R.version.string
```

## External Gene-Set Preparation

Use a local immune Reactome gene-set CSV exported in advance.

Recommended approach outside the main analysis script:

```r
library(dplyr)
library(msigdbr)

all_reactome_genesets <- msigdbr(
  species = "Homo sapiens",
  category = "C2",
  subcategory = "CP:REACTOME"
)

immune_genesets <- all_reactome_genesets %>%
  filter(grepl(
    "IMMUNE|IMMUNITY|INFLAMM|LYMPH|CYTOKINE|INTERFERON|ANTIGEN|T_CELL|B_CELL|NK_CELL",
    gs_name,
    ignore.case = TRUE
  ))

write.csv(immune_genesets, "immune_genesets.csv", row.names = FALSE)
```

Do not place this download or preprocessing logic inside `scripts/main.R`.

## Fixture Notes

- `tests/data/expression_matrix.csv`, `tests/data/group_info.csv`, and `tests/data/immune_genesets.csv` are the validated bundled smoke-test trio.
- The bundled smoke-test trio is meant to prove execution, output structure, and provenance logging. It may legitimately produce zero pathways at the default `FDR <= 0.05`, which triggers the documented fallback ranking by `|t|`.
- `tests/data/immune_genesets_minimal.csv` is a minimal fixture for narrow tests and helper validation. It is not a guaranteed drop-in partner for `tests/data/expression_matrix.csv` unless you also use a matrix with overlapping genes.

## CLI Examples

### Example 1: Full Workflow

```bash
Rscript scripts/main.R \
  --mode full \
  --input_file tests/data/expression_matrix.csv \
  --group_file tests/data/group_info.csv \
  --geneset_file tests/data/immune_genesets.csv \
  --case_group Tumor \
  --control_group Healthy \
  --focus_genesets REACTOME_INTERFERON_SIGNALING,REACTOME_ANTIGEN_PROCESSING \
  --output_dir ./tests/output \
  --seed 42
```

Expected behavior for the bundled smoke-test trio:

- The command should complete successfully.
- The command may log that no pathways passed the default `fdr_threshold`.
- The top-pathway export and heatmap can still be produced through fallback ranking by `|t|`.

### Example 2: Analysis Only

```bash
Rscript scripts/main.R \
  --mode analyze \
  --input_file ./expression_matrix.csv \
  --group_file ./group_info.csv \
  --geneset_file ./immune_genesets.csv \
  --case_group High \
  --control_group Low \
  --method ssgsea \
  --focus_genesets REACTOME_INTERFERON_SIGNALING,REACTOME_ANTIGEN_PROCESSING \
  --top_n 30 \
  --fdr_threshold 0.1 \
  --output_dir ./output/risk_run \
  --seed 42
```

### Example 3: Visualization Only

```bash
Rscript scripts/main.R \
  --mode visualize \
  --output_dir ./output/risk_run \
  --plot_file immune_heatmap_reused.pdf \
  --focus_genesets REACTOME_INTERFERON_SIGNALING,REACTOME_ANTIGEN_PROCESSING \
  --top_up 10 \
  --top_down 10 \
  --top_mode both \
  --append_stats TRUE
```

### Example 4: Custom Gene-Set Columns

```bash
Rscript scripts/main.R \
  --mode analyze \
  --input_file ./expression_matrix.csv \
  --group_file ./group_info.csv \
  --geneset_file ./immune_genesets_alt.csv \
  --geneset_column pathway_name \
  --gene_column symbol \
  --case_group High \
  --control_group Low \
  --output_dir ./output/custom_columns \
  --seed 42
```

Use this pattern when the local gene-set table does not use the default `gs_name` and `gene_symbol` headers.

## Validated Test Baseline

This section records the latest validated execution using the bundled test data in `tests/data/`. Replace it with a project-specific baseline if you later validate the skill on a real cohort.

### Environment

- Execution context: local validated test run from the skill root
- Platform: `Ubuntu 20.04.5 LTS`
- R version: `4.1.2`
- Command family: `Rscript tests/run_unit_tests.R`, `Rscript tests/run_tests.R`, `Rscript tests/test_skill.R`
- Seed: `42`
- Status: `Passed on 2026-04-20`

### Validated Package Versions

- `GSVA 1.42.0`
- `limma 3.50.3`
- `matrixStats 1.1.0`
- `Matrix 1.5-1`
- `optparse 1.7.5`
- `pheatmap 1.0.13`

Compatibility guard:

- This skill fails fast with `SKILL_VERSION_INCOMPATIBLE` when it detects `GSVA 1.42.0` together with `matrixStats >= 1.2.0`.

### Input Files

- Expression matrix: `tests/data/expression_matrix.csv`
- Group file: `tests/data/group_info.csv`
- Gene-set file: `tests/data/immune_genesets.csv`
- Gene-set source: bundled local immune Reactome subset for smoke testing
- Comparison: `Tumor` versus `Healthy`

### Interpreting The Bundled Demo Run

- Treat the bundled run as a smoke test and output-structure baseline, not as a benchmark expected to yield significant pathways.
- A successful bundled run can still report `0` pathways at the selected `fdr_threshold` and remain valid.
- If you need a showcase run with stronger pathway separation, prepare a project-specific positive-control dataset.

### Validation Commands

Boundary and parameter validation checks:

```bash
Rscript tests/run_unit_tests.R
```

Full smoke test with analysis and visualize-mode reuse:

```bash
Rscript tests/run_tests.R
```

Direct full workflow baseline command:

```bash
Rscript scripts/main.R \
  --mode full \
  --input_file tests/data/expression_matrix.csv \
  --group_file tests/data/group_info.csv \
  --geneset_file tests/data/immune_genesets.csv \
  --case_group Tumor \
  --control_group Healthy \
  --focus_genesets REACTOME_INTERFERON_SIGNALING,REACTOME_ANTIGEN_PROCESSING \
  --output_dir tests/output \
  --seed 42
```

Visualize-only reuse command:

```bash
Rscript scripts/main.R \
  --mode visualize \
  --output_dir tests/output \
  --plot_file reused_heatmap.pdf \
  --top_up 2 \
  --top_down 1 \
  --top_mode both
```
