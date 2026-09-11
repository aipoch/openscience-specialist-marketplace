# CLI Usage Guide

## Basic Syntax

```bash
Rscript scripts/main.R [OPTIONS]
```

`scripts/main.R` is the current CLI entry point for both enrichment and plotting. It sources `scripts/dochart.R` internally and calls `generate_dot_chart()` after the enrichment step.

## Main Arguments

| Argument | Description |
|----------|-------------|
| `-f, --feature` | Input gene list separated by commas, Chinese commas, semicolons, tabs, or newlines |
| `-o, --output_dir` | Main output directory |
| `-s, --sp` | Species database: `org.Hs.eg.db`, `org.Mm.eg.db`, `org.Rn.eg.db` |
| `-g, --gene_type` | Input gene ID type: `SYMBOL`, `ENSEMBL`, `ENTREZID` |
| `-p, --pvalue_cutoff` | P-value cutoff for enrichment |
| `-q, --qvalue_cutoff` | Q-value cutoff for enrichment |
| `-m, --pAdjustMethod` | Multiple-testing adjustment method |
| `--seed` | Random seed |
| `--go_input` | Optional GO `.rda`; defaults to `output_dir/temp/GO_list.rda` |
| `--kegg_input` | Optional KEGG `.rda`; defaults to `output_dir/temp/KEGG_list.rda` |
| `--outdir` | Plot output directory; defaults to `output_dir/plot` |
| `--go_top_n`, `--kegg_top_n` | Number of GO/KEGG items shown in the plot |
| `--format`, `--width`, `--height`, `--dpi` | Figure output settings |
| `--colors`, `--title`, `--xlab`, `--ylab` | Figure style settings |
| `--rotate`, `--no-rotate`, `--sorting` | Plot orientation and sorting |
| `--label_width`, `--title_size`, `--axis_title_size`, `--axis_text_size`, `--legend_title_size`, `--legend_text_size`, `--legend_position`, `--plot_margin`, `--axis_line_size`, `--axis_ticks_size`, `--show_grid`, `-v, --verbose` | Additional plotting controls |

## Usage Examples

### Example 1: Human gene symbols with default plotting

```bash
Rscript scripts/main.R \
  --feature "TP53,EGFR,BRCA1,MYC" \
  --output_dir ./output \
  --sp org.Hs.eg.db \
  --gene_type SYMBOL \
  --pvalue_cutoff 0.05 \
  --qvalue_cutoff 0.2 \
  --pAdjustMethod BH \
  --seed 66
```

### Example 2: Mouse Ensembl IDs

```bash
Rscript scripts/main.R \
  --feature "ENSMUSG00000017167,ENSMUSG00000064341" \
  --output_dir ./mouse_output \
  --sp org.Mm.eg.db \
  --gene_type ENSEMBL
```

### Example 3: Override plotting inputs and output directory

```bash
Rscript scripts/main.R \
  --feature "TP53,EGFR,BRCA1,MYC" \
  --output_dir ./output \
  --go_input ./output/temp/GO_list.rda \
  --kegg_input ./output/temp/KEGG_list.rda \
  --outdir ./custom_plot \
  --go_top_n 3 \
  --kegg_top_n 3 \
  --title "GO + KEGG Dot Chart"
```

### Example 4: Custom plot appearance

```bash
Rscript scripts/main.R \
  --feature "TP53,EGFR,BRCA1,MYC" \
  --output_dir ./output \
  --colors "#E41A1C,#FFFF33,#2E86AB,#4DAF4A" \
  --width 24 \
  --height 18 \
  --label_width 40 \
  --format pdf \
  --verbose
```

### Example 5: Input examples accepted by `--feature`

```bash
Rscript scripts/main.R --feature "TP53,EGFR,BRCA1,MYC" --output_dir ./example1
Rscript scripts/main.R --feature "TP53, EGFR, BRCA1, MYC" --output_dir ./example2
Rscript scripts/main.R --feature $'TP53\nEGFR\nBRCA1\nMYC' --output_dir ./example3
Rscript scripts/main.R --feature $'TP53\tEGFR\tBRCA1\tMYC' --output_dir ./example4
Rscript scripts/main.R --feature $'TP53； EGFR, BRCA1\tMYC' --output_dir ./example5
```

Note: all separators must be passed inside a single `--feature` argument value.

### Example 6: Modify plotting parameters

```bash
Rscript scripts/main.R \
  --feature "TP53,EGFR,BRCA1,MYC" \
  --output_dir ./custom_plot_output \
  --go_top_n 5 \
  --kegg_top_n 8 \
  --colors "#E41A1C,#FFFF33,#2E86AB,#4DAF4A" \
  --title "Custom GO + KEGG Dot Chart" \
  --xlab="-log10(adjusted p-value)" \
  --ylab="Enriched Terms" \
  --width 24 \
  --height 18 \
  --label_width 40 \
  --format png \
  --dpi 300 \
  --no-rotate \
  --verbose
```

Note: when a value passed to `--xlab` or `--ylab` begins with `-`, use `--option=value` syntax.

## Output Files

Running `scripts/main.R` typically generates:
- `temp/GO_df.csv`
- `temp/GO_list.rda`
- `temp/KEGG_df.csv`
- `temp/KEGG_list.rda`
- `plot/gokegg_dot_chart.pdf` or the selected format
- `plot/gokegg_dot_chart_data.csv`
- `plot/gokegg_dot_chart_data.rda`
- `session_info.txt`

## Getting Help

```bash
Rscript scripts/main.R --help
```

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | Failure, error message written to stderr |
