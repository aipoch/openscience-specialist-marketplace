---
name: estimate-immune-score-analysis
description: "Use this skill to compute ESTIMATE immune-related microenvironment scores from a bulk expression matrix, generate an ESTIMATE score heatmap, and optionally generate group-wise ESTIMATE score boxplots plus significance tables when a sample group file is supplied. Trigger keywords: ESTIMATE, immune score, stromal score, tumor microenvironment score. NOT for: immune cell deconvolution, single-cell analysis, differential expression, clinical diagnosis."
license: MIT
skill-author: AIPOCH
---

# ESTIMATE Immune Score Analysis

## When to Use

Use this skill when the user wants to:

- compute ESTIMATE-derived immune and stromal scores from a bulk expression matrix
- transform an expression matrix into `estimate` package input files and score outputs
- generate an ESTIMATE score heatmap across samples
- compare ESTIMATE scores across sample groups when a sample group file is available
- create a reproducible CLI-backed ESTIMATE workflow with structured output records

Typical request patterns:

- "Run ESTIMATE immune score analysis on this expression matrix"
- "Calculate ImmuneScore and StromalScore from my bulk RNA-seq data"
- "Generate ESTIMATE scores and save a sample-level result table"

## Execution Model

This is a CLI-backed analysis skill.

1. Use `SKILL.md` to confirm that the task is ESTIMATE score generation from bulk expression data.
2. Use `scripts/main.R` for the real execution.
3. Provide one expression matrix file with genes in the first column and samples in the remaining columns.
4. Optionally provide a sample group file to generate ESTIMATE score boxplots and a significance summary table.
5. The workflow always generates an ESTIMATE score heatmap from the computed score table.
6. Read reference files only when you need algorithm details, troubleshooting, or baseline execution notes.

## When to Read External Files

| Situation | File to Read | Purpose |
|-----------|--------------|---------|
| Need algorithm details | `references/algorithm.md` | Understand the ESTIMATE scoring workflow and result interpretation |
| Need to run the skill | `scripts/main.R` | Execute the CLI entry point |
| Encounter errors | `references/troubleshooting.md` | Find standard error codes and fixes |
| Need more CLI examples or the real-data baseline record | `references/cli-guide.md` | Copy commands and review the recorded execution template |
| Need sample input files | `tests/data/` | Use the bundled demo expression matrix |

## When Not to Use

- Immune cell fraction estimation: use a CIBERSORT-like deconvolution workflow instead
- Differential testing between biological groups: use a differential analysis skill instead
- Single-cell analysis: use a single-cell-specific workflow
- Clinical diagnosis or treatment decision support: do not use this skill

If the request is outside ESTIMATE score generation for bulk expression matrices, stop and explain that this skill only covers ESTIMATE-based score computation.

## Input Validation

This skill accepts:

- one bulk expression matrix in CSV or TSV format with genes in the first column and samples in the remaining columns
- an optional sample group file in CSV or TSV format for grouped boxplots and significance testing
- requests to compute ESTIMATE-derived StromalScore, ImmuneScore, ESTIMATEScore, TumorPurity, and related visualizations from bulk transcriptomic data

Do not use this workflow for:

- single-cell RNA-seq or spatial transcriptomics
- immune cell deconvolution requests
- direct clinical diagnosis, treatment recommendation, or patient-level medical decision making
- unrelated tasks such as literature writing, web scraping, or generic plotting without ESTIMATE score generation

If the user's request is outside this scope, do not proceed with the workflow. Instead respond:

> `estimate-immune-score-analysis` is designed to compute ESTIMATE-based tumor microenvironment scores from a bulk expression matrix. Your request appears to be outside this scope. Please provide a valid bulk expression matrix and, if needed, a matching sample group file, or use a more appropriate skill for your task.

## Usage

```bash
Rscript scripts/main.R \
  --input_file ./expression_matrix.csv \
  --group_file ./group_info.csv \
  --output_dir ./output \
  --gene_id_type GeneSymbol \
  --platform affymetrix \
  --seed 42
```

## Arguments

