# Research Paths Detailed Execution Instructions

Detailed instructions for executing each of the 6 research dimensions. For overview, see main [SKILL.md](../SKILL.md).

---

## PATH 1: Patient Population Sizing

### Objective
Estimate the eligible patient pool through a funnel model: base population → biomarker selection → eligibility criteria → geographic distribution.

### Step-by-Step Execution

**Step 1.1: Get disease prevalence**
```python
disease_info = tu.tools.OpenTargets_get_disease_id_description_by_name(
    diseaseName="non-small cell lung cancer"
)
efo_id = disease_info['data']['id']

phenotypes = tu.tools.OpenTargets_get_diseases_phenotypes(
    efoId=efo_id
)
# Supplement with literature (PubMed) for specific prevalence
```

**Step 1.2: Estimate biomarker mutation prevalence**
```python
egfr_variants = tu.tools.ClinVar_search_variants(
    gene="EGFR",
    significance="pathogenic,likely_pathogenic"
)
l858r_variants = [v for v in egfr_variants['data']
                  if 'L858R' in v.get('name', '')]

gnomad_egfr = tu.tools.gnomAD_search_gene_variants(gene="EGFR")
```

**Step 1.3: Search literature for epidemiology**
```python
epi_papers = tu.tools.PubMed_search_articles(
    query="EGFR L858R prevalence non-small cell lung cancer epidemiology",
    max_results=20
)
```

### Enrollment Funnel Calculation
```
US NSCLC incidence: 200,000/year
× EGFR+ prevalence: 15% = 30,000
× L858R within EGFR+: 45% = 13,500
× Eligible (age, PS, prior Tx): 60% = 8,100
÷ Competing trials: 3 = 2,700 available/year

For N=43, need 43/2,700 = 1.6% capture rate → Achievable
```

### Report Section Template: Patient Population Analysis
```markdown
## 3.1 Base Population Size
- **US Incidence**: [X per 100,000] [★★☆: Source]
- **Prevalence**: [Y total patients in US] [★★★: CDC/NCI data]
- **Annual new cases**: [Z patients/year]

## 3.2 Biomarker Selection Impact
- **Biomarker**: [e.g., EGFR L858R mutation]
- **Prevalence in disease**: [%] [★★★: ClinVar/COSMIC]
- **Geographic variation**: [Asian vs. Caucasian, etc.]
- **Testing availability**: [FDA-approved tests, CLIA labs]

## 3.3 Eligibility Criteria Funnel
| Criterion | Remaining Patients | % Retained |
|-----------|-------------------|------------|
| Base disease population | [N] | 100% |
| Biomarker positive | [N × biomarker %] | [%] |
| Age 18-75 | [N × age factor] | [%] |
| No prior therapy | [N × treatment-naive %] | [%] |
| ECOG 0-1 | [N × performance factor] | [%] |
| Adequate organ function | [N × eligibility factor] | [%] |
| **FINAL ELIGIBLE POOL** | **[N]** | **[%]** |

## 3.4 Geographic Distribution
- High-incidence regions: [e.g., Asia 50%, US 15% for EGFR+]
- Trial site implications
- Recruitment strategy recommendations

## 3.5 Enrollment Projections
**Assumptions**:
- Eligible pool: [N patients/year in US]
- Site activation: [M sites]
- Screening success rate: [%]
- Patients per site per month: [X]

**Target Enrollment**: [Total N]
**Projected Timeline**: [Months]
**Sites Required**: [Minimum M sites]
```

### Tool Reference for PATH 1
- `OpenTargets_get_disease_id_description_by_name` - Disease lookup
- `OpenTargets_get_diseases_phenotypes` - Prevalence data
- `ClinVar_search_variants` - Biomarker mutation frequency
- `gnomAD_search_gene_variants` - Population allele frequencies
- `PubMed_search_articles` - Epidemiology literature
- `search_clinical_trials` - Enrollment feasibility from past trials

