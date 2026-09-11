# CLI Usage Guide

## Basic Syntax

```bash
Rscript scripts/main.R [OPTIONS]
```

## Required Arguments

| Argument | Description |
|----------|-------------|
| `-i FILE` | Expression matrix file (`csv`, `tsv`, or `txt`) |
| `-g FILE` | Group information file (`csv`, `tsv`, or `txt`) |

## Optional Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `-d LABEL` | `case` | Group retained for clustering |
| `-k INT` | `4` | Maximum cluster count |
| `-o DIR` | `./output/` | Output directory |
| `-m MODE` | `highly_variable` | Gene selection mode |
| `-n INT` | `5000` | Number of top variable genes |
| `-l FILE` | `NULL` | Custom gene list file |
| `-c LOGICAL` | `TRUE` | Median-center genes |
| `-r INT` | `1000` | Consensus repetitions |
| `--p_item FLOAT` | `0.8` | Sample subsampling fraction |
| `--p_feature FLOAT` | `1.0` | Feature subsampling fraction |
| `-t INT` | `3600` | Elapsed timeout in seconds |
| `-s INT` | `42` | Random seed |

## Verified Local Runs

Environment recorded in all three `session_info.txt` files:

```text
R version 4.1.2 (2021-11-01)
Platform: x86_64-pc-linux-gnu (64-bit)
Running under: Ubuntu 20.04.5 LTS

other attached packages:
[1] optparse_1.7.1

loaded via a namespace (and not attached):
[1] compiler_4.1.2              tools_4.1.2
[3] Biobase_2.54.0              getopt_1.20.3
[5] data.table_1.15.4           ConsensusClusterPlus_1.58.0
[7] BiocGenerics_0.40.0         cluster_2.1.2
```

Resource measurement notes:

- `Start time`, `End time`, and `Elapsed time` were captured in the shell around the real `Rscript scripts/main.R ...` invocation.
- `User CPU time` and `System CPU time` come from the bash `time` keyword for the full CLI run.
- `Peak RSS` was sampled from the child `Rscript` process with `ps` while the command was running.
- The current CLI logs Vcells-based heap snapshots through `log_memory_usage()`, but it does not emit Ncells snapshots directly.

## Example 1: Highly Variable Genes

### Command

```bash
Rscript scripts/main.R \
  --input_file expression_matrix.csv \
  --group_file groups.csv \
  --disease_group case \
  --max_k 3 \
  --reps 20 \
  --output_dir ./results \
  --timeout_seconds 120 \
  --seed 42
```

### Actual Parameters

```text
input_file=expression_matrix.csv
group_file=groups.csv
disease_group=case
max_k=3
output_dir=./results
gene_selection=highly_variable
top_n=5000
gene_list=NULL
center_data=TRUE
reps=20
p_item=0.8
p_feature=1.0
timeout_seconds=120
seed=42
```

### Runtime And Resource Usage

| Metric | Value |
|--------|-------|
| Start time | `2026-04-17 11:07:54` |
| End time | `2026-04-17 11:07:56` |
| Elapsed time | `1.921 s` |
| User CPU time | `1.547 s` |
| System CPU time | `0.910 s` |
| Timeout setting | `120 s` |
| Exit status | `0` |
| Peak RSS | `120740 KB` |
| Logged GC snapshot (Vcells, after input loading) | `1077.83 MB / 8192.00 MB trigger` |
| Logged GC snapshot (Vcells, final) | `1218.79 MB / 8192.00 MB trigger` |

### Actual Output Inventory

```text
72 files total

Root-level files:
- session_info.txt
- CDF curve Plot.pdf
- Consensus Matrix Plot.pdf
- Cluster_res.csv
- samples_for_clustering.csv
- genes_for_clustering.csv

Method result folders:
- result_canberra_hc/
- result_canberra_pam/
- result_euclidean_hc/
- result_euclidean_km/
- result_euclidean_pam/
- result_maximum_pam/
- result_minkowski_pam/
- result_pearson_hc/
- result_pearson_pam/
- result_spearman_hc/
- result_spearman_pam/

Each method folder contains exactly these files for k=2..3:
- PAC_scores.csv
- consensus.pdf
- result_<method>.k=2.consensusClass.csv
- result_<method>.k=2.consensusMatrix.csv
- result_<method>.k=3.consensusClass.csv
- result_<method>.k=3.consensusMatrix.csv
```

### Actual Key File Contents

`Cluster_res.csv`

