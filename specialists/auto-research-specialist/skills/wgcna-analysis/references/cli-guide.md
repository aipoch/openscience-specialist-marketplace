# CLI Usage Guide

## Basic Syntax

```bash
Rscript scripts/main.R [OPTIONS]
```

## Required Arguments

| Argument | Description |
|----------|-------------|
| `-i, --input_file` | Expression matrix CSV file |
| `-g, --group_file` | Sample-to-group mapping CSV file |

## Optional Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `-o, --output_dir` | `./output/` | Output directory |
| `-a, --sample_column` | `sample` | Sample column in group file |
| `-b, --group_column` | `group` | Group column in group file |
| `-n, --network_type` | `unsigned` | WGCNA network type |
| `-c, --cor_type` | `pearson` | Correlation type |
| `-q, --mad_quantile` | `0.25` | MAD quantile cutoff |
| `-m, --min_mad` | `0.01` | Minimum MAD cutoff |
| `-k, --max_genes` | `0` | Max retained genes; `0` keeps all |
| `-p, --min_module_size` | `30` | Minimum module size |
| `-r, --merge_cut_height` | `0.25` | Module merge cut height |
| `-u, --soft_r2_cutoff` | `0.85` | Target scale-free fit cutoff |
| `-t, --trait_of_interest` | `NULL` | Trait used for module export plots |
| `-x, --module_of_interest` | `auto` | Module color(s) to export |
| `--top_modules` | `1` | Number of top modules to export in auto mode |
| `-y, --tom_sample_size` | `400` | Gene sample size for TOM heatmap |
| `--chunk_size` | `0` | Chunk size for row-wise loading |
| `-s, --seed` | `42` | Random seed |
| `-z, --timeout_seconds` | `0` | Optional elapsed-time limit |

## Complete Examples

### Example 1: Basic run with bundled test data

```bash
Rscript scripts/main.R \
  --input_file tests/data/expression.csv \
  --group_file tests/data/group.csv \
  --output_dir results/ \
  --seed 42
```

### Output Files

| File | Size |
|------|------|
| `data/analysis_objects.rds` | `1.71 MB (1787854 bytes)` |
| `data/net.rds` | `93.08 KB (95314 bytes)` |
| `data/wgcna_tom-block.1.RData` | `42.83 MB (44912052 bytes)` |
| `plots/gene_cluster_modules.pdf` | `78.96 KB (80850 bytes)` |
| `plots/module_eigengene_heatmap.pdf` | `10.64 KB (10895 bytes)` |
| `plots/module_membership_vs_trait_brown_Case.pdf` | `23.80 KB (24369 bytes)` |
| `plots/module_membership_vs_trait_cyan_Case.pdf` | `8.40 KB (8600 bytes)` |
| `plots/module_membership_vs_trait_salmon_Case.pdf` | `10.83 KB (11090 bytes)` |
| `plots/module_membership_vs_trait_turquoise_Case.pdf` | `49.70 KB (50893 bytes)` |
| `plots/module_trait_relationships.pdf` | `7.05 KB (7220 bytes)` |
| `plots/sample_clustering.pdf` | `5.02 KB (5141 bytes)` |
| `plots/soft_threshold.pdf` | `5.25 KB (5379 bytes)` |
| `plots/tom_heatmap.pdf` | `661.55 KB (677423 bytes)` |
| `session_info.txt` | `2.87 KB (2938 bytes)` |
| `tables/analysis_summary.csv` | `114 B (114 bytes)` |
| `tables/module_assignments.csv` | `60.58 KB (62030 bytes)` |
| `tables/module_genes_brown.csv` | `29.16 KB (29856 bytes)` |
| `tables/module_genes_cyan.csv` | `5.61 KB (5748 bytes)` |
| `tables/module_genes_salmon.csv` | `9.29 KB (9515 bytes)` |
| `tables/module_genes_turquoise.csv` | `72.11 KB (73841 bytes)` |
| `tables/module_trait_cor.csv` | `1.27 KB (1302 bytes)` |
| `tables/module_trait_p.csv` | `1.23 KB (1264 bytes)` |
| `tables/selected_modules.csv` | `138 B (138 bytes)` |
| `tables/sft_fit_indices.csv` | `2.17 KB (2220 bytes)` |

### Runtime and Resource Usage

| Metric | Value |
|--------|-------|
| Start time | `2026-04-17 15:24:23` |
| End time | `2026-04-17 15:24:56` |
| Exit code | `0` |
| Timing mode | `shell` |
| Wall-clock time | `33.599` |
| User CPU time | `27.237` |
| System CPU time | `16.331` |
| Max resident set size | `Not recorded by time tool` |
| Cgroup peak memory | `5.69 GB (6108057600 bytes)` |
| Cgroup current memory | `106.26 MB (111419392 bytes)` |
| Cgroup peak before run | `5.69 GB (6108057600 bytes)` |
| Auxiliary logs saved | `no` |

### Example 2: Signed network with robust correlation

