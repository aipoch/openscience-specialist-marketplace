# Complete Examples & Troubleshooting

Detailed example workflows and common pitfalls. For overview, see main [SKILL.md](../SKILL.md).

---

## Complete Example: EGFR L858R+ NSCLC Phase 1/2 Trial

```python
from tooluniverse import ToolUniverse

tu = ToolUniverse(use_cache=True)
tu.load_tools()

# ============================================================================
# PATH 1: PATIENT POPULATION SIZING
# ============================================================================

# Step 1.1: Get disease prevalence
disease_info = tu.tools.OpenTargets_get_disease_id_description_by_name(
    diseaseName="non-small cell lung cancer"
)
efo_id = disease_info['data']['id']

phenotypes = tu.tools.OpenTargets_get_diseases_phenotypes(
    efoId=efo_id
)

# Step 1.2: Estimate EGFR mutation prevalence
egfr_variants = tu.tools.ClinVar_search_variants(
    gene="EGFR",
    significance="pathogenic,likely_pathogenic"
)

l858r_variants = [v for v in egfr_variants['data']
                  if 'L858R' in v.get('name', '')]

gnomad_egfr = tu.tools.gnomAD_search_gene_variants(gene="EGFR")

# Step 1.3: Search literature for epidemiology
epi_papers = tu.tools.PubMed_search_articles(
    query="EGFR L858R prevalence non-small cell lung cancer epidemiology",
    max_results=20
)

# ============================================================================
# PATH 2: BIOMARKER PREVALENCE & TESTING
# ============================================================================

# Step 2.1: Find FDA-approved CDx tests
cdx_search = tu.tools.PubMed_search_articles(
    query="FDA approved companion diagnostic EGFR L858R",
    max_results=10
)

# Step 2.2: Literature on EGFR testing in clinical practice
testing_papers = tu.tools.PubMed_search_articles(
    query="EGFR mutation testing guidelines NCCN turnaround time",
    max_results=15
)

# ============================================================================
# PATH 3: COMPARATOR SELECTION
# ============================================================================

# Step 3.1: Find current standard of care (osimertinib)
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

# Step 3.2: Check FDA Orange Book for approved generics
orange_book = tu.tools.FDA_OrangeBook_search_drugs(ingredient=soc_drug)

# Step 3.3: Find FDA approval details
fda_approval = tu.tools.FDA_get_drug_approval_history(drug_name=soc_drug)

# ============================================================================
# PATH 4: ENDPOINT SELECTION
# ============================================================================

# Step 4.1: Search for precedent Phase 2 trials in EGFR+ NSCLC
precedent_trials = tu.tools.search_clinical_trials(
    condition="EGFR positive non-small cell lung cancer",
    phase="2",
    status="completed"
)

orr_trials = [t for t in precedent_trials['data']
              if 'response rate' in t.get('primary_outcome', '').lower()]

# Step 4.2: Find FDA approvals using ORR as primary endpoint
orr_approvals = tu.tools.PubMed_search_articles(
    query="FDA approval objective response rate NSCLC accelerated approval",
    max_results=30
)

# Step 4.3: Get detailed trial results for sample size justification
for trial in precedent_trials['data'][:5]:
    nct_id = trial.get('nct_number')
    trial_details = tu.tools.search_clinical_trials(nct_id=nct_id)

# ============================================================================
# PATH 5: SAFETY ENDPOINTS & MONITORING
# ============================================================================

# Step 5.1: Get mechanism-based toxicity from drug class
class_drug = "erlotinib"

class_safety = tu.tools.drugbank_get_pharmacology_by_drug_name_or_drugbank_id(
    drug_name_or_drugbank_id=class_drug
)

class_warnings = tu.tools.FDA_get_warnings_and_cautions_by_drug_name(
    drug_name=class_drug
)

# Step 5.2: FAERS data for real-world adverse events
faers_egfr_tki = tu.tools.FAERS_search_reports_by_drug_and_reaction(
    drug_name="erlotinib",
    limit=500
)

ae_summary = tu.tools.FAERS_count_reactions_by_drug_event(
    medicinalproduct="ERLOTINIB"
)

# Step 5.3: Search for DLT definitions in similar trials
dlt_papers = tu.tools.PubMed_search_articles(
    query="dose limiting toxicity Phase 1 EGFR inhibitor definition",
    max_results=20
)

# ============================================================================
# PATH 6: REGULATORY PATHWAY
# ============================================================================

# Step 6.1: Search for breakthrough therapy designations in NSCLC
breakthrough_search = tu.tools.PubMed_search_articles(
    query="FDA breakthrough therapy designation NSCLC EGFR mutation",
    max_results=20
)

# Step 6.2: Check if indication qualifies for orphan drug status
us_nsclc_annual = 200000
l858r_prevalence = 0.45 * 0.15
l858r_annual_us = us_nsclc_annual * l858r_prevalence  # ~13,500/year

# Step 6.3: Find relevant FDA guidance documents
fda_guidance_search = tu.tools.PubMed_search_articles(
    query="FDA guidance clinical trial endpoints oncology non-small cell lung cancer",
    max_results=15
)

# ============================================================================
# COMPILE FEASIBILITY REPORT
# ============================================================================

feasibility_scores = {
    'patient_availability': 8,
    'endpoint_precedent': 9,
    'regulatory_clarity': 7,
    'comparator_feasibility': 9,
    'safety_monitoring': 8
}

weights = {
    'patient_availability': 0.30,
    'endpoint_precedent': 0.25,
    'regulatory_clarity': 0.20,
    'comparator_feasibility': 0.15,
    'safety_monitoring': 0.10
}

overall_score = sum(feasibility_scores[k] * weights[k] * 10 for k in weights.keys())

print(f"Feasibility Score: {overall_score}/100 - HIGH")
print("Recommendation: RECOMMEND PROCEED to protocol development")
```

