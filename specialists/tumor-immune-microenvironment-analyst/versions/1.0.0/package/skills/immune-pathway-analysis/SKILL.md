---
name: immune-pathway-analysis
description: Run immune pathway GSVA or ssGSEA analysis from a bulk expression matrix, a sample group file, and a local immune Reactome gene-set table, then export differential pathway results and a heatmap for two-group comparison.
license: MIT
author: AIPOCH
---
> **Source**: [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills)

# Immune Pathway Analysis

## When to Use

Use this skill when the goal is to quantify immune-related pathway activity from bulk expression data and compare pathway enrichment between two sample groups.

Typical requests:

- "Run immune pathway GSVA for these samples."
- "Score immune Reactome pathways and compare case versus control."
- "Generate an immune pathway heatmap from a saved result."
- "Use a local immune gene-set table for pathway scoring."

This skill is appropriate for:

- Bulk RNA-seq or microarray-like expression matrices
- Local immune Reactome gene-set tables prepared in advance
- Two-group pathway differential analysis with `limma`
- Reproducible CLI execution with append-only provenance files

## Execution Model

This is a hybrid skill.

1. Confirm the request is in scope with this `SKILL.md`.
2. Ask only for missing file paths or missing group labels.
3. Run `scripts/main.R` with the appropriate mode.
4. Use `--mode analyze` to score pathways and export tables.
5. Use `--mode visualize` to regenerate a heatmap from a saved result object.
6. Use `--mode full` to run analysis and visualization in one pass.
7. Read reference files only when you need deeper algorithm, troubleshooting, or CLI details.
8. After execution, report the output directory, scoring method, comparison groups, and the primary output files.

## Completion Format

After a successful run, summarize the outcome in 3 short parts:

1. Mode and method used, plus the compared groups.
2. Output directory and key files written.
3. Important warnings that affect interpretation, such as no pathways meeting `fdr_threshold` and fallback to `|t|` ranking.

Example completion summary:

> Completed immune pathway analysis in `./output/run_001` using `gsva` for `Case` versus `Control`. Key outputs: `table/immune_pathway_diff.csv`, `table/immune_pathway_scores.csv`, `data/immune_pathway_result.rds`, and `plot/immune_pathway_heatmap.pdf`. No pathways passed `FDR <= 0.05`, so the workflow used the documented fallback ranking by `|t|` for the top-pathway export and heatmap subset.

## When to Read External Files

| Situation | File to Read | Purpose |
|-----------|--------------|---------|
| Need method details or interpretation guidance | `references/algorithm.md` | Review GSVA logic, limma comparison, and interpretation guidance |
| Need runnable commands or dependency setup | `references/cli-guide.md` | Reuse CLI examples, fixture notes, and validated baseline records |
| Need error remediation | `references/troubleshooting.md` | Map error codes, fallback behavior, and common fixes |
| Need the executable workflow | `scripts/main.R` | Use the CLI entry point |
| Need minimal demo inputs | `tests/data/` | Use the bundled example expression, group, and gene-set files |

## When Not to Use

- Immune cell fraction estimation or deconvolution
- Gene-level differential expression without pathway scoring
- Single-cell clustering, annotation, or communication analysis
- Clinical diagnosis or treatment selection

If the request falls outside these boundaries, stop and state that this skill only covers bulk immune pathway GSVA or ssGSEA analysis from a local immune gene-set table.

## Input Validation

This skill accepts:

- A bulk expression matrix in CSV or TSV format
- A sample group file with exactly two comparison groups for analysis mode
- A local immune gene-set table in long format
- An existing output directory containing `data/immune_pathway_result.rds` for visualize mode

If the user's request does not involve bulk immune pathway scoring from local files, do not proceed with the workflow. Instead respond:

> "Immune Pathway Analysis is designed for bulk immune pathway GSVA or ssGSEA analysis from a local gene-set table. Your request appears to be outside this scope. Please provide a bulk expression matrix, a two-group sample file, and a local pathway table, or use a more appropriate skill for deconvolution, differential expression, or single-cell analysis."

