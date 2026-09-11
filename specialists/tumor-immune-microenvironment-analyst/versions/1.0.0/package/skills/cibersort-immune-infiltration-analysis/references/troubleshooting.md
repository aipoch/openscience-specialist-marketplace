# Troubleshooting Guide

## Error Codes

### SKILL_FILE_NOT_FOUND

Typical causes:

- `--input_file` does not exist
- `--group_file` does not exist
- `--signature_file` points to a missing file

Fix:

- Verify the path and rerun
- If using the packaged test path, confirm that `tests/data/LM22.txt` exists

### SKILL_MISSING_COLUMNS

Typical causes:

- The group file has no supported sample column
- The group file has no supported group column
- The expression matrix or signature matrix does not contain one gene column plus value columns

Fix:

- Use sample columns such as `sample`, `sample_name`, `sample_id`, or `id`
- Use group columns such as `group`, `condition`, `class`, or `cluster`

### SKILL_EMPTY_DATA

Typical causes:

- All genes were removed by `--min_mean_expression`
- No genes overlap between the expression matrix and `LM22`
- A zero-variance vector was encountered during scaling

Fix:

- Lower `--min_mean_expression`
- Check whether gene identifiers match between the expression matrix and signature matrix
- Review `--gene_id_case`

### SKILL_INVALID_PARAMETER

Typical causes:

- A required CLI argument is missing
- `--perm`, `--svm_cores`, `--timeout_seconds`, or another option has an invalid value
- Boolean arguments such as `--qn`, `--auto_unlog`, or `--make_plots` use unsupported text
- The signature matrix contains non-numeric, `NA`, `NaN`, or `Inf` values in immune-cell columns

Fix:

- Review `SKILL.md` and rerun with valid values
- Use `true` or `false` for boolean flags
- Clean the signature matrix so every immune-cell column is fully numeric before rerunning

### SKILL_SAMPLE_MISMATCH

Typical causes:

- Sample names in the group file do not match the expression matrix columns
- One of the requested groups disappears after sample alignment

Fix:

- Harmonize sample identifiers before rerunning
- Confirm that both case and control groups still have matched samples

### SKILL_PACKAGE_NOT_FOUND

Typical causes:

- `preprocessCore`, `e1071`, `ggplot2`, or `pheatmap` is not installed

Fix:

- Install the missing package in the runtime container
- Re-run `Rscript scripts/main.R --help` after installation to confirm the CLI loads cleanly

### SKILL_TIMEOUT

Typical causes:

- `--timeout_seconds` is too small for the chosen matrix size and permutation count

Fix:

- Increase `--timeout_seconds`
- Lower `--perm`
- Set `--timeout_seconds 0` to disable the timeout

## Runtime Notes

### `pthread_create()` Error Or Thread Creation Failure

Typical causes:

- The container restricts OpenMP, OpenBLAS, MKL, or other low-level worker threads
- `preprocessCore::normalize.quantiles()` triggers an environment-level threading failure

Fix:

- This skill forces common BLAS/OpenMP thread environment variables to `1` inside `scripts/main.R`
- If the container still fails, use `--qn false`
- If quantile normalization is required, inspect whether `preprocessCore` must be rebuilt without threading support in that environment

Reference notes:

- Similar failures have been reported around `preprocessCore::normalize.quantiles()` in Bioconductor container environments
- This pattern indicates an environment-level threading issue rather than malformed input files

### Repeated `purrr` Or Package-Attach Messages

Typical cause:

- The runtime or one of its dependencies loads packages that print startup messages

Fix:

- The skill suppresses common package startup messages around the core deconvolution call
- If a small number of non-error messages still appear, treat them as cosmetic unless the command exits with status `1`

### Heatmap Uses `0` Where Correlation Is Non-Finite

Typical cause:

- The correlation matrix contains `NA`, `NaN`, or `Inf`, and `pheatmap` cannot cluster such values directly

Fix:

- The plotting helper now replaces non-finite correlation entries with `0` for visualization only
- Use `table/immune_cell_correlation_matrix.csv` as the authoritative result table rather than the rendered heatmap if you need to inspect raw values

### `--auto_unlog` Did Not Trigger

Typical cause:

- The expression matrix did not pass the conservative log-scale heuristic

Fix:

- Read the startup log to see the reported summary statistics
- If the matrix is already on a linear scale, keep `--auto_unlog false`
- If the matrix is known to be log-scaled but falls outside the heuristic, transform it explicitly before running the skill

### `--perm 0` Produced `NA` P-values

Typical cause:

- The run intentionally skipped permutation testing by setting `--perm 0`

Fix:

- This is expected behavior; the startup log and `run_record.txt` now state that empirical `P-value` estimation is disabled
- Use `--perm >= 1` when you need empirical `P-value` output

### Failed Rerun Did Not Replace Existing Outputs

Typical cause:

- The rerun hit a validation or execution error before the staged payload was promoted into the target `--output_dir`

Fix:

- Inspect the appended failure block in `run_record.txt`
- Inspect the appended failed-run entry in `output_manifest.txt`
- Correct the error and rerun; the prior successful payload is preserved until a new successful run completes