---

## PATH 2: Biomarker Prevalence & Testing

### Objective
Characterize the biomarker's prevalence, testing infrastructure, and logistics for screening.

### Step-by-Step Execution

**Step 2.1: Find FDA-approved CDx tests**
```python
cdx_search = tu.tools.PubMed_search_articles(
    query="FDA approved companion diagnostic EGFR L858R",
    max_results=10
)
```

**Step 2.2: Literature on testing in clinical practice**
```python
testing_papers = tu.tools.PubMed_search_articles(
    query="EGFR mutation testing guidelines NCCN turnaround time",
    max_results=15
)
```

### Cross-Source Validation
Cross-check ClinVar, gnomAD, COSMIC, and literature:
- ClinVar: Clinical significance
- gnomAD: Population frequency (for germline)
- COSMIC: Somatic mutation frequency in cancers
- Literature: Geographic/ethnic variation

### Report Section Template: Biomarker Strategy
```markdown
## 4.1 Primary Biomarker
- **Biomarker**: [Gene mutation, protein expression, etc.]
- **Prevalence**: [%] [★★★: ClinVar data]
- **Assay Type**: [NGS, IHC, PCR, etc.]
- **FDA-Approved Tests**: [List CDx tests]
- **Turnaround Time**: [Days]
- **Cost**: [$X per test]

## 4.2 Alternative/Complementary Biomarkers
| Biomarker | Prevalence | Correlation | Testing |
|-----------|------------|-------------|---------|
| [Alt 1] | [%] | [R²] | [Method] |
| [Alt 2] | [%] | [R²] | [Method] |

## 4.3 Biomarker Testing Logistics
- Pre-screening vs. screening approach
- Central lab vs. local testing
- Tissue vs. liquid biopsy (ctDNA)
- Quality control requirements
```

### Tool Reference for PATH 2
- `ClinVar_get_variant_details` - Variant pathogenicity
- `COSMIC_search_mutations` - Cancer-specific mutation frequencies
- `gnomAD_get_variant_details` - Population genetics
- `PubMed_search_articles` - CDx test performance, guidelines

---

## PATH 3: Comparator Selection

### Objective
Identify the standard of care, evaluate comparator feasibility, and assess trial design options.

### Step-by-Step Execution

**Step 3.1: Find current standard of care**
```python
soc_drug = "osimertinib"

soc_info = tu.tools.drugbank_get_drug_basic_info_by_drug_name_or_id(
    drug_name_or_drugbank_id=soc_drug
)
soc_indications = tu.tools.drugbank_get_indications_by_drug_name_or_drugbank_id(
    drug_name_or_drugbank_id=soc_drug
)
soc_pharmacology = tu.tools.drugbank_get_pharmacology_by_drug_name_or_drugbank_id(
    drug_name_or_drugbank_id=soc_drug
)
```

**Step 3.2: Check FDA Orange Book for approved generics**
```python
orange_book = tu.tools.FDA_OrangeBook_search_drugs(ingredient=soc_drug)
```

**Step 3.3: Find FDA approval details**
```python
fda_approval = tu.tools.FDA_get_drug_approval_history(drug_name=soc_drug)
```

