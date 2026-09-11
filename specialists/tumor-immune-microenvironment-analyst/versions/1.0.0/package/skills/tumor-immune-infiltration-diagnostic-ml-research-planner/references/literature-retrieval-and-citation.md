# Literature Retrieval and Citation Standard
# tumor-immune-infiltration-diagnostic-ml-research-planner

---

## Goal

This module supports **research design justification**, not citation padding. The agent should retrieve a compact, decision-relevant literature set that helps justify:
- why the selected cancer–immune-cell or cancer–immune-microenvironment direction is biologically plausible
- why the selected DEG / immune deconvolution / coexpression / ML diagnostic / nomogram modules are methodologically defensible
- whether there are similar published immune-linked diagnostic biomarker studies
- where the novelty gap may lie

---

## Mandatory Search Categories

### 1. Background Biology
Retrieve references that establish the relevance of the cancer–immune-cell or cancer–immune-state combination.

Examples:
- M2 macrophages in DLBCL or lymphoma microenvironment
- immune-cell-driven diagnostic signatures in solid tumors
- macrophage polarization and tumor progression

### 2. Method Justification
Retrieve core references for the methods actually used in the selected plan. Only cite methods that appear in the workflow.

Examples:
- limma / DESeq2 differential expression
- CIBERSORT / ssGSEA / xCell / MCP-counter
- WGCNA
- LASSO / SVM-RFE / Random Forest
- logistic regression / rms nomogram / calibration / decision curves

### 3. Similar-Study Benchmarking
Retrieve 3–6 representative studies with comparable logic.

Examples:
- immune-cell-related biomarker studies in the same cancer
- diagnostic ML transcriptome studies using public cohorts
- immune-module to biomarker studies with nomogram output

### 4. Novelty / Gap Framing
Retrieve or infer what is already saturated versus what remains underdeveloped:
- same cancer but different immune anchor
- same immune anchor but no diagnostic model
- diagnostic model exists but no external validation
- immune correlation exists but no consensus ML compression

---

## Citation Rules

- Do not invent references.
- Prefer primary method papers and disease-relevant reviews / original studies.
- Keep citations tied to actual modules used in the plan.
- Distinguish clearly between **rationale**, **method**, **benchmark**, and **gap** references.
- If evidence is weak or indirect, say so explicitly.