| Short | Long | Type | Default | Description |
|-------|------|------|---------|-------------|
| `-i` | `--input_file` | character | required | Expression matrix file in CSV or TSV format |
| `-o` | `--output_dir` | character | `./output` | Output directory |
|  | `--group_file` | character | optional | Sample group file used for ESTIMATE score boxplots and significance testing |
| `-g` | `--gene_id_type` | character | `GeneSymbol` | Gene identifier type: `GeneSymbol` or `EntrezID` |
| `-p` | `--platform` | character | `affymetrix` | ESTIMATE platform: `affymetrix`, `agilent`, or `illumina` |
| `-s` | `--seed` | integer | `42` | Random seed |
| `-t` | `--timeout_seconds` | integer | `0` | Optional timeout in seconds; `0` disables timeout |
|  | `--input_delimiter` | character | `auto` | Input delimiter hint: `auto`, `csv`, or `tsv` |
|  | `--group_delimiter` | character | `auto` | Group file delimiter hint: `auto`, `csv`, or `tsv` |
|  | `--sample_column` | character | `sample` | Sample column name in the group file |
|  | `--group_column` | character | `group` | Group column name in the group file |
|  | `--plot_file` | character | `estimate_scores_boxplot.pdf` | Boxplot file name written under `plot/` |
|  | `--heatmap_file` | character | `estimate_scores_heatmap.pdf` | Heatmap file name written under `plot/` |

## Input Format

- CSV or TSV file
- First column contains gene identifiers
- Remaining columns are sample names
- Expression values must be numeric and non-missing
- Sample column names must be unique; duplicate sample column names raise `SKILL_INVALID_PARAMETER`

Example:

```csv
gene,S1,S2,S3
TP53,8.1,7.9,6.5
EGFR,5.2,5.0,4.2
```

The bundled `tests/data/expression_matrix.csv` was copied from `cibersort-immune-infiltration-analysis/tests/data/expression_matrix.csv` for demo and validation use.

### Optional Group File

- CSV or TSV file
- Must contain one sample column and one group column
- Sample names must match the ESTIMATE score table sample IDs
- **Exactly two group levels are supported** for boxplot comparison. If more than two groups are present in the group file, `SKILL_INVALID_PARAMETER` is raised.
- Each group must contain **at least 3 samples** for valid statistical testing. Groups with fewer samples trigger `SKILL_INVALID_PARAMETER`.
- If the group file is provided but grouped comparison fails after core scoring, the command exits with a `SKILL_*` error after preserving the core ESTIMATE outputs and failure records

Example:

```csv
sample,group
S1,Tumor
S2,Tumor
S3,Healthy
S4,Healthy
```

## Output Files

| File | Description |
|------|-------------|
| `data/expression_input.tsv` | Tab-delimited expression matrix prepared for ESTIMATE |
| `data/estimate_input.gct` | GCT file created by `estimate::filterCommonGenes()` |
| `data/estimate_score.gct` | Raw ESTIMATE score output from `estimate::estimateScore()` |
| `table/estimate_scores.tsv` | Reformatted sample-by-score table |
| `plot/estimate_scores_heatmap.pdf` | Sample-level ESTIMATE score heatmap |
| `table/estimate_score_group_stats.csv` | Per-score p-values and the group with the higher median score when `--group_file` is provided |
| `plot/estimate_scores_boxplot.pdf` | ESTIMATE score boxplot when `--group_file` is provided |
| `session_info.txt` | R session and package version information |
| `output_manifest.txt` | Append-only output file manifest with descriptions |
| `run_record.txt` | Append-only run record with parameters, runtime, and output summary |

## Workflow

### Step 1: Validate Input

- Confirm the input file exists
- Confirm the matrix contains at least one gene column and one or more sample columns
- Confirm all expression columns are numeric and sample names are unique

### Step 2: Run ESTIMATE

- Convert the matrix to a tab-delimited file with the selected gene identifier header
- Run `estimate::filterCommonGenes()`
- Run `estimate::estimateScore()`

### Step 3: Export Results

