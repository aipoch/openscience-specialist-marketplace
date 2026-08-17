# Troubleshooting Guide

## Common Error Codes

### SKILL_FILE_NOT_FOUND

**Error examples:**

```text
SKILL_FILE_NOT_FOUND: Input file not found: path/to/expression.csv
SKILL_FILE_NOT_FOUND: Group file not found: path/to/group.csv
SKILL_FILE_NOT_FOUND: TOM object not found in saved TOM file: output/data/wgcna_tom-block.1.RData
```

**Cause:**

- The input file path is wrong
- The file was moved or deleted
- The TOM output file was not produced because the previous analysis failed

**Solution:**

- Verify that `--input_file` and `--group_file` point to existing files
- Use relative or absolute paths consistently when running `Rscript`
- If the TOM file is missing, rerun the full analysis and inspect earlier log messages

### SKILL_MISSING_COLUMNS

**Error examples:**

```text
SKILL_MISSING_COLUMNS: Group file sample column contains empty values
SKILL_MISSING_COLUMNS: Group file group column contains empty values
SKILL_MISSING_COLUMNS: Expression matrix sample columns must have non-empty names
SKILL_MISSING_COLUMNS: First column of the expression matrix must contain non-empty gene identifiers
```

**Cause:**

- Header names are missing or empty
- The selected sample/group columns do not exist
- Gene IDs are missing from the first column

**Solution:**

- Confirm the CSV header row is present
- Check `--sample_column` and `--group_column`
- Ensure the first column of the expression matrix contains gene IDs
- Remove blank sample names or blank group values

### SKILL_EMPTY_DATA

**Error examples:**

```text
SKILL_EMPTY_DATA: Expression matrix is empty or missing sample columns
SKILL_EMPTY_DATA: Group file is empty or missing required columns
SKILL_EMPTY_DATA: No genes passed the MAD filter
SKILL_EMPTY_DATA: Filtered matrix is too small for WGCNA after quality control
SKILL_EMPTY_DATA: No genes found in selected module 'brown'
```

**Cause:**

- The input file is empty
- Filtering is too strict
- Too many genes or samples are removed during QC
- A requested module contains no genes after processing

**Solution:**

- Check that the expression matrix contains enough genes and samples
- Lower `--mad_quantile` or `--min_mad`
- Set `--max_genes 0` to avoid trimming retained genes
- Verify the requested module exists in `tables/selected_modules.csv`

### SKILL_INVALID_PARAMETER

**Error examples:**

```text
SKILL_INVALID_PARAMETER: Both --input_file and --group_file are required
SKILL_INVALID_PARAMETER: network_type must be one of: unsigned, signed
SKILL_INVALID_PARAMETER: cor_type must be one of: pearson, bicor
SKILL_INVALID_PARAMETER: trait_of_interest must be one of: Case, Control
SKILL_INVALID_PARAMETER: module_of_interest must be one of: brown, turquoise, blue
```

**Cause:**

- A required argument was not supplied
- A numeric parameter is out of range
- A parameter value is not one of the allowed choices
- The selected trait or module is not available in the results

**Solution:**

- Run `Rscript scripts/main.R --help`
- Check valid values for `network_type`, `cor_type`, and numeric thresholds
- Inspect `tables/module_trait_cor.csv` and `tables/selected_modules.csv` before selecting a trait or module manually

### SKILL_SAMPLE_MISMATCH

**Error examples:**

```text
SKILL_SAMPLE_MISMATCH: Samples in group file not found in expression matrix: TCGA-01-0001, TCGA-01-0002
SKILL_SAMPLE_MISMATCH: Expression matrix contains samples missing from the group file
```

**Cause:**

- Sample IDs do not match between the expression matrix and the group file
- Different naming conventions, whitespace, or missing rows exist in one file

**Solution:**

- Make sample IDs identical across files
- Remove leading or trailing whitespace
- Check for duplicated or missing sample rows

### SKILL_PACKAGE_NOT_FOUND

**Error example:**

```text
SKILL_PACKAGE_NOT_FOUND: Required package is not installed: WGCNA
```

**Cause:**

- A required R package is missing from the environment

**Solution:**

- Install the missing package before rerunning
- Minimum required packages for this skill are `optparse`, `WGCNA`, and `data.table`

```r
install.packages(c("optparse", "data.table"))
if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager")
BiocManager::install("WGCNA")
```

## Practical Issues

### The analysis stops because of elapsed time limit

**Cause:** `--timeout_seconds` is too small for the dataset size.

**Solution:**

- Set `--timeout_seconds 0` to disable the limit
- Or increase the timeout value for larger analyses

### The TOM heatmap is slow or memory-intensive

**Cause:** Too many retained genes or too large a TOM sample.

**Solution:**

- Lower `--tom_sample_size`
- Reduce retained genes with `--max_genes`
- Enable chunked loading with `--chunk_size` for large input files

### The selected trait was not provided

**Observed behavior:**

The script warns and automatically uses the first trait column.

**Solution:**

- Set `--trait_of_interest` explicitly if you need a specific trait
- Review the encoded trait columns in `tables/module_trait_cor.csv`

### No module reaches the target scale-free fit threshold

**Observed behavior:**

The script logs a warning and falls back to a sample-size-dependent power.

**Solution:**

- Review `tables/sft_fit_indices.csv` and `plots/soft_threshold.pdf`
- Consider adjusting `--soft_r2_cutoff`
- Interpret results more cautiously when a fallback power is used
