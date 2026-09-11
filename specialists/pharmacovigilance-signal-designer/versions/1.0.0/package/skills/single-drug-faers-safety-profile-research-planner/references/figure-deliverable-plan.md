# Figure and Deliverable Plan
# single-drug-faers-safety-profile-research-planner

---

## Standard Figure Set (7–8 figures)

| Figure | Content | Required From |
|---|---|---|
| **Fig 1** | Overall study workflow schematic | All configs |
| **Fig 2** | Case-selection flowchart + exposure / comparator definition summary | All configs |
| **Fig 3** | Primary signal landscape (ranking, forest, heatmap, or bubble plot) | All configs |
| **Fig 4** | Core comparative or whole-profile signal table / atlas | All configs |
| **Fig 5** | Restricted comparison or subgroup characterization | Standard+ |
| **Fig 6** | Seriousness / onset / label-context extension | Standard+ |
| **Fig 7** | Sensitivity analysis and robustness summary | Standard+ |
| **Fig 8** | Integrated evidence and limitation summary figure | Standard+ |

---

## Advanced / Publication+ Extensions

| Figure | Content | Required From |
|---|---|---|
| **Fig 9** | Multi-restriction robustness comparison or richer subgroup map | Advanced+ |
| **Fig 10** | Within-class contrast or external regulatory-label alignment summary | Standard+ (can be supplementary) |
| **Fig 11** | Reviewer-facing evidence-tier matrix and claim-boundary panel | Publication+ |
| **Fig 12** | Final integrated safety-story schematic | Publication+ |

---

## Supplementary Figure Expectations

| Supplementary Content | Notes |
|---|---|
| Full PT/SOC signal tables | Prevent selective reporting |
| Full subgroup tables | Needed when demographic claims are made |
| Full seriousness or onset tables | Required if those modules are used |
| Alternative denominator / restriction outputs | Supports reviewer-facing robustness |
| MedDRA mapping details and code lists | Critical for reproducibility |
| Case de-duplication and inclusion logic details | Needed for pharmacovigilance methods transparency |

---

## Intermediate Deliverable Checklist

Use as a gate before moving to the next analysis phase.

**Phase 1 — Case Definition**
- [ ] Exposure definition fixed
- [ ] Comparator or scan scope fixed
- [ ] AE dictionary level fixed (SOC/PT/HLT)
- [ ] Signal metric route fixed

**Phase 2 — Primary Signal Analysis**
- [ ] Main case table complete
- [ ] Primary signal analysis complete
- [ ] Ranking / compression logic documented
- [ ] Final endpoint framing fixed

**Phase 3 — Characterization**
- [ ] Subgroup module complete if included
- [ ] Seriousness / onset module complete if included
- [ ] Label-context module complete if included
- [ ] Evidence labels drafted for each result type

**Phase 4 — Robustness**
- [ ] Sensitivity restriction complete if selected
- [ ] Alternative metric comparison complete if selected
- [ ] Limitation statements drafted
- [ ] Figure dependency order reviewed

**Phase 5 — Manuscript**
- [ ] Full figure set finalized
- [ ] Supplementary tables compiled
- [ ] Methods section aligned with actual extraction / filtering rules
- [ ] Results order aligned with figure order

---

## Dependency Map Deliverable (mandatory)

Every output must include a **Dependency Map / Evidence Map** as part of Section C.5. This is not a figure but a structured checklist that must appear before the step-by-step workflow.

### Required Format

```
Evidence Map — [Config Name]

PRESENT evidence layers:
- [list each declared data source and analysis method]

ABSENT evidence layers:
- [list what is NOT included in this configuration]

THEREFORE FORBIDDEN steps:
- [list downstream steps that cannot appear due to absent dependencies]

Endpoint formula used:
- [state the exact extraction / restriction / signal-selection formula]
```

This section must be generated for:
1. The recommended primary plan
2. The Minimal Executable Version (Section G)

If the two plans use different formulas, both must be stated separately.
