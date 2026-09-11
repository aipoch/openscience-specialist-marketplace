# Tumor Immune Microenvironment Bulk-Transcriptome Specialist

Estimates, triangulates and interprets tumor immune microenvironment composition from bulk transcriptomes via CIBERSORT-style deconvolution, ssGSEA, ESTIMATE and consensus subtyping, without treating scores as measured infiltration or making patient-level claims.

## Versions

- `1.0.0` - initial release with 15 bundled Skills and 7 Connector references.

The package uses the OpenScience App export/import v1 layout. Connector entries are references only;
credentials and executable Connector configuration are not included.

## Bundled Skills

Scores come from the upstream skill-auditor report shipped with each Skill (`eval_report_*.json`),
except where that report's test section is templated; there the score recorded in the Skill's
`POLISH_CHANGELOG.md` is used and the reported figure is shown alongside.

| Skill                                                      | Display name                            | Role       | Audit score                         |
| ---------------------------------------------------------- | --------------------------------------- | ---------- | ----------------------------------- |
| `tumor-immune-infiltration-diagnostic-ml-research-planner` | Tumor Immune-Infiltration Study Planner | core       | 90 (Production Ready, 2026-04-22)   |
| `cibersort-immune-infiltration-analysis`                   | CIBERSORT Immune Deconvolution          | core       | 90 (Production Ready, 2026-04-17)   |
| `ssgsea-immune-infiltration-analysis`                      | ssGSEA Immune Cell Enrichment           | core       | 95.3 (Production Ready, 2026-04-15) |
| `estimate-immune-score-analysis`                           | ESTIMATE Stromal And Immune Scoring     | core       | 97 (Production Ready, 2026-04-27)   |
| `consensus-clustering-analysis`                            | Consensus Clustering Subtyping          | core       | 94 (Production Ready, 2026-04-17)   |
| `deg-screening-analysis`                                   | limma DEG Screening                     | core       | 90 (Production Ready, 2026-04-16)   |
| `immune-pathway-analysis`                                  | Immune Pathway GSVA                     | supporting | 94 (Production Ready, 2026-04-20)   |
| `gsva-analysis-and-visualization`                          | MSigDB GSVA Pathway Analysis            | supporting | 95 (Production Ready, 2026-04-27)   |
| `gokegg-analysis`                                          | GO And KEGG Enrichment                  | supporting | 86 (Production Ready, 2026-04-15)   |
| `pcd-immune-oncology-research-planner`                     | PCD Immuno-Oncology Study Planner       | supporting | 89 (Production Ready, 2026-04-22)   |
| `hierarchical-clustering-plot`                             | Sample Hierarchical Clustering QC       | supporting | 91 (Production Ready, 2026-04-27)   |
| `sample-group-sankey-plot`                                 | Sample Group Sankey Plot                | supporting | 96 (Production Ready, 2026-04-27)   |
| `gene-protein-expression-matrix-normalization`             | Expression Matrix Normalization         | supporting | 93 (Production Ready, 2026-05-08)   |
| `batch-effect-correction`                                  | ComBat Batch Correction                 | supporting | 89 (Production Ready, 2026-04-27)   |
| `km-survival-curve`                                        | Kaplan-Meier Survival Curve             | supporting | 92 (Production Ready, 2026-04-20)   |

## Connector references

`expression`, `omics-archives`, `cancer-models`, `genes`, `cellguide`, `pubmed`, `literature`

## Source

Skills from [https://github.com/aipoch/medical-research-skills](https://github.com/aipoch/medical-research-skills) at `f5ef65b9bea79b6dd9553f52f95b0d08f7d64d26` (MIT).

Packaging notes (Skill files are otherwise byte-identical to that commit; audit reports are not
packaged):

- ssgsea-immune-infiltration-analysis: `tests/data/expression_matrix.csv` omitted from the package — 25.5 MB test fixture exceeds the marketplace 10 MiB per-file limit; tests/run_tests.R cannot run without it
- gsva-analysis-and-visualization: `tests/data/expr_matrix.csv` omitted from the package — 25.5 MB test fixture exceeds the marketplace 10 MiB per-file limit; tests/run_tests.R cannot run without it
- gene-protein-expression-matrix-normalization: bytes reused from published auto-research-specialist@1.0.1 (content digest 059eccb371e4) so installing both Specialists does not raise a Skill conflict
- batch-effect-correction: bytes reused from published auto-research-specialist@1.0.1 (content digest 9c2947db05ba) so installing both Specialists does not raise a Skill conflict
