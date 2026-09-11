# Analysis Module Library
# faers-pharmacovigilance-disproportionality-research-planner

---

## Product and Comparator Architecture Modules

| Module | Purpose | When Required |
|---|---|---|
| Drug / brand-name normalization | Ensure all relevant product names are captured | Always |
| Comparator-drug declaration | Prevent arbitrary benchmarking | Always |
| Cross-drug comparison matrix | Organize within-class comparisons systematically | Standard+ |
| Indication-group declaration | Define disease / reason-for-use strata | Pattern C / Standard+ |
| Date-range definition | Align products with market availability | Always |
| Control-drug rationale | Justify metformin/orlistat-like or therapeutic controls | Standard+ |

### Product Declaration Requirement

| Item | Required Content |
|---|---|
| Drug class / products | e.g., semaglutide, tirzepatide, liraglutide |
| Brand names | all included marketed names |
| Comparator products | explicit controls or within-class comparators |
| Time window | start/end dates and justification |
| Indication groups | e.g., with T2DM vs without T2DM |

### Dataset Declaration and Reference Block

| Item | Required Content |
|---|---|
| Database source | FAERS dashboard / downloadable files / equivalent source |
| Query date | exact date of extraction |
| Coding system | MedDRA SOC / PT logic |
| Report filter | serious reports, suspect-drug restrictions, concomitant exclusions |
| Availability note | public dashboard or file access route |

> **Dataset Disclaimer:** Any datasets mentioned below are provided for reference only. Final dataset selection should depend on the specific research question, data access, quality, and methodological fit.

---

## Case Definition and Filtering Modules

| Module | Purpose | When Required |
|---|---|---|
| Serious-case restriction | Improve signal specificity | Standard+ |
| Primary suspect / only suspect logic | Reduce competing-attribution noise | Standard+ |
| Concomitant-product exclusion | Reduce confounding from co-reported therapies | Standard+ |
| Reason-for-use stratification | Separate disease or indication groups | Pattern C |
| MedDRA PT extraction | Standardize adverse-event terms | Always |
| Preferred-term shortlist construction | Focus on domain-relevant outcomes | Lite+ |

### Case-Definition Requirement

| Element | Typical Rule |
|---|---|
| Seriousness filter | serious only or all reports, declared explicitly |
| Suspect-role rule | primary suspect or only suspect |
| Concomitant rule | exclude co-products if signal purity is prioritized |
| Indication rule | with / without condition, or indication-specific grouping |
| AE domain rule | MedDRA SOC and PT list declared explicitly |

---

## Disproportionality and Signal Modules

| Module | Purpose | When Required |
|---|---|---|
| ROR calculation | Primary disproportionality metric | Always |
| Confidence interval calculation | Bound statistical uncertainty | Always |
| Comparator-specific ROR tables | Separate control- and cross-drug signal logic | Standard+ |
| Strong-signal threshold rule | Focus interpretation on strongest signals | Standard+ |
| Cross-product signal ranking | Compare within-class product signal profiles | Standard+ |
| Signal shortlist construction | Reduce overload in domain-wide PT sets | Advanced+ |

### Signal Rule Examples

| Rule | Example |
|---|---|
| Main metric | ROR with 95% CI |
| Positive-signal minimum | ROR > 1 with CI excluding 1 |
| Strong-signal filter | stricter threshold such as ROR > 4 with lower CI > 1 |
| Cross-product comparison | same PT compared across products |
| Nominal vs strong signal label | mandatory in multi-PT result tables |

---

## Interpretation and Follow-Up Modules

| Module | Purpose | When Required |
|---|---|---|
| Comparator-qualified interpretation | Keep signals tied to chosen benchmark | Always |
| Indication-group comparison | Compare with-condition vs without-condition reporting patterns | Pattern C |
| Clinical-severity grouping | Separate serious / vision-threatening vs lower-severity PTs | Standard+ |
| Biological-plausibility layer | Frame possible relevance without causality claims | Standard+ |
| Signal-priority ranking | Identify highest-priority PTs for follow-up study | Pattern E / Advanced+ |
| Claim-boundary summary | Explicitly separate reporting signal from causal evidence | Always |
