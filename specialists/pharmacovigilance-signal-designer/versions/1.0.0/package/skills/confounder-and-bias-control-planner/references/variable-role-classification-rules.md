# Variable Role Classification Rules

## Core Rule
No adjustment recommendation is valid until major variables are classified by role.

## Required Roles
Use these labels when possible:
- exposure / index variable
- outcome / endpoint
- baseline confounder candidate
- mediator
- collider risk
- effect modifier
- matching candidate
- sampling / selection variable
- measurement-quality variable
- precision-only covariate
- post-baseline variable
- role-uncertain

## Important Rule
If chronology or causal position is not clear, prefer **role-uncertain** over forced classification.

## Reporting Rule
When a variable is placed in the adjustment set, state why it is there. When it is excluded, state why exclusion is safer.
