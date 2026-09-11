---
name: gokegg-analysis
description: Use when performing GO and KEGG enrichment on a gene list from bulk RNA-seq or microarray studies, then generating a combined GO/KEGG dot chart. NOT for single-cell RNA-seq, methylation data, or non-expression data.
license: MIT
author: AIPOCH
---
> **Source**: [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills)

## When To Read External Files

| Situation | File To Read | Purpose |
|---|---|---|
| Need algorithm details | `references/algorithm.md` | Statistical methods and formulas |
| Need to run the analysis | `scripts/main.R` | Full execution command |
| Encounter an error | `references/troubleshooting.md` | Troubleshooting guidance |
| Need CLI examples | `references/cli-guide.md` | Parameter usage examples |

## When To Use

Use this skill for:
- GO and KEGG enrichment from a gene list derived from bulk RNA-seq or microarray studies
- Supported gene ID types: `SYMBOL`, `ENSEMBL`, `ENTREZID`
- Supported species databases: `org.Hs.eg.db`, `org.Mm.eg.db`, `org.Rn.eg.db`

Do not use this skill for:
- Single-cell RNA-seq analysis
- Methylation, proteomics, or non-expression omics workflows
- Differential expression testing from raw count matrices

## Usage

Main analysis and plotting:
`Rscript scripts/main.R --feature "TP53,EGFR,BRCA1,MYC" --output_dir ./output --sp org.Hs.eg.db --gene_type SYMBOL --pvalue_cutoff 0.05 --qvalue_cutoff 0.2 --pAdjustMethod BH --seed 66 --go_top_n 3 --kegg_top_n 3 --format pdf`

Notes:
- `scripts/main.R` is the only command-line entry point
- `scripts/dochart.R` currently provides plotting functions and is sourced by `scripts/main.R`
- If `--go_input`, `--kegg_input`, or `--outdir` are omitted, `main.R` uses `output_dir/temp/GO_list.rda`, `output_dir/temp/KEGG_list.rda`, and `output_dir/plot` automatically

## Agent Output

On success, the agent should report:
- Whether GO enrichment completed successfully
- Whether KEGG enrichment completed successfully
- The normalized input gene count after trimming and parsing
- The main output directory
- The generated files, especially `GO_df.csv`, `KEGG_df.csv`, `GO_list.rda`, `KEGG_list.rda`, and the combined dot chart
- The path to `session_info.txt`

Post-run checklist:
- Re-parse the original `--feature` string using the documented separator rules and report the deduplicated gene count after trimming
- Check `temp/GO_df.csv` and `temp/GO_list.rda` before claiming GO success
- Check `temp/KEGG_df.csv` and `temp/KEGG_list.rda` before claiming KEGG success
- Check `plot/gokegg_dot_chart.<format>`, `plot/gokegg_dot_chart_data.csv`, `plot/gokegg_dot_chart_data.rda`, and `session_info.txt` before claiming full success
- Summarize the final result with: parsed gene count, GO status, KEGG status, plot status, output directory, and key output files

On failure, the agent should report:
- The exact `SKILL_*` error code
- The failing step, such as gene parsing, ID conversion, enrichment, or plotting
- The actionable next step, such as fixing input IDs, checking missing packages, or regenerating `.rda` files

## Parameter Reference

### `scripts/main.R`