### Report Section Template: Comparator Analysis
```markdown
## 6.1 Standard of Care
**Current SOC**: [Drug name(s)]
- FDA approval: [Year] [★★★: FDA_OrangeBook]
- Efficacy: [ORR/PFS from pivotal trial]
- Limitations: [Resistance, toxicity, access]

**SOC Comparator Feasibility**: [HIGH/MEDIUM/LOW]

## 6.2 Trial Design Options
### Option A: Single-Arm vs. SOC
- **Design**: Phase 2, single-arm, N=[X]
- **Comparator**: Historical SOC data (ORR=[%])
- **Pros**: Faster enrollment, smaller N
- **Cons**: Selection bias, regulatory skepticism
- **Feasibility Score**: [0-100]

### Option B: Randomized vs. SOC
- **Design**: Phase 2, 1:1 randomization, N=[X] per arm
- **Comparator**: Active control ([SOC drug])
- **Pros**: Robust comparison, regulatory preferred
- **Cons**: 2x enrollment, comparator sourcing
- **Feasibility Score**: [0-100]

### Option C: Non-Inferiority Design
- **Rationale**: [If aiming for better safety with similar efficacy]
- **Non-inferiority margin**: [Δ = X%]
- **Sample size**: [N] (larger than superiority)

## 6.3 Comparator Drug Sourcing
- Commercial availability: [Yes/No]
- Patent status: [Generic available?]
- Cost: [$X per course]
- Stability and storage: [Requirements]
```

### Tool Reference for PATH 3
- `drugbank_get_drug_basic_info_by_drug_name_or_id` - Drug info
- `drugbank_get_indications_by_drug_name_or_drugbank_id` - Approved indications
- `drugbank_get_pharmacology_by_drug_name_or_drugbank_id` - Mechanism
- `FDA_OrangeBook_search_drugs` - Generic availability
- `FDA_get_drug_approval_history` - Approval details
- `search_clinical_trials` - Historical control data

---

## PATH 4: Endpoint Selection

### Objective
Select and justify primary/secondary endpoints based on regulatory precedent and measurement feasibility.

### Step-by-Step Execution

**Step 4.1: Search for precedent trials**
```python
precedent_trials = tu.tools.search_clinical_trials(
    condition="EGFR positive non-small cell lung cancer",
    phase="2",
    status="completed"
)
orr_trials = [t for t in precedent_trials['data']
              if 'response rate' in t.get('primary_outcome', '').lower()]
```

**Step 4.2: Find FDA approvals using target endpoint**
```python
orr_approvals = tu.tools.PubMed_search_articles(
    query="FDA approval objective response rate NSCLC accelerated approval",
    max_results=30
)
```

**Step 4.3: Get detailed trial results for sample size justification**
```python
for trial in precedent_trials['data'][:5]:
    nct_id = trial.get('nct_number')
    trial_details = tu.tools.search_clinical_trials(nct_id=nct_id)
    # Extract: ORR, n, confidence intervals
```

### Report Section Template: Endpoint Selection & Justification
```markdown
## 5.1 Primary Endpoint
**Proposed**: [e.g., Objective Response Rate (ORR)]

**Regulatory Precedent** [★★★]:
- [N] FDA approvals in [indication] using ORR (2015-2024)
- Recent example: [Drug] approved [Year] (ORR XX%, n=YY)
- Source: search_clinical_trials, FDA_get_approval_history

**Measurement Feasibility**:
- Assessment method: [RECIST 1.1, irRECIST, etc.]
- Imaging modality: [CT, MRI, PET]
- Assessment frequency: [Every X weeks]
- Independent review: [Yes/No, cost]

**Statistical Considerations**:
- Expected ORR: [%] (based on [source])
- Null hypothesis: [%]
- Sample size: [N] (α=0.05, β=0.20, two-sided)
- Response duration: [Median months]

## 5.2 Secondary Endpoints
| Endpoint | Evidence Grade | Feasibility | Rationale |
|----------|----------------|-------------|-----------|
| Progression-Free Survival (PFS) | ★★★ | High | FDA-accepted, precedent in [trials] |
| Duration of Response (DoR) | ★★☆ | High | Standard in oncology |
| Overall Survival (OS) | ★★★ | Low (early phase) | Follow-up for long-term |
| [Biomarker response] | ★☆☆ | Medium | Exploratory, mechanistic |

## 5.3 Exploratory Endpoints
- Pharmacodynamic biomarkers (proof-of-mechanism)
- ctDNA clearance (liquid biopsy)
- Quality of life (PRO-CTCAE)
- Correlative science (tumor profiling)

## 5.4 Endpoint Risks & Mitigation
- Risk: [Low response rate → sample size inflation]
- Mitigation: [Adaptive design, interim analysis]
```

