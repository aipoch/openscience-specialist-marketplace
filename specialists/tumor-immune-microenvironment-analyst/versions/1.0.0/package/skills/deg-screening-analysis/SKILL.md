---
name: deg-screening-analysis
description: Use when screening differentially expressed genes from a bulk expression matrix between two user-specified groups, producing DEG tables, a volcano plot, and a clustered heatmap. Triggers include DEG analysis, volcano plot, clustered heatmap, limma-based two-group comparison, and case-vs-control screening. NOT for single-cell RNA-seq, multi-group contrasts, count-model workflows such as DESeq2/edgeR, or non-expression omics data.
license: MIT
author: AIPOCH
---
> **Source**: [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills)

# Differential Expression Gene Screening Analysis (Volcano Plot & Clustered Heatmap)

## When to Use

Use this skill when you need a reproducible two-group DEG workflow on a bulk expression matrix and want:
- a full differential expression table
- a filtered DEG table
- a volcano plot
- a clustered heatmap of top differential genes

Typical requests include:
- compare case vs control samples with limma
- screen upregulated and downregulated genes from a normalized expression matrix
- generate a DEG table with volcano and heatmap outputs from bulk transcriptome data

## Out of Scope

Do not use this skill for:
- single-cell RNA-seq workflows
- multi-group contrasts or factorial designs
- count-model pipelines that require `DESeq2` or `edgeR`
- batch correction, covariate-adjusted models, or generalized design-matrix consulting
- non-expression omics data

If the request falls outside this scope, stop and hand off to a more appropriate analysis workflow instead of forcing the data through this skill.

## Practical Caveats

- `Diffanalysis.csv` currently exports `name`, `logFC`, `P.value`, and `P.adj`.
- `--p_type` controls both DEG screening semantics and volcano plot significance semantics.
- `plot/heatmap.pdf` is generated only when at least two heatmap genes remain after ranking.
- When the result is very sparse, prefer keeping tables and volcano output as the primary artifacts.

## When to Read External Files

| Situation | File to Read | Purpose |
|-----------|--------------|---------|
| Need algorithm details or statistical assumptions | `references/algorithm.md` | limma method, filtering logic, volcano/heatmap selection rules |
| Need to execute the workflow | `scripts/main.R` | Get the exact CLI entry and runnable command |
| Encounter an error code or bad input format | `references/troubleshooting.md` | Match `SKILL_*` errors to causes and fixes |
| Need more CLI examples | `references/cli-guide.md` | See complete command examples for common use cases |
| Need a minimal runnable example | `tests/data/` | Use bundled test input files for validation |

## Usage

```bash
Rscript scripts/main.R \
  --input_file tests/data/oa_exp.csv \
  --group_file tests/data/oa_group.csv \
  --case OA \
  --control control \
  --output_dir ./results
```

## Arguments

| Short | Long | Type | Default | Required | Description |
|-------|------|------|---------|----------|-------------|
| `-i` | `--input_file` | character | none | yes | Expression matrix CSV. First column is gene ID, remaining columns are sample values. |
| `-g` | `--group_file` | character | none | yes | Group annotation CSV. The script auto-detects sample and group columns, including files where the first column is row names or index. |
| `-o` | `--output_dir` | character | `./DEG` | no | Output directory for tables, plots, and session metadata. |
| ` ` | `--case` | character | none | yes | Case group name to compare. Matching is case-insensitive and trimmed. |
| ` ` | `--control` | character | none | yes | Control group name to compare. Matching is case-insensitive and trimmed. |
| `-m` | `--diff_method` | character | `limma` | no | Differential expression method. Current implementation supports `limma` only. |
| `-p` | `--p_threshold` | numeric | `0.05` | no | Significance threshold for DEG screening. |
| `-f` | `--logfc_threshold` | numeric | `1` | no | Absolute log fold change threshold for DEG screening. |
| ` ` | `--top_n` | integer | `5` | no | Number of top upregulated and top downregulated genes considered for heatmap selection. |
| ` ` | `--p_type` | character | `p.adj` | no | P-value field used for significance filtering and volcano significance coloring. Allowed values: `p`, `p.adj`. |
| ` ` | `--run_plots` | logical | `TRUE` | no | Whether to generate the volcano plot and clustered heatmap. |
| ` ` | `--timeout_seconds` | integer | `3600` | no | Maximum allowed runtime before timeout. |
| `-s` | `--seed` | integer | `42` | no | Random seed recorded for reproducibility. |

