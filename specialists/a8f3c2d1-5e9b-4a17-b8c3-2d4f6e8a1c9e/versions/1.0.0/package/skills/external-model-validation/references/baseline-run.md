# Baseline Run Record

## Purpose

This document records a successful real-data run of the Skill. It serves as a reproducibility baseline for future Skill development, audit review, and regression checks.

## Baseline Command

```bash
Rscript scripts/main.R \
  --exp_file tests/data/BRCA_data.csv \
  --cli_file tests/data/BRCA_clinic.csv \
  --model_file tests/data/BRCA_coef.csv \
  --output_dir ./baseline_run_example
```

If rerunning into the same directory, add `--overwrite`.

## Effective Parameters

- `time_unit`: `month`
- `col_high`: `#E64B35`
- `col_low`: `#4DBBD5`
- `roc_cols`: `#E64B35,#00A087,#3C5488`
- `roc_times`: `1,3,5`
- `roc_pos`: `bottomright`
- `km_breaks`: `0`
- `seed`: `42`
- `timeout_seconds`: `3600`

## Input Summary

- Expression matrix: `3 genes x 928 samples`
- Clinical table: `928 rows`
- Model genes: `3`
- Matched samples used: `928`
- Risk groups: `464 low`, `464 high`
- Event counts: `801 censored`, `127 events`

## Runtime and Resource Baseline

- Wall time: `2.690 s`
- User CPU time: `2.516 s`
- System CPU time: `1.074 s`
- Memory after input loading: `130.20 MB`
- Memory after risk calculation: `130.70 MB`
- Memory after plot generation: `149.30 MB`

## Output Inventory

Example output directory layout from the recorded baseline run:

- `analysis.log`
- `run_parameters.tsv`
- `session_info.txt`
- `data/risk_data.rds`
- `table/out_varifyRisk.txt`
- `plot/out_varifySurv.pdf`
- `plot/out_varify.riskScore.pdf`
- `plot/out_varify.survStat.pdf`
- `plot/out_varify.heatmap.pdf`
- `plot/out_varify.ROC.pdf`

## Key Output Characteristics

### Risk Data Object

- Rows: `928`
- Columns: `8`
- Columns: `id, futime, fustat, TSPAN6, TNMD, DPM1, riskScore, risk`

### Risk Score Summary

- Min: `-1.49162`
- 1st Quartile: `0.543072`
- Median: `1.09803`
- Mean: `1.07804`
- 3rd Quartile: `1.6099`
- Max: `3.65997`

### Risk Table Example

```tsv
id	futime	fustat	TSPAN6	TNMD	DPM1	riskScore	risk
TCGA-3C-AALI	11.125	0	3.87904870689558	9.97599575444292	7.94862759943198	3.07019801826078	high
TCGA-3C-AALJ	4.09444444416667	0	4.53964502103344	5.86219785622998	6.10828786513876	1.69907054002054	high
TCGA-3C-AALK	4.0222222225	0	8.11741662829825	5.37750621865967	5.4073279302323	0.507616713398724	low
```

## Review Pointers

- Use this run to confirm future code changes do not alter the expected output inventory.
- Minor visual differences in PDFs can occur with different package versions, but file types and output structure should remain stable.
- Re-check `session_info.txt` if an environment change causes differences in plot rendering or AUC output.
