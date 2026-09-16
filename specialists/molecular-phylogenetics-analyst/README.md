# Molecular Phylogenetics Analyst

Takes homologous sequences to a defensible phylogeny: alignment and trimming, model selection, maximum-likelihood and Bayesian trees with honest support and convergence checks, coalescent species trees, divergence dating, and publication-ready tree figures.

## Versions

- `1.0.0` - initial release with 10 bundled Skills and 4 Connector references.

The package uses the OpenScience App export/import v1 layout. Connector entries are references only;
credentials and executable Connector configuration are not included.

## Bundled Skills

Scores come from skill-auditor runs made for this release between 2026-09-11 and 2026-09-15; the upstream
repository ships no audits. Where the generated code could not run here, the output was
graded by inspection; the table says how many test inputs actually ran.

| Skill                             | Display name                      | Role       | Audit score                                                     |
| --------------------------------- | --------------------------------- | ---------- | --------------------------------------------------------------- |
| `bio-alignment-multiple`          | Multiple Sequence Alignment       | core       | 85 (Production Ready, 2026-09-11; code ran for 7/7 test inputs) |
| `bio-phylo-modern-tree-inference` | Maximum-Likelihood Tree Inference | core       | 88 (Production Ready, 2026-09-15; code ran for 8/9 test inputs) |
| `bio-phylo-bayesian-inference`    | Bayesian Phylogenetic Inference   | core       | 87 (Production Ready, 2026-09-15; code ran for 8/9 test inputs) |
| `bio-phylo-species-trees`         | Coalescent Species Trees          | core       | 86 (Production Ready, 2026-09-15; code ran for 9/9 test inputs) |
| `bio-alignment-trimming`          | Alignment Trimming                | supporting | 83 (Limited Release, 2026-09-15; code ran for 9/9 test inputs)  |
| `bio-phylo-divergence-dating`     | Divergence Time Estimation        | supporting | 87 (Production Ready, 2026-09-15; code ran for 8/9 test inputs) |
| `bio-phylo-distance-calculations` | Distance Trees                    | supporting | 87 (Production Ready, 2026-09-15; code ran for 9/9 test inputs) |
| `bio-phylo-tree-manipulation`     | Rooting and Tree Editing          | supporting | 86 (Production Ready, 2026-09-15; code ran for 8/9 test inputs) |
| `bio-phylo-tree-io`               | Tree File I/O                     | supporting | 88 (Production Ready, 2026-09-15; code ran for 9/9 test inputs) |
| `bio-phylo-tree-visualization`    | Tree Figures                      | supporting | 84 (Limited Release, 2026-09-15; code ran for 9/9 test inputs)  |

## Connector references

`pubmed`, `protein-annotation`, `genes`, `genomes`

## Source

Skills from [https://github.com/mrsonord2240/optimizing-agent-science-skills](https://github.com/mrsonord2240/optimizing-agent-science-skills) at `2f7bc21efd510c4c500eee1f3df2ce29eeeff026`, under `skills/bioSkills/` (MIT).

These Skills originate in https://github.com/GPTomics/bioSkills at commit d91ed3d563019e649dc854c56ccd62551359488a (MIT).
They have been MODIFIED: defects found by audit were fixed in https://github.com/mrsonord2240/bioSkills at commit d1b8fdce4e647baf676759ba64da8d8412320244, then exported to the repository named above. Files change only where an audit
demonstrated a defect; every change has a fix log and a post-fix audit report.

Packaging notes (Skill files are otherwise byte-identical to that commit; audit reports are not
packaged):

- 46 text file(s) normalized to repository format: LF line endings, no trailing whitespace, no blank lines at end of file