| Short | Long | Type | Default | Required | Description |
|---|---|---|---|---|---|
| `-f` | `--feature` | character | `""` | Yes | Gene list separated by commas, Chinese commas, semicolons, tabs, or newlines |
| `-o` | `--output_dir` | character | `./output/` | No | Main output directory |
| `-s` | `--sp` | character | `org.Hs.eg.db` | No | Species database |
| `-g` | `--gene_type` | character | `SYMBOL` | No | Input gene ID type |
| `-p` | `--pvalue_cutoff` | numeric | `0.05` | No | Enrichment p-value cutoff |
| `-q` | `--qvalue_cutoff` | numeric | `0.2` | No | Enrichment q-value cutoff |
| `-m` | `--pAdjustMethod` | character | `BH` | No | P-value adjustment method |
|  | `--seed` | integer | `66` | No | Random seed |
|  | `--go_input` | character | `NULL` | No | Optional GO `.rda`; defaults to `output_dir/temp/GO_list.rda` |
|  | `--kegg_input` | character | `NULL` | No | Optional KEGG `.rda`; defaults to `output_dir/temp/KEGG_list.rda` |
|  | `--outdir` | character | `NULL` | No | Plot output directory; defaults to `output_dir/plot` |
|  | `--go_top_n` | numeric | `3` | No | Top GO terms per ontology |
|  | `--kegg_top_n` | numeric | `3` | No | Top KEGG pathways |
| `-w` | `--width` | numeric | `20` | No | Plot width in cm |
|  | `--height` | numeric | `16` | No | Plot height in cm |
|  | `--format` | character | `pdf` | No | Plot format: `pdf`, `png`, `svg` |
|  | `--dpi` | numeric | `300` | No | DPI for raster output |
| `-c` | `--colors` | character | `#E41A1C,#FFFF33,#2E86AB,#4DAF4A` | No | Colors for `GO:BP,GO:CC,GO:MF,KEGG` |
|  | `--title` | character | `GO + KEGG Dot Chart` | No | Plot title |
|  | `--xlab` | character | `NULL` | No | Horizontal axis label override |
|  | `--ylab` | character | `NULL` | No | Vertical axis label override |
|  | `--dot_size` | numeric | `4.5` | No | Dot size |
|  | `--shape` | numeric | `19` | No | Dot shape |
|  | `--rotate` / `--no-rotate` | logical flag | `TRUE` | No | Rotate plot orientation on or off |
|  | `--sorting` | character | `descending` | No | Dot sorting order |
|  | `--label_width` | numeric | `35` | No | Label wrap width |
|  | `--title_size` | numeric | `12` | No | Title font size |
|  | `--axis_title_size` | numeric | `9` | No | Axis title font size |
|  | `--axis_text_size` | numeric | `8` | No | Axis text font size |
|  | `--legend_title_size` | numeric | `8` | No | Legend title font size |
|  | `--legend_text_size` | numeric | `7` | No | Legend text font size |
|  | `--legend_position` | character | `top` | No | Legend position |
|  | `--plot_margin` | character | `10,10,10,10` | No | Plot margins: top,right,bottom,left |
|  | `--axis_line_size` | numeric | `0.5` | No | Axis line width |
|  | `--axis_ticks_size` | numeric | `0.5` | No | Axis tick width |
|  | `--show_grid` | logical | `FALSE` | No | Show grid lines |
| `-v` | `--verbose` | logical | `FALSE` | No | Enable verbose logging |

## Input Format

### Main Analysis Input
- `--feature` should be provided as a gene list
- Preferred separator: comma
- Also accepted: Chinese commas, semicolons, tabs, and newlines
- Leading and trailing spaces around each gene are removed automatically with trimming
- The gene ID type must match `--gene_type`
- `--sp` supports only `org.Hs.eg.db`, `org.Mm.eg.db`, and `org.Rn.eg.db`

Examples:
`TP53,EGFR,BRCA1,MYC`

`TP53, EGFR, BRCA1, MYC`

`TP53；EGFR；BRCA1；MYC`

`TP53\nEGFR\nBRCA1\nMYC`

Example command with minimal input:
`Rscript scripts/main.R --feature "TP53,EGFR,BRCA1,MYC" --output_dir ./example_output --sp org.Hs.eg.db --gene_type SYMBOL`

Example command with custom plotting parameters:
`Rscript scripts/main.R --feature "TP53,EGFR,BRCA1,MYC" --output_dir ./example_plot_output --sp org.Hs.eg.db --gene_type SYMBOL --go_top_n 5 --kegg_top_n 8 --colors "#E41A1C,#FFFF33,#2E86AB,#4DAF4A" --title "Custom GO + KEGG Dot Chart" --xlab="-log10(adjusted p-value)" --ylab="Enriched Terms" --width 24 --height 18 --label_width 40 --format png --dpi 300 --no-rotate --verbose`

Note: values passed to `--xlab` or `--ylab` that start with `-` should use `--option=value` syntax to avoid being parsed as flags.