```csv
"dist","clusterAlg","bestK","PAC","is_best"
"pearson","hc",2,0,TRUE
"spearman","hc",3,0.352631578947368,FALSE
"euclidean","hc",2,0.0157894736842105,FALSE
"canberra","hc",2,0.373684210526316,FALSE
"pearson","pam",3,0.152631578947368,FALSE
"spearman","pam",2,0.247368421052632,FALSE
"euclidean","pam",2,0.2,FALSE
"maximum","pam",2,0.494736842105263,FALSE
"canberra","pam",2,0.331578947368421,FALSE
"minkowski","pam",2,0.2,FALSE
"euclidean","km",2,0.105263157894737,FALSE
```

`samples_for_clustering.csv`

```csv
"sample","group"
"Sample01","case"
"Sample03","case"
"Sample06","case"
"Sample07","case"
"Sample11","case"
"Sample15","case"
"Sample16","case"
"Sample17","case"
"Sample19","case"
"Sample23","case"
"Sample24","case"
"Sample26","case"
"Sample28","case"
"Sample31","case"
"Sample32","case"
"Sample33","case"
"Sample34","case"
"Sample36","case"
"Sample39","case"
"Sample40","case"
```

`genes_for_clustering.csv`

```text
101 lines total (header + 100 genes)
First 10 data rows:
"gene","mode"
"SLC7A2","highly_variable"
"PDK4","highly_variable"
"DBNDD1","highly_variable"
"ZMYND10","highly_variable"
"BAD","highly_variable"
"CROT","highly_variable"
"TMEM176A","highly_variable"
"PRSS22","highly_variable"
"COPZ2","highly_variable"
"MEOX1","highly_variable"
```

`result_pearson_hc/PAC_scores.csv`

```csv
"k","PAC"
2,0
3,0.268421052631579
```

## Example 2: Custom Gene List

### Command

```bash
Rscript scripts/main.R \
  --input_file expression_matrix.csv \
  --group_file groups.csv \
  --disease_group case \
  --gene_selection custom \
  --gene_list genes.csv \
  --max_k 4 \
  --reps 20 \
  --output_dir ./results \
  --timeout_seconds 120 \
  --seed 42
```

### Actual Parameters

```text
input_file=expression_matrix.csv
group_file=groups.csv
disease_group=case
max_k=4
output_dir=./results
gene_selection=custom
top_n=5000
gene_list=genes.csv
center_data=TRUE
reps=20
p_item=0.8
p_feature=1.0
timeout_seconds=120
seed=42
```

### Runtime And Resource Usage

| Metric | Value |
|--------|-------|
| Start time | `2026-04-17 11:08:07` |
| End time | `2026-04-17 11:08:09` |
| Elapsed time | `2.131 s` |
| User CPU time | `1.625 s` |
| System CPU time | `0.942 s` |
| Timeout setting | `120 s` |
| Exit status | `0` |
| Peak RSS | `119168 KB` |
| Logged GC snapshot (Vcells, after input loading) | `1077.84 MB / 8192.00 MB trigger` |
| Logged GC snapshot (Vcells, final) | `1223.69 MB / 8192.00 MB trigger` |

### Actual Output Inventory

```text
94 files total

Root-level files:
- session_info.txt
- CDF curve Plot.pdf
- Consensus Matrix Plot.pdf
- Cluster_res.csv
- samples_for_clustering.csv
- genes_for_clustering.csv

Method result folders:
- result_canberra_hc/
- result_canberra_pam/
- result_euclidean_hc/
- result_euclidean_km/
- result_euclidean_pam/
- result_maximum_pam/
- result_minkowski_pam/
- result_pearson_hc/
- result_pearson_pam/
- result_spearman_hc/
- result_spearman_pam/

Each method folder contains exactly these files for k=2..4:
- PAC_scores.csv
- consensus.pdf
- result_<method>.k=2.consensusClass.csv
- result_<method>.k=2.consensusMatrix.csv
- result_<method>.k=3.consensusClass.csv
- result_<method>.k=3.consensusMatrix.csv
- result_<method>.k=4.consensusClass.csv
- result_<method>.k=4.consensusMatrix.csv
```

### Actual Key File Contents

`Cluster_res.csv`

```csv
"dist","clusterAlg","bestK","PAC","is_best"
"pearson","hc",2,0.336842105263158,FALSE
"spearman","hc",4,0.3,FALSE
"euclidean","hc",4,0.152631578947368,TRUE
"canberra","hc",4,0.389473684210526,FALSE
"pearson","pam",4,0.378947368421053,FALSE
"spearman","pam",4,0.378947368421053,FALSE
"euclidean","pam",4,0.405263157894737,FALSE
"maximum","pam",4,0.363157894736842,FALSE
"canberra","pam",4,0.452631578947368,FALSE
"minkowski","pam",4,0.405263157894737,FALSE
"euclidean","km",4,0.489473684210526,FALSE
```

`samples_for_clustering.csv`

```text
Identical to Example 1: 20 case samples retained.
```