### Tool Reference for PATH 4
- `search_clinical_trials` - Precedent trials, endpoints used
- `PubMed_search_articles` - FDA acceptance history, endpoint validation
- `FDA_get_drug_approval_history` - Approved endpoints by indication

---

## PATH 5: Safety Endpoints & Monitoring

### Objective
Define safety endpoints, identify mechanism-based toxicities, and create a monitoring plan.

### Step-by-Step Execution

**Step 5.1: Get mechanism-based toxicity from drug class**
```python
class_drug = "erlotinib"  # Example EGFR TKI for class effect reference

class_safety = tu.tools.drugbank_get_pharmacology_by_drug_name_or_drugbank_id(
    drug_name_or_drugbank_id=class_drug
)
class_warnings = tu.tools.FDA_get_warnings_and_cautions_by_drug_name(
    drug_name=class_drug
)
```

**Step 5.2: FAERS data for real-world adverse events**
```python
faers_egfr_tki = tu.tools.FAERS_search_reports_by_drug_and_reaction(
    drug_name="erlotinib",
    limit=500
)
ae_summary = tu.tools.FAERS_count_reactions_by_drug_event(
    medicinalproduct="ERLOTINIB"
)
```

**Step 5.3: Search for DLT definitions in similar trials**
```python
dlt_papers = tu.tools.PubMed_search_articles(
    query="dose limiting toxicity Phase 1 EGFR inhibitor definition",
    max_results=20
)
```

### Report Section Template: Safety Endpoints & Monitoring Plan
```markdown
## 7.1 Primary Safety Endpoint
**Dose-Limiting Toxicity (DLT)** [for Phase 1 component]:
- DLT definition: [Grade 3+ non-hematologic, Grade 4+ hematologic]
- DLT assessment period: [Cycle 1, 28 days]
- Dose escalation rule: [3+3, BOIN, mTPI]

## 7.2 Mechanism-Based Toxicities
**Drug Class**: [Kinase inhibitor, checkpoint inhibitor, etc.]

**Expected Toxicities** [★★★: FAERS, label data]:
| Toxicity | Incidence | Grade 3+ | Monitoring |
|----------|-----------|----------|------------|
| Diarrhea | 60% | 10% | Symptom diary, hydration |
| Rash | 40% | 5% | Dermatology consult PRN |
| Hepatotoxicity | 20% | 3% | LFTs weekly (cycle 1), then q3w |
| [Specific AE] | [%] | [%] | [Plan] |

**Data Source**: FAERS_search_reports (similar drugs), drugbank_get_pharmacology

## 7.3 Organ-Specific Monitoring
### Hepatic
- Baseline: LFTs, hepatitis panel
- Monitoring: AST/ALT/bili weekly (cycle 1), then q3w
- Stopping rule: ALT >5× ULN or bili >3× ULN

### Cardiac
- Baseline: ECG, ECHO if anthracycline history
- Monitoring: ECG q cycle, ECHO if symptoms
- Stopping rule: QTcF >500 ms, LVEF drop >15%

### Renal
- Baseline: Cr, eGFR, urinalysis
- Monitoring: Cr/eGFR q cycle
- Stopping rule: CrCl <30 mL/min

## 7.4 Safety Monitoring Committee (SMC)
- Composition: [3 independent experts: oncologist, toxicologist, biostatistician]
- Review frequency: [After every 6 patients, then quarterly]
- Stopping rules: [≥3 DLTs at dose level, ≥2 drug-related deaths]
```

