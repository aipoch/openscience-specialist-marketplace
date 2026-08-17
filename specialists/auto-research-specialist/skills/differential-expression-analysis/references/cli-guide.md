# CLI Usage Guide

## Basic Syntax

```bash
Rscript scripts/diff_main.R [OPTIONS]
```

## Required Arguments

| Argument | Description |
|----------|-------------|
| `-i FILE` | Expression matrix file (CSV) |
| `-g FILE` | Group information file (CSV) |

## Optional Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `-o DIR` | ./output/ | Output directory |
| `-m METHOD` | limma | Differential expression method |
| `-n METHOD` | TMM | Normalization method (edgeR only) |
| `-p VALUE` | 0.05 | P-value threshold |
| `-f VALUE` | 0.1 | Log fold change threshold |
| `-s VALUE` | 42 | Random seed |

## Complete Examples

### Example 1: Basic limma Analysis

```bash
# Prepare input files
# expression.csv: gene expression matrix
# groups.csv: sample-to-group mapping

Rscript scripts/diff_main.R \
  --input_file expression.csv \
  --group_file groups.csv \
  --output_dir ./results
```

### Example 2: DESeq2 for RNA-seq Counts

```bash
Rscript scripts/diff_main.R \
  --input_file counts.csv \
  --group_file groups.csv \
  --output_dir ./results \
  --diff_method deseq2
```

### Example 3: edgeR with Custom Thresholds

```bash
Rscript scripts/diff_main.R \
  --input_file counts.csv \
  --group_file groups.csv \
  --output_dir ./results \
  --diff_method edger \
  --norm_method TMM \
  --p_threshold 0.01 \
  --logfc_threshold 0.5
```

### Example 4: Non-parametric Analysis

```bash
Rscript scripts/diff_main.R \
  --input_file expression.csv \
  --group_file groups.csv \
  --diff_method wilcox
```

## Getting Help

```bash
Rscript scripts/diff_main.R --help
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Error (file not found, invalid parameter, etc.) |
