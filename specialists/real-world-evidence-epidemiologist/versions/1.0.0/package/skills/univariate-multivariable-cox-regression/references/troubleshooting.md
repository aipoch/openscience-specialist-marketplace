# Troubleshooting Guide

## Common `SKILL_*` Errors

### SKILL_INVALID_PARAMETER

**Typical messages**
```text
SKILL_INVALID_PARAMETER: --features must contain at least one feature name
SKILL_INVALID_PARAMETER: --timeout_seconds must be a non-negative number
SKILL_INVALID_PARAMETER: --data_file must use one of: xlsx, xls, csv
SKILL_INVALID_PARAMETER: Unknown command: cox-plot
SKILL_INVALID_PARAMETER: --data_file must be a readable clinical CSV: ...
SKILL_INVALID_PARAMETER: --data_file time values must be finite numbers greater than 0
SKILL_INVALID_PARAMETER: --data_file event values must use 0/1 encoding
SKILL_INVALID_PARAMETER: --data_file must contain at least 10 complete samples for Cox analysis
SKILL_INVALID_PARAMETER: --data_file must contain at least 2 events for Cox regression
SKILL_INVALID_PARAMETER: Cox model fitting failed for stage : ...
SKILL_INVALID_PARAMETER: Multivariable Cox model fitting failed: ...
```

**How to fix**
- Check that required CLI values were provided.
- Use valid file extensions.
- Use a supported subcommand: `analyze`, `forest-plot`, or `multi-forest-plot`.
- Make sure `--data_file` is a valid clinical CSV that can be parsed successfully.
- Ensure survival time values are numeric and positive.
- Encode the event column as `0` and `1` only.
- Provide at least 10 complete samples and at least 2 events.
- Collapse sparse factor levels or reduce unstable predictors if Cox fitting fails.
- Ensure numeric parameters such as `--width`, `--height`, `--font_size`, and `--timeout_seconds` are valid.
- Use `true` or `false` for `--skip_univariate`.

### SKILL_FILE_NOT_FOUND

**Typical message**
```text
SKILL_FILE_NOT_FOUND: --data_file does not exist: path/to/file.csv
```

**How to fix**
- Verify the file path.
- Use an absolute path if the working directory is uncertain.
- Confirm the file exists before running the command.

### SKILL_MISSING_COLUMNS

**Typical messages**
```text
SKILL_MISSING_COLUMNS: Clinical data is missing columns: futime, fustat
SKILL_MISSING_COLUMNS: Plot input is missing columns: HR (95% CI)
```

**How to fix**
- Check the column names in the clinical CSV.
- Ensure the plot command is reading the table produced by this skill.
- Avoid renaming or removing required columns from the result table.

### SKILL_EMPTY_DATA

**Typical messages**
```text
SKILL_EMPTY_DATA: Clinical data file is empty
SKILL_EMPTY_DATA: Plot input file contains no result rows
```

**How to fix**
- Confirm the file contains a header and data rows.
- Re-run `analyze` before generating a forest plot.
- Check that upstream filtering did not create an empty file.

### SKILL_PACKAGE_NOT_FOUND

**Typical message**
```text
SKILL_PACKAGE_NOT_FOUND: Required packages are not installed: survival, openxlsx
```

**How to fix**
- Install the missing CRAN packages.
- For plotting from Excel input, also install `readxl`.
- For PDF forest plots, install `forestplot`.

---

## Data Quality Checks

### Missing Clinical Values

Rows with missing values across requested features, time, or event columns are removed before modeling.

**Recommendation**
- Review missingness before running the analysis.
- Keep a record of how many rows were excluded.

### Factor Level Problems

Very small or perfectly separated factor levels can destabilize Cox fitting.

**Recommendation**
- Combine sparse levels.
- Remove clinically irrelevant categories with extremely low counts.

### No Significant Univariate Features

This is not an error in this skill.

**Current behavior**
- If fewer than 3 univariate features have `p < 0.05`, the multivariable model falls back to all requested features.
- If no complete rows remain after filtering requested columns, the skill raises `SKILL_EMPTY_DATA`.

---

## Plotting Issues

### Forest Plot Looks Blank or Missing

**Checks**
- Confirm the table contains non-empty `HR (95% CI)` values.
- Confirm `plot_save` points to a writable directory.
- Re-run the plot command on the fresh analysis output.

### Plot Command Fails On CSV/XLSX Input

**Checks**
- Use only `.csv`, `.xls`, or `.xlsx` files.
- If using Excel input, ensure `readxl` is installed.

---

## Recommended Validation Commands

```bash
Rscript scripts/main.R --help

Rscript scripts/main.R analyze \
  -d tests/data/sample_clinical_survival_data.csv \
  -o tests/expected_output/ \
  --overwrite

Rscript scripts/main.R forest-plot \
  -d tests/expected_output/table/prognosis_uni_cox_results.xlsx \
  -p tests/expected_output/plot/uni_forest_plot.pdf

Rscript scripts/main.R multi-forest-plot \
  -d tests/expected_output/table/prognosis_multi_cox_results.xlsx \
  -p tests/expected_output/plot/multi_forest_plot.pdf
```

If the problem persists, capture the full console log together with `session_info.txt`.
