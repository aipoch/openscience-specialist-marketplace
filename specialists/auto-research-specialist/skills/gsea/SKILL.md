---
name: gsea
description: Run GSEA on a ranked gene list and produce the enrichment table, running-score table, and enrichment plots.
license: MIT
author: AIPOCH
---
> **Source**: [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills)

## When to read external files

| Situation | Read | Purpose |
|---|---|---|
| Need algorithm details | `references/algorithm.md` | Statistical method and formulas |
| Need to run an analysis | `scripts/main.R` | Full command reference |
| Hit an error | `references/troubleshooting.md` | Look up error codes and fixes |
| Need CLI examples | `references/cli-guide.md` | Worked argument examples |

## Scope

Use this skill for:
- Running GSEA on a gene list ranked by a statistic
- Generating enrichment curve plots from existing `enrichGSEA.csv` and `gsea_running_scores.csv`
- Smoke-testing the pipeline with `tests/data/sample_deg_results.csv`

Do not use it for:
- Differential expression on raw expression matrices
- Single-sample ssGSEA
- Network analysis or multi-omics integration

## Usage

Analysis mode:
`Rscript scripts/main.R --input tests/data/sample_deg_results.csv --outdir ./GSEA_analysis --type KEGG --species human --seed 42 --timeout 300`

Plot mode:
`Rscript scripts/main.R --running_file ./GSEA_analysis/Table/gsea_running_scores.csv --enrich_file ./GSEA_analysis/Table/enrichGSEA.csv --plot_output ./GSEA_analysis/plot/gsea_plot.pdf --top_n 5 --plot_format pdf --seed 42 --timeout 300`

See `references/cli-guide.md` for more.

Mode selection:
- Passing only `--input` runs analysis mode
- Passing both `--running_file` and `--enrich_file` runs plot mode
- If both sets of arguments are provided, plot mode takes precedence; analysis mode is skipped and a warning is logged

## Arguments

### Analysis-mode arguments

| Short | Long | Type | Default | Required | Description |
|---|---|---|---|---|---|
| `-i` | `--input` | character | `NULL` | yes | Input CSV file |
| `-o` | `--outdir` | character | `GSEA_analysis` | no | Output directory |
| `-g` | `--gene_col` | character | `name` | no | Gene column name |
| `-f` | `--fc_col` | character | `logFC` | no | Ranking-statistic column name |
| `-t` | `--type` | character | `KEGG` | no | Gene-set type: `KEGG`, `HALLMARKS`, `GO_BP`, `GO_MF`, `GO_CC`. With a preloaded RDS, `HALLMARKS` is automatically mapped to the asset key `Hallmarks` |
| `-s` | `--species` | character | `human` | no | Species: `human`, `mouse`, `rat` |
| `-p` | `--pvalue_cutoff` | numeric | `0.05` | no | Significance threshold |
| `-m` | `--method` | character | `fgsea` | no | GSEA backend: `fgsea` or `DOSE` |
| `-c` | `--chunk_size` | numeric | `1000` | no | Chunk size for large gene-set conversion |
| `-r` | `--rds_path` | character | `NULL` | no | Path to a pre-stored gene-set RDS |
| `-v` | `--verbose` | logical | `FALSE` | no | Verbose logging |
|  | `--seed` | integer | `42` | no | Random seed |
|  | `--timeout` | integer | `300` | no | Timeout in seconds; `<=0` disables it |
| `-h` | `--help` | logical | `FALSE` | no | Show help |

### Plot-mode arguments

