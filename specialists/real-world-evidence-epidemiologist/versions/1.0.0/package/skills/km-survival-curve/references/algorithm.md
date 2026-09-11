# Kaplan-Meier Analysis Algorithm Details

## Statistical Methods

### 1. Kaplan-Meier Estimation

The script fits Kaplan-Meier survival curves stratified by the requested risk group column.

**Model form:**

```r
survfit(Surv(time, status) ~ risk_group, data = surv_data)
```

**Estimator:**

```text
S(t) = Product over event times t_i <= t of (1 - d_i / n_i)
```

where:

- `d_i` is the number of events at time `t_i`
- `n_i` is the number at risk just before `t_i`

### 2. Log-rank Test

When `--statistics_method logrank` is selected, the script compares groups using:

```r
survdiff(Surv(time, status) ~ risk_group, data = surv_data)
```

The chi-square statistic is converted to a p-value with:

```r
1 - pchisq(diff$chisq, df = k - 1)
```

where `k` is the number of groups.

### 3. Cox Model Route

When `--statistics_method wald` is selected, the script fits:

```r
coxph(Surv(time, status) ~ risk_group, data = surv_data)
```

and uses the coefficient-table p-value from:

```r
summary(cox_fit)$coefficients[1, 5]
```

Implementation note:

- The current Cox-based option is exposed only as `wald`.

## Data Preparation Steps

1. Read the input file from CSV, TXT, or TSV format.
2. Validate that the requested time, status, and risk group columns exist.
3. Convert time and status to numeric values.
4. Remove rows with missing time, status, or group values.
5. Require at least 2 retained samples and at least 2 retained groups.
6. Apply optional time conversion using the requested `time_unit` and `auto_convert_days` setting.

## Time Conversion Logic

The script uses the following rule, adapted from the time-dependent ROC workflow:

```r
if (time_unit == "year" && max(time) > 365) {
  time <- time / 365
} else if (time_unit == "month" && max(time) > 365) {
  time <- time / 30.4375
}
```

Notes:

- Conversion is only attempted when `auto_convert_days` is `true`.
- Conversion uses `max(time) > 365`, not `any(time >= 365)`.
- No automatic conversion is applied when `time_unit` is `day`.

## Output

The script saves a single figure file:

- `km-plot.pdf`

It also saves a run metadata file:

- `session_info.txt`

## Result Interpretation

### Practical Interpretation

- A clear separation between curves suggests different survival behavior across groups.
- Small groups can produce unstable curves and wide confidence intervals.
- The p-value should be interpreted alongside curve shape and visible risk-table counts.

## Assumptions

### Kaplan-Meier Assumptions

- Censoring is non-informative.
- Observations are independent.
- Event times are measured consistently.

### Log-rank Assumptions

- Groups are independent.
- The comparison is between full survival functions.
- Censoring patterns are not biased in a way that invalidates group comparison.

## Notes

### Group Labels

- The script uses the actual group values as legend labels.
- If the groups are `low` and `high`, that order is preserved.
- Otherwise, groups are ordered alphabetically.

### Time Unit Handling

- The requested output unit affects the x-axis title when `title_x` is left at its default value.
- Automatic conversion behavior is communicated through the console log during analysis.

### Limitations

- The script does not estimate an optimal cutpoint from continuous scores.
- The only saved result artifact is a single PDF figure.
