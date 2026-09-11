prepare_analysis_data <- function(data, features, time_col, event_col) {
  required_cols <- unique(c(features, time_col, event_col))
  missing_cols <- setdiff(required_cols, colnames(data))
  if (length(missing_cols) > 0)
    stop_skill("SKILL_MISSING_COLUMNS", paste("Clinical data is missing columns:", paste(missing_cols, collapse = ", ")))

  analysis_data <- data[, required_cols, drop = FALSE]
  analysis_data[[time_col]] <- suppressWarnings(as.numeric(analysis_data[[time_col]]))
  analysis_data[[event_col]] <- suppressWarnings(as.numeric(analysis_data[[event_col]]))

  for (feature in features) {
    if (is.character(analysis_data[[feature]]))
      analysis_data[[feature]] <- factor(analysis_data[[feature]])
  }

  complete_idx <- complete.cases(analysis_data)
  if (!all(complete_idx)) {
    removed_count <- sum(!complete_idx)
    log_warn(sprintf("Removed %d rows with incomplete values before Cox analysis", removed_count))
    analysis_data <- analysis_data[complete_idx, , drop = FALSE]
  }

  if (nrow(analysis_data) == 0)
    stop_skill("SKILL_EMPTY_DATA", "Clinical data has no complete rows after filtering requested columns")
  if (nrow(analysis_data) < 10)
    stop_skill("SKILL_INVALID_PARAMETER", "--data_file must contain at least 10 complete samples for Cox analysis")
  if (any(!is.finite(analysis_data[[time_col]])) || any(analysis_data[[time_col]] <= 0))
    stop_skill("SKILL_INVALID_PARAMETER", "--data_file time values must be finite numbers greater than 0")
  if (!all(analysis_data[[event_col]] %in% c(0, 1)))
    stop_skill("SKILL_INVALID_PARAMETER", "--data_file event values must use 0/1 encoding")
  if (sum(analysis_data[[event_col]] == 1) < 2)
    stop_skill("SKILL_INVALID_PARAMETER", "--data_file must contain at least 2 events for Cox regression")

  analysis_data
}

run_univariate_cox <- function(data, features, time_col, event_col) {
  surv_formula <- function(feature_name) as.formula(paste0("survival::Surv(`", time_col, "`, `", event_col, "`) ~ `", feature_name, "`"))
  all_rows <- lapply(features, function(feature_name) {
    fit <- tryCatch(
      survival::coxph(surv_formula(feature_name), data = data),
      error = function(e) stop_skill("SKILL_INVALID_PARAMETER", paste("Cox model fitting failed for", feature_name, ":", conditionMessage(e)))
    )
    collect_feature_rows(summary(fit), feature_name, data[[feature_name]], nrow(data))
  })
  do.call(rbind, all_rows)
}

select_multivariable_features <- function(univariate_rows, features, min_features = 3) {
  significant_features <- unique(univariate_rows$feature[!is.na(univariate_rows$p_numeric) & univariate_rows$p_numeric < 0.05])
  if (length(significant_features) < min_features) {
    log_warn("Fewer than 3 significant univariate features were found; using all requested features for multivariable analysis")
    return(features)
  }
  significant_features
}

run_multivariable_cox <- function(data, features, time_col, event_col) {
  formula_text <- paste0("survival::Surv(`", time_col, "`, `", event_col, "`) ~ `", paste(features, collapse = "` + `"), "`")
  fit <- tryCatch(
    survival::coxph(as.formula(formula_text), data = data),
    error = function(e) stop_skill("SKILL_INVALID_PARAMETER", paste("Multivariable Cox model fitting failed:", conditionMessage(e)))
  )
  summary_obj <- summary(fit)
  coefficient_table <- summary_obj$coefficients
  confint_table <- summary_obj$conf.int
  if (is.null(dim(coefficient_table)))
    coefficient_table <- matrix(coefficient_table, nrow = 1, dimnames = list(names(summary_obj$coefficients), NULL))
  if (is.null(dim(confint_table)))
    confint_table <- matrix(confint_table, nrow = 1, dimnames = list(names(summary_obj$conf.int), NULL))

  term_names <- rownames(confint_table)
  feature_names <- vapply(term_names, match_feature_name, character(1), features = features)
  characteristics <- vapply(term_names, format_multivariable_characteristic, character(1), features = features)

  data.frame(
    Characteristics = characteristics,
    `Total(N)` = nrow(data),
    `HR (95% CI)` = format_hr_ci(confint_table[, "exp(coef)"], confint_table[, "lower .95"], confint_table[, "upper .95"]),
    `P value` = format_p_value(coefficient_table[, "Pr(>|z|)"]),
    feature = feature_names,
    p_numeric = coefficient_table[, "Pr(>|z|)"],
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}
