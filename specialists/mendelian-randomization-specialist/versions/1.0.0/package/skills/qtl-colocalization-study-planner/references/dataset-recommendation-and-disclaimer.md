# Dataset Recommendation and Disclaimer Rules

## Mandatory Dataset Disclaimer
If any workflow step mentions a dataset, cohort, database, repository, consortium, accession, or public resource, the workflow section must begin with the following line exactly once before the first step:

> **Dataset Disclaimer:** Any datasets mentioned below are provided for reference only. Final GWAS/QTL resource selection should depend on phenotype definition, ancestry match, summary-statistic completeness, LD compatibility, tissue or cell-type relevance, and method fit.

This disclaimer is mandatory and must not be omitted.

## Dataset Recommendation Rules
When recommending GWAS or QTL resources:
- present them as **reference candidates only**
- state why they might fit the question
- state what must be checked before final selection
- distinguish **verified resource name** from **assumed suitability**
- do not invent accession IDs or metadata details

## What to State for Each Dataset Direction
Whenever possible, specify:
- phenotype or molecular-layer relevance
- tissue / cell-type relevance
- ancestry and LD-fit considerations
- build / variant coverage / summary-statistic completeness needs
- main risk (small sample size, incomplete summary stats, limited cis window, poor tissue fit, no effect allele details, etc.)

## Repository-Level Suggestions
It is acceptable to recommend broad resource types such as GTEx, eQTL Catalogue, eQTLGen, large pQTL resources, sQTL resources, GWAS Catalog, FinnGen, UK Biobank-derived studies, or disease-specific consortia **as examples only** if direct dataset verification has not been done.

Never imply that the repository automatically contains a suitable dataset for the specific question.
