---
name: gsva-analysis-and-visualization
description: "Use this skill to run GSVA or ssGSEA pathway-level differential analysis from a bulk expression matrix and a sample group file, then generate a heatmap from the saved GSVA result object. Trigger keywords: GSVA, ssGSEA, pathway enrichment, KEGG pathway analysis, MSigDB. NOT for: gene-level differential expression, single-cell analysis, methylation analysis, clinical diagnosis."
license: MIT
skill-author: AIPOCH
---

# GSVA Analysis And Visualization

## When to Use

Use this skill when the user wants one of the following:

- Pathway-level GSVA or ssGSEA analysis from a bulk expression matrix plus a sample group file
- Case-vs-control or treatment-vs-control pathway enrichment comparison using GSVA plus limma
- KEGG or MSigDB pathway analysis for bulk RNA-seq or microarray-like expression data
- Heatmap generation from an existing `data/GSVA_list.rda` result object
- A reproducible CLI-backed GSVA workflow with saved tables, an `.rda` object, and a PDF heatmap

Typical request patterns:

- "Run GSVA on my bulk RNA-seq matrix and compare case vs control"
- "Use ssGSEA to score pathways and save the pathway differential results"
- "Generate a KEGG pathway heatmap from my saved GSVA result"
- "Do pathway enrichment with GSVA for these grouped bulk samples"

## Execution Model

This is a hybrid skill.

1. Use `SKILL.md` to verify that the request is in scope.
2. Use `scripts/main.R` for real execution.
3. Use `--mode analyze` to compute pathway scores and differential results.
4. Use `--mode visualize` to reuse an existing `data/GSVA_list.rda` and generate a heatmap. In visualize mode, `GSVA_list.rda` must exist in `output_dir/data/`; run `analyze` or `full` mode first if it is missing (`SKILL_FILE_NOT_FOUND` will be raised otherwise).
5. Use `--mode full` to run analysis and visualization in one pass.
6. Read reference files only when you need algorithm details, troubleshooting, or additional CLI examples.

## When to Read External Files

| Situation | File to Read | Purpose |
|-----------|--------------|---------|
| Need algorithm details | `references/algorithm.md` | Understand GSVA, limma, and heatmap generation logic |
| Need to run analysis or plotting | `scripts/main.R` | Execute the CLI entry point |
| Encounter errors | `references/troubleshooting.md` | Find standard error codes and fixes |
| Need more CLI examples or the baseline execution record | `references/cli-guide.md` | Copy ready-to-run commands and review the recorded test run |
| Need sample input files | `tests/data/` | Use the bundled demo matrix and group file |

## When Not to Use

- Gene-level differential expression: use `differential-expression-analysis` instead
- Single-cell RNA-seq clustering or communication analysis: use `sc-clustering` or `cellchat`
- Immune infiltration scoring rather than pathway enrichment: use `ssgsea-r` or `ssgsea_immune`
- Clinical diagnosis, treatment selection, or patient-specific interpretation: do not use this skill; ask for a validated clinical workflow or human expert review

If the request falls outside these boundaries, stop and tell the user that this skill only covers bulk expression pathway-level GSVA/ssGSEA analysis plus downstream heatmap visualization.

## Method Selection Guide

Choose `--method` based on your data characteristics:

- `gsva`: kernel-based enrichment scores suitable for continuous expression data with moderate-to-large sample sizes (≥ 10 samples per group recommended).
- `ssgsea`: rank-based enrichment scores; less sensitive to outliers and more suitable for noisy data or smaller sample sizes.

For detailed methodological comparison, READ: `references/algorithm.md`

## Usage

```bash
Rscript scripts/main.R \
  --mode full \
  --input_file tests/data/expr_matrix.csv \
  --group_file tests/data/group.csv \
  --case_group Tumor \
  --control_group Healthy \
  --species "Homo sapiens" \
  --category C2 \
  --subcategory KEGG \
  --output_dir ./output \
  --seed 42
```

## Arguments