## Output Files

| File | Format | Description |
|------|--------|-------------|
| `session_info.txt` | txt | R session metadata and package versions used in the run. |
| `data/DEG_list.rda` | rda | Serialized R object containing method, groups, thresholds, the full differential table, and the screened DEG table. |
| `table/Diffanalysis.csv` | csv | Full differential expression result table with columns `name`, `logFC`, `P.value`, and `P.adj`. |
| `table/DEG.csv` | csv | Significant DEG table only, containing screened genes with `group` labels `up` or `down`. |
| `plot/volcano_plot.pdf` | pdf | Volcano plot of differential genes using the p-value mode selected by `--p_type`. |
| `plot/heatmap.pdf` | pdf | Clustered heatmap for selected top differential genes when at least two heatmap genes are available and plotting is enabled. |

## Workflow

### Step 1: Validate Input
- check that input files exist
- load the expression matrix and ensure it is non-empty
- auto-detect sample and group columns in the group file
- verify sample IDs overlap correctly
- verify case/control groups exist and each selected group has at least two samples

### Step 2: Run Differential Expression
- fit a two-group limma linear model
- build the contrast `case - control`
- compute empirical Bayes moderated statistics
- export the full differential result table

### Step 3: Screen Differentially Expressed Genes
- apply `p_threshold` and `logfc_threshold`
- use `P.value` or `P.adj` based on `--p_type`
- label genes as `up`, `down`, or `no`
- export DEG tables and serialized result objects

### Step 4: Generate Volcano Plot & Clustered Heatmap
- build `plot/volcano_plot.pdf` directly from the full differential table
- select top up and top down genes for heatmap input
- build `plot/heatmap.pdf` only when at least two heatmap genes are available

## Error Handling

| Error Code | Meaning | Typical Fix |
|------------|---------|-------------|
| `SKILL_FILE_NOT_FOUND` | Input file path does not exist | Verify the file path and rerun |
| `SKILL_PACKAGE_NOT_FOUND` | Required R package is missing | Install the missing package, then rerun |
| `SKILL_MISSING_COLUMNS` | Input file does not contain the necessary columns | Check CSV structure and column placement |
| `SKILL_EMPTY_DATA` | Input file is empty or limma returns no analyzable rows | Validate input content or confirm the matrix contains enough valid values |
| `SKILL_INVALID_PARAMETER` | Argument value or group selection is invalid | Check thresholds, `--case`, `--control`, and `--p_type` |
| `SKILL_SAMPLE_MISMATCH` | Expression matrix samples and group file samples do not match | Align sample IDs between the two input files |
| `SKILL_TIMEOUT` | The run exceeded the allowed runtime | Increase `--timeout_seconds` or simplify the run |

If you need step-by-step fixes, read `references/troubleshooting.md`.

## Testing

```bash
Rscript tests/run_tests.R
```

Minimal CLI smoke test:

```bash
Rscript scripts/main.R \
  --input_file tests/data/oa_exp.csv \
  --group_file tests/data/oa_group.csv \
  --case OA \
  --control control \
  --output_dir ./tests_output
```

Expected outputs:
- `tests_output/table/Diffanalysis.csv`
- `tests_output/table/DEG.csv`
- `tests_output/plot/volcano_plot.pdf`
- `tests_output/session_info.txt`

`tests_output/plot/heatmap.pdf` is expected only when enough significant genes remain for heatmap rendering.
Runs with fewer than two selected heatmap genes skip heatmap generation with a warning instead of failing.
`tests_output/table/DEG.csv` may be empty when no genes pass the current thresholds.

*Skill name: deg-screening-analysis*
