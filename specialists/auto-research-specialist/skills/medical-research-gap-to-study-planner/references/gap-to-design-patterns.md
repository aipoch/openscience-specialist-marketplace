# Gap-to-Design Patterns
# medical-research-gap-to-study-planner

---

## Pattern A. Evidence-Completion Pattern

**Use when:**
- the main problem is insufficient validation,
- findings are not yet externally replicated,
- available evidence is sparse, fragmented, or cohort-specific,
- reproducibility is the central weakness.

**Best-fit design logic:**
- define the exact candidate endpoint,
- use one discovery source plus one or more independent validation sources,
- focus on stability, reproducibility, external consistency, and conservative interpretation.

**Typical modules:**
- discovery cohort selection
- endpoint harmonization
- independent validation cohort(s)
- robustness / sensitivity analyses
- orthogonal support if available

**Avoid when:**
- the true problem is mechanistic ambiguity rather than evidence insufficiency.

---

## Pattern B. Mechanism-Resolution Pattern

**Use when:**
- the central gap is an unresolved pathway or functional chain,
- a candidate factor is associated with disease but its action remains poorly explained,
- upstream/downstream logic is incomplete.

**Best-fit design logic:**
- sharpen the biological question,
- define what mechanistic evidence is minimally necessary,
- combine computational prioritization with functional or perturbation-oriented validation if resources allow.

**Typical modules:**
- pathway and network narrowing
- mediator or upstream regulator screening
- perturbation or functional validation
- causal-chain interpretation with conservative boundaries

**Avoid when:**
- the user has no mechanism-capable data or assays and only needs reproducibility.

---

## Pattern C. Cell-State / Context-Mapping Pattern

**Use when:**
- bulk-level signals cannot be assigned to a cell type, cell state, or spatial context,
- the gap is about tumor microenvironment, tissue heterogeneity, lineage, or state-specific activity,
- localization of signal is the unresolved problem.

**Best-fit design logic:**
- define the unresolved context question,
- choose scRNA-seq, spatial transcriptomics, or carefully justified deconvolution / projection,
- ask whether the candidate signal is enriched, active, or interpretable in specific compartments.

**Typical modules:**
- cell-type/state annotation
- projection of candidate signal onto single-cell or spatial context
- microenvironment or context-specific association
- optional cross-platform triangulation

**Avoid when:**
- the core gap is simply lack of cohort validation.

---

## Pattern D. Translation-Bridge Pattern

**Use when:**
- there is biological plausibility but little clinical utility,
- a mechanism or biomarker exists but has not been translated into stratification, prognosis, diagnosis, or response prediction,
- the unresolved question is clinical applicability.

**Best-fit design logic:**
- define the intended clinical use-case,
- align endpoints, subgroup definitions, and validation to that use-case,
- avoid overclaiming implementation.

**Typical modules:**
- clinically interpretable endpoints
- subgroup or responder/non-responder comparison
- calibration / discrimination where relevant
- external or orthogonal validation

**Avoid when:**
- there is no outcome or clinically meaningful stratification data.

---

## Pattern E. Causality-Upgrade Pattern

**Use when:**
- prior work is mostly correlational,
- the user wants stronger causal or mediator logic,
- the gap specifically concerns driver vs passenger uncertainty.

**Best-fit design logic:**
- assess whether causal inference is actually feasible,
- choose MR, QTL-based anchoring, mediation, longitudinal analysis, perturbation evidence, or other causal-support module only if assumptions are supportable,
- explicitly downgrade claims when causal assumptions are weak.

**Typical modules:**
- instrument / anchor assessment
- causal-support analysis
- sensitivity analyses for assumptions
- strict claim-boundary statements

**Avoid when:**
- no valid causal-support data exist.

---

## Pattern F. Population / Stage-Specific Pattern

**Use when:**
- the gap concerns under-studied subgroups,
- disease stage, treatment stage, sex, age, ancestry, severity, or context modifies interpretation,
- evidence exists in the aggregate but not in the specific subgroup that matters.

**Best-fit design logic:**
- define the subgroup clearly,
- justify why subgroup-specific evidence matters,
- design the protocol around stratified, stage-aware, or context-specific analysis rather than aggregate averages.

**Typical modules:**
- cohort splitting or subgroup definition
- interaction / heterogeneity assessment
- subgroup-specific validation
- context-aware interpretation

**Avoid when:**
- subgroup size is too small to support meaningful inference.