### Tool Reference for PATH 5
- `drugbank_get_pharmacology_by_drug_name_or_drugbank_id` - Mechanism toxicity
- `FDA_get_warnings_and_cautions_by_drug_name` - FDA black box warnings
- `FAERS_search_reports_by_drug_and_reaction` - Real-world adverse events
- `FAERS_count_reactions_by_drug_event` - AE frequency
- `FAERS_count_death_related_by_drug` - Serious outcomes
- `PubMed_search_articles` - DLT definitions, monitoring strategies

---

## PATH 6: Regulatory Pathway

### Objective
Identify the optimal regulatory pathway, precedents, and interaction plan with FDA.

### Step-by-Step Execution

**Step 6.1: Search for breakthrough therapy designations**
```python
breakthrough_search = tu.tools.PubMed_search_articles(
    query="FDA breakthrough therapy designation NSCLC EGFR mutation",
    max_results=20
)
```

**Step 6.2: Check if indication qualifies for orphan drug status**
```python
# Estimate US prevalence
us_nsclc_annual = 200000  # From epidemiology data
l858r_prevalence = 0.45 * 0.15  # 45% of EGFR+ (15% of NSCLC)
l858r_annual_us = us_nsclc_annual * l858r_prevalence  # ~13,500/year
# Note: Orphan requires <200,000 total prevalence; may not qualify if prevalent
```

**Step 6.3: Find relevant FDA guidance documents**
```python
fda_guidance_search = tu.tools.PubMed_search_articles(
    query="FDA guidance clinical trial endpoints oncology non-small cell lung cancer",
    max_results=15
)
```

### Report Section Template: Regulatory Pathway
```markdown
## 10.1 FDA Pathway Selection
**Recommended**: [505(b)(1) / 505(b)(2) / Breakthrough / Orphan]

**Rationale**:
- [505(b)(1)]: New molecular entity, full development program
- [505(b)(2)]: [If relying on published safety data for similar drugs]
- **Breakthrough Therapy**: [If preliminary evidence of substantial improvement]
  - Criteria: [X-fold ORR vs. SOC in early data]
  - Benefits: Rolling review, frequent FDA meetings
- **Orphan Designation**: [If prevalence <200,000 in US]
  - Eligible if: [Biomarker-defined subtype constitutes orphan population]
  - Benefits: 7-year exclusivity, tax credits, fee waivers

## 10.2 Regulatory Precedents
**Similar Approvals** [★★★]:
- [Drug A]: [Indication], [Year], [Endpoint used], [N=X], [ORR=Y%]
- [Drug B]: [Indication], [Year], [Accelerated approval → full]
- Source: FDA_get_approval_history, drug labels

**FDA Guidance Documents**:
- [Relevant guidance title] (Year)
- Key recommendations: [e.g., ORR acceptable for Phase 2, confirmatory trial needed]

## 10.3 Pre-IND Meeting
**Recommended Topics**:
1. Primary endpoint acceptability (ORR vs. PFS)
2. Biomarker test qualification (CDx plan)
3. Comparator arm (single-arm acceptable?)
4. Pediatric study plan waiver
5. Safety monitoring plan

**Timing**: [3-4 months before IND submission]

## 10.4 IND Timeline
| Milestone | Month | Deliverable |
|-----------|-------|-------------|
| Pre-IND meeting request | -4 | Briefing package |
| Pre-IND meeting | -3 | FDA feedback |
| IND submission | 0 | Complete IND package |
| FDA 30-day review | 1 | Clinical hold or proceed |
| First patient dosed | 1-2 | After IND clearance |
```

### Tool Reference for PATH 6
- `FDA_get_drug_approval_history` - Precedent approvals
- `PubMed_search_articles` - Breakthrough designations, FDA guidance
- `search_clinical_trials` - Regulatory precedents (accelerated approval)

---

## Additional Report Sections (Not Path-Specific)

