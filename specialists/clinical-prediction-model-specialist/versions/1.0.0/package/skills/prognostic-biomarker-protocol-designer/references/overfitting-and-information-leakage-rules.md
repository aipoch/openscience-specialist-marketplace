# Overfitting and Information Leakage Rules

## Core Rule
Every prognostic biomarker protocol must identify the strongest overfitting and leakage threats.

## Required Behaviors
- Review leakage from feature selection outside resampling.
- Review outcome-informed threshold selection.
- Review low events-per-parameter pressure.
- Review reuse of the same data for discovery and validation.
- Review platform / batch instability.

## Important Rule
A model with attractive apparent discrimination can still be unusable if optimism, leakage, or miscalibration are not controlled.
