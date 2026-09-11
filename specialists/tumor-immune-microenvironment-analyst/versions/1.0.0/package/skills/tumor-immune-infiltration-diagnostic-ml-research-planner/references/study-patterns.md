# Study Patterns — Detailed Logic
# tumor-immune-infiltration-diagnostic-ml-research-planner

---

## Pattern A — Immune-Cell-First Diagnostic Workflow

**Use when:** User starts from a specific immune cell (for example macrophages, CD8 T cells, neutrophils) and wants a diagnostic biomarker story anchored to that immune axis.

**Canonical examples:** M2 macrophage-related genes in DLBCL, CD8 T-cell-linked diagnostic biomarkers in HCC, neutrophil-related diagnostic markers in CRC.

**Logic chain:**
1. Select disease vs control cohorts
2. Perform preprocessing and DEG analysis
3. Estimate immune infiltration
4. Identify disease-differential immune cell(s)
5. Build immune-linked modules / intersections
6. Compress to candidate biomarkers and evaluate diagnostic utility

**Key design decision:** The immune anchor should be chosen before module discovery rather than retrofitted after feature selection.

---

## Pattern B — Immune-Module-to-Biomarker Workflow

**Use when:** User wants immune-linked modules or coexpression structure first, then one or a few final biomarkers.

**Canonical examples:** WGCNA modules associated with macrophage abundance, immune-module-derived hub biomarkers, coexpression-to-diagnostic-gene study.

**Logic chain:**
1. DEG and immune estimation
2. WGCNA or coexpression module detection
3. Pick module most correlated with immune anchor
4. Intersect with DEGs and/or PPI hubs
5. Prioritize one or a few biomarkers
6. Validate diagnostic performance

**Key design decision:** Module selection must be linked to an explicit immune trait, not just the most visually appealing module.

---

## Pattern C — Consensus-ML Biomarker Workflow

**Use when:** User wants a strong machine-learning compression story with several algorithms converging on a compact biomarker panel.

**Canonical examples:** LASSO + SVM-RFE + RF consensus genes, transcriptome-based diagnostic classifier, public-data ML biomarker paper.

**Logic chain:**
1. Start with compressed candidate set
2. Run multiple feature-selection algorithms
3. Intersect or compare retained features
4. Construct interpretable diagnostic model
5. Assess ROC / calibration / external validation

**Key design decision:** Multiple ML tools should be applied to a biologically compressed candidate space, not an unrestricted genome-wide matrix unless justified.

---

## Pattern D — Diagnostic-Plus-Prognostic Hybrid Workflow

**Use when:** User primarily wants diagnosis, but the paper also benefits from survival relevance of selected biomarkers.

**Canonical examples:** diagnostic immune biomarkers with secondary survival analysis, nomogram study with survival extension.

**Logic chain:**
1. Build diagnostic biomarker panel first
2. Evaluate selected genes in survival-enabled cohorts
3. Add KM / Cox follow-up for selected genes or score
4. Keep prognosis clearly labeled as extension, not main endpoint

**Key design decision:** Diagnostic and prognostic evidence should remain separate in the conclusion.

---

## Pattern E — Translational Validation Workflow

**Use when:** User wants protein / tissue / experimental follow-up after computational prioritization.

**Canonical examples:** HPA support, qPCR confirmation, small in-house validation cohort, IHC after computational screening.

**Logic chain:**
1. Finish computational prioritization
2. Narrow to final lead genes
3. Add protein / tissue / portal support
4. Optional qPCR / IHC / small cohort validation
5. Reframe claims conservatively if wet-lab scope is limited

**Key design decision:** Translational follow-up should strengthen a clearly defined computational claim rather than substitute for weak computational design.
