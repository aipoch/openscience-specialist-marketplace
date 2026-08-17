---
name: wgcna-analysis
description: Use when building a weighted gene co-expression network from a bulk expression matrix and a sample group file, filtering variable genes by MAD, identifying co-expression modules with WGCNA, correlating modules with traits, and exporting module-level plots and gene tables. NOT for single-cell RNA-seq, differential expression testing, methylation analysis, or datasets that are too small for WGCNA after quality control.
license: MIT
author: AIPOCH
---
> **Source**: [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills)

# WGCNA Analysis

## When to Read External Files

**AI Agent: This section tells you when to read additional files.**

| Situation | File to Read | Purpose |
|-----------|--------------|---------|
| **Need algorithm details** | `references/algorithm.md` | WGCNA workflow, filtering strategy, statistics, assumptions |
| **Need to run analysis** | `scripts/main.R` | Execute: `Rscript scripts/main.R --input_file ... --group_file ...` |
| **Encounter errors** | `references/troubleshooting.md` | Common errors, causes, and fixes |
| **Need CLI examples** | `references/cli-guide.md` | Complete command examples for common scenarios |
| **Need conversion audit details** | `references/diagnosis-report.md` | Skill readiness assessment and remediation summary |
| **Need test data** | `tests/data/` | Minimal example input files for validation |

## When Not to Use

- Do not use for single-cell RNA-seq matrices.
- Do not use for methylation data, DEG testing, or other non-WGCNA workflows.
- Do not use if the user only wants exploratory discussion and does not want the analysis executed.
- Do not proceed if the dataset is obviously too small for WGCNA or becomes too small after QC.

When an input is out of scope, stop early and state which limitation applies.

---

## Usage

```bash
Rscript scripts/main.R \
  --input_file ./expression_matrix.csv \
  --group_file ./group_info.csv \
  --output_dir ./output/ \
  --sample_column sample \
  --group_column group \
  --network_type unsigned \
  --cor_type pearson \
  --mad_quantile 0.25 \
  --min_mad 0.01 \
  --max_genes 5000 \
  --min_module_size 30 \
  --merge_cut_height 0.25 \
  --soft_r2_cutoff 0.85 \
  --module_of_interest auto \
  --top_modules 1 \
  --tom_sample_size 400 \
  --chunk_size 0 \
  --seed 42 \
  --timeout_seconds 0
```

---

## Arguments

| Short | Long | Type | Default | Description |
|-------|------|------|---------|-------------|
| `-i` | `--input_file` | character | **required** | Expression matrix file with genes in rows and samples in columns |
| `-g` | `--group_file` | character | **required** | Sample-to-group mapping file |
| `-o` | `--output_dir` | character | `./output/` | Output directory |
| `-a` | `--sample_column` | character | `sample` | Sample column in the group file; falls back to the first column if not found |
| `-b` | `--group_column` | character | `group` | Group column in the group file; falls back to the second column if not found |
| `-n` | `--network_type` | character | `unsigned` | Network type for WGCNA: `unsigned` or `signed` |
| `-c` | `--cor_type` | character | `pearson` | Correlation type: `pearson` or `bicor` |
| `-q` | `--mad_quantile` | double | `0.25` | MAD quantile used to define the variability cutoff |
| `-m` | `--min_mad` | double | `0.01` | Minimum MAD cutoff combined with the quantile filter |
| `-k` | `--max_genes` | integer | `0` | Maximum number of retained variable genes; `0` keeps all filtered genes |
| `-p` | `--min_module_size` | integer | `30` | Minimum module size used by `blockwiseModules()` |
| `-r` | `--merge_cut_height` | double | `0.25` | Merge cut height for module merging |
| `-u` | `--soft_r2_cutoff` | double | `0.85` | Target scale-free topology R-squared cutoff for soft-threshold selection |
| `-t` | `--trait_of_interest` | character | `NULL` | Trait column used for module membership vs trait scatter plots; defaults to the first trait column |
| `-x` | `--module_of_interest` | character | `auto` | Module color or comma-separated module colors to export; `auto` ranks modules by absolute module-trait correlation |
|  | `--top_modules` | integer | `1` | Number of top-ranked modules to export when `module_of_interest=auto` |
| `-y` | `--tom_sample_size` | integer | `400` | Number of genes sampled for the TOM heatmap |
|  | `--chunk_size` | integer | `0` | Row chunk size for large expression matrices; `0` disables chunked loading |
| `-s` | `--seed` | integer | `42` | Random seed for reproducibility and TOM heatmap sampling |
| `-z` | `--timeout_seconds` | integer | `0` | Optional elapsed-time limit in seconds; `0` disables timeout |

