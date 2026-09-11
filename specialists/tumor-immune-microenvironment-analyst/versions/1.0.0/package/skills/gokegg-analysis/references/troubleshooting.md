# Troubleshooting Guide

## Overview

This document summarizes common errors and fixes for the `gokegg` module.
The module accepts a comma-separated gene list, converts gene IDs to `ENTREZID`, performs GO/KEGG enrichment, and generates a combined dot chart.

## Common Errors

### SKILL_FILE_NOT_FOUND

**Error:**
```text
SKILL_FILE_NOT_FOUND: 文件不存在 /path/to/file
```

**Typical causes:**
- `--go_input` or `--kegg_input` path is incorrect
- The KEGG mapping file under `assets/` is missing
- Output or input path was moved or deleted

**Solution:**
- Verify the file path is correct
- Confirm the file exists before running
- Check read permission for the file and parent directory

### SKILL_FILE_FORMAT_ERROR

**Error:**
```text
SKILL_FILE_FORMAT_ERROR: 无法读取 GO input /path/to/GO_list.rda ...
```

**Typical causes:**
- Input file is not a valid `.rda`
- File is corrupted or incomplete
- The file content does not match the expected saved object format

**Solution:**
- Re-generate the `.rda` file from the previous analysis step
- Verify the file can be loaded in R with `load()`
- Avoid editing `.rda` files manually

### SKILL_MISSING_COLUMNS

**Error:**
```text
SKILL_MISSING_COLUMNS: GO results missing required columns: Description, p.adjust
```

or

```text
SKILL_MISSING_COLUMNS: GO file does not contain GO_list object (or fallback 'obj')
```

**Typical causes:**
- GO/KEGG result table structure is incomplete
- Required columns were renamed or removed
- Loaded `.rda` does not contain the expected object name such as `GO_list` or `KEGG_list`
- Older intermediate files were generated before the object naming logic was fixed

**Solution:**
- Ensure GO results contain `Description` and `p.adjust`
- Ensure KEGG results contain `Description` and `p.adjust`
- Re-run the enrichment analysis to rebuild standard outputs
- In R, inspect a saved file with `load(path, envir = e); ls(e)` to confirm the object name matches the expected loader input

### SKILL_EMPTY_DATA

**Error:**
```text
SKILL_EMPTY_DATA: No GO or KEGG enrichment results to visualize
```

**Typical causes:**
- Input gene list is empty after trimming
- No genes could be converted to `ENTREZID`
- Enrichment returned no significant GO terms or KEGG pathways
- Plotting data became empty after filtering `p.adjust <= 0` or missing values

**Solution:**
- Check whether the input gene list is non-empty
- Verify the selected `gene_type` matches the actual input gene IDs
- Relax `pvalue_cutoff` or `qvalue_cutoff` if appropriate
- Confirm the species database matches the gene source

### SKILL_INVALID_PARAMETER

**Error:**
```text
SKILL_INVALID_PARAMETER: Unsupported species database org.Xx.eg.db
```

**Typical causes:**
- Missing required parameter such as `--feature`
- Unsupported species database
- Invalid plotting parameter values or malformed margin string

**Solution:**
- Check all required parameters are provided
- Use supported species only:
  - `org.Hs.eg.db`
  - `org.Mm.eg.db`
  - `org.Rn.eg.db`
- Verify parameter spelling and value format

### SKILL_PACKAGE_NOT_FOUND

**Error:**
```text
SKILL_PACKAGE_NOT_FOUND: 依赖包未安装 clusterProfiler
```

**Typical causes:**
- Required R package is not installed
- Species annotation package is missing

**Solution:**
- Install the missing package before running
- Common required packages include:
  - `clusterProfiler`
  - `optparse`
  - `ggplot2`
  - `dplyr`
  - `stringr`
  - `ggpubr`
  - species packages such as `org.Hs.eg.db`

### SKILL_ANALYSIS_FAILED

**Error:**
```text
SKILL_ANALYSIS_FAILED: KEGG enrichment failed ...
```

**Typical causes:**
- Enrichment function failed internally
- Gene ID conversion result is invalid for the selected analysis
- Species mapping and input IDs are inconsistent

**Solution:**
- Check whether input genes can be mapped to `ENTREZID`
- Confirm `gene_type` and `sp` are correct
- Test with a smaller known-valid gene list first

## Visualization Issues

### Combined Dot Chart Is Empty

**Cause:**
- No valid GO/KEGG rows remain after filtering
- Both GO and KEGG returned empty results
- `main.R` completed enrichment but the plotting inputs generated under `output_dir/temp` are empty after filtering

**Solution:**
- Check the upstream enrichment result tables
- Confirm `Description` and `p.adjust` are present and valid
- Reduce filtering strictness in upstream analysis if biologically reasonable

### Not Enough Colors For Categories

**Error:**
```text
SKILL_INVALID_PARAMETER: Not enough colors for categories: GO:BP, GO:CC, GO:MF, KEGG
```

**Cause:**
- `--colors` provides fewer colors than the number of plotted categories
- Plot validation stops before drawing when the palette length is insufficient

**Solution:**
- Provide at least 4 colors for a full GO+KEGG plot
- Recommended order:
  - `GO:BP`
  - `GO:CC`
  - `GO:MF`
  - `KEGG`

### Labels Are Too Crowded

**Cause:**
- Too many terms/pathways selected
- Label text is too long

**Solution:**
- Reduce `--go_top_n` or `--kegg_top_n`
- Increase `--label_width`
- Increase plot width/height
- Use `--rotate` to improve readability

## Debug Checklist

Before reporting an issue, check the following:
- Input gene list is not empty
- `gene_type` matches the actual ID type
- `sp` matches the species source
- GO/KEGG `.rda` files can be loaded normally
- Required columns `Description` and `p.adjust` exist
- Required R packages are installed
- Plot color count is sufficient for the number of categories

## Output Expectations

When the module runs successfully through `scripts/main.R`, you should obtain:
- GO result table and `GO_list.rda`
- KEGG result table and `KEGG_list.rda`
- Combined GO/KEGG dot chart
- `gokegg_dot_chart_data.csv`
- `gokegg_dot_chart_data.rda`
- `session_info.txt`

If enrichment succeeds but the plot is empty, the problem is usually in result filtering or plotting inputs, not in the plotting engine itself.
