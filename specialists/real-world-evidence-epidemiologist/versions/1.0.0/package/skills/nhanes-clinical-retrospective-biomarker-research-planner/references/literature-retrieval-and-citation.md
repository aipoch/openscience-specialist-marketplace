# Literature Retrieval and Citation Standard
# nhanes-clinical-retrospective-biomarker-research-planner

---

## Goal

This module supports **research design justification**, not citation padding. The agent should retrieve a compact, decision-relevant literature set that helps justify:
- why the target disease / complication matters clinically and epidemiologically
- why the selected biomarker family is biologically plausible
- why NHANES-style cross-sectional analysis plus logistic modeling, RCS, subgroup analysis, and retrospective validation are methodologically defensible
- whether similar observational biomarker studies already exist
- where the novelty gap remains

---

## Mandatory Search Categories

### 1. Background Disease and Biomarker Relevance
Retrieve references that establish:
- disease burden or complication relevance
- why the biomarker family could plausibly relate to disease status
- whether similar inflammatory / hematologic / nutritional indices have precedent in the disease area

### 2. Method Justification
Retrieve core references for the methods actually used in the selected plan:
- NHANES / NCHS / CDC survey resource references
- logistic regression / observational epidemiology reporting guidance
- restricted cubic spline references if used
- subgroup / interaction references if used
- retrospective case–control validation references if used
- ROC / discrimination reporting references if used

### 3. Similar-Study Precedents
Retrieve studies that resemble the planned analysis in at least one of these dimensions:
- same disease
- same biomarker family
- same NHANES / observational article logic
- same survey + hospital-validation hybrid logic

### 4. Resource / Dataset References
When a dataset or reporting framework is central to the plan, retrieve its canonical citation where possible.

Examples:
- NHANES / NCHS / CDC
- STROBE or similar observational reporting guidance
- disease-definition guideline source if it is central to case ascertainment

---

## Verification Rules

### Verified Citation (the only allowed formal citation status)
A reference may be listed as a formal citation **only when it is directly verified** from a trustworthy record such as:
- PubMed
- PubMed Central
- DOI / Crossref metadata
- official journal / publisher page
- official CDC / NCHS / institutional resource page

Minimum required verified fields:
- title
- first author or consortium / group author
- journal or source
- year
- at least one persistent identifier or stable access path: **DOI, PMID, PMCID, PubMed link, PMC link, official resource page, or official publisher landing page**

### Not Verified Enough for Formal Citation
If any core metadata remains uncertain, or if no DOI / stable link can be confirmed, the item must **not** be output as a formal reference.

Allowed handling:
- mention it only inside **I4. Search Strategy and Evidence Gaps**
- label it as a candidate paper or unverified lead
- explain which metadata is missing or why the record was excluded

### Forbidden Behavior
Do not:
- invent PMIDs or DOIs
- guess missing author lists
- infer journal / volume / issue / pages from memory alone
- cite causal or prognostic literature as if it directly validates a cross-sectional prevalence association
- output a formal citation without a DOI, PMID, PMCID, or direct stable link

## Output Format

Use the following structure in Section I.

### I1. Core Background References
For each item:
- **Citation**
- **Status**: verified
- **Identifier / Link**: DOI, PMID, PMCID, or direct stable link
- **Type**: original study / review / methods / resource
- **Why included**: what design choice it supports
- **Relevant module**: which section of the plan it informs

### I2. Method Justification References
Group by method family:
- NHANES / survey resource
- logistic / observational core
- RCS / subgroup / interaction only if used
- retrospective validation / ROC only if used

### I3. Similar-Study Precedents
For each item:
- similarity dimension
- what it already did
- what novelty space remains for the current plan

### I4. Search Strategy and Evidence Gaps
Must include:
- databases / sources searched
- keyword logic or query logic
- date or recency scope if used
- what was found reliably
- what was not found reliably
- which modules currently lack directly verified supporting references
- which candidate papers were excluded because DOI/link or metadata could not be verified

---

## Selection Principles

1. Prefer **fewer, high-relevance references** over long generic lists.
2. Prefer **recent reviews** for broad background and **classic method or survey-resource papers** for foundational methodology.
3. Prefer **same-disease precedent** over merely same-method precedent when discussing novelty.
4. Do not pad the list with unrelated high-impact papers.
5. If the workflow does not use a method, do not cite it just to sound comprehensive.

---

## Minimal Deliverable Standard

Even under Lite configuration, the agent should still provide:
- 2 background references
- 1 NHANES / observational method reference
- 1 analysis-method reference if relevant
- 1 similar-study or resource reference if available
- 1 explicit evidence-gap note

---

## Failure Handling

If reliable references cannot be verified for some modules:
- say so clearly
- keep the module if it remains methodologically valid
- output **no directly verified reference identified yet** for that slot
- flag it as **needs manual citation verification before manuscript drafting**

If browsing/search is unavailable:
- do not output guessed references
- instead output a precise search plan with query categories and target article types