---

## Input Format

### Expression Matrix (`input_file`)

CSV file with gene identifiers in the first column and sample IDs in the header row. All expression columns must be numeric.

```csv
,TCGA-78-7156,TCGA-44-6774,TCGA-69-A59K
A1BG,2.612908495,2.077948602,3.865545859
A1BG-AS1,3.526391179,3.221923473,4.684308865
A1CF,1.179552278,1.136255654,1.188781778
```

Requirements:

- First column contains non-empty gene IDs
- Sample column names are unique and non-empty
- Expression values are numeric
- After QC, the matrix must remain large enough for WGCNA

### Group File (`group_file`)

CSV file with at least two columns: one sample ID column and one group column.

```csv
sample,group
TCGA-78-7156,Control
TCGA-44-6774,Control
TCGA-69-A59K,Control
TCGA-44-6147,Case
```

Requirements:

- Sample IDs must match expression matrix column names
- Sample IDs must be unique
- Group values must be non-empty
- At least two groups are required

---

## Output Files

All files are written under `output_dir`.

| File | Format | Description |
|------|--------|-------------|
| `session_info.txt` | text | R session information and package versions |
| `plots/soft_threshold.pdf` | PDF | Scale-free topology fit and mean connectivity across tested powers |
| `plots/sample_clustering.pdf` | PDF | Sample dendrogram with group color annotation |
| `plots/gene_cluster_modules.pdf` | PDF | Gene dendrogram with module color labels |
| `plots/module_eigengene_heatmap.pdf` | PDF | Eigengene adjacency heatmap |
| `plots/tom_heatmap.pdf` | PDF | TOM-based network heatmap for a sampled subset of genes |
| `plots/module_trait_relationships.pdf` | PDF | Heatmap of module-trait correlations and p-values |
| `plots/module_membership_vs_trait_<module>_<trait>.pdf` | PDF | Scatter plot for each exported module against the selected trait |
| `tables/sft_fit_indices.csv` | CSV | Soft-threshold fit statistics returned by `pickSoftThreshold()` |
| `tables/module_trait_cor.csv` | CSV | Module eigengene vs trait correlation matrix |
| `tables/module_trait_p.csv` | CSV | P-value matrix corresponding to module-trait correlations |
| `tables/module_assignments.csv` | CSV | Per-gene module assignments |
| `tables/selected_modules.csv` | CSV | Ranked summary of exported modules for the selected trait |
| `tables/module_genes_<module>.csv` | CSV | Gene-level export for each selected module |
| `tables/analysis_summary.csv` | CSV | Summary of samples, retained genes, selected power, selected trait, and exported modules |
| `data/net.rds` | RDS | Full WGCNA network object returned by `blockwiseModules()` |
| `data/analysis_objects.rds` | RDS | Saved analysis objects, trait data, statistics, and selected modules |
| `data/wgcna_tom-block.*.RData` | RData | Saved TOM block file(s) produced by `blockwiseModules()` |

---

## Workflow

### Step 1: Load and validate inputs
- Validate file existence and CLI parameters
- Read the expression matrix and group file
- Check sample ID consistency between files

