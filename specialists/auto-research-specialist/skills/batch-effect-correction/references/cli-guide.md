# CLI Usage Guide

## Basic Syntax

```bash
Rscript scripts/main.R [OPTIONS]
```

## Required Arguments

| Argument | Description |
|----------|-------------|
| `-i FILE` | Expression matrix file (CSV; genes as rows, samples as columns) |
| `-g FILE` | Sample metadata file (CSV; must include sample, group, and batch columns) |

## Optional Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `-o DIR` | ./output/ | Output directory |
| `-b NAME` | batch | Batch column name in metadata |
| `-c NAME` | group | Biological group column name in metadata |
| `-n NAME` | sample | Sample ID column name in metadata |
| `-l MODE` | auto | Log transform mode: `auto`, `yes`, or `no` |
| `-t VALUE` | 600 | Timeout in seconds; use `0` to disable |
| `-s VALUE` | 42 | Random seed |

## Complete Examples

### Example 1: Basic Batch Correction

```bash
# Prepare input files
# expression_matrix.csv: merged expression matrix
# sample_info.csv: sample-to-group-and-batch mapping

Rscript scripts/main.R \
  --input_file expression_matrix.csv \
  --group_file sample_info.csv \
  --output_dir ./results
```

### Example 2: Custom Metadata Column Names

```bash
Rscript scripts/main.R \
  --input_file expression_matrix.csv \
  --group_file metadata.csv \
  --output_dir ./results \
  --sample_column sample_id \
  --group_column condition \
  --batch_column platform_batch
```

### Example 3: Disable Log Transform and Timeout

```bash
Rscript scripts/main.R \
  --input_file expression_matrix.csv \
  --group_file sample_info.csv \
  --output_dir ./results \
  --log_transform no \
  --timeout_seconds 0 \
  --seed 42
```

## Actual Baseline Run

### Input Parameters

```bash
Rscript scripts/main.R \
  --input_file tests/data/expression_matrix_merged.csv \
  --group_file tests/data/sample_info.csv \
  --output_dir tests/output \
  --batch_column batch \
  --group_column group \
  --sample_column sample \
  --log_transform auto \
  --timeout_seconds 600 \
  --seed 42
```

### Output Files

| File | Description |
|------|-------------|
| `corrected_expression_matrix.csv` | Batch-corrected expression matrix with `gene_id` and 79 sample columns |
| `matched_sample_info.csv` | Standardized metadata used by the run |
| `batch_before_boxplot.pdf` | Sample distribution boxplot before correction |
| `batch_after_boxplot.pdf` | Sample distribution boxplot after correction |
| `batch_before_pca.pdf` | PCA scatter plot before correction with batch-colored points; batch ellipses are added when batch size/covariance supports stable fitting |
| `batch_after_pca.pdf` | PCA scatter plot after correction with batch-colored points; batch ellipses are added when batch size/covariance supports stable fitting |
| `batch_before_clustering.pdf` | Hierarchical clustering before correction |
| `batch_after_clustering.pdf` | Hierarchical clustering after correction |
| `session_info.txt` | R version and loaded package versions |

### Output Directory Listing

```text
batch_after_boxplot.pdf
batch_after_clustering.pdf
batch_after_pca.pdf
batch_before_boxplot.pdf
batch_before_clustering.pdf
batch_before_pca.pdf
corrected_expression_matrix.csv
matched_sample_info.csv
session_info.txt
```

### Output Content Preview

#### corrected_expression_matrix.csv

```csv
"gene_id","GSM3130531","GSM3130532","GSM3130533",...
"DDX11L1",0.435906484400539,0.282700761914156,0.23441734976183,...
"WASH7P",4.72502867329995,5.62068056411745,5.02228533170582,...
```

#### matched_sample_info.csv

```csv
"sample_id","group","batch"
"GSM3130531","Normal","GSE114007"
"GSM3130532","Normal","GSE114007"
"GSM3130533","Normal","GSE114007"
```

#### session_info.txt

```text
R version 4.1.2 (2021-11-01)
Platform: x86_64-pc-linux-gnu (64-bit)
Running under: Ubuntu 20.04.5 LTS
other attached packages:
[1] limma_3.50.3 sva_3.42.0 BiocParallel_1.28.3
[4] genefilter_1.76.0 mgcv_1.8-38 nlme_3.1-153
[7] data.table_1.15.4 optparse_1.7.1
```

### Runtime And Resource Usage

The following metrics were captured from a local baseline run of the command above, using shell-level timing around the `Rscript` invocation plus the GC snapshot emitted by the script itself.

| Metric | Value |
|--------|-------|
| Start time | `2026-04-20 10:43:44` |
| End time | `2026-04-20 10:43:52` |
| Elapsed time | `7.729 s` |
| User CPU time | `8.069 s` |
| System CPU time | `3.371 s` |
| Timeout setting | `600` |
| GC snapshot (Ncells) | `used 5,597,851 (299.0 Mb)` |
| GC snapshot (Vcells) | `used 9,481,453 (72.4 Mb)` |

Resource note:

- The recorded baseline run completed without timeout, out-of-memory, or abnormal resource pressure in the target container environment.

## Getting Help

```bash
Rscript scripts/main.R --help
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Error (file not found, invalid parameter, invalid data, dependency issue, or runtime failure) |