```bash
Rscript scripts/main.R \
  --input_file tests/data/expression.csv \
  --group_file tests/data/group.csv \
  --output_dir results/ \
  --network_type signed \
  --cor_type bicor \
  --soft_r2_cutoff 0.9 \
  --min_module_size 40 \
  --seed 42
```

### Output Files

| File | Size |
|------|------|
| `data/analysis_objects.rds` | `1.40 MB (1472085 bytes)` |
| `data/net.rds` | `92.25 KB (94463 bytes)` |
| `data/wgcna_tom-block.1.RData` | `43.38 MB (45487714 bytes)` |
| `plots/gene_cluster_modules.pdf` | `78.28 KB (80163 bytes)` |
| `plots/module_eigengene_heatmap.pdf` | `8.75 KB (8965 bytes)` |
| `plots/module_membership_vs_trait_brown_Case.pdf` | `23.80 KB (24369 bytes)` |
| `plots/module_membership_vs_trait_cyan_Case.pdf` | `8.40 KB (8600 bytes)` |
| `plots/module_membership_vs_trait_salmon_Case.pdf` | `10.83 KB (11090 bytes)` |
| `plots/module_membership_vs_trait_turquoise_Case.pdf` | `49.70 KB (50893 bytes)` |
| `plots/module_trait_relationships.pdf` | `6.60 KB (6763 bytes)` |
| `plots/sample_clustering.pdf` | `5.02 KB (5141 bytes)` |
| `plots/soft_threshold.pdf` | `5.22 KB (5349 bytes)` |
| `plots/tom_heatmap.pdf` | `572.04 KB (585766 bytes)` |
| `session_info.txt` | `2.87 KB (2938 bytes)` |
| `tables/analysis_summary.csv` | `117 B (117 bytes)` |
| `tables/module_assignments.csv` | `59.66 KB (61096 bytes)` |
| `tables/module_genes_brown.csv` | `29.16 KB (29856 bytes)` |
| `tables/module_genes_cyan.csv` | `5.61 KB (5748 bytes)` |
| `tables/module_genes_salmon.csv` | `9.29 KB (9515 bytes)` |
| `tables/module_genes_turquoise.csv` | `72.11 KB (73841 bytes)` |
| `tables/module_trait_cor.csv` | `1000 B (1000 bytes)` |
| `tables/module_trait_p.csv` | `970 B (970 bytes)` |
| `tables/selected_modules.csv` | `141 B (141 bytes)` |
| `tables/sft_fit_indices.csv` | `2.16 KB (2215 bytes)` |

### Runtime and Resource Usage

| Metric | Value |
|--------|-------|
| Start time | `2026-04-17 15:25:43` |
| End time | `2026-04-17 15:26:09` |
| Exit code | `0` |
| Timing mode | `shell` |
| Wall-clock time | `25.488` |
| User CPU time | `25.917` |
| System CPU time | `14.169` |
| Max resident set size | `Not recorded by time tool` |
| Cgroup peak memory | `5.69 GB (6108057600 bytes)` |
| Cgroup current memory | `106.75 MB (111931392 bytes)` |
| Cgroup peak before run | `5.69 GB (6108057600 bytes)` |
| Auxiliary logs saved | `no` |


### Example 3: Export specific modules for a chosen trait

```bash
Rscript scripts/main.R \
  --input_file tests/data/expression.csv \
  --group_file tests/data/group.csv \
  --output_dir results/ \
  --trait_of_interest Case \
  --module_of_interest brown,turquoise \
  --tom_sample_size 200 \
  --seed 42
```

### Output Files

| File | Size |
|------|------|
| `data/analysis_objects.rds` | `1.71 MB (1787867 bytes)` |
| `data/net.rds` | `93.08 KB (95314 bytes)` |
| `data/wgcna_tom-block.1.RData` | `42.83 MB (44912052 bytes)` |
| `plots/gene_cluster_modules.pdf` | `78.96 KB (80850 bytes)` |
| `plots/module_eigengene_heatmap.pdf` | `10.64 KB (10895 bytes)` |
| `plots/module_membership_vs_trait_brown_Case.pdf` | `23.80 KB (24369 bytes)` |
| `plots/module_membership_vs_trait_cyan_Case.pdf` | `8.40 KB (8600 bytes)` |
| `plots/module_membership_vs_trait_salmon_Case.pdf` | `10.83 KB (11090 bytes)` |
| `plots/module_membership_vs_trait_turquoise_Case.pdf` | `49.70 KB (50893 bytes)` |
| `plots/module_trait_relationships.pdf` | `7.05 KB (7220 bytes)` |
| `plots/sample_clustering.pdf` | `5.02 KB (5141 bytes)` |
| `plots/soft_threshold.pdf` | `5.25 KB (5379 bytes)` |
| `plots/tom_heatmap.pdf` | `175.93 KB (180155 bytes)` |
| `session_info.txt` | `2.87 KB (2938 bytes)` |
| `tables/analysis_summary.csv` | `125 B (125 bytes)` |
| `tables/module_assignments.csv` | `60.58 KB (62030 bytes)` |
| `tables/module_genes_brown.csv` | `29.16 KB (29856 bytes)` |
| `tables/module_genes_cyan.csv` | `5.61 KB (5748 bytes)` |
| `tables/module_genes_salmon.csv` | `9.29 KB (9515 bytes)` |
| `tables/module_genes_turquoise.csv` | `72.11 KB (73841 bytes)` |
| `tables/module_trait_cor.csv` | `1.27 KB (1302 bytes)` |
| `tables/module_trait_p.csv` | `1.23 KB (1264 bytes)` |
| `tables/selected_modules.csv` | `212 B (212 bytes)` |
| `tables/sft_fit_indices.csv` | `2.17 KB (2220 bytes)` |

