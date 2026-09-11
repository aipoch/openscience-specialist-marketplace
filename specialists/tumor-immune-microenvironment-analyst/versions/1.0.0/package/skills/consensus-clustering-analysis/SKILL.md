---
name: consensus-clustering-analysis
description: "Use when identifying stable sample subtypes from bulk expression matrices with ConsensusClusterPlus, including PAC-based model selection and consensus matrix/CDF visualization. NOT for: differential expression analysis, single-cell clustering workflows, or non-expression tables."
license: MIT
author: AIPOCH
---
> **Source**: [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills)

# Consensus Clustering Analysis

## When to Use

Use this skill when you need to identify stable sample subtypes from a bulk expression matrix with `ConsensusClusterPlus`, compare candidate clustering settings with PAC, and export consensus matrix/CDF visualizations.

Do not use this skill for differential expression analysis, single-cell clustering, or non-expression tabular data.

## When to Read External Files

| Situation | File to Read | Purpose |
|-----------|--------------|---------|
| **Need algorithm details** | `references/algorithm.md` | Consensus clustering, PAC scoring, and preprocessing assumptions |
| **Need to run analysis** | `scripts/main.R` | Execute: `Rscript scripts/main.R --input_file ... --group_file ...` |
| **Encounter errors** | `references/troubleshooting.md` | Common errors and solutions |
| **Need CLI examples** | `references/cli-guide.md` | Detailed CLI usage examples with verified local runs |

---

## Usage

```bash
Rscript scripts/main.R \
  --input_file ./expression_matrix.csv \
  --group_file ./groups.csv \
  --disease_group case \
  --max_k 4 \
  --output_dir ./output/ \
  --gene_selection highly_variable \
  --top_n 5000 \
  --reps 1000 \
  --p_item 0.8 \
  --p_feature 1.0 \
  --timeout_seconds 3600 \
  --seed 42
```

---

## Arguments

| Short | Long | Type | Default | Description |
|-------|------|------|---------|-------------|
| `-i` | `--input_file` | character | **required** | Expression matrix file (genes as rows, samples as columns) |
| `-g` | `--group_file` | character | **required** | Group information file (sample ID + group columns) |
| `-d` | `--disease_group` | character | `case` | Group label retained for clustering |
| `-k` | `--max_k` | integer | `4` | Maximum cluster count to evaluate |
| `-o` | `--output_dir` | character | `./output/` | Output directory |
| `-m` | `--gene_selection` | character | `highly_variable` | Gene selection mode: `highly_variable` or `custom` |
| `-n` | `--top_n` | integer | `5000` | Number of top variable genes to keep |
| `-l` | `--gene_list` | character | `NULL` | Custom gene list file when `gene_selection=custom` |
| `-c` | `--center_data` | logical | `TRUE` | Median-center each gene before clustering |
| `-r` | `--reps` | integer | `1000` | Consensus resampling repetitions |
|  | `--p_item` | double | `0.8` | Sample resampling proportion |
|  | `--p_feature` | double | `1.0` | Feature resampling proportion |
| `-t` | `--timeout_seconds` | integer | `3600` | Elapsed timeout in seconds |
| `-s` | `--seed` | integer | `42` | Random seed for reproducibility |

---

## Input Format

### Expression Matrix (input_file)

Genes as rows, samples as columns, CSV/TSV/TXT format with gene ID in the first column.

```csv
,Sample01,Sample02,Sample03
TSPAN6,1.8479,1.8318,3.8276
TNMD,0.0349,0.0533,1.3889
```

### Group File (group_file)

Delimited text file with sample ID and group columns.

```csv
sample,group
Sample01,case
Sample02,control
Sample03,case
```

### Gene List (gene_list)

Optional plain text or single-column CSV file with one gene symbol per line.

```csv
TNMD
DPM1
SCYL3
```

---

## Output Files

