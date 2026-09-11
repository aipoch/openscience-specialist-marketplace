# CLI Usage Guide

## Basic Syntax

```bash
Rscript scripts/main.R [OPTIONS]
```

## Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `-i, --input_file` | required | Expression matrix CSV |
| `-g, --group_file` | required | Sample annotation CSV |
| `-o, --output_dir` | `./output/` | Output directory |
| `-d, --distance_method` | `euclidean` | Distance metric passed to `dist()` |
| `-m, --linkage_method` | `complete` | Linkage method passed to `hclust()`: complete, single, average, mcquitty, median, centroid, ward.D, ward.D2 |
| `-l, --label_column` | second column | Metadata column used as dendrogram labels |
| `-c, --label_cex` | `0.8` | Label size in the PDF output |
| `-t, --timeout_seconds` | `300` | Elapsed-time limit in seconds |
| `-s, --seed` | `42` | Random seed |

## Verified Local Runs

The commands below were executed locally on `2026-04-16` with the bundled dataset:

- Expression matrix: `tests/data/sample_expression_matrix.csv`
- Group file: `tests/data/sample_groups.csv`
- Data shape observed during execution: `21` features x `40` matched samples
- CSV reader used in all examples: `data.table::fread`
- Resource summary source:
  - Runtime from shell `time -p`
  - Memory from the script's `gc()`-based console messages, summed across tracked cell classes

### Example 1: Default Batch Labels

```bash
Rscript scripts/main.R \
  -i tests/data/sample_expression_matrix.csv \
  -g tests/data/sample_groups.csv \
  -o tests/cli_runs/default \
  -d euclidean \
  -m complete \
  -l batch \
  -c 0.8 \
  -t 300 \
  -s 42
```

**Actual runtime and resources**

- `real 0.68`
- `user 0.62`
- `sys 0.55`
- Peak in-script memory message: `28.60 MB` after writing outputs

**Output files**

- `clustering_order.csv` (`778 B`)
- `hierarchical_clustering_plot.pdf` (`5.5 KB`)
- `matched_samples.csv` (`656 B`)
- `sample_distance_matrix.csv` (`27 KB`)
- `session_info.txt` (`867 B`)

**Content preview**

`clustering_order.csv`

```csv
plot_order,sample_id,label
1,Sample21,batch2
2,Sample01,batch1
3,Sample30,batch2
4,Sample08,batch2
```

`matched_samples.csv`

```csv
sample_id,label
Sample01,batch1
Sample02,batch2
Sample03,batch1
Sample04,batch2
```

### Example 2: Use Sample IDs as Labels

```bash
Rscript scripts/main.R \
  -i tests/data/sample_expression_matrix.csv \
  -g tests/data/sample_groups.csv \
  -o tests/cli_runs/sample_labels \
  -d euclidean \
  -m complete \
  -l sample \
  -c 0.8 \
  -t 300 \
  -s 42
```

**Actual runtime and resources**

- `real 0.70`
- `user 0.54`
- `sys 0.44`
- Peak in-script memory message: `28.60 MB` after writing outputs

**Output files**

- `clustering_order.csv` (`858 B`)
- `hierarchical_clustering_plot.pdf` (`5.6 KB`)
- `matched_samples.csv` (`736 B`)
- `sample_distance_matrix.csv` (`27 KB`)
- `session_info.txt` (`867 B`)

**Content preview**

`clustering_order.csv`

```csv
plot_order,sample_id,label
1,Sample21,Sample21
2,Sample01,Sample01
3,Sample30,Sample30
4,Sample08,Sample08
```

This run keeps the same sample ordering as Example 1 because the distance and linkage settings are unchanged; only the displayed labels differ.

### Example 3: Average Linkage with Larger Labels

```bash
Rscript scripts/main.R \
  -i tests/data/sample_expression_matrix.csv \
  -g tests/data/sample_groups.csv \
  -o tests/cli_runs/average_linkage \
  -d euclidean \
  -m average \
  -l batch \
  -c 1.0 \
  -t 300 \
  -s 42
```

**Actual runtime and resources**

- `real 0.66`
- `user 0.52`
- `sys 0.44`
- Peak in-script memory message: `28.60 MB` after writing outputs

**Output files**

- `clustering_order.csv` (`778 B`)
- `hierarchical_clustering_plot.pdf` (`5.4 KB`)
- `matched_samples.csv` (`656 B`)
- `sample_distance_matrix.csv` (`27 KB`)
- `session_info.txt` (`867 B`)

**Content preview**

`clustering_order.csv`

```csv
plot_order,sample_id,label
1,Sample09,batch2
2,Sample26,batch1
3,Sample08,batch2
4,Sample01,batch1
```

This run changes the dendrogram order because `average` linkage produces a different cluster merge history from `complete` linkage.

## Session Output

Every successful run writes `session_info.txt` to the output directory.

```text
R version 4.1.2 (2021-11-01)
Platform: x86_64-pc-linux-gnu (64-bit)
other attached packages:
[1] optparse_1.7.1

loaded via a namespace (and not attached):
[1] compiler_4.1.2    getopt_1.20.3     data.table_1.15.4
```

## Getting Help

```bash
Rscript scripts/main.R --help
```

## Run Tests

```bash
Rscript tests/run_tests.R
```

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | Error (`SKILL_*` failure, invalid input, timeout, or output write failure) |
