# CLI examples

## Example 1: minimal run

```bash
Rscript scripts/main.R \
  --input tests/data/sample_deg_results.csv \
  --outdir ./output_basic \
  --type KEGG \
  --species human \
  --seed 42 \
  --timeout 300
```

## Example 2: custom column names with verbose logging

```bash
Rscript scripts/main.R \
  --input tests/data/sample_deg_results.csv \
  --outdir ./output_verbose \
  --gene_col name \
  --fc_col logFC \
  --type GO_BP \
  --species human \
  --method fgsea \
  --pvalue_cutoff 0.05 \
  --verbose \
  --seed 42 \
  --timeout 300
```

## Example 3: use a pre-stored gene-set RDS

Pass `--type HALLMARKS` on the CLI; the script automatically maps it to the asset key `Hallmarks` inside the preloaded RDS.

```bash
Rscript scripts/main.R \
  --input tests/data/sample_deg_results.csv \
  --outdir ./output_rds \
  --type HALLMARKS \
  --species human \
  --rds_path ./assets/ssGSEA.rds \
  --seed 42 \
  --timeout 300
```

## Example 4: plot enrichment curves

Run Example 1 first against `tests/data/sample_deg_results.csv` to produce `./output_basic/Table/enrichGSEA.csv` and `./output_basic/Table/gsea_running_scores.csv`.

```bash
Rscript scripts/main.R \
  --running_file ./output_basic/Table/gsea_running_scores.csv \
  --enrich_file ./output_basic/Table/enrichGSEA.csv \
  --plot_output ./output_basic/plot/gsea_plot.pdf \
  --top_n 3 \
  --plot_format pdf \
  --verbose \
  --seed 42 \
  --timeout 300
```