### Section 8: Study Design Recommendations
```markdown
## 8.1 Recommended Design
**Phase**: [1/2, 1b/2, 2]
**Design Type**: [Single-arm, randomized, basket, umbrella]
**Primary Objective**: [Assess safety and preliminary efficacy]

**Schema**:
[Indication + Biomarker]
    ↓ Screening (Biomarker testing)
    ↓ Enrollment
    ├─ [Phase 1 dose escalation: 3+3 design, N=12-18]
    │   Dose Levels: [X mg, Y mg, Z mg QD]
    │   DLT assessment: Cycle 1 (28 days)
    └─ [Phase 2 expansion: Simon 2-stage, N=43]
        Stage 1: N=13 (≥2 responses to proceed)
        Stage 2: N=30 additional
        Target ORR: 30% (H0: 10%, α=0.05, β=0.20)

## 8.2 Eligibility Criteria
**Inclusion**:
- Age ≥18 years
- Histologically confirmed [disease]
- [Biomarker] positive (central lab confirmed)
- Measurable disease per RECIST 1.1
- ECOG PS 0-1
- Adequate organ function
- [≤1 prior line for advanced disease]

**Exclusion**:
- Brain metastases (unless treated and stable)
- Prior [drug class] therapy
- Active infection, immunodeficiency
- Pregnancy/nursing
- Significant cardiovascular disease

## 8.3 Treatment Plan
- **Dosing**: [X mg PO QD, 28-day cycles]
- **Dose modifications**: [20% reductions for Grade 2+]
- **Duration**: Until progression, toxicity, or 24 months
- **Concomitant meds**: Supportive care allowed, restrictions on CYP3A4 inhibitors

## 8.4 Assessment Schedule
| Assessment | Screening | Cycle 1 | Cycles 2-6 | Cycles 7+ | EOT |
|------------|-----------|---------|------------|-----------|-----|
| History & PE | X | X | X | X | X |
| ECOG PS | X | X | X | X | X |
| Labs (CBC, CMP, LFT) | X | Weekly | q3w | q3w | X |
| Tumor imaging | X | - | q6w | q9w | X |
| ECG | X | - | q3w (if abnormal) | - | X |
| Biomarker (ctDNA) | X | C1D15 | q6w | - | X |
| AE assessment | - | Continuous | Continuous | Continuous | X |
```

### Section 9: Enrollment & Site Strategy
```markdown
## 9.1 Site Selection Criteria
**Required Capabilities**:
- [Biomarker] testing (or central lab partnership)
- Phase 1/2 experience
- GCP compliance, IRB approval
- Access to [patient population]
- Investigator publications in [indication]

**Geographic Distribution**:
- US sites: [N] (target regions: [high-incidence areas])
- International: [Consider Asia if biomarker enriched there]

## 9.2 Enrollment Projections
**Assumptions**:
- Screening rate: [X patients/site/month]
- Screen failure rate: [30%]
- Enrollment rate: [Y patients/site/month]

**Timeline** (N=[total]):
| Milestone | Month | Cumulative Enrolled |
|-----------|-------|---------------------|
| First site activated | 0 | 0 |
| First patient enrolled | 1 | 1 |
| 25% enrollment | [M1] | [0.25N] |
| 50% enrollment | [M2] | [0.5N] |
| 75% enrollment | [M3] | [0.75N] |
| Last patient enrolled | [M4] | [N] |
| Primary analysis | [M4 + follow-up] | - |

## 9.3 Recruitment Strategies
- Physician outreach: Academic consortia, tumor boards
- Patient advocacy groups: [Organization names]
- ClinicalTrials.gov listing (prominent, lay summary)
- Social media: Targeted ads in [indication] communities
- Referral network: Community oncologists
```

