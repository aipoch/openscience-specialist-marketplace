---
name: pca-dimensionality-reduction
description: Use when performing PCA principal component dimensionality reduction on tabular numeric data. Supports command-line parameter input, automatic numeric feature selection, parameter validation, result directory creation, and CSV or TXT format result export.
license: MIT
author: AIPOCH
---
> **Source**: [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills)

# PCA Dimensionality Reduction Analysis

Use this skill to run principal component analysis on a tabular dataset and export explained variance, sample scores, feature loadings, and diagnostic figures.

## Use This Skill When

- You need to reduce multiple numeric variables into a smaller set of principal components.
- You need a command-line PCA workflow with parameter validation.
- You need standardized output files for downstream analysis.

## Primary Command

```bash
Rscript scripts/main.R \
  --data_file <input_file> \
  --output_dir <output_dir> \
  --feature_columns <comma_separated_numeric_columns>
```

## Prerequisites

- `Rscript` is available in the shell.
- Required R packages: `optparse`, `data.table`.
- Install missing packages with `Rscript -e 'install.packages(c("optparse", "data.table"), repos="https://cloud.r-project.org")'`.

## Core Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `--data_file` | Yes | Input data file in CSV, TXT, or TSV format |
| `--output_dir` | No | Output directory, default `./PCA_Results` |
| `--feature_columns` | No | Comma-separated numeric feature columns. Default uses all numeric columns except ID/group columns |
| `--sample_id_column` | No | Optional sample ID column. If omitted and the first column is non-numeric with unique values, it is used automatically |
| `--group_column` | No | Optional grouping column to carry into score output and score plot |
| `--n_components` | No | Maximum number of principal components to export, default `5` |
| `--center_data` | No | `true` or `false`, default `true` |
| `--scale_data` | No | `true` or `false`, default `true` |
| `--top_loadings` | No | Number of top absolute loadings to export per component, default `10` |
| `--output_format` | No | `csv` or `txt`, default `csv` |
| `--output_prefix` | No | Output filename prefix, default `pca` |

## Input Requirements

- The input file must contain at least 2 usable numeric feature columns.
- PCA is run on rows as samples and columns as features.
- Missing or non-finite values in selected feature columns are removed row-wise before analysis.
- At least 2 complete samples must remain after filtering.
- Selected feature columns must have non-zero variance after filtering.

Example input:

```csv
SampleID,Group,GeneA,GeneB,GeneC,GeneD
S01,Control,2.1,1.9,8.2,4.3
S02,Control,2.4,2.2,8.0,4.6
S03,Treated,6.1,5.7,2.8,8.1
```

## Minimal Workflow

1. Confirm the input file exists and identify the numeric feature columns for PCA.
2. Run `scripts/main.R` with the requested output directory and optional feature, ID, or group columns.
3. Check the output directory for result files under `table/`, `data/`, and `figure/`.

If you omit `--data_file`, the script exits with `SKILL_MISSING_INPUT`.

## Outputs

Expected output structure:

```text
<output_dir>/
├── table/
├── figure/
└── data/
```

Primary result files:

- `table/<output_prefix>_summary.csv`
- `table/<output_prefix>_scores.csv`
- `table/<output_prefix>_loadings.csv`
- `table/<output_prefix>_top_loadings.csv`

Figure files:

- `figure/<output_prefix>_scree_plot.png`
- `figure/<output_prefix>_score_plot.png`

Key fields include:

- `component`
- `standard_deviation`
- `variance`
- `proportion_variance`
- `cumulative_variance`
- `sample_id`
- `feature`
- `loading`

## Interpretation Guide

- Use `proportion_variance` and `cumulative_variance` to decide how many components to retain.
- Use the score table to inspect sample separation in PC space.
- Use the loading tables to identify which original variables drive each component.

## Read These Files When Needed

| Need | File |
|------|------|
| PCA method details and interpretation | `references/algorithm.md` |
| More CLI examples | `references/cli-guide.md` |
| Error diagnosis | `references/troubleshooting.md` |
| Main execution entry point | `scripts/main.R` |
| Sample test data | `tests/data/` |

## Quick Examples

Basic PCA with explicit feature columns:

```bash
Rscript scripts/main.R \
  --data_file tests/data/sample_pca_1.csv \
  --sample_id_column SampleID \
  --group_column Group \
  --feature_columns GeneA,GeneB,GeneC,GeneD,GeneE \
  --output_dir tests/output_basic
```

Auto-detect all numeric columns:

```bash
Rscript scripts/main.R \
  --data_file tests/data/sample_pca_2.csv \
  --n_components 3 \
  --output_dir tests/output_numeric_only
```

Disable scaling:

```bash
Rscript scripts/main.R \
  --data_file tests/data/sample_pca_1.csv \
  --sample_id_column SampleID \
  --group_column Group \
  --scale_data false \
  --output_dir tests/output_unscaled
```

## Validation

```bash
Rscript scripts/main.R --help
```

```bash
Rscript scripts/main.R \
  --data_file tests/data/sample_pca_1.csv \
  --sample_id_column SampleID \
  --group_column Group \
  --feature_columns GeneA,GeneB,GeneC,GeneD,GeneE \
  --output_dir tests/validation_output
```

After running analysis, verify that `tests/validation_output/table/pca_summary.csv` exists.

## Common Errors

- `SKILL_FILE_NOT_FOUND`: Input file path is wrong or inaccessible.
- `SKILL_MISSING_COLUMNS`: A requested feature, sample ID, or group column is missing.
- `SKILL_INVALID_DATA`: Input data is malformed or unsuitable for PCA.
- `SKILL_INVALID_PARAMETER`: An argument value is invalid.
- `SKILL_INSUFFICIENT_DATA`: Too few complete samples or features remain for PCA.
- `SKILL_DEPENDENCY_MISSING`: A required R package such as `optparse` or `data.table` is unavailable.

If the issue is not obvious, read `references/troubleshooting.md`.
