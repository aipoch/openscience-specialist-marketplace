# Method Library
# single-drug-faers-safety-profile-research-planner

---

## FAERS / Signal Detection Core

| Method | Primary Use | Main Alternative | Decision Rule |
|---|---|---|---|
| ROR | Simple, interpretable disproportionality metric | PRR / IC / EBGM | Default for readable primary tables |
| PRR | Regulatory-style signal screening companion metric | ROR | Use as secondary support when conventional thresholds are desired |
| IC / Bayesian shrinkage metric | Stabilize sparse-cell behavior | ROR / PRR only | Prefer when sparse PT-level cells are prominent |
| Case de-duplication by latest case version | Reduce duplicate-report inflation | Naive case counting | Strongly preferred when raw exports contain multiple versions |
| Suspect-drug prioritization | Tighten exposure definition | All-role inclusion | Prefer when specificity is more important than breadth |

## Comparator / Scope Methods

| Method | Primary Use | Main Alternative | Decision Rule |
|---|---|---|---|
| Active comparator restriction | Reduce denominator mismatch | Whole-database background | Use when comparative therapeutic-space question is central |
| Same-class head-to-head comparison | Detect subclass or pharmacologic contrast | Class vs non-class comparison | Use when the story is within-class rather than across therapy spaces |
| Fixed SOC analysis | Keep one clinical safety theme coherent | Whole-profile scan | Prefer when the paper is anchored on one reviewer-friendly safety question |
| Curated PT panel | Focus on clinically meaningful events | Broad SOC scan | Use when the AE family is known and specific |

## Characterization Methods

| Method | Primary Use | Main Alternative | Decision Rule |
|---|---|---|---|
| Age / sex stratified signal summary | Demographic characterization | Unstratified global result only | Use when subgroup angle is explicitly requested or clinically relevant |
| Seriousness outcome tabulation | Add clinical context | Signal-only report | Use when hospitalization / death context matters |
| Time-to-onset summary | Add temporal characterization | No temporal layer | Use only if date fields are adequately usable |
| Label-context comparison | Frame known vs under-discussed signals | Pure signal table | Use when translational or regulatory discussion is part of the goal |

## Robustness Methods

| Method | Primary Use | Main Alternative | Decision Rule |
|---|---|---|---|
| Alternate exposure filter | Test signal stability under stricter inclusion | Single extraction rule only | Standard+ when overreporting risk is high |
| Alternate denominator restriction | Test comparative stability | One comparator frame only | Standard+ for reviewer-facing comparative papers |
| Multi-metric confirmation | Reduce one-metric overinterpretation | Single primary metric only | Standard+ when sparse or controversial signals dominate |
| Conservative PT thresholding | Control multiple weak noisy signals | Rank everything equally | Prefer when whole-profile scan is broad |