### Runtime and Resource Usage

| Metric | Value |
|--------|-------|
| Start time | `2026-04-17 15:26:46` |
| End time | `2026-04-17 15:27:13` |
| Exit code | `0` |
| Timing mode | `shell` |
| Wall-clock time | `26.531` |
| User CPU time | `26.355` |
| System CPU time | `15.342` |
| Max resident set size | `Not recorded by time tool` |
| Cgroup peak memory | `5.69 GB (6108057600 bytes)` |
| Cgroup current memory | `106.37 MB (111534080 bytes)` |
| Cgroup peak before run | `5.69 GB (6108057600 bytes)` |
| Auxiliary logs saved | `no` |


### Example 4: Large matrix with chunked loading

```bash
Rscript scripts/main.R \
  --input_file tests/data/expression.csv \
  --group_file tests/data/group.csv \
  --output_dir results/ \
  --chunk_size 5000 \
  --max_genes 8000 \
  --timeout_seconds 7200 \
  --seed 42
```

### Output Files

| File | Size |
|------|------|
| `data/analysis_objects.rds` | `1.71 MB (1787854 bytes)` |
| `data/net.rds` | `93.08 KB (95314 bytes)` |
| `data/wgcna_tom-block.1.RData` | `42.83 MB (44912052 bytes)` |
| `plots/gene_cluster_modules.pdf` | `78.96 KB (80850 bytes)` |
| `plots/module_eigengene_heatmap.pdf` | `10.64 KB (10895 bytes)` |
| `plots/module_membership_vs_trait_brown_Case.pdf` | `23.80 KB (24369 bytes)` |
| `plots/module_membership_vs_trait_cyan_Case.pdf` | `8.40 KB (8600 bytes)` |
| `plots/module_membership_vs_trait_salmon_Case.pdf` | `10.83 KB (11090 bytes)` |
| `plots/module_membership_vs_trait_turquoise_Case.pdf` | `49.70 KB (50893 bytes)` |
| `plots/module_trait_relationships.pdf` | `7.05 KB (7220 bytes)` |
| `plots/sample_clustering.pdf` | `5.02 KB (5141 bytes)` |
| `plots/soft_threshold.pdf` | `5.25 KB (5379 bytes)` |
| `plots/tom_heatmap.pdf` | `661.55 KB (677423 bytes)` |
| `session_info.txt` | `2.87 KB (2938 bytes)` |
| `tables/analysis_summary.csv` | `114 B (114 bytes)` |
| `tables/module_assignments.csv` | `60.58 KB (62030 bytes)` |
| `tables/module_genes_brown.csv` | `29.16 KB (29856 bytes)` |
| `tables/module_genes_cyan.csv` | `5.61 KB (5748 bytes)` |
| `tables/module_genes_salmon.csv` | `9.29 KB (9515 bytes)` |
| `tables/module_genes_turquoise.csv` | `72.11 KB (73841 bytes)` |
| `tables/module_trait_cor.csv` | `1.27 KB (1302 bytes)` |
| `tables/module_trait_p.csv` | `1.23 KB (1264 bytes)` |
| `tables/selected_modules.csv` | `138 B (138 bytes)` |
| `tables/sft_fit_indices.csv` | `2.17 KB (2220 bytes)` |

### Runtime and Resource Usage

| Metric | Value |
|--------|-------|
| Start time | `2026-04-17 15:27:37` |
| End time | `2026-04-17 15:28:03` |
| Exit code | `0` |
| Timing mode | `shell` |
| Wall-clock time | `26.443` |
| User CPU time | `24.692` |
| System CPU time | `11.554` |
| Max resident set size | `Not recorded by time tool` |
| Cgroup peak memory | `5.69 GB (6108057600 bytes)` |
| Cgroup current memory | `107.10 MB (112304128 bytes)` |
| Cgroup peak before run | `5.69 GB (6108057600 bytes)` |
| Auxiliary logs saved | `no` |


## Getting Help

```bash
Rscript scripts/main.R --help
```

## Notes

- `module_of_interest=auto` ranks non-grey modules by absolute module-trait correlation.
- `trait_of_interest` must match a trait column derived from the group file.
- Chunked loading is useful for large matrices but still requires enough memory for the retained genes during network construction.
