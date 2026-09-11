# CLI Guide — Sample Group Sankey Plot

## Minimal Run (Two Stages)

```bash
Rscript scripts/main.R \
  --input_file ./annotations.csv \
  --output_dir ./output \
  --columns risk,Responder
```

## Three-Stage Plot with Title

```bash
Rscript scripts/main.R \
  --input_file ./annotations.csv \
  --output_dir ./output_three_stage \
  --columns risk,Responder,Subtype \
  --title "Risk to response transitions" \
  --seed 42
```

## Use All Columns (auto-detect stages)

```bash
Rscript scripts/main.R \
  --input_file ./annotations.csv \
  --output_dir ./output_all_columns
```

## Custom Output Prefix and Aesthetics

```bash
Rscript scripts/main.R \
  --input_file ./annotations.csv \
  --output_dir ./output_custom \
  --columns risk,Responder,Subtype \
  --output_prefix my_analysis \
  --alpha 0.3 \
  --label_size 5 \
  --width 10 \
  --height 7
```

Expected outputs:
```
output_custom/table/selected_annotations.csv
output_custom/table/sankey_lodes.csv
output_custom/plot/my_analysis.pdf
output_custom/data/session_info.txt
```

## Handling Missing Values

```bash
Rscript scripts/main.R \
  --input_file ./annotations.csv \
  --output_dir ./output \
  --columns risk,Responder \
  --missing_label "Unknown"
```

Blank or `NA` entries in the selected columns are replaced with `Unknown` in both the CSV output and the plot strata.

## TSV Input

```bash
Rscript scripts/main.R \
  --input_file ./annotations.tsv \
  --output_dir ./output_tsv \
  --columns risk,Responder
```

Files with `.tsv` or `.txt` extensions are automatically parsed as tab-separated.

## Disable Timeout

```bash
Rscript scripts/main.R \
  --input_file ./large_annotations.csv \
  --output_dir ./output \
  --columns risk,Responder,Subtype,Cohort,Treatment \
  --timeout 0
```

Pass `--timeout 0` to disable the elapsed-time limit for large datasets.

## Print Help

```bash
Rscript scripts/main.R --help
```