### Step 2: Filter variable genes
- Compute per-gene MAD values
- Keep genes above the quantile-based MAD cutoff
- Optionally cap the retained genes with `max_genes`

### Step 3: Build the WGCNA network
- Transpose the matrix into the WGCNA sample-by-gene format
- Select soft-threshold power with `pickSoftThreshold()`
- Build modules with `blockwiseModules()`

### Step 4: Associate modules with traits
- Encode groups as a trait matrix
- Compute module-trait and gene-trait correlations
- Rank modules by absolute correlation with the selected trait

### Step 5: Export results
- Save summary tables, module assignments, and per-module gene exports
- Generate dendrogram, heatmap, TOM, and scatter plot PDFs
- Save session info and serialized R objects

---

## Error Handling

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `SKILL_FILE_NOT_FOUND` | Input file path is wrong or a required TOM file is missing | Check file paths and rerun the analysis from the start |
| `SKILL_MISSING_COLUMNS` | Required sample, group, or gene identifier columns are missing or empty | Verify the CSV header and column names |
| `SKILL_EMPTY_DATA` | Input is empty, no genes pass filtering, or the filtered matrix is too small for WGCNA | Check data quality and relax filtering settings |
| `SKILL_INVALID_PARAMETER` | A CLI value is missing, out of range, or not in the allowed choices | Review parameter values in the command |
| `SKILL_SAMPLE_MISMATCH` | Group file sample IDs do not match expression matrix sample IDs | Make sample identifiers identical across both files |
| `SKILL_PACKAGE_NOT_FOUND` | A required R package is not installed | Install missing packages before running |

**IF error persists**, READ: `references/troubleshooting.md`

---

## Testing

### Smoke Test

```bash
# Check CLI help
Rscript scripts/main.R --help

# Run with bundled test data
Rscript scripts/main.R \
  --input_file tests/data/expression.csv \
  --group_file tests/data/group.csv \
  --output_dir tests/output-skill/ \
  --sample_column sample \
  --group_column group \
  --network_type unsigned \
  --cor_type pearson \
  --mad_quantile 0.25 \
  --min_mad 0.01 \
  --max_genes 500 \
  --min_module_size 20 \
  --merge_cut_height 0.25 \
  --soft_r2_cutoff 0.8 \
  --module_of_interest auto \
  --top_modules 1 \
  --tom_sample_size 150 \
  --chunk_size 0 \
  --seed 42 \
  --timeout_seconds 0

# Validate required outputs
Rscript tests/validate_outputs.R tests/output-skill/
```

### Validation Commands

```bash
Rscript tests/validate_outputs.R tests/output-skill/
```

Expected outputs include `session_info.txt`, the plot PDFs, table CSVs, and the serialized R objects listed above.

### Additional Verification

- When exporting explicit modules, confirm the matching `tables/module_genes_<module>.csv` files exist.
- When generating module membership plots, confirm the matching `plots/module_membership_vs_trait_<module>_<trait>.pdf` files exist.
- If chunked loading is enabled, compare `tables/analysis_summary.csv` against a non-chunked run on the same input.

### Notes

- Re-running the same command with the same seed is expected to be reproducible.
- Failed runs may still create `output_dir` and `session_info.txt` before exiting; this is expected and safe to overwrite on retry.

---

## Implementation Checklist

- [x] CLI parsing with `optparse`
- [x] `set.seed()` for reproducibility
- [x] Dependency checks with explicit package loading
- [x] Relative `source()` paths via `get_script_dir()`
- [x] Optional timeout parameter
- [x] Optional chunked loading for large matrices
- [x] Session info recording
- [x] Error handling with `SKILL_*` codes
- [x] `SKILL.md` parameters match the implemented CLI
- [x] File reading instructions in `SKILL.md`
- [x] Test data provided in `tests/data/`
- [x] Smoke-test output validation script provided

---

*Last updated: 2026-04-17 | Version: 1.0.0*
