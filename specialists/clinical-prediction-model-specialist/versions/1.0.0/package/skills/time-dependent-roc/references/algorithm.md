# Time-Dependent ROC Algorithm Details

## Statistical Method

This skill uses `timeROC::timeROC()` to estimate time-dependent ROC curves for censored survival data.

## What Is Estimated

For each requested time point `t`, the analysis estimates:

- A time-specific ROC curve.
- The corresponding area under the ROC curve (AUC).
- ROC point coordinates as false-positive rate and sensitivity.

The marker is assumed to be a continuous or ordinal score where larger values imply higher risk.

## Core Inputs

- `T`: follow-up time from `futime`
- `delta`: event indicator from `fustat`
- `marker`: numeric risk marker column
- `cause`: event code treated as the event of interest
- `times`: time points where ROC and AUC are evaluated
- `weighting`: inverse probability of censoring weighting method

## Handling Censoring

The method accounts for right censoring through IPCW.

Supported weighting options:

- `aalen`: Aalen additive hazard model based weighting
- `marginal`: marginal Kaplan-Meier based weighting
- `cox`: Cox model based weighting

`aalen` is the default because it matches the original script behavior.

## Time Scale Behavior

The skill expects `times` to be expressed in the same unit shown in the output.

If `--auto_convert_days TRUE` and `max(futime) > 365`:

- `time_unit = year`: `futime` is divided by `365`
- `time_unit = month`: `futime` is divided by `30.4375`
- `time_unit = day`: no conversion is applied

This preserves the original script's convenience behavior for datasets stored in days.

## Marker Selection

If `--marker_col` is omitted, the skill uses `risk_score`.

If you want to analyze another marker, provide `--marker_col` explicitly.

## Data Filtering

Rows are removed if any of these are missing:

- `futime`
- `fustat`
- selected marker

## Minimum Data Requirements

- At least 5 complete rows after filtering
- At least 1 event with `fustat == cause`
- At least 2 distinct marker values

## Result Interpretation

### AUC

- `AUC = 0.5`: no discrimination at that time point
- `AUC > 0.7`: often considered acceptable discrimination
- `AUC > 0.8`: strong discrimination
- `AUC > 0.9`: very strong discrimination

Interpretation depends on censoring, event rate, follow-up distribution, and application context.

### ROC Curve

- X-axis: false-positive rate, equivalent to `1 - specificity`
- Y-axis: sensitivity
- Curves closer to the upper-left corner indicate better discrimination

## Limitations

- The method evaluates discrimination, not calibration.
- Poorly chosen time points may produce unstable estimates if few subjects remain under observation.
- Heavy censoring can reduce precision.
- Automatic day-to-year or day-to-month conversion is heuristic; if your data unit is known, choose `--time_unit` deliberately.
