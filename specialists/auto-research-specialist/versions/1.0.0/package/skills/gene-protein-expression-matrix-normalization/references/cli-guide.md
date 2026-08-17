# CLI Guide

## Dependencies

Dependency declarations are listed in `DESCRIPTION`.

Install runtime packages with:

```r
install.packages("optparse")
```

## CLI Examples

### Example 1: Default log2 transform

```bash
Rscript scripts/main.R \
  --input_file ./expression_matrix.csv \
  --output_dir ./output \
  --method log2
```

### Example 2: Sample-wise z-score normalization

```bash
Rscript scripts/main.R \
  --input_file ./expression_matrix.csv \
  --output_dir ./output \
  --method zscore \
  --margin column
```

### Example 3: Feature-wise min-max scaling

```bash
Rscript scripts/main.R \
  --input_file ./expression_matrix.csv \
  --output_dir ./output \
  --method minmax \
  --margin row
```

## Output Directory Behavior

- If `--output_dir` already exists, files with the same names are overwritten.
- With `--verbose=true`, the script prints a warning before writing into a non-empty output directory.

## Baseline Real-Data Execution Record

This skill currently ships with a bundled real expression matrix derived from the GEO `GSE150613` supplementary dataset and uses it as the baseline validation input.

### Input Files

- `tests/data/expression_matrix.csv`

### Input Summary

- 18947 features
- 6 samples
- Sample columns: `MCSF_1`, `MUC1_ST_1`, `MCSF_2`, `MUC1_ST_2`, `MCSF_3`, `MUC1_ST_3`
- Finite numeric expression values suitable for `log2`, `zscore`, and `minmax` normalization

### Baseline Command

```bash
Rscript scripts/main.R \
  --input_file tests/data/expression_matrix.csv \
  --output_dir tests/output/log2 \
  --method log2 \
  --pseudo_count 1 \
  --seed 42
```

### Output Files

- `table/normalized_matrix.csv`
- `table/feature_summary.csv`
- `table/sample_summary.csv`
- `data/normalized_matrix.rds`
- `run_record.txt`
- `output_manifest.txt`
- `session_info.txt`

The validated baseline run currently writes these files under `tests/output/log2/`.

### Validation Commands

```bash
Rscript tests/run_tests.R

Rscript tests/run_tests.R audit_output_check

Rscript tests/test_skill.R

Rscript tests/test_skill.R audit_output_check --skip-prepare
```

Run these commands in this order when you want `tests/test_skill.R` to validate outputs that were just produced by `tests/run_tests.R`.

If you provide a relative output directory name, both test scripts resolve it under `tests/output/`.
