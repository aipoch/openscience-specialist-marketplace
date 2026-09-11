# Scoring Algorithm & Endpoint Selection Detailed Rules

Detailed scoring methodology and endpoint selection guidance. For overview, see main [SKILL.md](../SKILL.md).

---

## Feasibility Score Calculation (0-100)

### Weighted Composite Formula

```
Feasibility Score = Σ(Dimension_Score × Weight × 10)

Where:
- Patient Availability:  Score (0-10) × 0.30 × 10
- Endpoint Precedent:   Score (0-10) × 0.25 × 10
- Regulatory Clarity:   Score (0-10) × 0.20 × 10
- Comparator Feasibility: Score (0-10) × 0.15 × 10
- Safety Monitoring:    Score (0-10) × 0.10 × 10
```

### Interpretation Thresholds

| Score Range | Feasibility Level | Recommendation |
|-------------|-------------------|----------------|
| ≥75 | HIGH | Recommend proceed to protocol development |
| 50-74 | MODERATE | Additional validation recommended |
| <50 | LOW | Significant de-risking required |

### Dimension Scoring Guide

#### Patient Availability (Weight: 30%)

| Score | Criteria |
|-------|----------|
| 9-10 | >10,000 eligible patients/year, global sites feasible |
| 7-8 | 2,000-10,000 eligible patients/year, adequate geography |
| 5-6 | 500-2,000 eligible patients/year, limited geography |
| 3-4 | 100-500 eligible patients/year, few sites |
| 1-2 | <100 eligible patients/year, ultra-rare |

Sub-dimensions:
- Base population size: Incidence/prevalence data quality
- Biomarker prevalence: Frequency in target disease
- Site access: Number of feasible trial sites

#### Endpoint Precedent (Weight: 25%)

| Score | Criteria |
|-------|----------|
| 9-10 | Grade A (★★★): FDA-accepted, multiple recent precedents |
| 7-8 | Grade B (★★☆): Validated in Phase 3, single precedent |
| 5-6 | Grade C (★☆☆): Phase 1 use, biomarker validation ongoing |
| 3-4 | Grade D (☆☆☆): Novel endpoint, no regulatory precedent |
| 1-2 | No validated measurement method exists |

Sub-dimensions:
- Regulatory acceptance: FDA approvals using this endpoint
- Measurement feasibility: Standard assessment methods available

#### Regulatory Clarity (Weight: 20%)

| Score | Criteria |
|-------|----------|
| 9-10 | Clear 505(b)(1) pathway, breakthrough eligible, precedents exist |
| 7-8 | Defined pathway, pre-IND recommended, some precedents |
| 5-6 | Pathway uncertain, FDA guidance needed, limited precedents |
| 3-4 | Novel indication, no regulatory framework |
| 1-2 | Regulatory barriers, clinical hold risk |

Sub-dimensions:
- Pathway defined: 505(b)(1), 505(b)(2), breakthrough, orphan
- Precedent approvals: Similar indications approved recently

#### Comparator Feasibility (Weight: 15%)

| Score | Criteria |
|-------|----------|
| 9-10 | SOC clearly defined, drug readily available (generic) |
| 7-8 | SOC available, branded drug, clear efficacy data |
| 5-6 | SOC debated, limited comparator options |
| 3-4 | No approved SOC, investigational comparators |
| 1-2 | Placebo only option, ethical concerns |

Sub-dimensions:
- SOC availability: Drug supply, commercial access
- Historical data: Published efficacy for comparison

#### Safety Monitoring (Weight: 10%)

| Score | Criteria |
|-------|----------|
| 9-10 | Well-characterized class, standard monitoring protocols |
| 7-8 | Known toxicities, established monitoring |
| 5-6 | Some unknowns, enhanced monitoring needed |
| 3-4 | Novel mechanism, significant safety uncertainty |
| 1-2 | Black box warnings expected, high-risk population |

Sub-dimensions:
- Known toxicities: Class effects characterized (FAERS, labels)
- Monitoring plan: Defined, feasible protocol

### Scorecard Template

```markdown
| Dimension | Weight | Score (0-10) | Weighted | Grade |
|-----------|--------|--------------|----------|-------|
| **Patient Availability** | 30% | [X] | [0.30×X] | [★★☆] |
| - Base population size | - | [X] | - | [Source] |
| - Biomarker prevalence | - | [X] | - | [ClinVar data] |
| - Site access | - | [X] | - | [N sites feasible] |
| **Endpoint Precedent** | 25% | [X] | [0.25×X] | [★★★] |
| - Regulatory acceptance | - | [X] | - | [FDA approvals using ORR] |
| - Measurement feasibility | - | [X] | - | [RECIST standard] |
| **Regulatory Clarity** | 20% | [X] | [0.20×X] | [★★☆] |
| - Pathway defined | - | [X] | - | [Breakthrough potential] |
| - Precedent approvals | - | [X] | - | [Similar indications] |
| **Comparator Feasibility** | 15% | [X] | [0.15×X] | [★★★] |
| - SOC availability | - | [X] | - | [FDA-approved, generic] |
| - Historical data | - | [X] | - | [Published ORR: X%] |
| **Safety Monitoring** | 10% | [X] | [0.10×X] | [★★☆] |
| - Known toxicities | - | [X] | - | [FAERS, class effects] |
| - Monitoring plan | - | [X] | - | [Defined, feasible] |
| **TOTAL FEASIBILITY SCORE** | **100%** | - | **[XX/100]** | - |
```

