---
name: hierarchical-clustering-plot
description: "Use when building a sample-level hierarchical clustering dendrogram from a bulk expression matrix and sample annotation table, especially for QC, batch inspection, or sample similarity assessment. Trigger keywords: hierarchical clustering, dendrogram, sample QC, batch inspection, sample similarity. NOT for: differential expression testing, gene clustering heatmaps, single-cell clustering workflows."
---

# Hierarchical Clustering Plot

## When to Use

Use this skill when you need a sample-level hierarchical clustering dendrogram from a bulk expression matrix and a sample annotation table.

- Good fits: sample QC, batch inspection, sample similarity assessment, checking whether annotated sample groups cluster as expected.
- Trigger keywords: hierarchical clustering, dendrogram, sample QC, batch inspection, sample similarity.
- Not for: differential expression testing, gene clustering heatmaps, single-cell clustering workflows.

## When to Read External Files

| Situation | File to Read | Purpose |
|-----------|--------------|---------|
| **Need algorithm details** | `references/algorithm.md` | Distance calculation, linkage rules, and clustering assumptions |
| **Need to run analysis or inspect CLI entrypoint behavior** | `scripts/main.R` | Execute the workflow and inspect argument parsing, defaults, required flags, and sourced modules |
| **Need workflow implementation details** | `scripts/run_analysis.R` | See orchestration order, temp workspace handling, and output generation |
| **Need logging or warning behavior** | `scripts/logging_utils.R` | See standardized console log formatting and memory usage messages |
| **Need file or parameter validation details** | `scripts/validation_utils.R` | See path checks, output-directory checks, and scalar validation |
| **Need timeout, temp workspace, or session info behavior** | `scripts/runtime_utils.R` | See timeout control, temp cleanup, output copying, and session-info export |
| **Need expression/group input handling** | `scripts/input_functions.R` | See CSV loading, sample matching, and label extraction |
| **Need clustering logic** | `scripts/clustering_functions.R` | See distance calculation and `hclust()` generation |
| **Need output-writing logic** | `scripts/output_utils.R` | See CSV export and PDF rendering |
| **Encounter errors, warnings, or unexpected clustering patterns** | `references/troubleshooting.md` | Common failures, warning follow-up, and interpretation guidance |
| **Need CLI examples or common parameter combinations** | `references/cli-guide.md` | Detailed command patterns for standard, variant, and test runs |
| **Need example input files or schema-concrete fixtures** | `tests/data/` | Inspect sample CSV layouts for expression and group inputs |
| **Need expected output names or artifact formats** | `## Output Files` and `references/cli-guide.md` | Confirm the files the workflow writes and inspect documented example previews |
| **Need to run regression tests** | `tests/run_tests.R` | Execute the automated test suite |
| **Need exact test assertions or edge cases** | `tests/testthat/test-clustering.R` | Inspect validation, reproducibility, and output checks |

---

## Usage

```bash
Rscript scripts/main.R \
  --input_file ./expression_matrix.csv \
  --group_file ./sample_groups.csv \
  --output_dir ./output/ \
  --distance_method euclidean \
  --linkage_method complete \
  --label_column batch \
  --timeout_seconds 300 \
  --seed 42
```

---

## Arguments

| Short | Long | Type | Default | Description |
|-------|------|------|---------|-------------|
| `-i` | `--input_file` | character | **required** | Expression matrix file (features as rows, samples as columns) |
| `-g` | `--group_file` | character | **required** | Sample annotation file (first column sample ID, one metadata column for labels) |
| `-o` | `--output_dir` | character | `./output/` | Output directory |
| `-d` | `--distance_method` | character | `euclidean` | Distance metric for `dist()`: euclidean, maximum, manhattan, canberra, binary, minkowski |
| `-m` | `--linkage_method` | character | `complete` | Linkage method for `hclust()`: complete, single, average, mcquitty, median, centroid, ward.D, ward.D2 |
| `-l` | `--label_column` | character | second column | Column used as dendrogram labels |
| `-c` | `--label_cex` | numeric | `0.8` | Dendrogram label size, must be `> 0` |
| `-t` | `--timeout_seconds` | integer | `300` | Elapsed time limit in seconds, must be `> 0` |
| `-s` | `--seed` | integer | `42` | Random seed for reproducibility |