| File | Description |
|------|-------------|
| `Cluster_res.csv` | PAC summary for each distance/algorithm combination with `is_best` marking the selected model |
| `genes_for_clustering.csv` | Selected genes and gene selection mode |
| `samples_for_clustering.csv` | Samples retained after disease-group filtering |
| `result_<distance>_<algorithm>/` | Method-specific consensus outputs and `PAC_scores.csv` |
| `Consensus Matrix Plot.pdf` | Consensus matrix heatmap for the optimal model |
| `CDF curve Plot.pdf` | CDF curves for the optimal method |
| `session_info.txt` | R session and package version info |

---

## Workflow

### Step 1: Validate Input
- Check file existence
- Detect sample and group columns in the group file
- Validate sample matching between expression matrix and group file

### Step 2: Prepare Clustering Matrix
- Filter samples by the requested disease group
- Select genes using `highly_variable` or `custom`
- Median-center genes if requested

### Step 3: Run Consensus Clustering
- Evaluate supported distance and clustering algorithm combinations
- Compute PAC scores across candidate K values
- Select the optimal model by minimum PAC

### Step 4: Generate Outputs
- Save result tables
- Generate consensus matrix and CDF plots
- Record session information for reproducibility

---

## Methods

### ConsensusClusterPlus
Repeated subsampling is used to estimate cluster stability across candidate K values and clustering settings.

### PAC Score
The proportion of ambiguous clustering is computed as `CDF(0.9) - CDF(0.1)` from lower-triangle consensus values. Lower PAC indicates more stable clustering.

### Gene Selection
- `highly_variable`: rank genes by median absolute deviation
- `custom`: use the intersection of the provided gene list and matrix row names

---

## Examples

### Basic Usage
```bash
Rscript scripts/main.R \
  -i expression_matrix.csv \
  -g groups.csv \
  -d case \
  -k 3 \
  -r 20 \
  -o output/example_basic \
  -t 120
```

### With a Custom Gene List
```bash
Rscript scripts/main.R \
  -i expression_matrix.csv \
  -g groups.csv \
  -d case \
  -m custom \
  -l genes.csv \
  -k 4 \
  -r 20 \
  -o output/example_custom \
  -t 120
```

### Without Median Centering
```bash
Rscript scripts/main.R \
  -i expression_matrix.csv \
  -g groups.csv \
  -d case \
  -c FALSE \
  -k 3 \
  -r 20 \
  -o output/example_rawscale \
  -t 120
```

---

## Error Handling

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `SKILL_FILE_NOT_FOUND` | Input file does not exist | Check file path and permissions |
| `SKILL_MISSING_COLUMNS` | Group file lacks sample/group columns | Verify column names in the group file |
| `SKILL_SAMPLE_MISMATCH` | Sample names do not match | Ensure group file sample IDs match matrix columns |
| `SKILL_INVALID_PARAMETER` | CLI value is invalid | Check allowed options and numeric ranges |
| `SKILL_INVALID_DATA` | Too few samples/genes remain after filtering | Lower `max_k` or review the input data |
| `SKILL_TIMEOUT` | Run exceeded the configured timeout | Increase `timeout_seconds` or reduce `reps` |
| `SKILL_DEPENDENCY_MISSING` | Required R package is not installed | Install missing packages before rerunning |

**IF error persists**, READ: `references/troubleshooting.md`

---

## Testing

### Smoke Check

```bash
# Check help
Rscript scripts/main.R --help

# Run analysis
Rscript scripts/main.R \
  -i tests/data/expression_matrix.csv \
  -g tests/data/groups.csv \
  -d case \
  -k 3 \
  -r 20 \
  -o output/example_basic \
  -t 120
```

### Validation Commands

```bash
# Inspect selected model
cat output/example_basic/Cluster_res.csv

# Check output plots exist
ls -la output/example_basic
```

---

## Implementation Checklist

- [x] CLI parsing with `optparse`
- [x] `set.seed()` for reproducibility
- [x] `requireNamespace()` dependency checks
- [x] Session info recording
- [x] `data.table::fread()` input reading
- [x] File reading instructions in `SKILL.md`
- [x] Modular script structure (<150 lines per file)
- [x] Test data provided
- [x] Error handling with `SKILL_*` codes
- [x] Scripts in `scripts/` directory
- [x] References in `references/` directory

---

*Last updated: 2026-04-17 | Version: 1.0.0*
