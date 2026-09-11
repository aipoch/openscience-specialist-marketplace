# Troubleshooting Guide

## Common Errors

### SKILL_FILE_NOT_FOUND

**Meaning**
The specified input file path does not exist.

**Typical causes**
- Wrong relative path
- Wrong working directory
- File name typo

**Fix**
- Check `--input_file` and `--group_file`
- Confirm the file exists with `ls`
- Rerun from the project root if you use relative paths

---

### SKILL_PACKAGE_NOT_FOUND

**Meaning**
A required R package is not installed.

**Typical causes**
- Missing package such as `optparse`, `data.table`, `limma`, `dplyr`, `ggplot2`, `pheatmap`, or `qs`

**Fix**
- Install the missing package in R
- Then rerun the same command

Example:
```r
install.packages(c("optparse", "data.table", "dplyr", "ggplot2", "pheatmap"))
if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager")
BiocManager::install("limma")
```

---

### SKILL_MISSING_COLUMNS

**Meaning**
The input CSV does not contain the required structural columns.

**Typical causes**
- Expression matrix has no gene ID column
- Group file has fewer than two columns
- Group file layout is badly malformed

**Fix**
- Ensure the expression matrix first column is gene ID
- Ensure the group file contains enough columns to identify sample and group
- If the first column is just row index, keep sample and group in later columns

---

### SKILL_EMPTY_DATA

**Meaning**
The loaded data is empty, or limma returned no analyzable rows.

**Typical causes**
- Empty CSV file
- Header-only input file
- Expression matrix contains only invalid rows after preprocessing

**Fix**
- Check whether the input files contain data rows
- Verify the matrix contains numeric values for downstream modeling

---

### SKILL_INVALID_PARAMETER

**Meaning**
A provided CLI argument or group selection is invalid.

**Typical causes**
- Missing required arguments
- `--p_type` is not `p` or `p.adj`
- `--diff_method` is not supported
- `--case` or `--control` does not exist in the group file
- Fewer than two samples in one selected group

**Fix**
- Recheck all required arguments
- Use `--p_type p` or `--p_type p.adj`
- Use `--diff_method limma`
- Print the group file and verify available group labels

---

### SKILL_SAMPLE_MISMATCH

**Meaning**
Sample IDs in the expression matrix and group file do not align.

**Typical causes**
- Expression matrix sample names do not appear in the group file
- Hidden whitespace in sample IDs
- Wrong column selected as sample column in a malformed group file

**Fix**
- Compare expression matrix column names with group file sample IDs
- Remove leading/trailing whitespace
- Ensure the group file contains one column with true sample IDs

---

## Plot-Related Notes

### Heatmap not generated

**Cause**
No significant genes passed filtering, or fewer than two selected heatmap genes remained after ranking.

**Fix**
- Relax `--p_threshold`
- Decrease `--logfc_threshold`
- Increase `--top_n` if significant genes exist but selection is too narrow
- An empty `table/DEG.csv` is expected when no genes pass the thresholds
- If the run only selects one heatmap gene, `plot/heatmap.pdf` is skipped by design

### Volcano plot not generated

**Cause**
The DEG screening step failed before plot generation.

**Fix**
- Resolve upstream input or filtering errors first
- Confirm that `plot/volcano_plot.pdf` is produced

## Recommended Debug Order

1. Run `Rscript scripts/main.R --help`
2. Check that both input files exist
3. Check the first few rows of both CSV files
4. Confirm sample IDs overlap
5. Confirm `--case` and `--control` exist in the group file
6. Rerun with a new output directory to avoid stale files