Note: separator variants are supported only when they are passed inside a single `--feature` argument value.

### Plot Input
- Plotting is triggered by `scripts/main.R`
- `--go_input`: optional `.rda` file containing a `GO_list` object
- `--kegg_input`: optional `.rda` file containing a `KEGG_list` object
- If not provided, `main.R` uses the newly generated files under `output_dir/temp`
- Plotting requires result tables with at least `Description` and `p.adjust`

## Output Files

| File Name | Format | Description |
|---|---|---|
| `temp/GO_df.csv` | CSV | GO enrichment result table |
| `temp/GO_list.rda` | RDA | Full GO enrichment object |
| `temp/KEGG_df.csv` | CSV | KEGG enrichment result table |
| `temp/KEGG_list.rda` | RDA | Full KEGG enrichment object |
| `plot/gokegg_dot_chart.pdf` etc. | PDF/PNG/SVG | Combined GO/KEGG dot chart |
| `plot/gokegg_dot_chart_data.csv` | CSV | Combined plotting table used for the figure |
| `plot/gokegg_dot_chart_data.rda` | RDA | Plot bundle with plotting data and parameters |
| `session_info.txt` | TXT | Runtime session information |

## Error Handling

Common error codes and fixes:
- `SKILL_FILE_NOT_FOUND`: Input file does not exist; check the path and permissions
- `SKILL_FILE_FORMAT_ERROR`: `.rda` cannot be read or is malformed; regenerate upstream results
- `SKILL_MISSING_COLUMNS`: Result table is missing `Description` or `p.adjust`
- `SKILL_EMPTY_DATA`: Input genes are empty after parsing, cannot be converted, or enrichment results are empty
- `SKILL_INVALID_PARAMETER`: Required parameter missing, unsupported species, or insufficient color count
- `SKILL_PACKAGE_NOT_FOUND`: Required package is not installed
- `SKILL_ANALYSIS_FAILED`: Internal GO/KEGG enrichment failure; verify `gene_type`, `sp`, and input genes

For detailed troubleshooting, read `references/troubleshooting.md`.

## Testing

Minimal test dataset: use a small built-in gene list directly, with no extra files required.

Smoke test command:
`Rscript scripts/main.R --feature "TP53,EGFR,BRCA1,MYC" --output_dir ./test_output --sp org.Hs.eg.db --gene_type SYMBOL --pvalue_cutoff 0.05 --qvalue_cutoff 0.2 --pAdjustMethod BH --seed 66 --go_top_n 3 --kegg_top_n 3 --format pdf --verbose`

Expected smoke-test outputs:
- `./test_output/temp/GO_list.rda`
- `./test_output/temp/KEGG_list.rda`
- `./test_output/temp/GO_df.csv`
- `./test_output/temp/KEGG_df.csv`
- `./test_output/plot/gokegg_dot_chart.pdf`
- `./test_output/plot/gokegg_dot_chart_data.csv`
- `./test_output/plot/gokegg_dot_chart_data.rda`
- `./test_output/session_info.txt`
- Exit status code `0`

Automated regression script:
`Rscript test/test_regressions.R`

The regression script covers:
- Separator parsing with comma, Chinese semicolon, newline, tab, and mixed separators
- Empty parsed-gene handling
- Invalid `--plot_margin` validation
- Plot input validation for missing GO/KEGG inputs

Separator examples for manual CLI verification:
`Rscript scripts/main.R --feature "TP53,EGFR,BRCA1,MYC" --output_dir ./test_sep_comma`
`Rscript scripts/main.R --feature "TP53；EGFR；BRCA1；MYC" --output_dir ./test_sep_cn_semicolon`
`Rscript scripts/main.R --feature $'TP53\nEGFR\nBRCA1\nMYC' --output_dir ./test_sep_newline`
`Rscript scripts/main.R --feature $'TP53\tEGFR\tBRCA1\tMYC' --output_dir ./test_sep_tab`
`Rscript scripts/main.R --feature $'TP53； EGFR, BRCA1	MYC' --output_dir ./test_sep_mixed`

Note: all separators must be passed inside a single `--feature` argument value.