---

## Example Use Cases

### Use Case 1: Biomarker-Selected Oncology Trial
**Query**: "Assess feasibility of Phase 2 trial for EGFR L858R+ NSCLC, ORR primary endpoint"

**Workflow**:
1. Disease prevalence: 200K NSCLC/year × 15% EGFR+ = 30K
2. Biomarker: L858R is 45% of EGFR+ → 13.5K/year
3. Eligible: 60% → 8K/year
4. Endpoint: ORR accepted (osimertinib precedent)
5. Comparator: Osimertinib (ORR 57%, generic available)
6. Feasibility: HIGH (82/100) → RECOMMEND PROCEED

### Use Case 2: Rare Disease Trial
**Query**: "Feasibility of trial in Niemann-Pick Type C (prevalence 1:120,000)"

**Workflow**:
1. US prevalence: ~2,750 patients total, ~25 new cases/year
2. Endpoint challenge: No validated clinical outcome
3. Orphan drug: QUALIFIED (7-year exclusivity)
4. Comparator: No approved drugs → single-arm feasible
5. Enrollment: Multi-year, need ALL US centers
6. Feasibility: MODERATE (58/100) → CONDITIONAL GO (requires patient registry partnership)

### Use Case 3: Superiority Trial vs. Standard of Care
**Query**: "Phase 2b design for new checkpoint inhibitor vs. pembrolizumab in PD-L1 high NSCLC"

**Workflow**:
1. Patient availability: 40K PD-L1 high NSCLC/year (HIGH)
2. Endpoint: ORR for Phase 2b, plan OS for Phase 3
3. Comparator: Pembrolizumab (ORR 45%, PFS 10mo) - readily available
4. Design: Randomized 1:1, N=120 (60/arm) for 20% ORR improvement
5. Feasibility: HIGH (78/100) → RECOMMEND PROCEED

### Use Case 4: Non-Inferiority Trial
**Query**: "Non-inferiority trial for oral anticoagulant vs. warfarin"

**Workflow**:
1. Patient availability: 2M AFib patients, 600K on warfarin (HIGH)
2. Endpoint: Stroke/SE (FDA-accepted, but requires large N)
3. Non-inferiority margin: HR <1.5 (FDA guidance)
4. Sample size: N=5,000+ for 90% power → LARGE trial
5. Comparator: Warfarin generic, INR monitoring standard
6. Feasibility: MODERATE (65/100) - large N drives cost and timeline

### Use Case 5: Basket Trial (Multiple Cancers, One Biomarker)
**Query**: "Basket trial for NTRK fusion+ solid tumors (15 histologies)"

**Workflow**:
1. Patient availability: NTRK fusions rare (<1% across cancers) → Broad screening
2. Biomarker testing: NGS required (FDA-approved FoundationOne CDx)
3. Endpoint: ORR (precedent: larotrectinib approval, ORR 75%, n=55)
4. Design: Single-arm, N=15-20 per histology × 5-10 histologies
5. Regulatory: Tissue-agnostic approval precedent (★★★: pembrolizumab MSI-H)
6. Feasibility: MODERATE (62/100) - enrollment slow but feasible with broad screening

---

## Common Pitfalls to Avoid

### ❌ Don't: Show Tool Outputs to User
```markdown
# BAD
OpenTargets returned:
{
  "data": {
    "id": "EFO_0003060",
    "name": "non-small cell lung carcinoma"
  }
}
```

### ✅ Do: Present Synthesized Report
```markdown
# GOOD
## Disease Background
Non-small cell lung cancer (NSCLC) represents 85% of lung cancers, with
~200,000 new cases annually in the US [★★★: CDC WONDER]. EGFR mutations
occur in 15% of Caucasian and 50% of Asian patients [★★★: PMID:23816960].
*Source: OpenTargets, ClinVar*
```