### Feasibility Score Transparency

Always show the calculation:
```markdown
| Dimension | Weight | Raw Score | Weighted | Evidence |
|-----------|--------|-----------|----------|----------|
| Patient Availability | 30% | 8/10 | 24 | ★★★: Epi data |
| Endpoint Precedent | 25% | 9/10 | 22.5 | ★★★: FDA approvals |
| Regulatory Clarity | 20% | 7/10 | 14 | ★★☆: Pre-IND advised |
| Comparator Feasibility | 15% | 9/10 | 13.5 | ★★★: Generic avail |
| Safety Monitoring | 10% | 8/10 | 8 | ★★☆: Class effects |
| **TOTAL** | **100%** | - | **82/100** | **HIGH** |
```

---

## Endpoint Selection Detailed Rules

### Primary Endpoint Decision Tree

```
Is there an FDA-accepted endpoint for this indication?
├─ YES → Use it (Grade A, ★★★)
│   └─ Verify: search_clinical_trials + FDA_get_approval_history
│
└─ NO → Is there a validated surrogate?
    ├─ YES → Use surrogate (Grade B, ★★☆)
    │   └─ Need: Literature validation + FDA pre-IND discussion
    │
    └─ NO → Is there an exploratory endpoint with Phase 1 data?
        ├─ YES → Use with caution (Grade C, ★☆☆)
        │   └─ Must: Plan for adaptive design + interim analysis
        │
        └─ NO → Propose novel endpoint (Grade D, ☆☆☆)
            └─ Must: Pre-IND meeting + biomarker qualification plan
```

### Endpoint Selection by Phase

| Phase | Primary Endpoint | Evidence Grade Required |
|-------|-----------------|------------------------|
| Phase 1 | DLT, MTD/RP2D | ★★☆ (standard definitions) |
| Phase 1b/2 | ORR, DCR | ★★★ (FDA-accepted) or ★★☆ (with precedent) |
| Phase 2 | ORR, PFS | ★★★ (regulatory acceptance needed) |
| Phase 2b/3 | PFS, OS | ★★★ (confirmatory, regulatory standard) |

### Endpoint Measurement Standards

**ORR (Objective Response Rate)**:
- Assessment: RECIST 1.1 (solid tumors), iwGCLL (hematologic), RANO (CNS)
- Imaging: CT/MRI per standard schedule
- Independent review: Required for regulatory submission
- Frequency: Every 6-9 weeks (tumor-dependent)

**PFS (Progression-Free Survival)**:
- Assessment: RECIST 1.1 progression criteria
- Blinded independent central review (BICR) recommended
- Censoring rules must be pre-specified in SAP

**DLT (Dose-Limiting Toxicity)**:
- Standard: Grade 3+ non-hematologic, Grade 4+ hematologic (CTCAE v5.0)
- Assessment period: Cycle 1 (typically 28 days)
- Escalation rules: 3+3, BOIN, mTPI-2

### Surrogate vs. Clinical Endpoints

| Surrogate | Clinical Endpoint | Validation Level |
|-----------|-------------------|------------------|
| ORR | OS | ★★★ in NSCLC, renal cell; ★★☆ in others |
| PFS | OS | ★★★ in many solid tumors |
| ctDNA clearance | PFS/OS | ★☆☆ (exploratory, under validation) |
| Biomarker response | Clinical benefit | ★☆☆ (mechanistic, needs correlation) |

### Endpoint Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Low response rate | Sample size inflation | Interim futility analysis |
| Slow time-to-event | Extended trial duration | Surrogate endpoints with crossover |
| Measurement variability | False negative | Independent central review |
| Missing assessments | Bias | Prospective imaging schedule |

### Evidence Grade Application in Endpoints

Every endpoint claim must carry an evidence grade:
```markdown
ORR of 30-40% is projected [★★☆] based on:
- Similar EGFR TKI (erlotinib): 32% ORR in EGFR+ NSCLC (NCT00949650)
- Our drug's 2× IC50 potency vs. erlotinib (preclinical)
*Source: ClinicalTrials.gov, internal data*
```

**NOT acceptable**:
```markdown
ORR of 60% is expected based on preclinical data.
```

---

## Success Criteria Detailed Definitions

### Phase 1 → Phase 2 Transition
- ≤33% DLT rate at RP2D
- ≥50% patients achieve PD biomarker response
- No unexpected safety signals (Grade 5 AEs, new class effects)
- PK supports proposed dosing schedule

### Phase 2 Simon Two-Stage Design
**Stage 1** (N=13):
- ≥2 responses (ORR ≥15%) → Proceed to Stage 2
- <2 responses → Stop for futility

**Stage 2** (N=30 additional):
- Final analysis at N=43
- Target: ORR ≥30% with 95% CI lower bound >10%

### Phase 2 → Phase 3 Advancement
- ORR ≥30% (95% CI lower bound >10%)
- Median DoR ≥6 months
- PFS signal (HR <0.7 vs. historical SOC)
- Safety profile manageable (Grade ≥3 AE <40%)
- Biomarker correlation with response (enrichment signal)
