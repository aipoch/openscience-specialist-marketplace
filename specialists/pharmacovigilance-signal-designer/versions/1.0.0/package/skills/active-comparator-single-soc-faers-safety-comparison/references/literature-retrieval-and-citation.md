# Literature Retrieval and Citation Standard
# active-comparator-single-soc-faers-safety-comparison-research-planner

---

## Goal

This module supports **research design justification**, not citation padding. The agent should retrieve a compact, decision-relevant literature set that helps justify:
- why the selected drug or safety-domain question is clinically plausible
- why the selected FAERS / disproportionality / comparator / subgroup / onset / seriousness / label-context modules are methodologically defensible
- whether there are similar published pharmacovigilance studies
- where the novelty gap may lie

---

## Mandatory Search Categories

### 1. Background Safety Context
Retrieve references that establish the relevance of the drug–safety-question combination.

Examples:
- antidepressants and neuropsychiatric adverse events
- beta-blockers and psychiatric or CNS safety concern framing
- one-drug post-marketing safety summaries in special populations

### 2. Method Justification
Retrieve core references for the methods actually used in the selected plan. Only cite methods that appear in the workflow.

Examples:
- FAERS database or spontaneous-reporting-system use papers
- disproportionality metrics (ROR / PRR / IC / EBGM)
- case de-duplication and exposure-definition standards
- comparator restriction or sensitivity-framework papers
- time-to-onset characterization papers if present

### 3. Similar-Study Precedents
Retrieve studies that resemble the planned analysis in at least one of these dimensions:
- same drug or drug class
- same safety domain
- same FAERS comparative logic or same single-drug atlas logic
- same subgroup or onset extension

### 4. Resource / Dataset References
When FAERS or another pharmacovigilance resource is central to the plan, retrieve its canonical citation or official documentation reference when possible.

---

## Formal Output Rules

For each item in the final reference pack, include:
- **citation status:** verified only
- **article type:** original study / review / methods / resource paper
- **why included in this design**
- **one-line relevance note tied to a specific module**
- **DOI or direct stable link**

If a candidate reference cannot be verified, do not output it as a formal reference.

If no suitable verified reference is found for a needed module, say:
- **no directly verified reference identified yet**

Do not guess.

---

## Search Failure Behavior

If browsing or citation verification is unavailable:
1. Say so explicitly
2. Output a structured search strategy instead of fake references
3. List the exact evidence gaps still unresolved

Example:
- Need 1 method paper on ROR/PRR signal detection
- Need 1 precedent paper using active comparator restriction in FAERS
- Need 1 background review on the drug-class safety concern

---

## Overclaim Guardrail

References should justify:
- why the study question matters
- why the workflow is methodologically reasonable
- why similar work exists or why there is a gap

References should **not** be used to claim:
- that a FAERS signal proves causality
- that a comparator-restricted signal equals incidence difference
- that a label-gap signal is a confirmed novel adverse reaction
