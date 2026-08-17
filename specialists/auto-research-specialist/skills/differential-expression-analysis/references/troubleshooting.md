# Troubleshooting Guide

## Common Errors

### SKILL_FILE_NOT_FOUND

**Error:**
```
SKILL_FILE_NOT_FOUND: Input file does not exist: path/to/file.csv
```

**Solution:**
- Verify the file path is correct
- Check file permissions
- Ensure file exists before running

### SKILL_SAMPLE_MISMATCH

**Error:**
```
SKILL_SAMPLE_MISMATCH: Samples in group file not found in expression matrix: GSM1442228, GSM1442229
```

**Solution:**
- Verify sample IDs in group file match column names in expression matrix exactly
- Check for whitespace or encoding issues
- Ensure all samples in group file have expression data

### SKILL_FILTER_ERROR

**Error:**
```
SKILL_FILTER_ERROR: Insufficient significant genes (0) below minimum (1)
```

**Solution:**
- Relax p-value or logFC thresholds
- Check if your data has biological variation
- Verify correct group comparisons (treatment vs control)

### SKILL_INVALID_PARAMETER

**Error:**
```
SKILL_INVALID_PARAMETER: Unknown method: invalid_method
```

**Solution:**
- Use valid method: limma, deseq2, edger, t, wilcox
- Check spelling and case sensitivity

## Visualization Issues

### Empty Heatmap

**Cause:** No significant genes found with current thresholds

**Solution:**
- Increase p_threshold or decrease logfc_threshold
- Check if data has differential expression

### Missing Volcano Plot Labels

**Cause:** top_n parameter too small or gene list empty

**Solution:**
- Set `top_n` to larger value (e.g., 20)
- Or specify genes explicitly: `--gene_labels gene1,gene2,gene3`

## Method-Specific Issues

### DESeq2 Warning: "ncol(x) == nrow(design) is not TRUE"

**Cause:** Sample names in count matrix don't match design matrix

**Solution:**
- Ensure column names of count matrix match rownames of group data

### edgeR Error: "all groups must be represented at least once"

**Cause:** Some groups in group file have no samples

**Solution:**
- Verify each group has at least one sample
- Check group file for typos

### limma Warning: "Coefficient not estimable"

**Cause:** Model matrix is not full rank

**Solution:**
- Ensure at least 2 samples per group
- Check for duplicate sample IDs
