# Literature Retrieval and Citation Standard
# mendelian-randomization-protocol-designer

---

## Goal

This module supports **research design justification**, not citation padding. The agent should retrieve a compact, decision-relevant literature set that helps justify:
- why the exposure and outcome matter clinically or biologically
- why MR is appropriate for this question
- why the selected MR pattern (simple, reverse-check, bidirectional, MVMR, mechanistic follow-up) is justified
- whether similar MR studies already exist
- where the novelty gap remains

---

## Verification Rules

### Verified Citation (the only allowed formal citation status)
A reference may be listed as a formal citation **only when it is directly verified** from a trustworthy record such as:
- PubMed
- PubMed Central
- DOI / Crossref metadata
- official journal / publisher page
- official consortium / resource page

Minimum required verified fields:
- title
- first author or consortium / group author
- journal or source
- year
- at least one persistent identifier or stable access path: **DOI, PMID, PMCID, PubMed link, PMC link, official resource page, or official publisher landing page**

### Not Verified Enough for Formal Citation
If any core metadata remains uncertain, or if no DOI / stable link can be confirmed, the item must **not** be output as a formal reference.

### Forbidden Behavior
Do not:
- invent PMIDs or DOIs
- guess missing author lists
- infer journal / volume / issue / pages from memory alone
- output a formal citation without a DOI, PMID, PMCID, or direct stable link

---

## Output Format

### K1. Core Background References
### K2. Method Justification References
### K3. Similar-Study Precedents
### K4. Search Strategy and Evidence Gaps

If reliable references cannot be verified for some modules:
- say so clearly
- output **no directly verified reference identified yet** for that slot
