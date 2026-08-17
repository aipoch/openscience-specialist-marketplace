---
name: differential-expression-analysis
description: Use when analyzing bulk RNA-seq or microarray expression data to identify differentially expressed genes between two biological groups (case vs control), with volcano plots and heatmap visualization. NOT for:single-cell RNA-seq, methylation analysis, non-expression data.
license: MIT
author: AIPOCH
---
> **Source**: [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills)

# Differential Expression Analysis

## When to Read External Files

| Situation | File to Read | Purpose |
|-----------|--------------|---------|
| **Need algorithm details** | `references/algorithm.md` | Statistical methods, formulas, assumptions |
| **Need to run analysis** | `scripts/main.R` | Execute: `Rscript scripts/main.R --input_file ... --group_file ...` |
| **Encounter errors** | `references/troubleshooting.md` | Common errors and solutions |
| **Need CLI examples** | `references/cli-guide.md` | Detailed CLI usage examples |
| **Need test data** | `tests/data/` | Sample input files for testing |

---

## Usage

```bash
Rscript scripts/main.R \
  --input_file ./expression_matrix.csv \
  --group_file ./group_info.csv \
  --output_dir ./output/ \
  --diff_method limma \
  --p_threshold 0.05 \
  --logfc_threshold 0.1 \
  --seed 42
```

---

## Arguments

| Short | Long | Type | Default | Description |
|-------|------|------|---------|-------------|
| `-i` | `--input_file` | character | **required** | Expression matrix file (genes as rows, samples as columns) |
| `-g` | `--group_file` | character | **required** | Group information file (sample ID + group columns) |
| `-o` | `--output_dir` | character | `./output/` | Output directory |
| `-m` | `--diff_method` | character | `limma` | Method: limma, deseq2, edger, t, wilcox |
| `-n` | `--norm_method` | character | `TMM` | Normalization for edgeR: TMM, RLE, upperquartile |
| `-p` | `--p_threshold` | numeric | `0.05` | P-value threshold |
| `-f` | `--logfc_threshold` | numeric | `0.1` | Log fold change threshold |
| `-s` | `--seed` | integer | `42` | Random seed for reproducibility |

---

## Input Format

### Expression Matrix (input_file)

Genes as rows, samples as columns, CSV format with gene ID in first column.

```csv
"","GSM1442228","GSM1442229","GSM1442230"
"0610006L08Rik",3.438,3.237,3.265
"0610007P14Rik",6.734,7.017,6.807
```

### Group File (group_file)

CSV with sample ID and group columns.

```csv
"ID","group"
"GSM1442228","Control"
"GSM1442229","Control"
"GSM1442230","DIC"
```

---

## Output Files

| File | Description |
|------|-------------|
| `Diffanalysis.csv` | Complete DE results with gene_id, logFC, Pvalue, Padj |
| `volcano_plot.pdf` | Volcano plot with significance thresholds |
| `heatmap.pdf` | Heatmap of top upregulated/downregulated genes |
| `session_info.txt` | R session and package version info |
| `temp/rdegs.csv` | Significant differentially expressed genes |
| `temp/Diffanalysis_filtered.csv` | Full results with group annotations |

---

## Workflow

### Step 1: Validate Input
- Check file existence
- Validate sample matching between expression matrix and group file
- Verify at least 2 samples per group

### Step 2: Run Differential Expression
- Choose method: limma, DESeq2, edgeR, t-test, or Wilcoxon
- Calculate logFC and p-values
- Apply multiple testing correction (Benjamini-Hochberg)

### Step 3: Filter Results
- Filter by p-value and logFC thresholds
- Classify genes as Up, Down, or Not significant

### Step 4: Generate Visualizations
- Volcano plot showing significance vs fold change
- Heatmap of top differential genes

---

## Methods

### limma
Linear models for microarray and RNA-seq with empirical Bayes moderation. Recommended for normalized expression data (FPKM, TPM).

### DESeq2
Negative binomial GLM with variance stabilization. Recommended for raw count data.

### edgeR
Empirical Bayes methods with TMM normalization. Supports robust dispersion estimation.

### t-test / Wilcoxon
Simple pairwise statistical tests. t-test for parametric, Wilcoxon for non-parametric.

---

## Examples

### Basic Usage (limma)
```bash
Rscript scripts/main.R \
  -i expression_matrix.csv \
  -g group_info.csv \
  -o ./output \
  -m limma
```

### With DESeq2 for Count Data
```bash
Rscript scripts/main.R \
  -i count_matrix.csv \
  -g group_info.csv \
  -o ./output \
  -m deseq2
```

### Custom Thresholds
```bash
Rscript scripts/main.R \
  -i expression_matrix.csv \
  -g group_info.csv \
  -o ./output \
  -p 0.01 \
  -f 0.5
```

---

## Error Handling

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `SKILL_FILE_NOT_FOUND` | Input file doesn't exist | Check file path |
| `SKILL_SAMPLE_MISMATCH` | Sample names don't match | Verify group file matches expression matrix columns |
| `SKILL_INVALID_DATA` | Less than 2 groups or samples per group | Check group file |
| `SKILL_FILTER_ERROR` | No significant genes found | Relax thresholds or check data quality |
| `SKILL_DEPENDENCY_MISSING` | R package not installed | Install required packages |

**IF error persists**, READ: `references/troubleshooting.md`

---

## Testing

### Test with Sample Data

```bash
# Check help
Rscript scripts/main.R --help

# Run with sample data
Rscript scripts/main.R \
  -i tests/data/Combined_Datasets_Matrix_mus.csv \
  -g tests/data/Combined_Datasets_mus_Group.csv \
  -o tests/output/
```

### Validation Commands

```bash
# Count lines in output
wc -l output/Diffanalysis.csv

# Check volcano plot exists
ls -la output/volcano_plot.pdf
```

---

## Implementation Checklist

- [x] CLI parsing with `optparse`
- [x] `set.seed()` for reproducibility
- [x] `requireNamespace()` dependency checks
- [x] Session info recording
- [x] Temp file cleanup
- [x] File reading instructions in SKILL.md
- [x] Modular script structure (<100 lines per file)
- [x] Test data provided
- [x] Error handling with SKILL_* codes
- [x] Scripts in `scripts/` directory
- [x] References in `references/` directory

---

*Last updated: 2026-04-01 | Version: 2.0.0*
