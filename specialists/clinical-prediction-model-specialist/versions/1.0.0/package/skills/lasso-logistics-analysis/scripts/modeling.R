prepare_model_inputs <- function(expr_mat, group_df, case_group, control_group, feature_list, nfolds) {
  labels <- unique(group_df$group)
  if (identical(case_group, control_group))
    stop("SKILL_INVALID_PARAMETER: --case_group and --control_group must be different")
  if (!(case_group %in% labels) || !(control_group %in% labels))
    stop("SKILL_INVALID_GROUP: case_group or control_group not found in group file")
  model_groups <- group_df[group_df$group %in% c(case_group, control_group), , drop = FALSE]
  if (nrow(model_groups) < 4)
    stop("SKILL_INVALID_DATA: Need at least 4 samples across the two selected groups")
  if (!all(model_groups$sample %in% colnames(expr_mat))) {
    missing_samples <- setdiff(model_groups$sample, colnames(expr_mat))
    stop(paste("SKILL_SAMPLE_MISMATCH: Samples in group file not found in expression matrix:",
               paste(missing_samples, collapse = ", ")))
  }
  sample_order <- model_groups$sample
  y <- ifelse(model_groups$group == case_group, 1, 0)
  if (any(table(y) < 2))
    stop("SKILL_INVALID_DATA: Each class must contain at least 2 samples")
  if (nfolds > min(table(y)))
    stop("SKILL_INVALID_PARAMETER: nfolds cannot exceed the smallest class size")
  available_features <- rownames(expr_mat)
  missing_features <- character(0)
  if (!is.null(feature_list)) {
    missing_features <- setdiff(feature_list, available_features)
    keep_features <- intersect(feature_list, available_features)
    if (length(keep_features) == 0)
      stop("SKILL_INVALID_DATA: None of the requested features were found in the expression matrix")
    available_features <- keep_features
  }
  x <- t(expr_mat[available_features, sample_order, drop = FALSE])
  feature_matrix <- data.frame(
    sample = sample_order,
    group = model_groups$group,
    event = y,
    x,
    check.names = FALSE,
    row.names = NULL
  )
  list(x = x, y = y, feature_matrix = feature_matrix, missing_features = missing_features)
}

fit_lasso_models <- function(x, y, nfolds, seed) {
  set.seed(seed)
  fit <- glmnet::glmnet(x, y, family = "binomial", alpha = 1)
  set.seed(seed)
  cv_fit <- glmnet::cv.glmnet(x, y, family = "binomial", alpha = 1, nfolds = nfolds)
  list(fit = fit, cv_fit = cv_fit)
}

extract_coefficients <- function(fit, cv_fit) {
  coef_mat <- as.matrix(stats::coef(fit, s = cv_fit$lambda.min))
  coef_df <- data.frame(
    feature = rownames(coef_mat),
    coefficient = as.numeric(coef_mat[, 1]),
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  coef_df
}
