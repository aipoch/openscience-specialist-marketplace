# Reference Module 04: Bias and Analysis Guardrails

## Core Rule
A good case-control design blueprint must make the main bias structure visible before offering analytic recommendations.

## Minimum Bias Set
The output must assess:
- selection bias,
- recall bias,
- information bias,
- exposure misclassification,
- confounding,
- overmatching risk when relevant,
- survivor or prevalent-case distortion,
- missing-data distortion.

## Analysis Rule
The default analysis line should usually be framed around:
- crude odds ratio estimation,
- adjusted logistic regression,
- conditional logistic regression if individual matching is used.

## Important Interpretation Rule
Do not claim the study estimates incidence or absolute risk.
Do not treat odds ratios as if they are always directly interpretable as risk ratios.
Do not imply causal identification merely because multivariable adjustment is planned.

## Confounding Rule
Confounder control should be grounded in subject-matter logic, not in indiscriminate variable inclusion.

## Missing Data Rule
If important covariates or exposure fields may be incomplete, the output should identify this as a design risk, not just an analysis footnote.

## Reporting Rule
The analysis section should state:
- the main effect measure,
- the core adjustment logic,
- the consequence of matching for the model choice,
- and the main interpretive limitation.