If the request is in scope but required inputs are missing, ask only for the missing file paths or group labels before running `scripts/main.R`.

## Usage

```bash
Rscript scripts/main.R \
  --mode full \
  --input_file ./expression_matrix.csv \
  --group_file ./group_info.csv \
  --geneset_file ./immune_genesets.csv \
  --case_group Case \
  --control_group Control \
  --output_dir ./output/run_001 \
  --seed 42
```

## Arguments

| Short | Long | Type | Default | Description |
|-------|------|------|---------|-------------|
| `-m` | `--mode` | character | `analyze` | Run mode: `analyze`, `visualize`, or `full` |
| `-i` | `--input_file` | character | required for `analyze` or `full` | Expression matrix file in CSV or TSV format |
| `-g` | `--group_file` | character | required for `analyze` or `full` | Sample group file in CSV or TSV format |
|  | `--geneset_file` | character | required for `analyze` or `full` | Local immune gene-set table in long format |
|  | `--geneset_column` | character | `gs_name` | Pathway column in the gene-set table |
|  | `--gene_column` | character | `gene_symbol` | Gene symbol column in the gene-set table |
|  | `--focus_genesets` | character | optional | Comma-separated pathway names to prioritize in the heatmap |
| `-a` | `--case_group` | character | required for `analyze` or `full` | Case group label |
| `-c` | `--control_group` | character | required for `analyze` or `full` | Control group label |
| `-o` | `--output_dir` | character | `./output` | Output directory inside this skill folder |
|  | `--method` | character | `gsva` | Scoring method: `gsva` or `ssgsea` |
|  | `--kcdf` | character | `Gaussian` | GSVA kernel: `Gaussian`, `Poisson`, or `none` |
|  | `--min_sz` | integer | `2` | Minimum gene-set size |
|  | `--max_sz` | integer | `5000` | Maximum gene-set size |
|  | `--parallel_sz` | integer | `1` | Worker count passed to `GSVA::gsva` |
|  | `--mx_diff` | logical | `TRUE` | GSVA `mx.diff` flag |
|  | `--tau` | double | `1` | GSVA `tau` value |
|  | `--fdr_threshold` | double | `0.05` | FDR threshold for significance summaries |
|  | `--top_n` | integer | `20` | Maximum number of pathways exported to the top-score matrix |
|  | `--seed` | integer | `42` | Random seed |
|  | `--timeout_seconds` | integer | `0` | Optional timeout in seconds; `0` disables timeout |
|  | `--plot_file` | character | `immune_pathway_heatmap.pdf` | Heatmap file name stored under `plot/` |
|  | `--plot_title` | character | `Immune Pathway GSVA Heatmap` | Heatmap title |
|  | `--width` | double | `14` | Heatmap width in inches |
|  | `--height` | double | `8` | Heatmap height in inches |
|  | `--colors` | character | `#91bfdb,#ffffbf,#fc8d59` | Comma-separated heatmap colors |
|  | `--scale` | character | `none` | Heatmap scale mode: `none`, `row`, or `column` |
|  | `--cluster_rows` | logical | `TRUE` | Cluster heatmap rows |
|  | `--cluster_cols` | logical | `FALSE` | Cluster heatmap columns |
|  | `--show_rownames` | logical | `TRUE` | Show pathway names on the heatmap |
|  | `--show_colnames` | logical | `FALSE` | Show sample names on the heatmap |
|  | `--fontsize` | double | `10` | Base heatmap font size |
|  | `--fontsize_row` | double | `8` | Heatmap row font size |
|  | `--fontsize_col` | double | `9` | Heatmap column font size |
|  | `--legend_cex` | double | `1` | Legend text scaling factor |
|  | `--top_up` | integer | optional | Number of up-regulated pathways kept for plotting |
|  | `--top_down` | integer | optional | Number of down-regulated pathways kept for plotting |
|  | `--top_mode` | character | `both` | Heatmap subset mode: `both`, `up`, `down`, or `total` |
|  | `--sort_by` | character | `FDR` | Pathway ranking: `FDR`, `absLFC`, or `LFC` |
|  | `--append_stats` | logical | `FALSE` | Append `FDR` and `logFC` to heatmap labels |
|  | `--label_max_chars` | integer | `90` | Maximum heatmap label length |

