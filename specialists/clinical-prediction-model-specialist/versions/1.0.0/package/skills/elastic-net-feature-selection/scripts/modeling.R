run_single_alpha_fit <- function(x, y, alpha, foldid, actual_nfolds, standardize) {
  fit <- suppress_glmnet_warnings(
    glmnet::glmnet(x, y, family = "binomial", alpha = alpha, standardize = standardize)
  )
  cv_fit <- suppress_glmnet_warnings(
    glmnet::cv.glmnet(
      x,
      y,
      family = "binomial",
      alpha = alpha,
      nfolds = actual_nfolds,
      standardize = standardize,
      foldid = foldid
    )
  )
  min_idx <- which.min(cv_fit$cvm)
  list(
    fit = fit,
    cv_fit = cv_fit,
    alpha = alpha,
    cvm_min = cv_fit$cvm[min_idx],
    lambda_min = cv_fit$lambda.min,
    lambda_1se = cv_fit$lambda.1se,
    nzero_min = cv_fit$nzero[min_idx],
    actual_nfolds = actual_nfolds
  )
}

build_alpha_tuning_table <- function(candidate_results, best_idx) {
  data.frame(
    alpha = vapply(candidate_results, function(res) res$alpha, numeric(1)),
    cvm_min = vapply(candidate_results, function(res) res$cvm_min, numeric(1)),
    lambda_min = vapply(candidate_results, function(res) res$lambda_min, numeric(1)),
    lambda_1se = vapply(candidate_results, function(res) res$lambda_1se, numeric(1)),
    nzero_min = vapply(candidate_results, function(res) res$nzero_min, numeric(1)),
    selected = seq_along(candidate_results) == best_idx,
    stringsAsFactors = FALSE
  )
}

fit_fixed_alpha_model <- function(x, y, alpha_value, cv_setup, standardize) {
  fit_result <- run_single_alpha_fit(
    x = x,
    y = y,
    alpha = alpha_value,
    foldid = cv_setup$foldid,
    actual_nfolds = cv_setup$actual_nfolds,
    standardize = standardize
  )
  list(
    fit = fit_result$fit,
    cv_fit = fit_result$cv_fit,
    actual_nfolds = fit_result$actual_nfolds,
    selected_alpha = fit_result$alpha,
    alpha_mode = "fixed",
    alpha_tuning = build_alpha_tuning_table(list(fit_result), 1L)
  )
}

fit_auto_alpha_model <- function(x, y, alpha_grid, cv_setup, standardize) {
  log_info(sprintf("Selecting alpha across %d candidate values.", length(alpha_grid)))
  candidate_results <- lapply(alpha_grid, function(candidate_alpha) {
    run_single_alpha_fit(x, y, candidate_alpha, cv_setup$foldid, cv_setup$actual_nfolds, standardize)
  })
  best_idx <- which.min(vapply(candidate_results, function(res) res$cvm_min, numeric(1)))[1]
  best_result <- candidate_results[[best_idx]]
  log_info(sprintf("Selected alpha %.3f by minimum cross-validated error.", best_result$alpha))
  list(
    fit = best_result$fit,
    cv_fit = best_result$cv_fit,
    actual_nfolds = best_result$actual_nfolds,
    selected_alpha = best_result$alpha,
    alpha_mode = "auto",
    alpha_tuning = build_alpha_tuning_table(candidate_results, best_idx)
  )
}

fit_elastic_net_model <- function(x, y, alpha_spec, alpha_grid, nfolds, standardize) {
  cv_setup <- build_cv_setup(y, nfolds)
  if (alpha_spec$mode == "fixed") {
    return(fit_fixed_alpha_model(x, y, alpha_spec$value, cv_setup, standardize))
  }
  fit_auto_alpha_model(x, y, alpha_grid, cv_setup, standardize)
}