### Section 11: Budget & Resource Considerations
```markdown
## 11.1 Cost Drivers
| Item | Cost Estimate | Notes |
|------|---------------|-------|
| Protocol development | $50-100K | CRO or internal |
| IND preparation | $100-200K | CMC, toxicology reports |
| Site activation | $50K/site × [M sites] | IRB, contracts |
| Patient recruitment | $200-500K | Advertising, patient navigation |
| [Biomarker] testing | $[X]/patient | Central lab, CDx |
| Imaging (RECIST) | $3-5K/scan × [N scans] | CT, independent review |
| Drug supply | [Depends on sponsor] | If not sponsor-provided |
| CRO monitoring | $100-300/hour | Site visits, SDV |
| Data management | $150-300K | EDC, database lock |
| Statistical analysis | $50-100K | SAP, CSR |
| **TOTAL (Phase 1/2)** | **$[X-Y]M** | [N patients, M sites] |

## 11.2 Timeline & FTE Requirements
**Duration**: [X months] (enrollment) + [Y months] (follow-up)
**Team**:
- Medical monitor: 0.5 FTE
- Project manager: 0.8 FTE
- Clinical operations: 0.3 FTE
- Data manager: 0.3 FTE
- Biostatistician: 0.2 FTE
```

### Section 12: Risk Assessment
```markdown
## 12.1 Feasibility Risks (High Priority)
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Slow enrollment (biomarker screen fail) | HIGH | HIGH | - Expand sites to [high-prevalence regions]<br>- Allow alternative biomarkers<br>- Liquid biopsy screening |
| Low response rate (ORR <10%) | MEDIUM | CRITICAL | - Interim futility analysis (Simon stage 1)<br>- Lower null hypothesis if justified<br>- Pivot to combination if single-agent weak |
| Unexpected toxicity (>33% DLT rate) | LOW | CRITICAL | - Conservative starting dose<br>- Dose escalation with BOIN (adaptive)<br>- Close SMC oversight |
| Comparator drug supply issues | MEDIUM | MEDIUM | - Secure commercial supply early<br>- Generic sourcing if available |
| Regulatory pushback on single-arm design | MEDIUM | HIGH | - Pre-IND meeting to align<br>- Plan for randomized Phase 2b if needed |

## 12.2 Scientific Risks
- Biomarker hypothesis unvalidated: [Correlative studies to de-risk]
- Patient heterogeneity: [Stratification by [factor]]
- Resistance mechanisms: [Serial biopsies for molecular profiling]
```

### Section 14: Recommendations & Next Steps
```markdown
## 14.1 Final Recommendation
**GO / CONDITIONAL GO / NO-GO**: [Decision]

**Rationale**:
[2-3 paragraphs synthesizing feasibility analysis]

## 14.2 Critical Path to IND
**Immediate Next Steps** (Months 0-3):
- [ ] Request pre-IND meeting with FDA (target Month 1)
- [ ] Initiate CDx partnership for [biomarker] test
- [ ] Secure drug supply (GMP manufacturing, stability)
- [ ] Draft protocol (v1.0) and ICF
- [ ] Site feasibility surveys (target [M] sites)

**IND Preparation** (Months 3-6):
- [ ] Complete CMC section
- [ ] Finalize preclinical package
- [ ] Prepare clinical protocol (incorporate FDA feedback)
- [ ] Develop CRFs and EDC database
- [ ] IND submission (Month 6)

**Post-IND** (Months 6-9):
- [ ] IRB submissions
- [ ] Site contracts and budgets
- [ ] Investigator meeting
- [ ] First patient enrolled (Month 7-8)

## 14.3 Alternative Designs (If Current Design Infeasible)
**Plan B**: [If enrollment too slow]
- Broaden biomarker criteria
- Add international sites
- Basket design

**Plan C**: [If single-arm rejected by FDA]
- Randomized Phase 2 (1:1 vs. SOC)
- Increase sample size to N=86 (43/arm)
- Requires 2x sites and budget

## 14.4 Long-Term Development Strategy
**If Phase 2 Successful**:
- Phase 3 design: Randomized, OS primary endpoint, N=300-500
- Companion diagnostic (CDx): Parallel FDA submission
- Commercial readiness: Manufacturing scale-up
- Patent strategy: File composition-of-matter or method-of-use
```