## Input Format

### Expression Matrix

- CSV or TSV file
- The first column contains gene identifiers
- Remaining columns are sample names
- Values must be numeric
- Missing values are not allowed

### Group File

- CSV or TSV file with a header
- Supported sample column names: `sample`, `sample_name`, `sample_id`, `sampleid`
- Supported group column names: `group`, `condition`, `class`, `cluster`
- Sample names must match the expression matrix columns

### Gene-Set Table

- CSV or TSV file in long format
- One row per gene-to-pathway mapping
- Must contain a pathway column and a gene column
- Default column names are `gs_name` and `gene_symbol`
- Alternate schemas are supported through `--geneset_column` and `--gene_column`

## Output Files

| File | Description |
|------|-------------|
| `table/immune_pathway_diff.csv` | Differential pathway results from `limma` |
| `table/immune_pathway_scores.csv` | Full GSVA or ssGSEA score matrix |
| `table/immune_pathway_scores_top.csv` | Top pathway score matrix selected from the differential results |
| `table/immune_gene_set_summary.csv` | Per-pathway gene counts after table parsing |
| `data/immune_pathway_result.rds` | Saved analysis object used by visualize mode |
| `plot/immune_pathway_heatmap.pdf` | Heatmap PDF generated in `visualize` or `full` mode |
| `session_info.txt` | R session and package version record |
| `output_manifest.txt` | Append-only output manifest |
| `run_record.txt` | Append-only run record |

When no pathways pass the selected `fdr_threshold`, the workflow logs a warning and falls back to ranking pathways by `|t|`. In that case, `table/immune_pathway_scores_top.csv` can still be populated for downstream plotting and review.

## Error Handling

| Error Code | Meaning | Solution |
|------------|---------|----------|
| `SKILL_FILE_NOT_FOUND` | An input file or saved result object does not exist | Check the path and rerun |
| `SKILL_MISSING_COLUMNS` | The group file or gene-set table lacks required columns | Rename the columns or export the correct table |
| `SKILL_EMPTY_DATA` | The matrix, gene-set list, or plotting matrix is empty | Check the input content, gene overlap, and selected gene-set columns |
| `SKILL_INVALID_PARAMETER` | A CLI value is missing, invalid, or unsafe | Review the argument table and rerun |
| `SKILL_SAMPLE_MISMATCH` | Samples do not align between the matrix and group file | Align sample names before rerunning |
| `SKILL_PACKAGE_NOT_FOUND` | Required R packages are missing | Install the packages listed in `references/cli-guide.md` |
| `SKILL_VERSION_INCOMPATIBLE` | Installed package versions are a known incompatible combination | Follow the version guidance in `references/cli-guide.md` and rerun |

Read `references/troubleshooting.md` if the error persists.

## Testing

- Minimal runnable files are bundled in `tests/data/`.
- The bundled smoke-test dataset is intended to validate execution and the fallback path. It may legitimately produce zero pathways with `FDR <= 0.05`.
- `tests/data/immune_genesets_minimal.csv` is a unit-test fixture, not a drop-in full-workflow demo with `tests/data/expression_matrix.csv` unless you prepare a matching matrix with overlapping genes.
- Use `Rscript tests/run_unit_tests.R` to run boundary checks, helper-function checks, and validation tests without the full GSVA workflow.
- Use `Rscript tests/run_tests.R` to execute the unit checks plus the full smoke-test workflow.
- Use `Rscript tests/test_skill.R tests/output` to validate the expected outputs.
- The validated test baseline, package versions, fixture notes, and custom-column CLI examples are documented in `references/cli-guide.md`.
