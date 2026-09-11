# Troubleshooting

## Error Codes

### `SKILL_FILE_NOT_FOUND`

Meaning:
The input expression file does not exist, or a required intermediate file was not generated.

Common causes:

- `--input_file` points to the wrong path
- the ESTIMATE step failed before writing `estimate_input.gct` or `estimate_score.gct`

Resolution:

- verify the input path
- rerun the workflow and inspect the log output
- confirm that the `estimate` package is installed and loadable

### `SKILL_MISSING_COLUMNS`

Meaning:
The first column intended to hold gene identifiers contains missing values.

Common causes:

- blank gene identifiers
- malformed header or delimiter problems

Resolution:

- ensure the first column contains gene identifiers for all rows
- verify that the selected delimiter matches the real file format

### `SKILL_EMPTY_DATA`

Meaning:
The input matrix or an ESTIMATE output file was empty.

Common causes:

- the input file contains no rows
- the matrix has no sample columns
- `filterCommonGenes()` filtered out all usable genes

Resolution:

- check that the input matrix is not empty
- confirm that the first column contains valid gene identifiers
- confirm that the gene identifier type matches `--gene_id_type`

### `SKILL_INVALID_PARAMETER`

Meaning:
A CLI argument is missing, out of range, or inconsistent with the file content.

Common causes:

- unsupported `--platform`
- unsupported `--gene_id_type`
- unsupported `--plot_file`
- non-numeric expression values
- duplicate sample names

Resolution:

- rerun `Rscript scripts/main.R --help`
- correct the invalid CLI argument
- ensure all sample columns are numeric

### `SKILL_SAMPLE_MISMATCH`

Meaning:
Sample names in the group file do not overlap the ESTIMATE score table.

Common causes:

- the group file uses different sample IDs from the expression matrix
- whitespace or formatting differences between the two files

Resolution:

- align the sample IDs between the expression matrix and the group file
- confirm that `--sample_column` points to the correct column in the group file

Partial-output note:

- if the mismatch is detected after the ESTIMATE score table has already been created, you may still see partial core outputs such as `data/estimate_score.gct`, `table/estimate_scores.tsv`, `plot/estimate_scores_heatmap.pdf`, `output_manifest.txt`, and `run_record.txt`
- grouped comparison outputs such as `estimate_score_group_stats.csv` and `estimate_scores_boxplot.pdf` should not be present for this failure mode

### `SKILL_PACKAGE_NOT_FOUND`

Meaning:
One or more required R packages are not installed.

Common causes:

- `estimate` or `optparse` is missing from the container

Resolution:

- install the missing packages before rerunning
- see `references/cli-guide.md` for dependency installation examples

Install hints:

- for CRAN packages such as `optparse`, `pheatmap`, `ggplot2`, `ggpubr`, `tidyr`, and `dplyr`, run `install.packages(...)`
- for the public Bioconductor package `estimate`, run `if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager")` followed by `BiocManager::install("estimate")`

### `SKILL_TIMEOUT`

Meaning:
The analysis exceeded the configured time limit.

Common causes:

- `--timeout_seconds` was set too low for the input matrix size
- the execution environment is under heavy resource pressure

Resolution:

- rerun with a larger `--timeout_seconds` value
- test the same input with `--timeout_seconds 0` to disable timeout temporarily
- verify that the environment has enough CPU and memory for the dataset size

## Practical Checks

1. Run `Rscript scripts/main.R --help`.
2. Confirm that `tests/data/expression_matrix.csv` can be opened.
3. If using group-wise plotting, confirm that `tests/data/group_info.csv` can be opened.
4. Confirm that the first column contains gene symbols.
5. Confirm that the `estimate` package is installed in the execution environment.
6. Confirm that `pheatmap` is installed for heatmap output.
7. If using `--group_file`, confirm that `ggplot2`, `ggpubr`, `tidyr`, and `dplyr` are installed.
8. If you enabled `--timeout_seconds`, confirm that the configured limit is realistic for the dataset size.
9. After a successful run, confirm that `output_manifest.txt` and `run_record.txt` were created.
