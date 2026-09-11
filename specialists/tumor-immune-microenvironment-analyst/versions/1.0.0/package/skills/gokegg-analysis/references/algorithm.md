# Algorithm Details

## Overview

This module performs **GO enrichment** and **KEGG enrichment** for a user-provided gene list, then generates a combined GO/KEGG dot chart.

Core implementation:
- Convert input gene IDs to `ENTREZID`
- Run `clusterProfiler::enrichGO()` and `clusterProfiler::enrichKEGG()`
- Adjust p-values using the user-selected `pAdjustMethod` (default: `BH`)
- Visualize enrichment significance with `-log10(p.adjust)`

## 1. Gene ID Conversion

Input genes are provided as a comma-separated list and converted to `ENTREZID` using `clusterProfiler::bitr()`.

Formula-style description:

```text
Input IDs  --bitr()-->  ENTREZID
```

Supported input ID types:
- `SYMBOL`
- `ENSEMBL`
- `ENTREZID`

Supported species databases:
- `org.Hs.eg.db`
- `org.Mm.eg.db`
- `org.Rn.eg.db`

## 2. GO Enrichment Analysis

GO enrichment is performed with:

```r
enrichGO(
  gene = genes_id$ENTREZID,
  OrgDb = sp,
  keyType = "ENTREZID",
  ont = "ALL",
  pAdjustMethod = pAdjustMethod,
  pvalueCutoff = pvalue_cutoff,
  qvalueCutoff = qvalue_cutoff,
  readable = TRUE
)
```

The `ont = "ALL"` setting analyzes all three GO ontologies:
- BP: Biological Process
- CC: Cellular Component
- MF: Molecular Function

## 3. KEGG Enrichment Analysis

KEGG enrichment is performed with:

```r
enrichKEGG(
  gene = genes_id$ENTREZID,
  organism = kegg_org,
  keyType = "kegg",
  pAdjustMethod = pAdjustMethod,
  pvalueCutoff = pvalue_cutoff,
  qvalueCutoff = qvalue_cutoff,
  use_internal_data = TRUE
)
```

Species are mapped internally to KEGG organism codes:
- human -> `hsa`
- mouse -> `mmu`
- rat -> `rno`

After enrichment, KEGG pathway names and pathway classes are filled from the local mapping table `KEGG_pathway_name.txt`.

## 4. Statistical Basis

GO/KEGG enrichment in `clusterProfiler` is based on **over-representation analysis (ORA)**, typically using the hypergeometric model.

For a pathway/term, the enrichment p-value can be expressed as:

```text
P(X >= k) = 1 - sum_{i=0}^{k-1} [ C(M, i) * C(N-M, n-i) / C(N, n) ]
```

Where:
- `N`: total number of background genes
- `M`: number of genes annotated to a given GO term or KEGG pathway
- `n`: number of input genes after ID conversion
- `k`: number of overlapping genes between input genes and the term/pathway

Interpretation:
- smaller p-value means stronger enrichment evidence
- adjusted p-value (`p.adjust`) is used for downstream filtering and plotting

## 5. Multiple Testing Correction

The module uses the user-selected `pAdjustMethod`, defaulting to **Benjamini-Hochberg (BH)**.

BH-style expression:

```text
p.adjust ≈ p * m / rank
```

Where:
- `p`: raw p-value
- `m`: number of tested terms/pathways
- `rank`: rank of the p-value after sorting

In practice, adjusted values are computed by the underlying R implementation.

## 6. Result Filtering

For plotting, rows are kept only if:
- `Description` is not missing
- `p.adjust` is finite and `> 0`

Then the plotting score is computed as:

```text
LOG10pvalue = -log10(p.adjust)
```

Larger `LOG10pvalue` indicates more significant enrichment.

## 7. Dot Chart Construction

### GO selection
- If `ONTOLOGY` exists, the script selects the top `n` terms **within each ontology** by `LOG10pvalue`
- Categories are labeled as `GO:BP`, `GO:CC`, `GO:MF`

### KEGG selection
- The script selects the top `n` pathways by `LOG10pvalue`
- Category is labeled as `KEGG`

### Combined visualization
The final chart merges GO and KEGG results into one data frame and plots:
- x-axis: `Description`
- y-axis: `LOG10pvalue`
- color: enrichment category (`GO:BP`, `GO:CC`, `GO:MF`, `KEGG`)
- optional rotation, sorting, label wrapping, and theme customization

## 8. Execution Flow And Output Objects

Execution flow:
1. `scripts/main.R` parses all analysis and plotting parameters
2. `run_gokegg_analysis()` generates GO/KEGG enrichment outputs under `output_dir/temp`
3. `generate_dot_chart()` from `scripts/dochart.R` is called by `main.R` to create the combined figure under `output_dir/plot`
4. `save_session_info()` writes runtime metadata to `output_dir/session_info.txt`

Main intermediate/result objects:
- `temp/GO_df.csv`: GO result table
- `temp/GO_list.rda`: GO enrichment object saved as `GO_list`
- `temp/KEGG_df.csv`: KEGG result table
- `temp/KEGG_list.rda`: KEGG enrichment object saved as `KEGG_list`
- `plot/gokegg_dot_chart.pdf` or other selected format: combined dot chart figure
- `plot/gokegg_dot_chart_data.csv`: merged plotting table
- `plot/gokegg_dot_chart_data.rda`: plot bundle containing plotting data and plotting parameters
- `session_info.txt`: R version and loaded package versions

## 9. Notes

- This module performs **functional enrichment**, not differential expression analysis.
- The statistical significance shown in the plot is based on `p.adjust`, not raw p-values.
- KEGG gene IDs in the result table are converted back from `ENTREZID` to the user-requested `gene_type` for readability.
- `scripts/dochart.R` currently acts as a function file and is sourced by `scripts/main.R`, rather than serving as the primary CLI entry point.