---

## Input Format

### Expression Matrix (`input_file`)

Features as rows, samples as columns, CSV format with feature IDs in the first column.

```csv
,Sample01,Sample02,Sample03
TSPAN6,1.847876677,1.831755661,3.827625975
TNMD,0.034919984,0.053250385,1.388850793
```

**Requirements:**
- The first column contains unique feature IDs.
- All sample columns must be numeric.
- Sample column names must be unique and non-empty.
- At least two matched samples are required.

### Sample Annotation (`group_file`)

CSV with sample IDs in the first column. The second column is used by default for leaf labels unless `--label_column` is provided.

```csv
sample,batch
Sample01,batch1
Sample02,batch2
Sample03,batch1
```

**Requirements:**
- Sample IDs must match expression matrix column names exactly.
- The selected label column must exist and contain no empty values.
- The file must contain at least one metadata column in addition to sample IDs.

---

## Output Files

| File | Description |
|------|-------------|
| `hierarchical_clustering_plot.pdf` | Sample dendrogram plot |
| `sample_distance_matrix.csv` | Pairwise sample distance matrix |
| `clustering_order.csv` | Leaf order shown in the dendrogram |
| `matched_samples.csv` | Sample-to-label table used for plotting |
| `session_info.txt` | R session and package version info |

## Workflow

### Step 1: Validate Input
**WHEN checking file or parameter validation**, READ: `scripts/validation_utils.R`

**WHEN checking expression/group CSV handling**, READ: `scripts/input_functions.R`

- Check file existence
- Reject empty files before parsing
- Read the expression matrix and sample annotation CSV files
- Validate required columns, unique IDs, and numeric expression values

### Step 2: Align Samples
**WHEN checking sample matching logic**, READ: `scripts/input_functions.R`

- Match sample IDs between the annotation file and expression matrix
- Reorder matrix columns to the annotation file order
- Select the label column used for plotting

### Step 3: Build Hierarchical Clustering
**WHEN interpreting distance or linkage behavior**, READ: `references/algorithm.md`

**WHEN checking clustering implementation**, READ: `scripts/clustering_functions.R`

- Transpose the expression matrix to sample-by-feature form
- Compute pairwise sample distances with `dist()`
- Build the dendrogram with `hclust()`

### Step 4: Save Outputs
**WHEN checking output staging and cleanup behavior**, READ: `scripts/run_analysis.R`

**WHEN checking PDF/CSV export behavior**, READ: `scripts/output_utils.R`

**WHEN checking timeout, session info, or final file copy behavior**, READ: `scripts/runtime_utils.R`

- Stage outputs in a temporary workspace
- Export the pairwise distance matrix
- Export the plotted leaf order
- Render the dendrogram as PDF
- Copy finalized outputs into the requested output directory

---

## Methods

### Distance Matrix
Sample distances are computed from the transposed expression matrix using base R `dist()`.

### Hierarchical Clustering
The clustering tree is built with base R `hclust()`. The default linkage method is `complete`, matching the source analysis script.

---

## Examples

### Basic Usage
```bash
Rscript scripts/main.R \
  -i tests/data/sample_expression_matrix.csv \
  -g tests/data/sample_groups.csv \
  -o ./output/ \
  -t 300
```

### Use Sample IDs as Labels
```bash
Rscript scripts/main.R \
  -i tests/data/sample_expression_matrix.csv \
  -g tests/data/sample_groups.csv \
  -o ./output_sample_labels/ \
  -l sample
```

### Use Average Linkage
```bash
Rscript scripts/main.R \
  -i tests/data/sample_expression_matrix.csv \
  -g tests/data/sample_groups.csv \
  -o ./output_average/ \
  -m average
```

---

## Error Handling

### Common Errors

