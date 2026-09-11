# Troubleshooting

## Error Codes

| Error Code | Meaning | Common Trigger | Resolution |
|------------|---------|----------------|------------|
| `SKILL_FILE_NOT_FOUND` | A required input file or saved result file is missing | Wrong `input_file`, `group_file`, `geneset_file`, or visualize-mode result path | Check the path, file name, and working directory |
| `SKILL_MISSING_COLUMNS` | The group file or gene-set table lacks required columns | Header names do not match the accepted column list | Rename the columns to supported names such as `sample`, `group`, `gs_name`, and `gene_symbol` |
| `SKILL_EMPTY_DATA` | The matrix, gene-set table, gene overlap, or plotting matrix is empty | Empty input, no gene overlap, or all pathways filtered out | Verify the matrix content and that gene identifiers match the gene-set table |
| `SKILL_INVALID_PARAMETER` | A CLI argument is missing, unsafe, or outside the accepted range | Invalid `mode`, bad thresholds, output path outside the skill folder, or path separators in `plot_file` | Review `SKILL.md`, correct the value, and rerun |
| `SKILL_SAMPLE_MISMATCH` | Sample names do not match between the matrix and group file | Matrix columns are absent from the group file | Align the sample names before rerunning |
| `SKILL_PACKAGE_NOT_FOUND` | Required R packages are unavailable | `GSVA`, `limma`, `optparse`, `pheatmap`, or `grid` are not installed | Install the dependencies listed in `references/cli-guide.md` |
| `SKILL_VERSION_INCOMPATIBLE` | Installed packages match a known incompatible version combination | `GSVA 1.42.0` is paired with a newer `matrixStats` such as `1.5.0` | Pin `matrixStats` to `1.1.0` in the validated environment and rerun |

## Known Version Compatibility

The validated container uses:

- `R 4.1.2`
- `GSVA 1.42.0`
- `matrixStats 1.1.0`
- `Matrix 1.5.1`

Known issue:

- `GSVA 1.42.0` can fail with an error mentioning `useNames` when `matrixStats` is upgraded to newer releases such as `1.5.0`.

Recommended fix in the validated `R 4.1.x` environment:

```r
install.packages("remotes")
remotes::install_version("matrixStats", version = "1.1.0")
```

Then verify:

```r
packageVersion("GSVA")
packageVersion("matrixStats")
packageVersion("Matrix")
R.version.string
```

## Common Situations

### `SKILL_FILE_NOT_FOUND`

Symptoms:

- The run stops immediately before scoring
- Visualize mode cannot locate the saved result object

Checks:

- Confirm the file exists
- Confirm the working directory is the skill root or use absolute paths
- In visualize mode, confirm `data/immune_pathway_result.rds` is present in the selected `output_dir`
- Confirm the gene-set CSV was exported locally and not left in a temporary download path

### `SKILL_MISSING_COLUMNS`

The group file must contain one supported sample column and one supported group column.

Supported sample columns:

- `sample`
- `sample_name`
- `sample_id`
- `sampleid`

Supported group columns:

- `group`
- `condition`
- `class`
- `cluster`

The gene-set table must contain:

- One pathway column, by default `gs_name`
- One gene column, by default `gene_symbol`

### `SKILL_EMPTY_DATA`

This error usually means one of the following:

- The expression matrix has too few rows or columns
- The matrix contains only missing or non-numeric values
- The gene-set table becomes empty after trimming invalid rows
- The expression matrix and gene-set table share too few genes
- The heatmap subset contains no rows

Resolution steps:

- Confirm the first column contains gene identifiers
- Remove empty rows and non-numeric expression columns
- Check that the gene symbols in the expression matrix and gene-set table use the same naming scheme
- Confirm that `--geneset_column` and `--gene_column` point to the actual pathway and gene columns when using a non-default schema
- Reduce `min_sz` if your input is small

### No Significant Pathways At The Selected FDR

This is not an execution failure by itself.

Observed behavior:

- The skill logs a warning when no pathways pass the selected `fdr_threshold`
- `immune_pathway_scores_top.csv` can still be generated
- The fallback ranking uses absolute pathway test statistics (`|t|`) so the downstream heatmap and top-score table remain usable

What to do next:

- Inspect `table/immune_pathway_diff.csv` to confirm the magnitude and direction of pathway changes
- Consider using a less stringent `--fdr_threshold` for exploratory work
- Reduce the plotted subset with `--top_up`, `--top_down`, or `--focus_genesets` if the fallback heatmap is too broad

### `SKILL_INVALID_PARAMETER`

Typical causes:

- Missing `case_group` or `control_group`
- Unsupported `mode`, `method`, `kcdf`, `scale`, or `top_mode`
- `fdr_threshold` outside `[0, 1]`
- `top_n < 1`
- `output_dir` resolves outside the skill directory
- `plot_file` contains path separators or an empty base name

### `SKILL_SAMPLE_MISMATCH`

The expression matrix columns must match the sample names in the group file.

Recommendations:

- Export sample names exactly once and reuse them
- Avoid hidden spaces in CSV headers and cells
- Check for duplicated sample names before running the skill

### `SKILL_PACKAGE_NOT_FOUND`

Install missing packages with the commands in `references/cli-guide.md`.

### `SKILL_VERSION_INCOMPATIBLE`

This skill checks for the validated incompatibility between `GSVA 1.42.0` and newer `matrixStats` releases.

Resolution:

1. Check `packageVersion("GSVA")` and `packageVersion("matrixStats")`.
2. If the pair is `GSVA 1.42.0` and `matrixStats >= 1.2.0`, downgrade `matrixStats` to `1.1.0`.
3. Re-run `Rscript tests/run_tests.R` after the downgrade.

### `useNames` Error During GSVA

Typical message:

- `Argument 'useNames' must be either TRUE or FALSE`

Interpretation:

- This usually indicates an environment-level compatibility problem between `GSVA 1.42.0` and a newer `matrixStats` version, not a problem in the expression matrix itself.

Resolution:

1. Check package versions with `packageVersion("GSVA")` and `packageVersion("matrixStats")`.
2. If `GSVA == 1.42.0` and `matrixStats >= 1.2.0`, downgrade `matrixStats` to `1.1.0`.
3. Re-run `Rscript tests/run_tests.R` after the downgrade.

## Logging And Exit Codes

- Log messages use the format `[LEVEL] YYYY-MM-DD HH:MM:SS | message`
- Success exits with status `0`
- Failure exits with status `1`
- Detailed provenance is recorded in `run_record.txt` and `output_manifest.txt`