- Save the raw GCT outputs under `data/`
- Reformat the score matrix into `table/estimate_scores.tsv`
- Create `plot/estimate_scores_heatmap.pdf`
- If `--group_file` is supplied, create `plot/estimate_scores_boxplot.pdf`
- If `--group_file` is supplied, create `table/estimate_score_group_stats.csv`
- If grouped comparison fails after core scoring, keep the core outputs, append failure details to `output_manifest.txt` and `run_record.txt`, and exit with a `SKILL_*` message
- Save `session_info.txt`
- Append a run section to `output_manifest.txt` and `run_record.txt`

## Examples

### Basic Usage

```bash
Rscript scripts/main.R \
  --input_file ./expression_matrix.csv \
  --output_dir ./output
```

### Grouped Comparison

```bash
Rscript scripts/main.R \
  --input_file ./expression_matrix.csv \
  --group_file ./group_info.csv \
  --output_dir ./grouped_output
```

### TSV Input

```bash
Rscript scripts/main.R \
  --input_file ./expression_matrix.tsv \
  --input_delimiter tsv \
  --output_dir ./tsv_output \
  --gene_id_type GeneSymbol
```

### Alternate Platform

```bash
Rscript scripts/main.R \
  --input_file ./expression_matrix.csv \
  --output_dir ./illumina_output \
  --platform illumina \
  --seed 123
```

For the real-data baseline execution record, READ: `references/cli-guide.md`

## Error Handling

| Error Code | Meaning | Solution |
|------------|---------|----------|
| `SKILL_FILE_NOT_FOUND` | Input file is missing or an expected intermediate file was not created | Check file paths and rerun |
| `SKILL_MISSING_COLUMNS` | The gene identifier column contains missing values | Repair the first column and rerun |
| `SKILL_EMPTY_DATA` | The matrix or ESTIMATE output is empty | Verify input content and identifier compatibility |
| `SKILL_INVALID_PARAMETER` | A CLI argument is unsupported; the matrix contains invalid values; duplicate sample column names detected; more than two group levels provided; or a group contains fewer than 3 samples | Review arguments and input values |
| `SKILL_SAMPLE_MISMATCH` | Sample names in the group file do not overlap the ESTIMATE score table | Align sample IDs before rerunning |
| `SKILL_PACKAGE_NOT_FOUND` | Required R packages are not installed | Install missing packages listed in `references/cli-guide.md` |

If the error persists, READ: `references/troubleshooting.md`

For optional group comparison failures such as `SKILL_SAMPLE_MISMATCH`, inspect the preserved core outputs together with `output_manifest.txt` and `run_record.txt` to see what completed before the grouped step failed.

## Testing

```bash
Rscript scripts/main.R --help

Rscript tests/run_tests.R

Rscript scripts/main.R \
  --input_file tests/data/expression_matrix.csv \
  --group_file tests/data/group_info.csv \
  --output_dir tests/output \
  --gene_id_type GeneSymbol \
  --platform affymetrix \
  --seed 42
```

Expected outputs:

- `tests/output/data/expression_input.tsv`
- `tests/output/data/estimate_input.gct`
- `tests/output/data/estimate_score.gct`
- `tests/output/table/estimate_scores.tsv`
- `tests/output/plot/estimate_scores_heatmap.pdf`
- `tests/output/table/estimate_score_group_stats.csv`
- `tests/output/plot/estimate_scores_boxplot.pdf`
- `tests/output/session_info.txt`
- `tests/output/output_manifest.txt`
- `tests/output/run_record.txt`

Optional post-check:

```bash
Rscript tests/test_skill.R tests/output
```

## References

1. Yoshihara K, Shahmoradgoli M, Martinez E, et al. (2013) Inferring tumour purity and stromal and immune cell admixture from expression data. *Nature Communications*. doi:10.1038/ncomms3612

For detailed algorithm notes, READ: `references/algorithm.md`

## Implementation Checklist

- [x] CLI parsing with `optparse`
- [x] `set.seed()` for reproducibility
- [x] Only public CRAN/Bioconductor packages used
- [x] Script parameters documented in `SKILL.md`
- [x] `get_script_dir()` defined before any call to it
- [x] File reading instructions in `SKILL.md`
- [x] Test data provided in `tests/data/`
- [x] Error handling implemented with `SKILL_*` messages
- [x] Baseline record completed in `references/cli-guide.md`
- [x] `skill-auditor` outputs generated after container execution