| Error | Cause | Solution | Read More |
|-------|-------|----------|-----------|
| `SKILL_DEPENDENCY_MISSING` | Required R package is not installed | Install the missing package and rerun | `references/troubleshooting.md#skill_dependency_missing` |
| `SKILL_FILE_NOT_FOUND` | Input file does not exist or output directory could not be created | Check the path and permissions | `references/troubleshooting.md#skill_file_not_found` |
| `SKILL_EMPTY_FILE` | Input file is empty | Re-export the CSV and confirm it contains data | `references/troubleshooting.md#skill_empty_file` |
| `SKILL_EMPTY_DATA` | CSV parsed successfully but contains no data rows | Confirm the CSV has at least one data row | `references/troubleshooting.md#skill_empty_data` |
| `SKILL_PARSE_ERROR` | CSV parsing failed | Check encoding, delimiters, and CSV structure | `references/troubleshooting.md#skill_parse_error` |
| `SKILL_MISSING_COLUMNS` | Expected columns or headers are missing | Check CSV headers and metadata columns | `references/troubleshooting.md#skill_missing_columns` |
| `SKILL_INVALID_TYPE` | Expression values or parameters have the wrong type | Ensure numeric fields are numeric | `references/troubleshooting.md#skill_invalid_type` |
| `SKILL_SAMPLE_MISMATCH` | Sample IDs do not match | Ensure the first column in `group_file` matches matrix column names | `references/troubleshooting.md#skill_sample_mismatch` |
| `SKILL_INVALID_DATA` | Expression or annotation data is malformed | Check duplicate IDs, missing labels, and numeric values | `references/troubleshooting.md#skill_invalid_data` |
| `SKILL_INVALID_PARAMETER` | Unsupported distance, linkage, or label parameter | Use one of the documented parameter values | `references/troubleshooting.md#skill_invalid_parameter` |
| `SKILL_TIMEOUT` | Analysis exceeded the time limit | Increase `--timeout_seconds` and rerun | `references/troubleshooting.md#skill_timeout` |
| `SKILL_PLOT_ERROR` | Plot device failed while writing PDF | Check output directory permissions and rerun | `references/troubleshooting.md#skill_plot_error` |
| `SKILL_WRITE_ERROR` | Output or intermediate files could not be written | Check output directory permissions and free disk space | `references/troubleshooting.md#skill_write_error` |
| `SKILL_WARNING` | Non-fatal warning occurred during execution | Inspect console warnings and verify output quality | `references/troubleshooting.md#skill_warning` |
| `SKILL_MEMORY_WARNING` | Memory usage exceeded the warning threshold | Reduce input size or rerun with more memory | `references/troubleshooting.md#skill_memory_warning` |

**IF error persists**, READ: `references/troubleshooting.md`

---

## Testing

### Test with Sample Data

```bash
# Check help
Rscript scripts/main.R --help

# Run with sample data
Rscript scripts/main.R \
  -i tests/data/sample_expression_matrix.csv \
  -g tests/data/sample_groups.csv \
  -o ./output/

# Run unit tests (requires testthat and data.table)
Rscript tests/run_tests.R
```

### Validation Commands

```bash
# Check main output plot exists
ls -la ./output/hierarchical_clustering_plot.pdf

# Inspect clustering order
wc -l ./output/clustering_order.csv
```

## Implementation Checklist

- [x] CLI parsing with `optparse`
- [x] `set.seed()` for reproducibility
- [x] Input validation (file existence, emptiness, types, required columns)
- [x] Try-catch based fatal error handling
- [x] Standardized `SKILL_*` error classification
- [x] Timeout control with `setTimeLimit()`
- [x] Standardized console-only logging
- [x] Base R clustering implementation
- [x] Session info recording with `sink()`
- [x] Temporary workspace cleanup with `on.exit()`
- [x] Memory usage reporting with `gc()`
- [x] File reading instructions in SKILL.md
- [x] Modular script structure across `scripts/`
- [x] Test template added under `tests/testthat/`
- [x] Test data provided
- [x] Error handling with `SKILL_*` codes
- [x] `get_script_dir()` defined before use
- [x] Scripts in `scripts/` directory
- [x] References in `references/` directory

---

*Last updated: 2026-04-16 | Version: 1.0.0*
