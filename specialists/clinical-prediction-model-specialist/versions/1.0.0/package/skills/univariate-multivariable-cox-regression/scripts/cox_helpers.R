format_p_value <- function(p_value) {
  ifelse(p_value < 0.001, "<0.001", sprintf("%.3f", p_value))
}

format_hr_ci <- function(hr, ci_low, ci_high) {
  ifelse(is.na(hr), NA_character_, sprintf("%.2f (%.2f-%.2f)", hr, ci_low, ci_high))
}

collect_feature_rows <- function(summary_obj, feature_name, data_column, total_n) {
  coefficient_table <- summary_obj$coefficients
  confint_table <- summary_obj$conf.int
  if (is.null(dim(coefficient_table)))
    coefficient_table <- matrix(coefficient_table, nrow = 1, dimnames = list(names(summary_obj$coefficients), NULL))
  if (is.null(dim(confint_table)))
    confint_table <- matrix(confint_table, nrow = 1, dimnames = list(names(summary_obj$conf.int), NULL))

  rows <- data.frame(
    Characteristics = rownames(confint_table),
    `Total(N)` = total_n,
    `HR (95% CI)` = format_hr_ci(confint_table[, "exp(coef)"], confint_table[, "lower .95"], confint_table[, "upper .95"]),
    `P value` = format_p_value(coefficient_table[, "Pr(>|z|)"]),
    feature = feature_name,
    p_numeric = coefficient_table[, "Pr(>|z|)"],
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

  if (is.factor(data_column)) {
    level_names <- levels(data_column)
    effect_levels <- sub(paste0("^", feature_name), "", rows$Characteristics)
    reference_levels <- setdiff(level_names, effect_levels)
    if (length(reference_levels) > 0) {
      ref_rows <- data.frame(
        Characteristics = reference_levels,
        `Total(N)` = total_n,
        `HR (95% CI)` = NA_character_,
        `P value` = NA_character_,
        feature = feature_name,
        p_numeric = NA_real_,
        stringsAsFactors = FALSE,
        check.names = FALSE
      )
      rows$Characteristics <- effect_levels
      rows <- rbind(ref_rows, rows)
    }
  } else {
    rows$Characteristics <- feature_name
  }

  rows
}

match_feature_name <- function(term_name, features) {
  matched_features <- features[startsWith(term_name, features)]
  if (length(matched_features) == 0)
    return(term_name)
  matched_features[[which.max(nchar(matched_features))]]
}

format_multivariable_characteristic <- function(term_name, features) {
  feature_name <- match_feature_name(term_name, features)
  suffix <- substring(term_name, nchar(feature_name) + 1L)
  if (!nzchar(suffix))
    return(feature_name)
  suffix
}
