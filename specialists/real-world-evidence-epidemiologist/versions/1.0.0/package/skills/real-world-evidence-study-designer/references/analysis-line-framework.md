# Analysis Line Framework

## Core Rule
Choose the main analysis family based on the estimand, outcome structure, exposure structure, and follow-up logic.

## Common Matches
- Time-to-event outcome → survival analysis family.
- Repeated measures / longitudinal trajectories → longitudinal data analysis family.
- Rate outcomes → Poisson / negative-binomial style framing.
- Strong confounding-control need in treatment comparison → consider propensity-score-based design or marginal structural modeling when justified.

## Important Rule
Do not specify a highly technical model unless the data structure needed for it is actually plausible.
