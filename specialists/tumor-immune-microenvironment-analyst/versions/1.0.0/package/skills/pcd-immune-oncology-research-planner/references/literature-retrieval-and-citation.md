# Literature Retrieval and Citation Standard
# pcd-immune-oncology-research-planner

---

## Goal

This module supports **research design justification**, not citation padding. The agent should retrieve a compact, decision-relevant literature set that helps justify:
- why the selected PCD / RCD mechanism is relevant to the target cancer
- why clustering and prognostic modeling are appropriate for the question
- why the chosen immune-analysis modules are methodologically defensible
- whether drug-sensitivity prediction is a reasonable computational add-on and what its limits are
- where similar studies already exist and where the novelty gap remains

---

## Mandatory Search Categories

### 1. Background Biology
Retrieve references that establish the relevance of the selected cell-death mechanism to the target cancer.

Examples:
- ferroptosis in hepatocellular carcinoma
- pyroptosis in colorectal cancer
- mixed programmed cell death in gastric adenocarcinoma

### 2. Method Justification
Retrieve core references for the methods actually used in the chosen configuration:
- limma / differential expression
- ConsensusClusterPlus clustering
- GSVA / ssGSEA
- glmnet / LASSO-Cox
- maftools mutation analysis
- TIDE / TMB context if used
- oncoPredict / GDSC / PRISM / CTRP if used

### 3. Similar-Study Precedent
Retrieve studies with the same or closely related article logic:
- curated death-related genes → subtype discovery
- death-related genes → prognostic signature
- death-related genes → immune landscape + drug sensitivity

### 4. Evidence Gaps
Actively identify what is **not** well supported.
Examples:
- limited same-cancer precedent for a specific death mechanism
- no directly validated drug-screen follow-up
- no treated-ICI cohort validation

---

## Formal Output Standard

Every formal reference must include:
- verified citation status only
- article type (original / review / methods / resource)
- why it is included in the study design
- one-line relevance note linked to a specific module
- **DOI or direct stable link**

Allowed stable links include:
- DOI link
- PubMed
- PMC
- official journal / publisher landing page

Not allowed:
- guessed citations
- incomplete placeholders
- "probably this paper"
- unverifiable preprints presented as established evidence without clear labeling

If no verified reference is found:
- say **"no directly verified reference identified yet"**
- describe what search was attempted
- specify what evidence is still needed

---

## Retrieval Prioritization

1. Disease + mechanism review or original study
2. Method papers for modules actually used
3. Same-cancer precedent using similar framework
4. Closely related cancer precedent if same-cancer evidence is sparse

Prefer:
- recent reviews for biology framing
- canonical method papers for core pipelines
- disease-specific original studies for precedent

---

## Claim-Limitation Rule

If a cited study used only computational analyses, do not cite it as if it experimentally proved mechanism or therapy response.
The agent must preserve the evidence tier of the original paper.
