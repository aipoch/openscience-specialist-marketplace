# CLI Guide

## Basic Syntax

```bash
Rscript scripts/main.R [OPTIONS]
```

## Required Arguments

| Argument | Description |
|----------|-------------|
| `--input_file` | Expression matrix CSV |
| `--group_file` | Group annotation CSV |
| `--case` | Case group name |
| `--control` | Control group name |

## Optional Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `--output_dir` | `./DEG` | Output directory |
| `--diff_method` | `limma` | DEG method; current code supports `limma` |
| `--p_threshold` | `0.05` | Significance threshold |
| `--logfc_threshold` | `1` | Absolute logFC threshold |
| `--top_n` | `5` | Top up/down genes for clustered heatmap export |
| `--p_type` | `p.adj` | P-value field used for screening |
| `--run_plots` | `TRUE` | Whether to generate volcano plot and clustered heatmap |
| `--timeout_seconds` | `3600` | Runtime timeout |
| `--seed` | `42` | Random seed |

## Example 1: Minimal Test Run

```bash
Rscript scripts/main.R \
  --input_file tests/data/oa_exp.csv \
  --group_file tests/data/oa_group.csv \
  --case OA \
  --control control \
  --output_dir ./results
```

### Output Files

| File | Size (bytes) |
|------|--------------|
| `data/DEG_list.rda` | `56191` |
| `plot/heatmap.pdf` | `9666` |
| `plot/volcano_plot.pdf` | `118402` |
| `session_info.txt` | `864` |
| `table/DEG.csv` | `4169` |
| `table/Diffanalysis.csv` | `133214` |

### Runtime and Resource Usage

| Metric | Value |
|--------|-------|
| Start time | `2026-04-16 10:26:11` |
| End time | `2026-04-16 10:26:12` |
| Exit code | `0` |
| Wall-clock time | `1.253` |
| User CPU time | `1.372` |
| System CPU time | `1.259` |
| Max resident set size | `Not recorded` |

## Example 2: Custom Thresholds

```bash
Rscript scripts/main.R \
  --input_file tests/data/oa_exp.csv \
  --group_file tests/data/oa_group.csv \
  --case OA \
  --control control \
  --output_dir ./results \
  --p_threshold 0.01 \
  --logfc_threshold 1.5 \
  --top_n 10
```

### Output Files

| File | Size (bytes) |
|------|--------------|
| `data/DEG_list.rda` | `55306` |
| `plot/heatmap.pdf` | `10093` |
| `plot/volcano_plot.pdf` | `118209` |
| `session_info.txt` | `864` |
| `table/DEG.csv` | `1034` |
| `table/Diffanalysis.csv` | `133214` |

### Runtime and Resource Usage

| Metric | Value |
|--------|-------|
| Start time | `2026-04-16 10:28:14` |
| End time | `2026-04-16 10:28:15` |
| Exit code | `0` |
| Wall-clock time | `1.202` |
| User CPU time | `1.366` |
| System CPU time | `1.209` |
| Max resident set size | `Not recorded` |

## Example 3: Use Raw P-values for Screening

```bash
Rscript scripts/main.R \
  --input_file tests/data/oa_exp.csv \
  --group_file tests/data/oa_group.csv \
  --case OA \
  --control control \
  --output_dir ./results \
  --p_type p
```

### Output Files

| File | Size (bytes) |
|------|--------------|
| `data/DEG_list.rda` | `56220` |
| `plot/heatmap.pdf` | `9666` |
| `plot/volcano_plot.pdf` | `121079` |
| `session_info.txt` | `864` |
| `table/DEG.csv` | `4236` |
| `table/Diffanalysis.csv` | `133214` |

### Runtime and Resource Usage

| Metric | Value |
|--------|-------|
| Start time | `2026-04-16 10:30:27` |
| End time | `2026-04-16 10:30:28` |
| Exit code | `0` |
| Wall-clock time | `1.362` |
| User CPU time | `1.529` |
| System CPU time | `1.189` |
| Max resident set size | `Not recorded` |

## Example 4: Disable Plot Generation

```bash
Rscript scripts/main.R \
  --input_file tests/data/oa_exp.csv \
  --group_file tests/data/oa_group.csv \
  --case OA \
  --control control \
  --output_dir ./results \
  --run_plots FALSE
```

### Output Files

| File | Size (bytes) |
|------|--------------|
| `data/DEG_list.rda` | `56191` |
| `plot/heatmap.pdf` | `9666` |
| `plot/volcano_plot.pdf` | `121079` |
| `session_info.txt` | `864` |
| `table/DEG.csv` | `4169` |
| `table/Diffanalysis.csv` | `133214` |

### Runtime and Resource Usage

| Metric | Value |
|--------|-------|
| Start time | `2026-04-16 10:31:01` |
| End time | `2026-04-16 10:31:01` |
| Exit code | `0` |
| Wall-clock time | `0.770` |
| User CPU time | `1.062` |
| System CPU time | `1.155` |
| Max resident set size | `Not recorded` |

## Help

```bash
Rscript scripts/main.R --help
```

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | Failure |

## Output Layout After the Latest Revision

- `data/DEG_list.rda`: R serialized result object
- `table/Diffanalysis.csv`: full differential result table
- `table/DEG.csv`: significant genes only
- `plot/volcano_plot.pdf`: volcano plot
- `plot/heatmap.pdf`: clustered heatmap
