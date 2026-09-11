# Study Patterns — Detailed Logic
# nhanes-clinical-retrospective-biomarker-research-planner

---

## Pattern A — Cross-Sectional Association

**Use when:** User starts from disease prevalence association in NHANES or similar survey data.

**Canonical examples:** biomarker and CKD prevalence, inflammatory index and diabetic complication prevalence, metabolic ratio and NAFLD prevalence

**Logic chain:**
1. Define survey cohort and exclusions
2. Define disease outcome
3. Derive biomarker formulas
4. Baseline comparison and crude / adjusted logistic regression
5. Optional quantile analysis and interpretation under observational limits

**Key design decision:** This pattern should stay prevalence-association-centered unless a stronger validation step is explicitly added later.

---

## Pattern B — Dose-Response / RCS

**Use when:** User wants to test whether the biomarker-outcome relationship is linear or nonlinear.

**Canonical examples:** inflammatory index showing linear relationship with complication prevalence, nutritional biomarker with threshold-like association, continuous lab ratio with nonlinearity testing

**Logic chain:**
1. Complete main adjusted model first
2. Keep biomarker as a continuous exposure
3. Run restricted cubic spline model
4. Report overall and nonlinearity p-values
5. Interpret shape conservatively without claiming biological thresholds

**Key design decision:** RCS requires a continuous biomarker, adequate sample support, and explicit caution against overinterpreting turning points.

---

## Pattern C — Subgroup-Stability

**Use when:** User wants to know whether the biomarker association is stable across demographic or clinical strata.

**Canonical examples:** biomarker association across sex, BMI, smoking, hypertension, age groups

**Logic chain:**
1. Prespecify subgroups
2. Run stratified logistic models
3. Compare direction and confidence intervals
4. Add interaction testing if the subgroup story becomes important
5. Keep sparse-strata results conservative

**Key design decision:** Subgroup analysis should be framed as stability / heterogeneity assessment, not automatic discovery of new causal effects.

---

## Pattern D — NHANES + Retrospective Validation

**Use when:** User wants a population-level association analysis plus a smaller clinically grounded retrospective validation cohort.

**Canonical examples:** NHANES inflammatory biomarker association plus hospital case–control validation, population screening logic with local diabetic-complication validation

**Logic chain:**
1. Complete NHANES-based main association workflow
2. Build retrospective case–control or matched validation set
3. Replicate biomarker direction and adjusted association
4. Compare consistency of effect direction and magnitude
5. Optionally add exploratory ROC

**Key design decision:** The validation cohort strengthens orthogonal consistency, but does not convert the study into a causal or true prediction design.

---

## Pattern E — Preliminary Screening-Performance

**Use when:** User wants ROC / AUC / exploratory discrimination as a secondary endpoint, usually in the retrospective validation cohort.

**Canonical examples:** compare biomarker AUCs in a local hospital cohort, secondary discrimination analysis after main association result

**Logic chain:**
1. Fix the main association result first
2. Restrict ROC to a clearly labeled secondary analysis
3. Report AUC with caution and no overclaiming of screening performance
4. Avoid threshold-optimization hype in small retrospective cohorts

**Key design decision:** This pattern is usually secondary, not primary, and should not masquerade as a full prediction-model paper.

---

## Pattern Combination Rules

| Combination | When Appropriate |
|---|---|
| A + B | Main association plus spline characterization |
| A + C | Main association plus subgroup-stability assessment |
| D + E | NHANES association plus retrospective ROC secondary endpoint |
| D + B | NHANES association plus RCS plus retrospective validation |
| D + C | NHANES association plus subgroup stability plus retrospective validation |

Combining > 2 patterns typically requires Advanced or Publication+ workload.