`genes_for_clustering.csv`

```text
39 lines total (header + 38 genes)
All retained genes:
"gene","mode"
"TNMD","custom"
"DPM1","custom"
"SCYL3","custom"
"C1orf112","custom"
"FGR","custom"
"CFH","custom"
"FUCA2","custom"
"GCLC","custom"
"NFYA","custom"
"STPG1","custom"
"NIPAL3","custom"
"LAS1L","custom"
"ENPP4","custom"
"SEMA3F","custom"
"CFTR","custom"
"ANKIB1","custom"
"CYP51A1","custom"
"KRIT1","custom"
"RAD52","custom"
"MYH16","custom"
"BAD","custom"
"LAP3","custom"
"CD99","custom"
"HS3ST1","custom"
"AOC1","custom"
"WNT16","custom"
"HECW1","custom"
"MAD1L1","custom"
"LASP1","custom"
"SNX11","custom"
"TMEM176A","custom"
"M6PR","custom"
"KLHL13","custom"
"CYP26B1","custom"
"ICA1","custom"
"DBNDD1","custom"
"ALS2","custom"
"CASP10","custom"
```

`result_euclidean_hc/PAC_scores.csv`

```csv
"k","PAC"
2,0.168421052631579
3,0.226315789473684
4,0.152631578947368
```

## Example 3: Raw Scale Without Centering

### Command

```bash
Rscript scripts/main.R \
  --input_file expression_matrix.csv \
  --group_file groups.csv \
  --disease_group case \
  --center_data FALSE \
  --max_k 3 \
  --reps 20 \
  --output_dir ./results \
  --timeout_seconds 120 \
  --seed 42
```

### Actual Parameters

```text
input_file=expression_matrix.csv
group_file=groups.csv
disease_group=case
max_k=3
output_dir=./results
gene_selection=highly_variable
top_n=5000
gene_list=NULL
center_data=FALSE
reps=20
p_item=0.8
p_feature=1.0
timeout_seconds=120
seed=42
```

### Runtime And Resource Usage

| Metric | Value |
|--------|-------|
| Start time | `2026-04-17 11:08:16` |
| End time | `2026-04-17 11:08:18` |
| Elapsed time | `2.032 s` |
| User CPU time | `1.609 s` |
| System CPU time | `0.937 s` |
| Timeout setting | `120 s` |
| Exit status | `0` |
| Peak RSS | `120984 KB` |
| Logged GC snapshot (Vcells, after input loading) | `1077.83 MB / 8192.00 MB trigger` |
| Logged GC snapshot (Vcells, final) | `1218.79 MB / 8192.00 MB trigger` |

### Actual Output Inventory

```text
72 files total

Root-level files:
- session_info.txt
- CDF curve Plot.pdf
- Consensus Matrix Plot.pdf
- Cluster_res.csv
- samples_for_clustering.csv
- genes_for_clustering.csv

Method result folders:
- result_canberra_hc/
- result_canberra_pam/
- result_euclidean_hc/
- result_euclidean_km/
- result_euclidean_pam/
- result_maximum_pam/
- result_minkowski_pam/
- result_pearson_hc/
- result_pearson_pam/
- result_spearman_hc/
- result_spearman_pam/

Each method folder contains exactly these files for k=2..3:
- PAC_scores.csv
- consensus.pdf
- result_<method>.k=2.consensusClass.csv
- result_<method>.k=2.consensusMatrix.csv
- result_<method>.k=3.consensusClass.csv
- result_<method>.k=3.consensusMatrix.csv
```

### Actual Key File Contents

`Cluster_res.csv`

```csv
"dist","clusterAlg","bestK","PAC","is_best"
"pearson","hc",3,0.352631578947368,FALSE
"spearman","hc",3,0.368421052631579,FALSE
"euclidean","hc",2,0.0157894736842105,FALSE
"canberra","hc",2,0.173684210526316,FALSE
"pearson","pam",2,0.136842105263158,FALSE
"spearman","pam",2,0,TRUE
"euclidean","pam",2,0.2,FALSE
"maximum","pam",2,0.494736842105263,FALSE
"canberra","pam",2,0.421052631578947,FALSE
"minkowski","pam",2,0.2,FALSE
"euclidean","km",2,0.105263157894737,FALSE
```

`samples_for_clustering.csv`

```text
Identical to Example 1: 20 case samples retained.
```

`genes_for_clustering.csv`

```text
Identical to Example 1: 101 lines total (header + 100 highly variable genes).
```

`result_spearman_pam/PAC_scores.csv`

```csv
"k","PAC"
2,0
3,0.236842105263158
```

## Getting Help

```bash
Rscript scripts/main.R --help
```

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | Error |
