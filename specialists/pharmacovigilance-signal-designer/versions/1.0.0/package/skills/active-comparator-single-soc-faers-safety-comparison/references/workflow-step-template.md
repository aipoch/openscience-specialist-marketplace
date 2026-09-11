# Workflow Step Template
# active-comparator-single-soc-faers-safety-comparison-research-planner

---

## Required Step Format

Every workflow step in the final answer must follow the exact 8-field format below.

Before the first step, always output this exact line if any public resource is mentioned:

> **Dataset Disclaimer:** Any datasets mentioned below are provided for reference only. Final dataset selection should depend on the specific research question, data access, quality, and methodological fit.

This disclaimer is mandatory whenever data sources are mentioned in the workflow and must not be omitted, paraphrased away, or moved to another section.

```
Step Name:        Short descriptive label
Purpose:          What this step accomplishes in the overall pipeline
Input:            Exact data / files / outputs from prior steps needed
Method:           Specific tool(s) and algorithm(s) — explain WHY this choice
                  over the main alternative(s)
Key Parameters /
Decision Rules:   Thresholds, cutoffs, acceptance criteria — be specific
Expected Output:  File format + content description + what "success" looks like
Failure Points:   What could go wrong; how to detect it; what it looks like
Alternative
Approaches:       Backup tool/method if primary fails or data doesn't support it
```

---

## Standard Step Sequence (adapt to selected pattern and config)

### Data and Scope Block

1. **Case Extraction, Exposure Definition, and Scope Harmonization**
2. **AE Dictionary Mapping and Safety-Domain Definition**
3. **Primary Signal Detection**
4. **Initial Signal Compression and Candidate Prioritization**

### Comparative / Characterization Block

5. **Comparator Restriction or Global Atlas Construction**
6. **Subgroup / Within-Class / Characterization Extension**
7. **Signal Selection Compression to Final Story Endpoint**
8. **Robustness and Sensitivity Analysis**
9. **Integrated Safety Interpretation and Claim Boundary Review**

### Reporting Block

10. **Figure Assembly and Supplementary Table Packaging**
11. **Reference Pack and Evidence-Gap Mapping**
12. **Integrated Evidence and Limitation Summary Figure**

---

## Step Ordering Rules

- Extraction and dictionary mapping must occur before any signal analysis.
- Comparator restriction or whole-profile scope must be fixed before downstream interpretation.
- Subgroup, seriousness, or onset modules should appear only after the primary signal route is complete.
- A final signal story must not be selected before ranking and compression logic is declared.
- Robustness analysis should appear before final claims are summarized.
- If the plan is FAERS-only, language must remain conservative.

---

## Intersection Formula Requirement

Every step that prioritizes, filters, or selects events must explicitly declare its logic formula. Do not omit this or switch formulas silently between configurations.

```
Intersection Formula: [e.g., suspect-drug cases ∩ fixed SOC PTs ∩ ROR-positive signals ∩ comparator-stable signals]
Dependency Check:     [list what data/analyses this formula requires]
```

If a formula requires a field or restriction not declared in the configuration, use the reduced formula and note the limitation.

---

## Upgrade-Only Module Labeling

When the Step-by-Step Workflow for Advanced or Publication+ introduces a module not present in Lite/Standard, label it explicitly:

```
[UPGRADE-ONLY — Advanced+]
Module: e.g., Alternate denominator robustness comparison
Newly Introduced: Yes
Reason for Addition: Tests whether the primary signal depends too heavily on one restriction choice
New Evidence Tier Enabled: Stronger robustness support
```

Do not back-propagate upgrade-only modules into the Lite or Standard sections.
