# Algorithm

## Overview

This skill takes a gene list ranked by a statistic and runs gene-set enrichment analysis with `clusterProfiler::GSEA()`.
It supports the `fgsea` and `DOSE` backends, and five gene-set families: `KEGG`, `HALLMARKS`, `GO_BP`, `GO_MF`, `GO_CC`.

## Input and preprocessing

The input file is a CSV with at least:
- a gene column (default `name`)
- a ranking-statistic column (default `logFC`)

The script preprocesses it by:
1. Verifying the input file exists
2. Verifying the required columns exist
3. Dropping NA and empty-string entries
4. Building a ranked vector by sorting on `logFC` descending

## Pipeline

1. Read input data
2. Load the gene-set data, or read from `--rds_path`
3. Build `TERM2GENE`
4. Run GSEA
5. Export the result table, running-score table, and session info

## Key statistics

- `ES`: enrichment score, the maximum deviation of the running curve
- `NES`: normalized enrichment score, controlling for gene-set size
- `p.adjust`: significance after multiple-testing correction

## Reproducibility

- The entry-point flag `--seed` defaults to `42`
- `session_info.txt` is written at the end of the run
- Identical input and arguments should yield identical results
