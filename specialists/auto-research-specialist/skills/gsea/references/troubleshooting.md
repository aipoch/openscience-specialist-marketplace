# Troubleshooting

## Error codes and remedies

### SKILL_FILE_NOT_FOUND
- When: a path passed via `--input`, `--running_file`, `--enrich_file`, or `--rds_path` does not exist
- Fix: check the file path, permissions, and working directory

### SKILL_MISSING_COLUMNS
- When: the input file is missing the column named by `--gene_col` or `--fc_col`
- Fix: confirm the column names; pass them explicitly if needed

### SKILL_EMPTY_DATA
- When: the input table is empty, or no genes remain after dropping NA values
- Fix: inspect the file contents and column quality

### SKILL_INVALID_PARAMETER
- When: an argument such as `type`, `species`, `method`, `pvalue_cutoff`, or `timeout` has an invalid value
- Fix: run `Rscript scripts/main.R --help` and check each argument

### SKILL_PACKAGE_NOT_FOUND
- When: a required package such as `optparse`, `clusterProfiler`, `fgsea`, `msigdbr`, or `enrichplot` is not installed
- Fix: install the missing package and re-run

### SKILL_ANALYSIS_FAILED
- When: GSEA still fails after retries
- Fix: check input data quality, gene-set contents, and the `--method` argument; review the full error log

## Log format

Logs follow this format:
- `[INFO]  YYYY-MM-DD HH:MM:SS | message`
- `[WARN]  YYYY-MM-DD HH:MM:SS | message`
- `[ERROR] YYYY-MM-DD HH:MM:SS | code: message`

## Suggested triage order

1. Run `Rscript scripts/main.R --help`
2. Check the input file and column names
3. Check that argument values are valid
4. Check that all required packages are installed

## Example

`[ERROR] 2026-04-15 10:00:00 | SKILL_FILE_NOT_FOUND: File does not exist ./missing.csv`
