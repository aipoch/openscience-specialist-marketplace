# Troubleshooting

## SKILL_FILE_NOT_FOUND

Cause:

- `--input_file` does not exist
- `--group_file` does not exist
- `--output_dir/data/GSVA_list.rda` is missing in `visualize` mode

Fix:

- Confirm the file path is correct
- Use absolute paths if the working directory is uncertain
- Run `analyze` mode before `visualize` mode

## SKILL_MISSING_COLUMNS

Cause:

- The group file does not contain a supported sample column
- The group file does not contain a supported group column

Fix:

- Rename the sample column to `sample`, `sample_name`, or `sample_id`
- Rename the group column to `group`, `condition`, `cluster`, or `class`

## SKILL_SAMPLE_MISMATCH

Cause:

- Sample names in the expression matrix do not match the group file
- The saved GSVA result does not overlap with the available group metadata

Fix:

- Remove extra whitespace from sample names
- Ensure sample identifiers are spelled identically in both files
- Confirm that the expression matrix columns exclude the gene ID column only

## SKILL_EMPTY_DATA

Cause:

- The expression matrix has too few rows or columns
- The matrix contains missing or non-numeric values
- The selected MSigDB query returns no pathways
- Heatmap filtering retains fewer than two pathways

Fix:

- Check the input matrix for empty rows, empty columns, and missing values
- Verify `--species`, `--category`, and `--subcategory`
- Try a broader gene set collection or a different species
- Remove `--top_up` and `--top_down` if the subset is too small

## SKILL_INVALID_PARAMETER

Cause:

- A required CLI argument is missing
- `--mode`, `--method`, `--kcdf`, `--scale`, or `--top_mode` has an unsupported value
- `--plot_file` contains path separators or parent directory segments
- `--fdr_threshold` is outside `[0, 1]`
- Fewer than two samples exist in one of the comparison groups

Fix:

- Run `Rscript scripts/main.R --help`
- Compare the command with `references/cli-guide.md`
- Ensure the case and control labels exactly match the group file

## SKILL_PACKAGE_NOT_FOUND

Cause:

- One or more R packages are not installed in the current R environment

Fix:

```r
install.packages(c("optparse", "pheatmap"))
if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager")
BiocManager::install(c("GSVA", "limma", "msigdbr"))
```

## Generic Runtime Warnings

Cause:

- The selected pathways are not significant at the requested FDR threshold

Fix:

- Inspect `table/GSVA_diff.csv`
- Increase `--top_n`
- Relax `--fdr_threshold`
- Test `--method ssgsea` if the default GSVA mode is unstable for your data
