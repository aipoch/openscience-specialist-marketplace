run_svm_rfe <- function(expression_df, group_factor, options) {
  folds <- create_stratified_folds(group_factor, options$svm_k, options$seed)
  lapply(seq_along(folds), function(index) {
    test_idx <- folds[[index]]
    feature_ids <- rank_features_once(
      train_x = expression_df[-test_idx, , drop = FALSE],
      train_y = group_factor[-test_idx],
      inner_k = options$svm_k,
      halve_above = options$svm_halve_above,
      seed = options$seed + index
    )
    list(feature_ids = feature_ids, train_ids = rownames(expression_df)[-test_idx], test_ids = rownames(expression_df)[test_idx])
  })
}

aggregate_rankings <- function(results, feature_names) {
  rank_matrix <- sapply(results, function(result) {
    fold_ranks <- numeric(length(feature_names))
    fold_ranks[result$feature_ids] <- seq_along(result$feature_ids)
    fold_ranks
  })
  avg_rank <- rowMeans(rank_matrix)
  order_idx <- order(avg_rank)
  data.frame(
    Feature = feature_names[order_idx],
    FeatureID = order_idx,
    AvgRank = avg_rank[order_idx],
    Rank = seq_along(order_idx),
    stringsAsFactors = FALSE
  )
}

compute_error_curve <- function(results, expression_df, group_factor, max_features) {
  sapply(seq_len(max_features), function(n_features) {
    fold_errors <- vapply(results, function(result) {
      feature_ids <- result$feature_ids[seq_len(n_features)]
      train_x <- expression_df[result$train_ids, feature_ids, drop = FALSE]
      valid_x <- expression_df[result$test_ids, feature_ids, drop = FALSE]
      prediction <- fit_linear_svm_prediction(train_x, group_factor[result$train_ids], valid_x)
      mean(prediction != group_factor[result$test_ids])
    }, numeric(1))
    mean(fold_errors)
  })
}

select_feature_count <- function(error_rates, rule, tol) {
  min_error <- min(error_rates, na.rm = TRUE)
  if (rule == "tolerance") {
    candidates <- which(error_rates <= (min_error + tol))
    if (length(candidates) > 0) return(min(candidates))
  }
  which.min(error_rates)
}

build_result_bundle <- function(expression_df, group_factor, options, case_group, control_group) {
  results <- run_svm_rfe(expression_df, group_factor, options)
  ranking <- aggregate_rankings(results, colnames(expression_df))
  max_features <- min(options$svm_max_features_cap, ncol(expression_df))
  error_rates <- compute_error_curve(results, expression_df, group_factor, max_features)
  selected_count <- min(select_feature_count(error_rates, options$svm_select_rule, options$svm_tol), nrow(ranking))
  list(
    case_group = case_group,
    control_group = control_group,
    seed = options$seed,
    group_factor = group_factor,
    svm_res = list(
      error_rates = error_rates,
      optimal_feature_count = selected_count,
      results = ranking[seq_len(selected_count), , drop = FALSE],
      full_ranking = ranking
    )
  )
}

build_result_summary <- function(bundle) {
  ranking <- bundle$svm_res$full_ranking
  top_feature <- if (nrow(ranking) > 0) ranking$Feature[1] else "None"
  c(
    sprintf("Features ranked: %d", nrow(ranking)),
    sprintf("Optimal feature count: %d", bundle$svm_res$optimal_feature_count),
    sprintf("Top-ranked feature: %s", top_feature),
    sprintf("Minimum cross-validated error: %s", format(min(bundle$svm_res$error_rates), digits = 4, nsmall = 4))
  )
}