| Short | Long | Type | Default | Description |
|-------|------|------|---------|-------------|
| `-m` | `--mode` | character | `analyze` | Run mode: `analyze`, `visualize`, or `full` |
| `-i` | `--input_file` | character | required for `analyze`/`full` | Expression matrix file (CSV or TSV, genes as rows, samples as columns) |
| `-g` | `--group_file` | character | required for `analyze`/`full` | Sample group file (CSV or TSV with sample and group columns) |
| `-a` | `--case_group` | character | required for `analyze`/`full` | Case or treatment group label |
| `-c` | `--control_group` | character | required for `analyze`/`full` | Control group label |
| `-o` | `--output_dir` | character | `./output/` | Output directory |
| `-s` | `--species` | character | `Homo sapiens` | MSigDB species |
| `-C` | `--category` | character | `C2` | MSigDB category |
| `-S` | `--subcategory` | character | `KEGG` | MSigDB subcategory |
|  | `--method` | character | `gsva` | GSVA method: `gsva` or `ssgsea` (see Method Selection Guide above) |
|  | `--kcdf` | character | `Gaussian` | GSVA kernel: `Gaussian`, `Poisson`, or `none` |
|  | `--min_sz` | integer | `2` | Minimum gene set size |
|  | `--max_sz` | integer | `10000` | Maximum gene set size |
|  | `--parallel_sz` | integer | `1` | Parallel worker count passed to GSVA |
|  | `--mx_diff` | logical | `TRUE` | GSVA `mx.diff` flag |
|  | `--tau` | double | `1` | GSVA `tau` value |
|  | `--fdr_threshold` | double | `0.05` | FDR threshold used to select top pathways |
|  | `--top_n` | integer | `20` | Number of pathways exported to the top score matrix |
|  | `--seed` | integer | `42` | Random seed |
|  | `--timeout_seconds` | integer | `0` | Optional timeout in seconds; `0` disables it |
|  | `--plot_file` | character | `GSVA_heatmap.pdf` | Heatmap file name under `plot/` (file name only; no path separators) |
|  | `--plot_title` | character | `GSVA Enrichment Heatmap` | Heatmap title |
|  | `--width` | double | `14` | Heatmap width in inches |
|  | `--height` | double | `8` | Heatmap height in inches |
|  | `--colors` | character | `#91bfdb,#ffffbf,#fc8d59` | Comma-separated heatmap colors |
|  | `--scale` | character | `none` | Heatmap scale mode: `none`, `row`, or `column` |
|  | `--cluster_rows` | logical | `TRUE` | Cluster heatmap rows |
|  | `--cluster_cols` | logical | `FALSE` | Cluster heatmap columns |
|  | `--show_rownames` | logical | `TRUE` | Show pathway names on the heatmap |
|  | `--show_colnames` | logical | `FALSE` | Show sample names on the heatmap |
|  | `--fontsize` | double | `10` | Base heatmap font size |
|  | `--fontsize_row` | double | `8` | Row label font size |
|  | `--fontsize_col` | double | `9` | Column label font size |
|  | `--legend_cex` | double | `1` | Legend text scaling factor |
|  | `--top_up` | integer | optional | Number of up-regulated pathways retained for plotting |
|  | `--top_down` | integer | optional | Number of down-regulated pathways retained for plotting |
|  | `--top_mode` | character | `both` | Heatmap subset mode: `both`, `up`, `down`, or `total` |
|  | `--sort_by` | character | `FDR` | Pathway ranking: `FDR`, `absLFC`, or `LFC` |
|  | `--append_stats` | logical | `FALSE` | Append `FDR` and `logFC` to heatmap labels |
|  | `--label_max_chars` | integer | `80` | Maximum heatmap label length |

## Input Format

### Expression Matrix

- CSV or TSV file
- First column contains gene identifiers
- Remaining columns are sample names
- Values must be numeric and contain no missing values

Example:

```csv
gene,S1,S2,S3,S4
TP53,8.1,7.9,6.5,6.3
EGFR,5.2,5.0,4.2,4.1
```