### ❌ Don't: Make Unsupported Claims
```markdown
# BAD
ORR of 60% is expected based on preclinical data.
```

### ✅ Do: Ground in Evidence
```markdown
# GOOD
ORR of 30-40% is projected [★★☆] based on:
- Similar EGFR TKI (erlotinib): 32% ORR in EGFR+ NSCLC (NCT00949650)
- Our drug's 2× IC50 potency vs. erlotinib (preclinical)
*Source: ClinicalTrials.gov, internal data*
```

### ❌ Don't: Ignore Geographic Variation
```markdown
# BAD
EGFR L858R prevalence: 7% of NSCLC
```

### ✅ Do: Specify Geography
```markdown
# GOOD
EGFR L858R prevalence [★★★: COSMIC, ClinVar]:
- Caucasian (US/EU): 6-7% of NSCLC
- East Asian: 20-25% of NSCLC
→ Trial site strategy: Include Asian sites for 2× enrollment
```

---

## Best Practices

### 1. Start with Report Template
Create full report structure FIRST, then populate:
```markdown
# Clinical Trial Feasibility Report: [INDICATION]
## 1. Executive Summary
[Researching...]
## 2. Disease Background
[Researching...]
[...all 14 sections...]
```

### 2. Use English for All Tool Calls
Even if user asks in another language:
- "EGFR+ NSCLC" not "EGFR+ non-small cell lung cancer (in Chinese)"
- "breast cancer" not "cancer du sein"
- Translate results back to user's language

### 3. Validate Biomarker Prevalence Across Sources
Cross-check ClinVar, gnomAD, COSMIC, and literature:
- ClinVar: Clinical significance
- gnomAD: Population frequency (for germline)
- COSMIC: Somatic mutation frequency in cancers
- Literature: Geographic/ethnic variation

### 4. Calculate Enrollment Funnel Explicitly
Show math for patient availability:
```
US NSCLC incidence: 200,000/year
× EGFR+ prevalence: 15% = 30,000
× L858R within EGFR+: 45% = 13,500
× Eligible (age, PS, prior Tx): 60% = 8,100
÷ Competing trials: 3 = 2,700 available/year

For N=43, need 43/2,700 = 1.6% capture rate → Achievable
```

### 5. Evidence Grade Every Key Claim
```markdown
EGFR L858R prevalence is 45% of EGFR+ NSCLC [★★★: PMID:12345, large
sequencing study n=1,500]. *Source: ClinVar, COSMIC*
```

### 6. Provide Regulatory Precedent Details
Not just "ORR is accepted" but:
```markdown
ORR is FDA-accepted for accelerated approval in NSCLC [★★★: FDA approvals]:
- Osimertinib (2015): ORR 57%, n=411, Tx-resistant EGFR+ (NCT01802632)
- Dacomitinib (2018): ORR 45%, n=452, 1L EGFR+ (NCT01774721)
- [3 more examples]
```

### 7. Address Feasibility Risks Proactively
For each HIGH risk, provide mitigation:
```markdown
Risk: Biomarker screen failure rate >70%
→ Mitigation: Liquid biopsy pre-screening (ctDNA EGFR, 7-day turnaround)
```

### 8. Separate Phase 1 and Phase 2 Components
If combined Phase 1/2:
- Phase 1: Safety, DLT, RP2D (N=12-18, 3+3 or BOIN)
- Phase 2: Efficacy, ORR (N=43, Simon 2-stage)
- Distinct success criteria for each phase

---

## Integration with Other Skills

### Works Well With
- **tooluniverse-drug-research**: Investigate mechanism, preclinical data
- **tooluniverse-disease-research**: Deep dive on disease biology
- **tooluniverse-target-research**: Validate drug target, essentiality
- **tooluniverse-pharmacovigilance**: Post-market safety for comparator drugs
- **tooluniverse-precision-oncology**: Biomarker biology, resistance mechanisms

### Complementary Analyses
After feasibility report, consider:
1. **Budget model**: Use cost estimates to build financial model
2. **Site feasibility surveys**: Validate enrollment projections with sites
3. **Regulatory strategy document**: Detailed FDA interaction plan
4. **Statistical analysis plan (SAP)**: Translate design into statistical methods

---

## Version Information

- **Version**: 1.0.0
- **Last Updated**: February 2026
- **Compatible with**: ToolUniverse 0.5+
- **Focus**: Phase 1/2 early clinical development

---

## Support & Resources

- **ToolUniverse Docs**: https://zitniklab.hms.harvard.edu/ToolUniverse/
- **FDA Guidance Documents**: https://www.fda.gov/regulatory-information/search-fda-guidance-documents
- **ClinicalTrials.gov**: https://clinicaltrials.gov/
- **Slack Community**: https://join.slack.com/t/tooluniversehq/shared_invite/zt-3dic3eoio-5xxoJch7TLNibNQn5_AREQ
