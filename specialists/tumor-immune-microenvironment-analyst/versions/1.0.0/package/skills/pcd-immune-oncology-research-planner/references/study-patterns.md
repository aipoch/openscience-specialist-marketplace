# Study Patterns
# pcd-immune-oncology-research-planner

---

## Pattern A — Mechanism Gene-Set Driven

**Use when:** user starts with ferroptosis / pyroptosis / cuproptosis / anoikis / mixed PCD.

**Typical sequence:**
1. curate gene set
2. differential expression + survival screen
3. cluster patients by mechanism genes
4. compare survival / immune / pathway states
5. optionally build prognostic score

---

## Pattern B — Molecular Subtype Discovery

**Use when:** user primarily wants robust patient classes / subtypes.

**Typical sequence:**
1. mechanism-gene selection
2. consensus clustering
3. subtype stability and dimensionality checks
4. survival difference
5. immune and pathway interpretation
6. optional subtype-to-risk translation

---

## Pattern C — Prognostic Signature Construction

**Use when:** user wants a signature, score, nomogram, biomarker set.

**Typical sequence:**
1. identify mechanism-related candidate genes
2. univariate Cox screen
3. LASSO shrinkage
4. multivariable Cox
5. KM + ROC + external validation
6. protein/tissue plausibility checks

---

## Pattern D — Immune Response Stratification

**Use when:** user emphasizes TME, checkpoints, TIDE, TMB, ICI context.

**Typical sequence:**
1. define subtypes or risk groups
2. estimate immune infiltration
3. compare checkpoint expression
4. add TIDE / TMB only if data supports it
5. state clearly that output is predictive context, not actual treatment response

---

## Pattern E — Translational Drug-Hypothesis

**Use when:** user wants computational drug sensitivity / repositioning hypotheses.

**Typical sequence:**
1. define biologically meaningful risk or subtype groups
2. estimate relative drug sensitivity via oncoPredict / GDSC
3. group compounds by class and mechanism
4. cross-check with PRISM / CTRP if Advanced+
5. explicitly label all outputs as computational hypotheses requiring follow-up
