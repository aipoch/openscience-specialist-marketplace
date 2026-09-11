# Troubleshooting — Sample Group Sankey Plot

## SKILL_DEPENDENCY_MISSING

**Symptom:** Script exits with `SKILL_DEPENDENCY_MISSING: Missing required packages: ggplot2, ggalluvial`.

**Fix:** Run the dependency installer:
```bash
Rscript scripts/install_dependencies.R
```
If installation fails due to network or permission issues, install manually:
```r
install.packages(c("ggplot2", "ggalluvial", "optparse"))
```

---

## SKILL_FILE_NOT_FOUND

**Symptom:** `SKILL_FILE_NOT_FOUND: /path/to/file.csv`

**Fix:** Verify the path supplied to `--input_file`. Use an absolute path to avoid working-directory ambiguity.

---

## SKILL_EMPTY_DATA

**Symptom:** `SKILL_EMPTY_DATA: Input table has no data rows` or `SKILL_EMPTY_DATA: Input file is empty`

**Fix:** Confirm the input file has at least one data row (not just a header). If the file is non-empty but reported empty, check that the separator is correct (`.tsv`/`.txt` extensions are auto-detected as tab-separated; `.csv` as comma-separated).

---

## SKILL_MISSING_COLUMNS

**Symptom:** `SKILL_MISSING_COLUMNS: columnA, columnB`

**Fix:** The listed column names do not match the file header. Check for typos, extra spaces, or case differences. The `--columns` argument is case-sensitive.

---

## SKILL_INVALID_PARAMETER

**Symptom:** Various — e.g. `--alpha must be between 0 and 1` or `--output_prefix may only contain letters, numbers, dot, underscore, and hyphen`.

**Fix:** Review the Arguments table in SKILL.md and supply a valid value.

---

## SKILL_IO_ERROR

**Symptom:** `SKILL_IO_ERROR: Failed to create output directory` or `Output directory is not writable`.

**Fix:** Check that the parent directory of `--output_dir` exists and that the current user has write permission.

---

## Plot is hard to read / strata overlap

**Cause:** Too many stages or too many unique values per stage.

**Fix:**
- Reduce the number of stages passed to `--columns` (recommended: fewer than 5).
- Aggregate or bin stage values to fewer than 8 unique values per stage before plotting.
- Increase `--width` and `--height` for larger canvases.
- Reduce `--label_size` if labels overlap.

---

## PDF is blank or missing

**Cause:** `ggplot2::ggsave()` failed silently, or the output directory was not writable.

**Fix:** Check stderr output for `SKILL_IO_ERROR`. Verify `--output_dir` is writable and that sufficient disk space is available.