The bundled `tests/data/expr_matrix.csv` is derived from the public GEO series `GSE44076` after probe-to-gene collapsing and contains the `Tumor` versus `Healthy` subset.

### Group File

- CSV or TSV file with a header row
- One sample column: `sample`, `sample_name`, or `sample_id`
- One group column: `group`, `condition`, `cluster`, or `class`
- Sample names must match the expression matrix columns

Example:

```csv
sample,group
GSM1077746,Tumor
GSM1077747,Tumor
GSM1077598,Healthy
GSM1077599,Healthy
```

## Output Files

| File | Description |
|------|-------------|
| `table/GSVA_diff.csv` | limma differential pathway results with `logFC`, `P.Value`, and `adj.P.Val` |
| `table/GSVA_enrichment_results.csv` | Full GSVA score matrix |
| `table/GSVA_enrichment_results_topN.csv` | Top pathway score matrix selected by `--top_n` and `--fdr_threshold` |
| `data/GSVA_list.rda` | Saved `gsva_result` object for downstream visualization |
| `plot/GSVA_heatmap.pdf` | Heatmap PDF generated in `visualize` or `full` mode |
| `session_info.txt` | R session and package version information |
| `output_manifest.txt` | Append-only manifest of generated outputs across runs in the same `output_dir` |
| `run_record.txt` | Append-only run log with parameters, runtime, and output summaries across runs in the same `output_dir` |

### table/GSVA_diff.csv

| Column | Type | Description |
|--------|------|-------------|
| `logFC` | numeric | limma-estimated pathway score difference between case and control |
| `AveExpr` | numeric | Average pathway score across all samples |
| `t` | numeric | Moderated t statistic from limma |
| `P.Value` | numeric | Raw p-value from limma |
| `adj.P.Val` | numeric | Benjamini-Hochberg adjusted p-value |
| `B` | numeric | Log-odds that the pathway is differentially enriched |
| `geneset` | character | Pathway identifier used in the GSVA run |

## Workflow

### Step 1: Validate Input

- Check that the expression matrix and group file exist
- Validate supported columns and matching sample names
- Validate CLI ranges and mode-specific required parameters

### Step 2: Run Pathway Analysis

- Load MSigDB gene sets for the requested species and collection
- Compute GSVA or ssGSEA scores for each sample
- Fit a limma model for the case-vs-control pathway comparison

### Step 3: Generate Output

- Save the full score matrix, top pathway subset, and differential results to `table/`
- Save the reusable `gsva_result` object to `data/GSVA_list.rda`
- Generate the heatmap PDF in `plot/` when running `visualize` or `full`
- Append a new section to `output_manifest.txt` and `run_record.txt` for each invocation so earlier provenance is preserved when reusing one `output_dir`

## Examples

### Basic Usage

```bash
Rscript scripts/main.R \
  --mode full \
  --input_file ./expression_matrix.csv \
  --group_file ./group_info.csv \
  --case_group treatment \
  --control_group control \
  --output_dir ./output
```

### With ssGSEA and Custom Parameters

```bash
Rscript scripts/main.R \
  --mode analyze \
  --input_file ./expression_matrix.csv \
  --group_file ./group_info.csv \
  --case_group treatment \
  --control_group control \
  --method ssgsea \
  --top_n 30 \
  --fdr_threshold 0.1 \
  --output_dir ./ssgsea_output \
  --seed 123
```

### Reuse a Saved Result Object

```bash
Rscript scripts/main.R \
  --mode visualize \
  --output_dir ./output \
  --plot_file custom_heatmap.pdf \
  --top_up 10 \
  --top_down 10 \
  --top_mode both
```

For the bundled real-data baseline record, READ: `references/cli-guide.md`

## Error Handling

