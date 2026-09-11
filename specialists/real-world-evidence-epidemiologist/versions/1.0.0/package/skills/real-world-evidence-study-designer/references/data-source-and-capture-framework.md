# Data Source and Capture Framework

## Core Rule
Select the data source based on capture structure, not convenience.

## Typical Strengths
| Source | Often captures relatively well | Often weak or missing |
|---|---|---|
| EHR | labs, vitals, clinician-recorded diagnoses, timing within health system | care outside system, complete medication fill behavior, uniform coding |
| Claims | billing-based encounters, procedures, dispensed medications, longitudinal utilization | granular clinical severity, nuanced symptoms, many labs, chart-level adjudication |
| Registry | disease- or procedure-focused structured variables, curated outcomes | off-registry care, broad comorbidity capture, complete medication history |

## Required Behavior
- State why the selected source fits the primary exposure and outcome.
- State the main capture gaps explicitly.
- If linked sources are needed, mark them as verified only if explicitly stated by the user.
