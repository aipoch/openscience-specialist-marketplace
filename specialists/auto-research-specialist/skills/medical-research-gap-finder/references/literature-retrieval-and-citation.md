# Literature Retrieval and Citation Standard
# medical-research-gap-finder

---

## Goal

This module supports **real gap identification**, not citation padding.
The retrieval layer must be strong enough to justify:
- what the field has already covered,
- what remains unresolved,
- what is merely weakly supported,
- and which “gaps” are too generic to trust.

---

## Mandatory Sources

### 1. PubMed — Primary Biomedical Anchor
Use as the main source for biomedical literature retrieval whenever the topic falls within medicine, translational biology, omics, disease mechanisms, biomarkers, therapeutics, or population health.

### 2. Google Scholar — Broad Recall and Citation Chaining
Use to widen recall, discover adjacent literature, and identify frequently cited or follow-up studies.

### 3. Web of Science — Indexed Coverage and Citation-Network Check
Use when available to check field coverage, identify highly connected records, and inspect whether a topic is crowded or thin.

### 4. Preprint Sources
Use arXiv or other preprint platforms only as explicitly labeled, non-peer-reviewed evidence.
Preprints may inform trend detection or emerging methods, but must not be treated as equivalent to validated peer-reviewed support.

---

## Minimum Retrieval Tasks

### A. Topic Background
Retrieve literature that establishes the core disease / pathway / therapy / method context.

### B. Closest-Topic Studies
Retrieve papers that directly match the requested topic combination.
Example: if the topic is gastric cancer network pharmacology, direct-topic studies must be distinguished from general TCM studies or network pharmacology papers in other cancers.

### C. Study-Type Distribution
Determine what kinds of studies dominate the area:
- review vs original study
- computational prediction vs wet-lab validation
- observational vs mechanistic
- bulk omics vs single-cell / spatial
- discovery-only vs external validation
- preclinical vs clinical / translational

### D. Similar-Question Precedents
Find papers that already answer part of the same scientific question, even if not with the exact same disease/pathway pair.

### E. Contradictory or Limiting Evidence
Retrieve evidence that weakens over-strong novelty claims.
This is mandatory whenever the first-pass literature looks too favorable.

---

## Verification Rules

### Verified Citation — the only allowed formal citation status
A reference may be listed as a formal citation only when its core metadata is directly verified from a trustworthy source such as:
- PubMed record
- PubMed Central record
- official publisher or journal page
- DOI / Crossref-backed metadata page

Minimum required verified fields:
- title
- first author or group author
- journal or source
- year
- at least one persistent identifier or stable link

### Candidate Paper — not verified enough for formal citation
If any core metadata remains uncertain, or if the item was only seen through a search snippet, AI summary, third-party list, or memory, it must not be output as a formal reference.

Allowed handling:
- mention only as a candidate lead
- place it in the search-strategy / evidence-gap notes
- explain why it was excluded from formal citation status

### Forbidden Behavior
Do not:
- invent PMIDs or DOIs
- guess authors, journals, years, or titles from memory
- cite a paper formally when only partial metadata is visible
- treat preprints as peer-reviewed without explicit labeling

---

## Required Retrieval Report

The final output must include a retrieval report with:
- sources searched
- search logic or query logic summary
- retrieval date or recency note
- inclusion / exclusion logic
- rough record counts or equivalent coverage description
- what was found reliably
- what remains uncertain
- which candidate leads were excluded from formal citation

---

## Selection Principles

1. Prefer fewer, more decision-relevant papers over bloated generic lists.
2. Prefer direct-topic evidence over adjacent-topic evidence when making gap claims.
3. Use adjacent evidence only when clearly labeled as transferable, not direct proof.
4. Prefer records with directly verifiable metadata.
5. If retrieval is incomplete, narrow the claim rather than inflating the conclusion.

---

## Failure Handling

If reliable records cannot be confirmed for part of the topic:
- say so clearly
- downgrade the certainty of any gap related to that subtopic
- do not pretend the absence of verified evidence proves novelty
