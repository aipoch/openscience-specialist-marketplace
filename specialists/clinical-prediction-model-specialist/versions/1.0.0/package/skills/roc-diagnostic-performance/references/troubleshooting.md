# Troubleshooting Guide

## Common `SKILL_*` Errors

### SKILL_INVALID_PARAMETER

**Typical messages**
```text
SKILL_INVALID_PARAMETER: --marker_genes must contain at least one gene name
SKILL_INVALID_PARAMETER: --legend_position must be one of bottomright, bottomleft, topright, topleft, right, left, top, bottom, center
SKILL_INVALID_PARAMETER: --case_group was not found in group column: group
SKILL_INVALID_PARAMETER: At least 2 case samples and 2 control samples are required
SKILL_INVALID_PARAMETER: Failed to fit logistic regression model: ...
```

**How to fix**
- Confirm all required arguments were provided.
- Use valid values for `--show_diagonal`, `--legend_position`, and numeric plot parameters.
- Check that the selected case label appears in the chosen group column.
- Confirm the matched cohort includes at least 2 case samples and 2 control samples.
- Reduce unstable markers if logistic regression fails because of separation or sparse classes.
- Check that the output directory is writable.

### SKILL_FILE_NOT_FOUND

**Typical message**
```text
SKILL_FILE_NOT_FOUND: --expression_file does not exist: path/to/file.csv
```

**How to fix**
- Verify the file path.
- Use an absolute path if the working directory is uncertain.

### SKILL_EMPTY_DATA

**Typical message**
```text
SKILL_EMPTY_DATA: --group_file contains no usable rows or columns
SKILL_EMPTY_DATA: No requested marker genes remained after filtering the expression matrix
```

**How to fix**
- Make sure the file contains a header row and data rows.
- Confirm the delimiter matches the file extension.
- Ensure at least one requested marker gene exists in the expression matrix.

### SKILL_MISSING_COLUMNS

**Typical message**
```text
SKILL_MISSING_COLUMNS: --group_col not found in group file: diagnosis
```

**How to fix**
- Check the exact header name in the group file.
- Omit `--group_col` to use auto-detection if only one label column is present.

### SKILL_SAMPLE_MISMATCH

**Typical message**
```text
SKILL_SAMPLE_MISMATCH: Expression matrix and group file do not share any sample IDs
```

**How to fix**
- Ensure the first column of the group file contains the same sample IDs used by the expression matrix.
- Remove extra whitespace or formatting differences before rerunning.

### SKILL_PACKAGE_NOT_FOUND

**Typical message**
```text
SKILL_PACKAGE_NOT_FOUND: Required packages are not installed: pROC
```

**How to fix**
- Install missing CRAN packages such as `optparse` and `pROC`.

---

## Recommended Validation Commands

```bash
Rscript scripts/main.R --help

Rscript scripts/main.R \
  -e tests/data/sample_expression_matrix.csv \
  -g tests/data/sample_group_info.csv \
  -m FOXP3,CD45,CD3E \
  -c Disease \
  -o tests/expected_output/ \
  --overwrite

Rscript tests/run_smoke_test.R
```

If the problem persists, capture the full console log together with `session_info.txt`.
