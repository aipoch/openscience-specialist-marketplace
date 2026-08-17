# Troubleshooting

## `SKILL_FILE_NOT_FOUND`

Cause:

- The input matrix path does not exist.

Fix:

- Confirm the file path passed to `--input_file`.

## `SKILL_MISSING_COLUMNS`

Cause:

- The file does not contain one feature column plus at least one numeric data column.

Fix:

- Ensure the first column is the feature identifier and the remaining columns are samples.

## `SKILL_INVALID_PARAMETER`

Cause:

- Unsupported `--method`, `--margin`, `--delimiter`, or malformed boolean/numeric input.
- `log2` was requested with non-positive `x + pseudo_count`.
- The matrix contains non-finite values such as `Inf` or `-Inf`.

Fix:

- Recheck the CLI arguments.
- Increase `--pseudo_count` if your matrix contains zeros or negative values and you still want to use `log2`.

## `SKILL_TIMEOUT`

Cause:

- The workflow exceeded the elapsed or CPU time limit set by `--timeout_seconds`.

Fix:

- Increase `--timeout_seconds`.
- Re-run with a smaller matrix if the timeout is intended as a guardrail.

## `SKILL_EMPTY_DATA`

Cause:

- The file has no data rows, or no usable numeric sample columns remain after parsing.

Fix:

- Inspect the input file for blank rows, malformed numeric columns, or an input table that only contains the feature column.

## Output Overwrite Behavior

Cause:

- The selected `--output_dir` already contains files from a previous run.

Fix:

- Use a fresh output directory if you want to preserve earlier results.
- Keep `--verbose=true` to receive a warning before writing into a non-empty output directory.
