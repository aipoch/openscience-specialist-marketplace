# External Model Validation — Project Structure

## Directory Layout

```text
external-model-validation/
├── SKILL.md
├── scripts/
│   ├── main.R
│   ├── run_analysis.R
│   ├── functions.R
│   ├── io.R
│   ├── plotting.R
│   └── utils.R
├── references/
│   ├── algorithm.md
│   ├── troubleshooting.md
│   ├── cli-guide.md
│   └── baseline-run.md
└── tests/
    ├── output/
    │   ├── analysis.log
    │   ├── run_parameters.tsv
    │   ├── session_info.txt
    │   ├── data/
    │   ├── table/
    │   └── plot/
    ├── refresh_example_output.R
    ├── testthat.R
    ├── testthat/
    │   └── test_external_model_validation.R
    └── data/
        ├── BRCA_data.csv
        ├── BRCA_clinic.csv
        └── BRCA_coef.csv
```

## Implementation Checklist

- [x] CLI parsing with `optparse`
- [x] `set.seed()` for reproducibility
- [x] Dependency checks with `requireNamespace()`
- [x] Structured logging to console and file
- [x] Timeout control with `setTimeLimit()`
- [x] Session info recording
- [x] Real test data provided in `tests/data/`
- [x] R tests provided in `tests/testthat/`
- [x] Overwrite protection for non-empty output directories
- [x] Retained-output refresh helper provided in `tests/refresh_example_output.R`
- [x] File reading instructions in `SKILL.md`
- [x] Modular script structure in `scripts/`
- [x] Error handling with `SKILL_*` codes
- [x] Baseline run captured for manual review and future audits