| Short | Long | Type | Default | Required | Description |
|---|---|---|---|---|---|
|  | `--running_file` | character | `NULL` | yes | Path to `gsea_running_scores.csv` |
|  | `--enrich_file` | character | `NULL` | yes | Path to `enrichGSEA.csv` |
|  | `--plot_output` | character | `gsea_plot.pdf` | no | Output plot path |
|  | `--plot_width` | numeric | `8` | no | Plot width |
|  | `--plot_height` | numeric | `6` | no | Plot height |
|  | `--plot_format` | character | `pdf` | no | Output format: `pdf` or `png` |
|  | `--top_n` | numeric | `1` | no | Number of top pathways to plot when `geneSetID` is not given |
|  | `--rank_by` | character | `p.adjust` | no | Column used to rank pathways |
|  | `--geneSetID` | character | `""` | no | Comma-separated pathway IDs |
|  | `--plot_title` | character | `""` | no | Plot title |
|  | `--colors` | character | `#4DBBD5,#E64B35,#00A087,#F39B7F,#3C5488,#8491B4` | no | Color list |
|  | `--base_size` | numeric | `11` | no | Base font size |
|  | `--subplots` | character | `1,2,3` | no | Sub-panel indices to display |
|  | `--rel_heights` | character | `1.5,0.8,1` | no | Relative panel heights |
|  | `--NES_table` | logical | `TRUE` | no | Show NES annotation |
|  | `--no_NES_table` | logical | `FALSE` | no | Disable NES annotation |
|  | `--NES_label_size` | numeric | `4` | no | NES label font size |
|  | `--NES_label_x` | numeric | `0.75` | no | NES label x position |
|  | `--NES_label_y` | numeric | `0.75` | no | NES label y position |
|  | `--NES_label_color` | character | `black` | no | NES label color |
|  | `--NES_label_hjust` | numeric | `0` | no | NES label horizontal justification |
|  | `--NES_label_vjust` | numeric | `1` | no | NES label vertical justification |
|  | `--line_width` | numeric | `1` | no | ES line width |
|  | `--dot_size` | numeric | `1.2` | no | ES dot size |
|  | `--legend_position` | character | `auto` | no | Legend position |
|  | `--legend_x` | numeric | `0.02` | no | Inset legend x coordinate |
|  | `--legend_y` | numeric | `0.02` | no | Inset legend y coordinate |
|  | `--legend_just_x` | numeric | `0` | no | Legend horizontal justification |
|  | `--legend_just_y` | numeric | `0` | no | Legend vertical justification |
|  | `--legend_text_size` | numeric | `9` | no | Legend text size |
|  | `--legend_key_size` | numeric | `0.6` | no | Legend key size |
|  | `--legend_bg_alpha` | numeric | `0` | no | Legend background alpha |
|  | `--grid_major_color` | character | `grey92` | no | Major grid color |
|  | `--grid_minor_color` | character | `grey92` | no | Minor grid color |
|  | `--ylab_es` | character | `Enrichment Score` | no | ES panel y-axis title |
|  | `--ylab_rank` | character | `Ranked List Metric` | no | Rank panel y-axis title |
|  | `--xlab_rank` | character | `Rank in Ordered Dataset` | no | Rank panel x-axis title |
|  | `--hit_height` | numeric | `1` | no | Hit-bar height |
|  | `--hit_gap` | numeric | `0` | no | Hit-bar gap |
|  | `--hit_linewidth` | numeric | `0.5` | no | Hit-bar line width |
|  | `--rank_bar_alpha` | numeric | `0.9` | no | Rank-bar alpha |
|  | `--rank_bar_height_ratio` | numeric | `0.3` | no | Rank-bar height ratio |
|  | `--rank_metric_segment_color` | character | `grey` | no | Rank-line color |
|  | `--rank_metric_segment_width` | numeric | `0.3` | no | Rank-line width |
|  | `--rank_metric_segment_alpha` | numeric | `1` | no | Rank-line alpha |
|  | `--pvalue_table` | logical | `FALSE` | no | Show p-value table |
|  | `--ES_geom` | character | `line` | no | ES geometry: `line` or `dot` |
|  | `--verbose` | logical | `FALSE` | no | Verbose logging |
|  | `--seed` | integer | `42` | no | Random seed |
|  | `--timeout` | integer | `300` | no | Timeout in seconds; `<=0` disables it |
| `-h` | `--help` | logical | `FALSE` | no | Show help |

## Input format

Analysis-mode input is a CSV with at least:
- a gene column (default name `name`)
- a ranking-statistic column (default name `logFC`)

Example:
```csv
name,logFC,pvalue,padj
TP53,2.5,0.001,0.01
BRCA1,1.8,0.005,0.02
EGFR,-1.2,0.01,0.05
```

Value constraints:
- `type` accepts `KEGG`, `HALLMARKS`, `GO_BP`, `GO_MF`, `GO_CC`
- When using a preloaded RDS, `HALLMARKS` is automatically matched to the asset key `Hallmarks`
- `species` accepts `human`, `mouse`, `rat`

## Output files

| File | Format | Description |
|---|---|---|
| `data/GSEA_list.rda` | RDA | Full GSEA result object |
| `Table/enrichGSEA.csv` | CSV | Enrichment result table |
| `Table/gsea_running_scores.csv` | CSV | Running-score table; if no enrichment passes, a header-only file is still written |
| `plot/` | directory | Plot output directory |
| `session_info.txt` | TXT | R version and package versions |

`enrichGSEA.csv` mainly contains: `ID`, `Description`, `NES`, `pvalue`, `p.adjust`, `core_enrichment`.

## Error handling

Common error codes:
- `SKILL_FILE_NOT_FOUND`: input file does not exist
- `SKILL_MISSING_COLUMNS`: required columns are missing
- `SKILL_EMPTY_DATA`: input is empty, or empty after filtering
- `SKILL_INVALID_PARAMETER`: an argument has an invalid value
- `SKILL_PACKAGE_NOT_FOUND`: a required package is not installed
- `SKILL_ANALYSIS_FAILED`: GSEA still failed after retries

Triage doc: `references/troubleshooting.md`

Exit codes:
- `0`: success
- `1`: failure

## Testing

Minimal test dataset: `tests/data/sample_deg_results.csv`

Minimal command:
`Rscript scripts/main.R --input tests/data/sample_deg_results.csv --outdir ./test_output --type KEGG --species human --seed 42 --timeout 300 --verbose`

Expected output:
- `./test_output/data/GSEA_list.rda`
- `./test_output/Table/enrichGSEA.csv`
- `./test_output/Table/gsea_running_scores.csv`
- `./test_output/session_info.txt`
- If no significant enrichment is found, `gsea_running_scores.csv` is still written but contains only the header
- Exit code `0`
