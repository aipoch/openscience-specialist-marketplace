# Method Library
# faers-pharmacovigilance-disproportionality-research-planner

---

## Core Pharmacovigilance Tooling

### Primary Analysis Environments
| Tool | Language | Use Case |
|---|---|---|
| Python | Python | FAERS export parsing, filtering, PT counting, ROR table generation |
| R | R | Statistical tables, CI calculation, figures, forest plots |
| SQL / dataframe pipeline | mixed | Large report-table filtering and normalization |

### FAERS / Spontaneous-Report Resources
| Tool / Resource | Use Case |
|---|---|
| FAERS public dashboard | report retrieval and exploratory query |
| Downloadable FAERS files | scalable filtering and reproducible extraction |
| MedDRA dictionary | standard adverse-event coding |
| FDA documentation | resource and reporting-framework context |

### Disproportionality Methods
| Method | Role |
|---|---|
| Reporting Odds Ratio (ROR) | Primary disproportionality metric |
| 95% confidence interval | Bound uncertainty around ROR |
| Comparator benchmarking | Tie signals to control products |
| Cross-product comparison | Compare signal pattern within class |
| Strong-signal thresholding | Focus interpretation on higher-priority signals |

---

## Data Resources

### Common Pharmacovigilance Platforms
| Resource | Coverage |
|---|---|
| FAERS | FDA spontaneous-report adverse-event database |
| Vigibase / EudraVigilance | optional alternative systems if explicitly requested |
| MedDRA | controlled vocabulary for adverse-event coding |

### Dataset Planning Requirement

| Item | What to Declare |
|---|---|
| Database | source, access route, extraction date |
| Product list | generic and brand names |
| Comparator list | therapeutic or class controls |
| AE coding | SOC / PT selection logic |
| Filtering logic | seriousness, suspect role, concomitant exclusion |

> **Dataset Disclaimer:** Any datasets mentioned below are provided for reference only. Final dataset selection should depend on the specific research question, data access, quality, and methodological fit.

---

## Parameter Defaults and Decision Rules

| Parameter | Default | Notes |
|---|---|---|
| Main metric | ROR | declare formula explicitly |
| Confidence interval | 95% | mandatory |
| Strong-signal rule | stricter threshold than nominal signal | declare exact cutoff explicitly |
| Comparator strategy | therapeutic control or within-class comparison | justify choice |
| Serious-case filter | optional but preferred for cleaner signals | declare explicitly |
| MedDRA PT scope | domain-specific PT shortlist | avoid uncontrolled PT inflation |
| Interpretation rule | reporting signal only | never causal or incidence claim |
