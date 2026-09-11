---
name: ssgsea-immune-infiltration-analysis
description: Use when estimating immune infiltration from bulk RNA-seq expression matrices with ssGSEA/GSVA, comparing case versus control groups, and generating downstream immune-score visualizations. NOT for single-cell RNA-seq, absolute cell proportion estimation, or clinical decision making.
license: MIT
author: AIPOCH
---
> **Source**: [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills)

# ssGSEA Immune Infiltration Analysis

## When to Use

- Estimate relative immune infiltration from a bulk RNA-seq expression matrix.
- Compare immune enrichment scores between one case group and one control group.
- Generate structured result tables plus optional PDF visualizations for downstream review.

## When Not to Use

- Single-cell RNA-seq or spatial transcriptomics.
- Absolute immune cell proportion estimation or deconvolution.
- Clinical diagnosis, treatment recommendation, or any other medical decision making.

## Workflow

1. Confirm that the expression matrix, group file, and gene-set file match the documented schemas.
2. Run `scripts/main.R` with the target case and control groups.
3. Review `run_record.txt`, `output_manifest.txt`, and the generated tables or plots.
4. If execution fails, read `references/troubleshooting.md` before retrying.

## When to Read External Files

| Situation | File to Read | Purpose |
|-----------|--------------|---------|
| Need to run the analysis | `scripts/main.R` | CLI entry point |
| Need algorithm details | `references/algorithm.md` | Method assumptions and interpretation |
| Encounter an error | `references/troubleshooting.md` | Error codes and fixes |
| Need CLI examples or baseline execution details | `references/cli-guide.md` | Examples and recorded run details |
| Need dependency declarations | `DESCRIPTION` | Package list and Bioconductor source note |
| Need test commands | `tests/run_tests.R` | End-to-end test entry |

## Usage

```bash
Rscript scripts/main.R \
  --input_file ./expression_matrix.csv \
  --group_file ./group_info.csv \
  --gene_set ./immune_gene_sets.csv \
  --case_group treatment \
  --control_group control \
  --output_dir ./output \
  --method ssgsea \
  --seed 42
```

Validated path note:

- `ssgsea` is the default validated path.
- `gsva` is supported, but only with kernels validated in the local GSVA environment.
- In the current audited environment, `gsva` with `Gaussian` completed successfully and is the documented baseline.

## Arguments

| Short | Long | Type | Default | Description |
|-------|------|------|---------|-------------|
| `-i` | `--input_file` | file | required | Expression matrix with genes as rows and samples as columns |
| `-g` | `--group_file` | file | required | Group annotation table |
| `-e` | `--gene_set` | file | `tests/data/immune_gene_sets.csv` | Immune gene-set CSV |
| `-a` | `--case_group` | string | required | Case group label |
| `-b` | `--control_group` | string | required | Control group label |
| `-o` | `--output_dir` | dir | `./output` | Output directory |
| `-m` | `--method` | string | `ssgsea` | GSVA method: `ssgsea`, `gsva` |
| `-k` | `--kcdf` | string | `Gaussian` | Kernel mode: `Gaussian`, `Poisson`; `Gaussian` is the validated GSVA baseline |
| `-n` | `--min_sz` | integer | `2` | Minimum overlap genes per gene set |
| `-x` | `--max_sz` | integer | `10000` | Maximum genes per gene set |
| `-p` | `--parallel_sz` | integer | `2` | Requested parallel CPU count |
| `-u` | `--tau` | numeric | `0.25` | Tau parameter for ssGSEA |
| `-d` | `--mx_diff` | boolean | `true` | GSVA `mx.diff` switch |
| `-c` | `--gene_id_case` | string | `upper` | Gene ID normalization: `asis`, `upper`, `lower` |
| `-s` | `--seed` | integer | `42` | Random seed |
| `-t` | `--timeout_seconds` | integer | `0` | Optional timeout; `0` disables it |
|  | `--sample_col` | string/int | none | Sample column name or 1-based index |
|  | `--group_col` | string/int | none | Group column name or 1-based index |
|  | `--make_plots` | boolean | `true` | Generate PDF plots |
|  | `--verbose` | boolean | `true` | Print progress logs |

## Input Format

### Expression Matrix

CSV or TSV. The first column must contain gene identifiers. Remaining columns are sample-level numeric expression values.

```csv
gene,Sample1,Sample2,Sample3
TP53,10.2,8.5,9.1
CXCL9,4.3,6.1,5.7
```

### Group File

CSV or TSV with at least one sample column and one group column.

```csv
sample,group
Sample1,control
Sample2,treatment
Sample3,treatment
```

### Gene Set File

CSV with `gene` and `cell_type`; `immunity_class` is optional.

```csv
gene,cell_type,immunity_class
CXCL9,Activated CD8 T cell,Adaptive
CD3D,Activated CD8 T cell,Adaptive
```

## Output Files

| File | Description |
|------|-------------|
| `data/ssgsea_list.rds` | Serialized analysis result object |
| `table/ssgsea_scores_long.csv` | Long-format immune infiltration scores |
| `table/ssgsea_scores_wide.csv` | Wide-format immune infiltration score matrix |
| `table/ssgsea_group_compare.csv` | Case-vs-control comparison summary |
| `table/immune_cell_correlation_matrix.csv` | Immune-cell Spearman correlation matrix |
| `table/immune_cell_correlation_pvalue.csv` | Correlation p-value matrix |
| `plot/immune_cell_composition_sample.pdf` | Sample-level composition plot; generated only when `--make_plots=true` |
| `plot/immune_group_boxplot.pdf` | Group comparison boxplot; generated only when `--make_plots=true` |
| `plot/immune_correlation_heatmap.pdf` | Immune-cell correlation heatmap; generated only when `--make_plots=true` |
| `plot/gene_immune_correlation_scatter_*.pdf` | Auto-selected gene-vs-cell scatter plot; generated only when `--make_plots=true` |
| `run_record.txt` | Structured execution record |
| `output_manifest.txt` | Output file manifest with descriptions |
| `session_info.txt` | R session information |

## Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| `SKILL_FILE_NOT_FOUND` | Input file path is invalid | Check file paths |
| `SKILL_MISSING_COLUMNS` | Required columns are absent | Fix the input schema |
| `SKILL_EMPTY_DATA` | No usable rows, gene sets, or aligned samples remain | Check IDs and filters |
| `SKILL_INVALID_PARAMETER` | CLI value is invalid or data is malformed | Review arguments and file content |
| `SKILL_SAMPLE_MISMATCH` | Expression and group samples do not align | Harmonize sample identifiers |
| `SKILL_PACKAGE_NOT_FOUND` | Required R package is missing | Install the missing package |
| `SKILL_TIMEOUT` | The configured time limit was exceeded | Increase `--timeout_seconds` or disable it with `0` |

## Testing

```bash
Rscript scripts/main.R --help

Rscript tests/run_tests.R

Rscript tests/test_skill.R
```

`tests/test_skill.R` is self-contained: if expected outputs are absent, it first runs `tests/run_tests.R` and then validates both file presence and core result structure.
