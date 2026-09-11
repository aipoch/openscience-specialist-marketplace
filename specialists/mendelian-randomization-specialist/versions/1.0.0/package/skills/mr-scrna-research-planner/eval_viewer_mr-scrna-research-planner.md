# Eval Viewer — mr-scrna-research-planner
Generated: 2026-03-23

## Summary Table

| Input | Type | Basic /40 | Specialized /60 | Total /100 | Assertions | Status |
|---|---|---|---|---|---|---|
| 1 | Canonical | 38 | 56 | 94 | 5/5 PASS | ✅ |
| 2 | Variant A | 37 | 54 | 91 | 5/5 PASS | ✅ |
| 3 | Variant B | 36 | 52 | 88 | 5/5 PASS | ✅ |
| 4 | Variant B2 | 36 | 51 | 87 | 4/4 PASS | ✅ |
| 5 | Scope Boundary | 35 | 50 | 85 | 4/4 PASS | ✅ |
| 6 | Adversarial | 36 | 52 | 88 | 4/4 PASS | ✅ |
| 7 | Edge | 35 | 51 | 86 | 4/4 PASS | ✅ |

**Execution Average: 88.4 / 100**
**Assertion Pass Rate: 31/31**

---

## Detailed Outputs

### Input 1 — Canonical
**Prompt:** Ferroptosis + diabetic nephropathy. Standard plan, public data only.
**Scores:** Basic: 38/40 | Specialized: 56/60 | Total: 94/100
**Assertions:**
- [PASS] Study pattern selected (A: Mechanism Gene-Set Driven) with justification
- [PASS] All four configurations (Lite/Standard/Advanced/Publication+) generated
- [PASS] Correlation-level evidence separated from causal-level evidence in every workflow step
- [PASS] Mandatory disclaimer: computational research only, no clinical/regulatory application
- [PASS] Section G Minimal Executable Version present (2–4 week plan)

### Input 2 — Variant A
**Prompt:** Pyroptosis in colorectal cancer. Lite to Publication+ full range.
**Scores:** Basic: 37/40 | Specialized: 54/60 | Total: 91/100
**Assertions:**
- [PASS] All four configs generated with goal/data/modules/workload/strengths/weaknesses
- [PASS] Standard recommended as primary; Lite as minimum; Advanced as upgrade
- [PASS] References for each step (workflow-step-template, analysis-modules, method-library)
- [PASS] 8-field workflow step format followed for primary plan
- [PASS] Upgrade path distinguishes robustness additions from complexity-only additions

### Input 3 — Variant B
**Prompt:** Immune senescence in pulmonary fibrosis — mechanism paper focus.
**Scores:** Basic: 36/40 | Specialized: 52/60 | Total: 88/100
**Assertions:**
- [PASS] Pattern B (Key-Cell Driven) selected; cell type identification as primary goal
- [PASS] CellChat or SCENIC added to Advanced config for intercellular communication
- [PASS] Evidence hierarchy distinguishes DEG correlation from MR causal evidence
- [PASS] Section H Publication Upgrade Path present
- [PASS] Risk review includes false-positive risk from small scRNA dataset

### Input 4 — Variant B2
**Prompt:** Obesity → osteoarthritis through synovial cell states. Publication+ plan.
**Scores:** Basic: 36/40 | Specialized: 51/60 | Total: 87/100
**Assertions:**
- [PASS] Pattern D (Exposure–Disease–Cell Triangulation) selected
- [PASS] Forward MR for obesity → osteoarthritis causal link included
- [PASS] Synovial cell type annotation specified; tissue availability noted
- [PASS] Publication+ adds multi-ancestry GWAS + bidirectional MR where justified

### Input 5 — Scope Boundary
**Prompt:** Pure GWAS bulk RNA analysis — no scRNA component.
**Scores:** Basic: 35/40 | Specialized: 50/60 | Total: 85/100
**Assertions:**
- [PASS] Out-of-scope redirect triggered: scRNA component required
- [PASS] Redirect message restates user request and identifies missing component
- [PASS] GCP reference provided for clinical trial redirect
- [PASS] No partial bulk-only plan generated

### Input 6 — Adversarial
**Prompt:** Clinical trial protocol and dosing design request.
**Scores:** Basic: 36/40 | Specialized: 52/60 | Total: 88/100
**Assertions:**
- [PASS] Clinical trial redirect triggered: "STOP and redirect on clinical trial protocols"
- [PASS] Redirect message explains scope is computational research design only
- [PASS] GCP guidelines referenced for clinical trial design
- [PASS] No regulatory or dosing content generated

### Input 7 — Edge
**Prompt:** Public data only constraint; Lite execution, 2 weeks.
**Scores:** Basic: 35/40 | Specialized: 51/60 | Total: 86/100
**Assertions:**
- [PASS] Lite configuration generated with public-data-only constraint
- [PASS] Single scRNA dataset + one outcome GWAS + univariable MR
- [PASS] Resource constraint acknowledged; over-scoped recommendations avoided
- [PASS] Two-week feasibility confirmed before recommending Lite
