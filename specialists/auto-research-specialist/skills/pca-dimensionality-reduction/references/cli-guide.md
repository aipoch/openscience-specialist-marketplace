# CLI Usage Guide

## Basic Syntax

```bash
Rscript scripts/main.R [OPTIONS]
```

## Core Arguments

| Argument | Description |
|----------|-------------|
| `-d FILE` or `--data_file FILE` | Input data file (CSV, TXT, TSV format). Required |
| `-f COLS` or `--feature_columns COLS` | Comma-separated numeric feature columns for PCA |
| `-s COL` or `--sample_id_column COL` | Optional sample ID column |
| `-g COL` or `--group_column COL` | Optional group column |

## Optional Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `-o DIR` | `./PCA_Results` | Output directory |
| `-n INT` | `5` | Maximum number of components to export |
| `-c BOOL` | `true` | Center variables before PCA |
| `-z BOOL` | `true` | Scale variables before PCA |
| `-t INT` | `10` | Top absolute loadings exported per component |
| `-m FORMAT` | `csv` | Output format: csv, txt |
| `-p PREFIX` | `pca` | Output file prefix |

## Complete Examples

### Example 1: Basic PCA with Explicit Features

```bash
Rscript scripts/main.R \
  --data_file tests/data/sample_pca_1.csv \
  --sample_id_column SampleID \
  --group_column Group \
  --feature_columns GeneA,GeneB,GeneC,GeneD,GeneE \
  --output_dir ./pca_results
```

### Example 2: Numeric-Only Table with Auto Feature Selection

```bash
Rscript scripts/main.R \
  --data_file tests/data/sample_pca_2.csv \
  --n_components 3 \
  --output_dir ./numeric_results
```

### Example 3: TXT Output

```bash
Rscript scripts/main.R \
  --data_file tests/data/sample_pca_1.csv \
  --sample_id_column SampleID \
  --group_column Group \
  --feature_columns GeneA,GeneB,GeneC,GeneD,GeneE \
  --output_format txt \
  --output_prefix study_pca \
  --output_dir ./txt_results
```

### Example 4: Disable Scaling

```bash
Rscript scripts/main.R \
  --data_file tests/data/sample_pca_1.csv \
  --sample_id_column SampleID \
  --group_column Group \
  --feature_columns GeneA,GeneB,GeneC,GeneD,GeneE \
  --scale_data false \
  --output_dir ./unscaled_results
```

### Example 5: Keep Fewer Components

```bash
Rscript scripts/main.R \
  --data_file tests/data/sample_pca_1.csv \
  --sample_id_column SampleID \
  --group_column Group \
  --feature_columns GeneA,GeneB,GeneC,GeneD,GeneE \
  --n_components 2 \
  --top_loadings 5 \
  --output_dir ./compact_results
```

## Test Dataset Examples

### Example 6: Built-In Data with Missing Values

```bash
Rscript scripts/main.R \
  --data_file tests/data/sample_pca_3.csv \
  --sample_id_column SampleID \
  --group_column Batch \
  --feature_columns Marker1,Marker2,Marker3,Marker4 \
  --output_dir ./missing_value_results
```

The script removes rows with missing values in the selected feature columns before PCA.

## Getting Help

```bash
Rscript scripts/main.R --help
```

## Output Directory Structure

```text
PCA_Results/
├── table/
│   ├── pca_summary.csv
│   ├── pca_scores.csv
│   ├── pca_loadings.csv
│   ├── pca_top_loadings.csv
│   └── pca_metadata.csv
├── figure/
│   ├── pca_scree_plot.png
│   └── pca_score_plot.png
└── data/
    └── pca_filtered_input.csv
```

## Common Usage Patterns

### Quick Run

```bash
Rscript scripts/main.R -d data.csv -f var1,var2,var3
```

### Preserve Metadata Columns

```bash
Rscript scripts/main.R \
  -d data.csv \
  -s SampleID \
  -g Condition \
  -f Gene1,Gene2,Gene3,Gene4
```

### Use All Numeric Columns Except Metadata

```bash
Rscript scripts/main.R \
  -d data.csv \
  -s SampleID \
  -g Group
```

## Tips

1. Use scaling when features have different units or ranges.
2. Inspect the scree plot before choosing the number of retained components.
3. Check the top loadings table to see which features drive each component.
4. If too many rows are removed, inspect missing values in the selected feature columns.
