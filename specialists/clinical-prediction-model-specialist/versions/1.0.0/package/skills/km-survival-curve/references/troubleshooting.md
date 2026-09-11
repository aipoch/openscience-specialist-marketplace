# Troubleshooting Guide

## Common Errors

### SKILL_FILE_NOT_FOUND

**Error:**

```text
SKILL_FILE_NOT_FOUND: Input file not found: path/to/file.csv
```

**Solution:**

- Verify the file path is correct.
- Check file permissions.
- Use an absolute path if needed.

### SKILL_MISSING_COLUMNS

**Error:**

```text
SKILL_MISSING_COLUMNS: Missing required columns: futime, fustat, risk_group
```

**Solution:**

- Check the exact column names in your input file.
- Pass explicit names with `--time_col`, `--status_col`, and `--risk_col`.
- Confirm the header row is present and correctly delimited.

### SKILL_INVALID_DATA

**Error examples:**

```text
SKILL_INVALID_DATA: Time column 'futime' must be numeric
SKILL_INVALID_DATA: Status column 'fustat' must be coded as 0 or 1
SKILL_INVALID_DATA: Risk group column must contain at least 2 groups
```

**Solution:**

- Ensure time values are finite numeric values.
- Ensure status is coded as `0` for censored and `1` for event.
- Ensure at least 2 groups remain after filtering missing values.
- Check for empty strings or missing values in the risk group column.

### SKILL_INSUFFICIENT_DATA

**Error:**

```text
SKILL_INSUFFICIENT_DATA: Need at least 2 complete observations for survival analysis
```

**Solution:**

- Inspect missing values in the time, status, and group columns.
- Confirm the requested columns are correct.
- Use a dataset with more retained observations after filtering.

### SKILL_INVALID_PARAMETER

**Error examples:**

```text
SKILL_INVALID_PARAMETER: statistics_method must be one of: 'logrank', 'wald'
SKILL_INVALID_PARAMETER: time_unit must be one of: year, month, day
```

**Solution:**

- Use valid parameter values shown in the help message.
- For boolean arguments, use `true` or `false`.
- Ensure numeric size arguments are greater than 0.

### SKILL_DEPENDENCY_MISSING

**Error:**

```text
SKILL_DEPENDENCY_MISSING: survminer
```

**Solution:**

- Install required packages:

```r
install.packages(c("optparse", "data.table", "survival", "survminer", "ggplot2"))
```

- Confirm that `Rscript` is using the expected library path.

## Data Issues

### Too Few Samples in a Group

**Problem:**

The script logs a warning that some groups have fewer than 3 retained samples.

**Solution:**

- Check the input data and your group split.
- Inspect missing values in the required columns.
- Rebuild the group variable upstream if one group becomes too small.

### Time Values Look Different Than Expected

**Cause:**

If `--auto_convert_days true` and `max(time) > 365`, the script assumes the retained time values are in days and may convert them to years or months depending on `--time_unit`.

**Solution:**

- Use consistent time units in the source data.
- Only keep `--auto_convert_days true` when the source time column is known to be in days.
- Set `--auto_convert_days false` if the source data are already in years or months.
- Set `--time_unit day` to prevent automatic day-to-year or day-to-month conversion.
- Adjust `--title_x` so the displayed unit matches the requested output unit.
- Review the console log for the automatic conversion warning to confirm whether conversion was applied.

### Group Order in the Legend

**Cause:**

The script preserves `low`, `high` ordering when present, otherwise it sorts group labels alphabetically.

**Solution:**

- Standardize group labels before analysis if you need a specific legend order.
- If necessary, adjust `resolve_group_levels()` in `scripts/functions.R`.

## Output Issues

### No Output File Generated

**Cause:**

The analysis terminated before output creation.

**Solution:**

- Read the first error in the console output.
- Run `Rscript scripts/main.R --help` to review the expected arguments.
- Verify that the output directory is writable.
- On success, the directory should contain `km-plot.pdf` and `session_info.txt`.

### PDF Save Failure

**Cause:**

The PDF device could not write `km-plot.pdf`.

**Solution:**

- Check write permissions for the output directory.
- Confirm the requested font family is available on the system.

## Quick Validation Steps

```bash
Rscript scripts/main.R --help
```

```bash
Rscript scripts/main.R \
  --input_file tests/data/km_sample1.txt \
  --output_dir tests/check_output
```

Then verify:

```bash
ls tests/check_output
```

You should see `km-plot.pdf` and `session_info.txt`.
