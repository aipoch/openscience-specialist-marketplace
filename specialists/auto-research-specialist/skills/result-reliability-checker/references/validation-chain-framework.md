# Validation Chain Framework
# result-reliability-checker

---

## Goal

This module forces the skill to separate weak confirmation from strong confirmation.

---

## Validation Levels

### 1. No Validation
The claim is based only on the discovery analysis or initial experiment.

### 2. Internal Validation Only
Examples:
- split-sample validation within one cohort
- bootstrap or cross-validation only
- repeat assay on the same narrowly defined source base

This supports internal consistency, not broad generalizability.

### 3. External Validation
The finding is evaluated in a distinct cohort, dataset, center, or source population.
This is stronger than internal validation but still requires context review.

### 4. Orthogonal Validation
The signal is checked using a different assay, modality, or evidentiary layer.
Examples:
- transcript signal supported by protein measurement
- computational result supported by independent laboratory method

### 5. Replication / Multi-Context Support
The finding is reproduced across multiple independent settings or populations.

### 6. Prospective / Implementation-Level Support
The result is supported in a way that tests future-facing, practice-oriented, or workflow-relevant performance.

---

## Strong Rules

- Internal validation must never be described as external validation.
- External association support does not automatically prove utility.
- Orthogonal validation strengthens plausibility but does not erase design flaws.
- A result with no validation should be treated as exploratory unless the design and statistical chain are exceptionally strong.
