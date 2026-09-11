# Reproducibility Check Reference Guide

## Mode A — Methods Completeness Audit

### Input Checklist

- Full text of the Methods section (text or file)
- Experimental materials, equipment, and software versions
- Experimental/Data processing workflow
- Statistical analysis plan (if any)

### Output Checklist

- List of missing information
- List of ambiguous descriptions
- Reproducibility risk assessment
- List of supplementary recommendations

### Output Format

- Output missing items and recommendations step-by-step.
- Distinguish between high and low priority.
- Risk assessment must include levels and rationale.

### Priority Definitions

- High Priority: Missing key materials, equipment, parameters, or statistical methods required for replication.
- Low Priority: Details that can be supplemented through routine practices or have a minor impact on replication.

### Risk Assessment Levels

- Low: Key information is complete and directly reproducible.
- Medium: Minor key information is missing; reproducible after supplementation.
- High: Significant gaps in key processes or parameters; difficult to reproduce in the short term.

### Quality Check

- Materials, equipment, and software versions are clearly specified.
- Sample size, randomization, control groups, and number of replicates are clearly specified.
- Statistical methods and parameters are complete.
- Data preprocessing and outlier handling are clearly explained.

### Common Issues

- Neglecting details of data processing and preprocessing.
- Failing to label units for key parameters.
- Inferring unprovided information, leading to distorted conclusions.

## Mode B — Open Science Best Practices

### Pre-registration Platforms

| Platform | Best For | URL |
|---|---|---|
| OSF Registries | General research, any discipline | osf.io/registries |
| AsPredicted | Streamlined quick pre-registration | aspredicted.org |
| ClinicalTrials.gov | Clinical trials (mandatory) | clinicaltrials.gov |
| PROSPERO | Systematic reviews & meta-analyses | crd.york.ac.uk/prospero |
| INPLASY | International systematic reviews | inplasy.com |

### FAIR Principles Quick Reference

| Principle | Key Actions |
|---|---|
| **Findable** | Persistent identifier (DOI), rich metadata, indexed in searchable resource |
| **Accessible** | retrievable via standard protocol (HTTP), clear access conditions (open or controlled) |
| **Interoperable** | Standard formats (CSV, JSON, HDF5), controlled vocabularies (GO, MeSH, EFO), qualified references |
| **Reusable** | Clear license (CC-BY, CC0 for data; MIT, Apache for code), provenance, community standards (MIAME, MINSEQE) |

### Data Repository Recommendations by Domain

| Domain | Recommended Repository |
|---|---|
| Genomics | GEO, SRA, ENA |
| Proteomics | PRIDE, MassIVE |
| Clinical trials | ClinicalTrials.gov, WHO ICTRP |
| General | Zenodo, Dryad, Figshare, OSF |

### Computational Reproducibility Checklist

- [ ] Code shared in public repository (GitHub/GitLab)
- [ ] Zenodo DOI minted for code release
- [ ] All dependencies documented (requirements.txt / renv.lock / environment.yml)
- [ ] Dockerfile or Binder configuration provided
- [ ] README with execution instructions included
- [ ] Code tested on clean environment

### Replication Study Design Guide

- **Direct replication**: Match original methods as closely as possible; sample size based on safeguard power (assume effect 75% of original).
- **Conceptual replication**: Test same hypothesis with different methods/paradigm; define success criteria a priori.
- **Success criteria**: Equivalence test bounds (e.g., TOST) or replication Bayes factor thresholds.
- **Power analysis**: Use original effect size with safeguard adjustment; report achieved power.

### Reporting Guidelines Reference

| Study Type | Guideline |
|---|---|
| RCT | CONSORT |
| Observational (cohort/case-control) | STROBE |
| Animal studies | ARRIVE |
| Systematic reviews / meta-analyses | PRISMA |
| Diagnostic accuracy | STARD |
| Prediction models | TRIPOD |

### Open Science Badges

- **Open Data Badge**: Data publicly available in trusted repository.
- **Open Materials Badge**: Research materials publicly available.
- **Pre-registered Badge**: Study pre-registered before data collection with verified timestamp.