| Error Code | Meaning | Solution |
|------------|---------|----------|
| `SKILL_FILE_NOT_FOUND` | Input file or saved result file is missing; in visualize mode, `GSVA_list.rda` must exist in `output_dir/data/` — run analyze or full mode first | Check the path and rerun with the correct file |
| `SKILL_MISSING_COLUMNS` | Group file lacks a valid sample or group column | Rename the columns to a supported name |
| `SKILL_SAMPLE_MISMATCH` | Sample names do not match between files | Align sample names before running the skill |
| `SKILL_EMPTY_DATA` | Input matrix, gene set query, or plotting matrix is empty | Verify the input matrix and MSigDB settings |
| `SKILL_INVALID_PARAMETER` | A CLI argument is missing or out of range | Review the parameter table and rerun |
| `SKILL_PACKAGE_NOT_FOUND` | Required R packages are not installed | Install the missing packages listed in `references/cli-guide.md` |

If the error persists, READ: `references/troubleshooting.md`

## Input Validation

This skill accepts:

- A bulk expression matrix file in CSV or TSV format with genes as rows and samples as columns
- A sample group file with one supported sample column and one supported group column
- A valid case/control comparison for pathway-level GSVA or ssGSEA analysis
- Optional heatmap customization parameters for visualization of a saved `GSVA_list.rda`

Privacy and data-handling note:

- If your matrix or group file can be linked to patients or protected records, anonymize it before use
- This workflow writes result tables, a saved R object, plots, and session metadata to the local `output_dir`
- Review local output retention practices before using sensitive material

If the user's request does not involve bulk expression pathway enrichment analysis or GSVA heatmap generation — for example, asking for single-cell analysis, gene-level DE testing, methylation analysis, or clinical diagnosis — do not proceed with this workflow. Instead respond:

> "gsva-analysis-and-visualization is designed for bulk expression pathway-level GSVA/ssGSEA analysis and saved-result heatmap visualization. Your request appears to be outside this scope. Please provide a bulk expression matrix plus sample group file for GSVA/ssGSEA analysis, or use a more appropriate skill for your task."

## Testing

```bash
Rscript scripts/main.R --help

Rscript tests/run_tests.R

Rscript scripts/main.R \
  --mode full \
  --input_file tests/data/expr_matrix.csv \
  --group_file tests/data/group.csv \
  --case_group Tumor \
  --control_group Healthy \
  --species "Homo sapiens" \
  --category C2 \
  --subcategory KEGG \
  --output_dir tests/output \
  --seed 42
```

Expected outputs:

- `tests/output/table/GSVA_diff.csv`
- `tests/output/table/GSVA_enrichment_results.csv`
- `tests/output/table/GSVA_enrichment_results_topN.csv`
- `tests/output/data/GSVA_list.rda`
- `tests/output/plot/GSVA_heatmap.pdf`
- `tests/output/session_info.txt`
- `tests/output/output_manifest.txt`
- `tests/output/run_record.txt`

Optional post-check:

```bash
Rscript tests/test_skill.R tests/output
```

`tests/run_tests.R` executes the full demo workflow, validates the expected output files, then reruns `visualize` in the same `output_dir` to confirm that `output_manifest.txt` and `run_record.txt` preserve both run sections.

## References

1. Hanzelmann S, Castelo R, Guinney J. (2013) GSVA: gene set variation analysis for microarray and RNA-seq data. *BMC Bioinformatics*. doi:10.1186/1471-2105-14-7
2. Ritchie ME, Phipson B, Wu D, et al. (2015) limma powers differential expression analyses for RNA-sequencing and microarray studies. *Nucleic Acids Research*. doi:10.1093/nar/gkv007
3. Liberzon A, Birger C, Thorvaldsdottir H, et al. (2015) The Molecular Signatures Database Hallmark Gene Set Collection. *Cell Systems*. doi:10.1016/j.cels.2015.12.004

For detailed algorithm notes, READ: `references/algorithm.md`

## Implementation Checklist

- [x] CLI parsing with `optparse`
- [x] `set.seed()` for reproducibility
- [x] Only CRAN/Bioconductor packages
- [x] Documented parameters match script
- [x] `get_script_dir()` defined before any call to it
- [x] File reading instructions in `SKILL.md`
- [x] Test data provided in `tests/data/`
- [x] Error handling implemented with `SKILL_*` messages
- [x] `Rscript scripts/main.R --help` works
