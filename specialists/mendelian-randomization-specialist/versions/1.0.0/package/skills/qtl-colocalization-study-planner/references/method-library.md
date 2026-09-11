# Method Library

## Default Method Roles
- **Bayesian colocalization framework**: default primary option when the data structure supports posterior-probability interpretation under explicit assumptions.
- **Fine-mapping-assisted colocalization**: use when single-signal assumptions are fragile or multiple independent signals are plausible.
- **Conditional analysis / signal decomposition**: use when one locus likely contains more than one association signal.
- **SMR + HEIDI**: use as a linked prioritization / follow-up module, not as a direct replacement for all coloc settings.
- **MR after coloc support**: use only when the question truly involves exposure–outcome causal interpretation and the data architecture supports it.

## Method-Selection Rules
- Choose the method stack based on locus architecture, summary-statistic completeness, and whether the goal is prioritization versus causal follow-up.
- If only limited summary statistics are available, explicitly downgrade the design instead of pretending fine-mapping-grade inference is available.
- If the question is about splice events, transcript-level mapping and isoform ambiguity must be addressed explicitly.
- If the question is about proteins, distinguish cis-pQTL interpretation from downstream biomarker enthusiasm.

## Interpretation Rules
- Posterior support should be interpreted in context, not as a standalone truth label.
- A non-supportive coloc result can reflect poor data fit, tissue mismatch, or locus complexity — not only biological absence.
- Concordance across eQTL, pQTL, sQTL, and annotation can strengthen prioritization, but does not automatically prove mechanism.
