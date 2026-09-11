# Literature Retrieval and Citation Standard
# mr-scrna-research-planner

---

## Goal

This module supports **research design justification**, not citation padding. The agent should retrieve a compact, decision-relevant literature set that helps justify:
- why the disease–mechanism combination is biologically plausible
- why the selected MR design is appropriate
- why the selected single-cell modules are methodologically defensible
- whether there are similar published studies and where the novelty gap may lie

---

## Mandatory Search Categories

### 1. Background Biology
Retrieve references that establish the relevance of the mechanism theme to the target disease or phenotype.

Examples:
- ferroptosis in diabetic nephropathy
- immune senescence in pulmonary fibrosis
- obesity-related inflammatory remodeling in osteoarthritis

### 2. Method Justification
Retrieve core references for the methods actually used in the selected plan. Only cite methods that appear in the workflow.

Examples:
- Mendelian randomization assumptions / sensitivity framework
- multivariable MR
- colocalization / SMR HEIDI if present
- Seurat / SingleR / Monocle3 / Slingshot
- CellChat / NicheNet / SCENIC if present

### 3. Similar-Study Precedents
Retrieve studies that resemble the planned analysis in at least one of these dimensions:
- same disease
- same mechanism theme
- same MR + scRNA integration logic
- same translational biomarker framing

### 4. Resource / Dataset References
When a dataset or reference resource is central to the plan, retrieve its canonical citation where possible.

Examples:
- IEU OpenGWAS
- GTEx
- Human Protein Atlas
- GEO dataset-associated paper

---

## Verification Rules

### Verified Citation (the only allowed formal citation status)
A reference may be listed as a formal citation **only when it is directly verified** from a trustworthy record such as:
- PubMed
- PubMed Central
- DOI / Crossref metadata
- official journal / publisher page

Minimum required verified fields:
- title
- first author or consortium / group author
- journal
- year
- at least one persistent identifier or stable access path: **DOI, PMID, PMCID, PubMed link, PMC link, or official publisher landing page**

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
- cite a paper as support if only the abstract snippet or third-party summary was seen and metadata is unverified
- output a formal citation without a DOI or direct stable link

## Output Format

Use the following structure in Section I.

### I1. Core Background References
For each item:
- **Citation**
- **Status**: verified
- **Identifier / Link**: DOI or direct stable link
- **Type**: original study / review / methods / resource
- **Why included**: what design choice it supports
- **Relevant module**: which section of the plan it informs

### I2. Method Justification References
Group by method family:
- MR core
- MR sensitivity / MVMR / colocalization if used
- scRNA core workflow
- advanced modules only if they appear in the chosen config

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
2. Prefer **recent reviews** for broad background and **classic method papers** for foundational methodology.
3. Prefer **same-disease precedent** over merely same-method precedent when discussing novelty.
4. Do not pad the list with unrelated high-impact papers.
5. If the workflow does not use a method, do not cite it just to sound comprehensive.

---

## Minimal Deliverable Standard

Even under Lite configuration, the agent should still provide:
- 2 background references
- 1 MR method reference
- 1 scRNA method reference
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
