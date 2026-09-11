# Troubleshooting Guide

## Common Errors

### SKILL_FILE_NOT_FOUND

**Error:**

```text
SKILL_FILE_NOT_FOUND: Data file not found: path/to/file.csv
```

**Solution:**

- Verify the path is correct.
- Check file permissions.
- Prefer absolute paths if the working directory is unclear.

### SKILL_MISSING_COLUMNS

**Error:**

```text
SKILL_MISSING_COLUMNS: Missing required columns: futime, fustat
SKILL_MISSING_COLUMNS: Marker column not found in data: risk_score
```

**Solution:**

- Confirm that `futime` and `fustat` exist in the header row.
- If using `--marker_col`, make sure the name matches exactly.
- Run with a CSV header you can inspect directly.

### SKILL_INVALID_DATA

**Error:**

```text
SKILL_INVALID_DATA: Marker column 'risk_score' could not be parsed as numeric
SKILL_INVALID_DATA: Marker column 'risk_score' must contain at least 2 distinct values
SKILL_INVALID_DATA: Unusable AUC values were produced for time point(s): 100
```

**Solution:**

- Ensure the marker contains numeric values.
- Remove text labels or symbols from marker cells.
- Ensure the marker is not constant.
- If AUC values are unusable at later times, retry with earlier time points that are better supported by follow-up.

### SKILL_INSUFFICIENT_DATA

**Error:**

```text
SKILL_INSUFFICIENT_DATA: Need at least 5 complete rows, found: 3
SKILL_INSUFFICIENT_DATA: No events found for cause = 1
```

**Solution:**

- Check how many complete rows remain after removing missing values.
- Confirm that `fustat` uses the requested event code.
- Use time points supported by your follow-up range.

### SKILL_INVALID_PARAMETER

**Error:**

```text
SKILL_INVALID_PARAMETER: times must contain positive numeric values
SKILL_INVALID_PARAMETER: time_unit must be one of: year, month, day
SKILL_INVALID_PARAMETER: weighting must be one of: aalen, marginal, cox
```

**Solution:**

- Check argument spelling and case.
- Ensure `--times` is a comma-separated numeric list such as `1,3,5`.
- Use `Rscript scripts/main.R --help` to review all options.

### SKILL_DEPENDENCY_MISSING

**Error:**

```text
SKILL_DEPENDENCY_MISSING: timeROC
```

**Solution:**

- Install required packages:

```r
install.packages(c("optparse", "timeROC", "survival", "ggplot2", "openxlsx"), repos = "https://cloud.r-project.org")
```

- Re-run the command after installation.

## Data Issues

### No Useful Marker Column Detected

**Cause:** the default `risk_score` column is missing, or the selected marker column is character-valued or cannot be parsed as numeric.

**Solution:**

- Confirm that `risk_score` exists when relying on the default marker.
- Provide `--marker_col` explicitly if you want to analyze a different marker column.
- Inspect whether the marker column contains commas, spaces, or non-numeric text.

### Unexpected Time Scaling

**Cause:** `--auto_convert_days TRUE` converted `futime` because values looked like days.

**Solution:**

- If your `futime` is already in years or months, disable auto conversion with `--auto_convert_days FALSE`.
- Align `--times` with the same unit used in the analysis.

### Few or Empty ROC Curves at Some Time Points

**Cause:** the requested time points are outside the practical follow-up range or too few subjects remain informative.

**Solution:**

- Try earlier time points.
- Check the follow-up distribution in `futime`.
- Ensure you have enough uncensored follow-up around each requested time.

## Output Issues

### Figure File Not Generated

**Cause:** analysis failed before plotting or `ggplot2` is missing.

**Solution:**

- Check the console error message first.
- Confirm that the output directory is writable.
- Confirm `ggplot2` is installed.

### Empty AUC or ROC Output Tables

**Cause:** the analysis did not produce valid ROC points or usable AUC values for the requested times.

**Solution:**

- Reduce the number of requested time points.
- Retry with earlier time points that fall within the observed follow-up range.
- Check whether event counts are too small.

## Validation Steps

```bash
Rscript scripts/main.R \
  --data_file tests/data/time_roc_sample1.txt \
  --times 1,3,5 \
  --output_dir ./test_output
```

Check that these files exist:

- `test_output/data/time_roc_points.csv`
- `test_output/table/time_roc_auc.csv`
- `test_output/figure/time_roc.pdf`
- `test_output/session_info.txt`

If problems persist, inspect `session_info.txt` in the output directory.
