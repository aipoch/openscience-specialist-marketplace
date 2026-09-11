resolve_group_column <- function(group_df, group_col, case_group) {
  if (!is.null(group_col) && nzchar(group_col)) {
    if (!group_col %in% colnames(group_df))
      stop_skill("SKILL_MISSING_COLUMNS", paste("--group_col not found in group file:", group_col))
    return(group_col)
  }
  candidate_cols <- setdiff(colnames(group_df), colnames(group_df)[1])
  matched_cols <- candidate_cols[vapply(candidate_cols, function(col_name) any(group_df[[col_name]] == case_group, na.rm = TRUE), logical(1))]
  if (length(matched_cols) == 1)
    return(matched_cols[[1]])
  if (length(matched_cols) > 1)
    stop_skill("SKILL_INVALID_PARAMETER", paste("--case_group matched multiple columns; specify --group_col explicitly:", paste(matched_cols, collapse = ", ")))
  candidate_cols[[1]]
}

validate_input_tables <- function(expression_df, group_df) {
  if (ncol(expression_df) < 2)
    stop_skill("SKILL_INVALID_PARAMETER", "--expression_file must contain one gene column and at least one sample column")
  if (ncol(group_df) < 2)
    stop_skill("SKILL_INVALID_PARAMETER", "--group_file must contain one sample column and at least one group column")
  if (anyNA(expression_df[[1]]) || anyDuplicated(expression_df[[1]]) > 0)
    stop_skill("SKILL_INVALID_PARAMETER", "Expression matrix gene identifiers must be non-missing and unique")
  if (anyNA(colnames(expression_df)[-1]) || any(!nzchar(colnames(expression_df)[-1])) || anyDuplicated(colnames(expression_df)[-1]) > 0)
    stop_skill("SKILL_INVALID_PARAMETER", "Expression matrix sample identifiers must be non-missing and unique")
  if (anyNA(group_df[[1]]) || any(!nzchar(group_df[[1]])) || anyDuplicated(group_df[[1]]) > 0)
    stop_skill("SKILL_INVALID_PARAMETER", "Group file sample identifiers must be non-missing and unique")
  invisible(TRUE)
}

prepare_group_data <- function(expression_df, group_df, case_group, group_col) {
  colnames(expression_df)[1] <- "gene"
  colnames(group_df)[1] <- "sample"
  selected_group_col <- resolve_group_column(group_df, group_col, case_group)
  group_df <- group_df[, c("sample", selected_group_col), drop = FALSE]
  colnames(group_df)[2] <- "group"
  if (!case_group %in% group_df$group)
    stop_skill("SKILL_INVALID_PARAMETER", paste("--case_group was not found in group column:", selected_group_col))
  list(expression_df = expression_df, group_df = group_df, group_col = selected_group_col)
}

prepare_expression_matrix <- function(expression_df, group_df, genes) {
  matched_samples <- intersect(colnames(expression_df)[-1], group_df$sample)
  if (length(matched_samples) == 0)
    stop_skill("SKILL_SAMPLE_MISMATCH", "Expression matrix and group file do not share any sample IDs")
  if (length(matched_samples) < length(colnames(expression_df)) - 1)
    log_warn(sprintf("Using %d matched samples shared by both files", length(matched_samples)))

  valid_genes <- intersect(genes, expression_df$gene)
  if (length(valid_genes) == 0)
    stop_skill("SKILL_EMPTY_DATA", "No requested marker genes remained after filtering the expression matrix")
  if (length(valid_genes) < length(genes))
    log_warn(paste("Skipping missing marker genes:", paste(setdiff(genes, valid_genes), collapse = ", ")))

  expr_subset <- expression_df[match(valid_genes, expression_df$gene), c("gene", matched_samples), drop = FALSE]
  expr_matrix <- t(as.matrix(expr_subset[, -1, drop = FALSE]))
  mode(expr_matrix) <- "numeric"
  if (any(!is.finite(expr_matrix)))
    stop_skill("SKILL_INVALID_PARAMETER", "Selected expression values must be numeric and finite")
  list(expr_subset = expr_subset, expr_matrix = expr_matrix, genes = valid_genes)
}

prepare_analysis_data <- function(expression_df, group_df, genes, case_group, group_col = NULL) {
  validate_input_tables(expression_df, group_df)
  grouped <- prepare_group_data(expression_df, group_df, case_group, group_col)
  expression_df <- grouped$expression_df
  group_df <- grouped$group_df
  matrix_bundle <- prepare_expression_matrix(expression_df, group_df, genes)

  model_data <- as.data.frame(matrix_bundle$expr_matrix, stringsAsFactors = FALSE)
  colnames(model_data) <- matrix_bundle$expr_subset$gene
  model_data$sample <- rownames(matrix_bundle$expr_matrix)
  merged_data <- merge(group_df, model_data, by = "sample", all = FALSE, sort = FALSE)
  merged_data$outcome <- ifelse(merged_data$group == case_group, 1, 0)
  if (nrow(merged_data) < 10)
    stop_skill("SKILL_INVALID_PARAMETER", "At least 10 matched samples are required for ROC analysis")
  if (sum(merged_data$outcome == 1) < 2 || sum(merged_data$outcome == 0) < 2)
    stop_skill("SKILL_INVALID_PARAMETER", "At least 2 case samples and 2 control samples are required")
  if (nrow(merged_data) < 30)
    log_warn(sprintf("Current matched sample size is small (N = %d); diagnostic estimates may be unstable", nrow(merged_data)))
  list(data = merged_data, genes = matrix_bundle$genes, group_col = grouped$group_col)
}

fit_logistic_model <- function(analysis_data, genes) {
  formula_text <- paste("outcome ~", paste(genes, collapse = " + "))
  tryCatch(
    stats::glm(stats::as.formula(formula_text), data = analysis_data, family = stats::binomial()),
    error = function(e) stop_skill("SKILL_INVALID_PARAMETER", paste("Failed to fit logistic regression model:", conditionMessage(e)))
  )
}

extract_coefficient_table <- function(model) {
  coefficient_matrix <- summary(model)$coefficients
  confint_matrix <- tryCatch(suppressMessages(stats::confint.default(model)), error = function(e) NULL)
  odds_ratio <- exp(coefficient_matrix[, "Estimate"])
  data.frame(
    term = rownames(coefficient_matrix),
    estimate = coefficient_matrix[, "Estimate"],
    std_error = coefficient_matrix[, "Std. Error"],
    z_value = coefficient_matrix[, "z value"],
    p_value = coefficient_matrix[, "Pr(>|z|)"],
    odds_ratio = odds_ratio,
    odds_ratio_95_ci = if (is.null(confint_matrix)) NA_character_ else sprintf("%.3f (%.3f-%.3f)", odds_ratio, exp(confint_matrix[, 1]), exp(confint_matrix[, 2])),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}
