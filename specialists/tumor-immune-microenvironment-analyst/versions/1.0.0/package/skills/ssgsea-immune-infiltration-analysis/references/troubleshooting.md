# Troubleshooting

## Error Codes

### `SKILL_FILE_NOT_FOUND`

Cause:
An input file path does not exist.

Fix:
Confirm `--input_file`, `--group_file`, and `--gene_set`.

### `SKILL_MISSING_COLUMNS`

Cause:
The group file or gene-set file does not contain required columns.

Fix:
- Group file: provide sample and group columns.
- Gene-set file: provide `gene` and `cell_type`.

### `SKILL_EMPTY_DATA`

Cause:
The run has no usable gene sets, no valid sample-group pairs, or no retained genes after filtering.

Fix:
- Check whether gene IDs match between the expression matrix and the gene-set file.
- Reduce `--min_sz` if the overlap is too strict.
- Remove empty rows or malformed records.

### `SKILL_INVALID_PARAMETER`

Cause:
An unsupported CLI value was supplied, or the expression matrix contains non-numeric values.

Fix:
- Confirm `--method`, `--kcdf`, and `--gene_id_case`.
- For this release, use validated kernels only: `Gaussian` or `Poisson`.
- Confirm `--min_sz >= 1`, `--max_sz >= --min_sz`, `--parallel_sz >= 1`, and `--tau >= 0`.
- Check for duplicated IDs and non-numeric expression values.

### `SKILL_SAMPLE_MISMATCH`

Cause:
Sample names in the expression matrix do not match the group file after alignment.

Fix:
- Harmonize sample names exactly.
- Use `--sample_col` and `--group_col` if column auto-detection is wrong.

### `SKILL_PACKAGE_NOT_FOUND`

Cause:
One or more R packages are unavailable.

Fix:
- Install the required packages before running the skill.
- Use the `DESCRIPTION` file as the authoritative dependency list.
- Install `GSVA` via `BiocManager::install("GSVA")` because it is a Bioconductor package.

### `SKILL_TIMEOUT`

Cause:
The run exceeded the CPU or elapsed time configured by `--timeout_seconds`.

Fix:
- Increase `--timeout_seconds` for larger datasets.
- Use `--timeout_seconds 0` to disable the limit when running interactively.

## Plotting Note

The correlation heatmap is rendered by opening the target PDF device first, drawing the precomputed `pheatmap(..., silent = TRUE)` object on that device, and closing the device last. Do not call `dev.off()` before `grid.draw()`, or R may create an unintended `Rplots.pdf` and damage the intended output file.
