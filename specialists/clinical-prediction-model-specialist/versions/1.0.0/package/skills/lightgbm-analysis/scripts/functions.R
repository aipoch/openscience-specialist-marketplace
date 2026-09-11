parse_column_list <- function(x) {
  if (is.null(x) || !nzchar(trimws(x))) {
    return(NULL)
  }
  values <- trimws(strsplit(x, ",", fixed = TRUE)[[1]])
  values[nzchar(values)]
}

warn_on_suspicious_features <- function(selected_features) {
  suspicious_patterns <- c(
    "^id$",
    "^ids$",
    "^sample_?id$",
    "^patient_?id$",
    "^subject_?id$",
    "^case_?id$",
    "^record_?id$",
    "^accession$",
    "^accession_number$",
    "^v1$",
    "_id$"
  )

  suspicious_features <- selected_features[vapply(selected_features, function(feature_name) {
    feature_name_lc <- tolower(feature_name)
    any(vapply(suspicious_patterns, grepl, logical(1), x = feature_name_lc, perl = TRUE))
  }, logical(1))]

  if (length(suspicious_features) > 0) {
    log_warn(
      "Potential identifier-like columns are still included in modeling:",
      paste(suspicious_features, collapse = ", "),
      "Review --drop_cols or --feature_cols before interpreting exported rankings."
    )
  }
}

resolve_feature_columns <- function(data, target_var, feature_cols = NULL, drop_cols = NULL) {
  available_cols <- colnames(data)

  if (!(target_var %in% available_cols)) {
    stop("SKILL_MISSING_COLUMNS: target_var '", target_var, "' not found in data")
  }

  requested_features <- parse_column_list(feature_cols)
  dropped_features <- unique(parse_column_list(drop_cols))

  if (!is.null(requested_features)) {
    missing_requested <- setdiff(requested_features, available_cols)
    if (length(missing_requested) > 0) {
      stop("SKILL_MISSING_COLUMNS: Requested feature columns not found: ", paste(missing_requested, collapse = ", "))
    }
    selected_features <- requested_features
  } else {
    selected_features <- setdiff(available_cols, c(target_var, dropped_features))
  }

  selected_features <- setdiff(selected_features, target_var)

  if (!is.null(dropped_features)) {
    missing_drops <- setdiff(dropped_features, available_cols)
    if (length(missing_drops) > 0) {
      stop("SKILL_MISSING_COLUMNS: drop_cols not found in data: ", paste(missing_drops, collapse = ", "))
    }
    selected_features <- setdiff(selected_features, dropped_features)
  }

  if (length(selected_features) == 0) {
    stop("SKILL_INVALID_DATA: No usable feature columns remain after applying target_var and drop_cols")
  }

  warn_on_suspicious_features(selected_features)

  selected_features
}

infer_task_type <- function(y) {
  y_non_missing <- y[!is.na(y)]
  unique_values <- unique(y_non_missing)

  if (length(unique_values) < 2) {
    stop("SKILL_INVALID_DATA: Target must contain at least two distinct values")
  }

  if (!is.numeric(y_non_missing) && !is.integer(y_non_missing)) {
    if (length(unique_values) == 2) "binary" else "multiclass"
  } else {
    if (length(unique_values) == 2) {
      return("binary")
    }

    integer_like <- all(abs(unique_values - round(unique_values)) < 1e-8)
    class_threshold <- min(20, max(3, floor(length(y_non_missing) * 0.2)))
    if (integer_like && length(unique_values) <= class_threshold) "multiclass" else "regression"
  }
}

encode_feature_frame <- function(feature_df) {
  encoded_cols <- list()
  categorical_features <- character(0)
  encoders <- list()

  for (feature_name in colnames(feature_df)) {
    column <- feature_df[[feature_name]]

    if (is.factor(column) || is.character(column)) {
      factor_col <- factor(column)
      encoded_values <- as.integer(factor_col) - 1L
      encoded_cols[[feature_name]] <- as.numeric(encoded_values)
      categorical_features <- c(categorical_features, feature_name)
      encoders[[feature_name]] <- levels(factor_col)
    } else if (is.logical(column)) {
      encoded_cols[[feature_name]] <- as.numeric(column)
    } else if (is.numeric(column) || is.integer(column)) {
      encoded_cols[[feature_name]] <- as.numeric(column)
    } else {
      stop("SKILL_INVALID_DATA: Unsupported feature type for column '", feature_name, "'")
    }
  }

  encoded_df <- as.data.frame(encoded_cols, check.names = FALSE, stringsAsFactors = FALSE)
  matrix_data <- as.matrix(encoded_df)
  colnames(matrix_data) <- colnames(encoded_df)

  list(
    matrix = matrix_data,
    feature_names = colnames(encoded_df),
    categorical_features = categorical_features,
    encoders = encoders
  )
}

encode_target <- function(target, task_type) {
  if (task_type == "regression") {
    if (!(is.numeric(target) || is.integer(target))) {
      stop("SKILL_INVALID_DATA: Regression target must be numeric")
    }

    return(list(
      values = as.numeric(target),
      levels = NULL
    ))
  }

  target_factor <- factor(target)
  if (length(levels(target_factor)) < 2) {
    stop("SKILL_INVALID_DATA: Classification target must contain at least two classes")
  }

  if (task_type == "binary" && length(levels(target_factor)) != 2) {
    stop("SKILL_INVALID_DATA: Binary task requires exactly two target classes")
  }

  list(
    values = as.integer(target_factor) - 1L,
    levels = levels(target_factor)
  )
}

prepare_model_input <- function(data, params) {
  feature_cols <- resolve_feature_columns(data, params$target_var, params$feature_cols, params$drop_cols)
  modeling_data <- data[, c(feature_cols, params$target_var), with = FALSE]

  non_missing_target <- !is.na(modeling_data[[params$target_var]])
  modeling_data <- modeling_data[non_missing_target]

  if (nrow(modeling_data) < 20) {
    stop("SKILL_INVALID_DATA: Need at least 20 rows after removing missing target values")
  }

  task_type <- if (params$task_type == "auto") infer_task_type(modeling_data[[params$target_var]]) else params$task_type
  feature_df <- as.data.frame(modeling_data[, feature_cols, with = FALSE], stringsAsFactors = FALSE)
  encoded_features <- encode_feature_frame(feature_df)
  encoded_target <- encode_target(modeling_data[[params$target_var]], task_type)

  if (nrow(encoded_features$matrix) != length(encoded_target$values)) {
    stop("SKILL_INVALID_DATA: Feature matrix row count does not match target length")
  }

  list(
    feature_matrix = encoded_features$matrix,
    target = encoded_target$values,
    target_levels = encoded_target$levels,
    task_type = task_type,
    feature_names = encoded_features$feature_names,
    categorical_features = encoded_features$categorical_features,
    feature_encoders = encoded_features$encoders,
    n_rows = nrow(modeling_data)
  )
}

stratified_sample_indices <- function(y, proportion, min_remaining = 1) {
  sampled_idx <- integer(0)

  for (class_value in unique(y)) {
    class_idx <- which(y == class_value)
    if (length(class_idx) <= min_remaining) {
      next
    }

    take_n <- floor(length(class_idx) * proportion)
    if (take_n == 0 && proportion > 0 && length(class_idx) > (min_remaining + 1)) {
      take_n <- 1
    }

    take_n <- min(take_n, length(class_idx) - min_remaining)
    if (take_n > 0) {
      sampled_idx <- c(sampled_idx, sample(class_idx, take_n))
    }
  }

  sort(unique(sampled_idx))
}

split_model_input <- function(prepared, params) {
  set.seed(params$seed)

  n <- nrow(prepared$feature_matrix)
  all_idx <- seq_len(n)
  is_classification <- prepared$task_type %in% c("binary", "multiclass")

  if (is_classification) {
    test_idx <- stratified_sample_indices(prepared$target, params$test_size, min_remaining = 2)
  } else {
    test_n <- max(1, floor(n * params$test_size))
    test_n <- min(test_n, n - 3)
    test_idx <- sort(sample(all_idx, test_n))
  }

  train_valid_idx <- setdiff(all_idx, test_idx)
  train_valid_target <- prepared$target[train_valid_idx]

  if (length(train_valid_idx) < 3 || length(test_idx) < 1) {
    stop("SKILL_INVALID_DATA: Not enough rows remain after the train/test split")
  }

  if (is_classification) {
    valid_local_idx <- stratified_sample_indices(train_valid_target, params$valid_size, min_remaining = 1)
    valid_idx <- train_valid_idx[valid_local_idx]
  } else {
    valid_n <- max(1, floor(length(train_valid_idx) * params$valid_size))
    valid_n <- min(valid_n, length(train_valid_idx) - 2)
    valid_idx <- sort(sample(train_valid_idx, valid_n))
  }

  train_idx <- setdiff(train_valid_idx, valid_idx)

  if (length(train_idx) < 2 || length(valid_idx) < 1) {
    stop("SKILL_INVALID_DATA: Not enough rows remain after the train/validation split")
  }

  list(
    train_matrix = prepared$feature_matrix[train_idx, , drop = FALSE],
    train_label = prepared$target[train_idx],
    valid_matrix = prepared$feature_matrix[valid_idx, , drop = FALSE],
    valid_label = prepared$target[valid_idx],
    test_matrix = prepared$feature_matrix[test_idx, , drop = FALSE],
    test_label = prepared$target[test_idx],
    train_rows = length(train_idx),
    valid_rows = length(valid_idx),
    test_rows = length(test_idx)
  )
}

resolve_metric <- function(task_type, metric) {
  if (metric != "auto") {
    return(metric)
  }

  if (task_type == "regression") {
    "rmse"
  } else if (task_type == "binary") {
    "binary_logloss"
  } else {
    "multi_logloss"
  }
}

build_lgb_params <- function(params, prepared, metric_name) {
  objective <- if (prepared$task_type == "regression") {
    "regression"
  } else if (prepared$task_type == "binary") {
    "binary"
  } else {
    "multiclass"
  }

  lgb_params <- list(
    objective = objective,
    metric = metric_name,
    learning_rate = params$learning_rate,
    num_leaves = params$num_leaves,
    max_depth = params$max_depth,
    min_data_in_leaf = params$min_data_in_leaf,
    feature_fraction = params$feature_fraction,
    bagging_fraction = params$bagging_fraction,
    bagging_freq = params$bagging_freq,
    lambda_l1 = params$lambda_l1,
    lambda_l2 = params$lambda_l2,
    seed = params$seed
  )

  if (prepared$task_type == "multiclass") {
    lgb_params$num_class <- length(prepared$target_levels)
  }

  lgb_params
}

validate_analysis_outputs <- function(metrics_df, importance_df, params) {
  gain_sum <- sum(importance_df$gain, na.rm = TRUE)
  split_sum <- sum(importance_df$split, na.rm = TRUE)
  selected_sum <- if (params$importance_type == "gain") gain_sum else split_sum

  if (selected_sum == 0) {
    log_warn(
      "Requested", params$importance_type, "importance is all zero.",
      "Try lowering --min_data_in_leaf, checking feature signal, or using --importance_type gain."
    )
  }

  if (gain_sum == 0 && split_sum == 0) {
    stop(
      "SKILL_DEGENERATE_MODEL: The trained model produced an all-zero feature importance table. ",
      "Try lowering --min_data_in_leaf, reviewing --feature_cols, or rerunning with --importance_type gain."
    )
  }

  if (isTRUE(metrics_df$best_iteration[[1]] <= 1)) {
    log_warn(
      "Training stopped at the first boosting iteration.",
      "If the metrics look weak, try lowering --min_data_in_leaf or revisiting the feature set."
    )
  }

  invisible(NULL)
}

annotate_model_quality <- function(metrics_df, importance_df, params) {
  collect_model_quality_issues <- function(metrics_df, importance_df, params) {
    issues <- character(0)
    selected_values <- if (params$importance_type == "gain") importance_df$gain else importance_df$split
    nonzero_selected <- sum(selected_values > 0, na.rm = TRUE)

    if (isTRUE(metrics_df$best_iteration[[1]] <= 1)) {
      issues <- c(issues, "best_iteration<=1")
    }

    if ("prediction_collapse_flag" %in% names(metrics_df) && isTRUE(metrics_df$prediction_collapse_flag[[1]])) {
      issues <- c(issues, "single_predicted_class")
    }

    if (identical(metrics_df$task_type[[1]], "binary")) {
      if (isTRUE(metrics_df$recall[[1]] == 0)) {
        issues <- c(issues, "recall=0")
      }

      if (is.na(metrics_df$f1[[1]])) {
        issues <- c(issues, "f1=NA")
      }

      if (is.na(metrics_df$precision[[1]])) {
        issues <- c(issues, "no_positive_predictions")
      }
    }

    if (nonzero_selected <= 1) {
      issues <- c(issues, paste0(params$importance_type, "_importance_sparse"))
    }

    unique(issues)
  }

  build_rerun_recommendations <- function(issues, params) {
    recommendations <- character(0)

    if ("best_iteration<=1" %in% issues) {
      recommendations <- c(recommendations, "Lower --min_data_in_leaf and rerun after checking that the selected features contain signal.")
    }

    if ("single_predicted_class" %in% issues) {
      recommendations <- c(recommendations, "Review class balance and the selected predictors before using the ranking downstream.")
    }

    if ("recall=0" %in% issues || "no_positive_predictions" %in% issues) {
      recommendations <- c(recommendations, "Revisit --feature_cols or the target balance if the model predicts no positive cases on the test split.")
    }

    if ("f1=NA" %in% issues) {
      recommendations <- c(recommendations, "Treat the run as diagnostic-only until precision and recall are both defined on a rerun.")
    }

    if (paste0(params$importance_type, "_importance_sparse") %in% issues) {
      alternate_type <- if (params$importance_type == "gain") "split" else "gain"
      recommendations <- c(recommendations, paste0("Switch to --importance_type ", alternate_type, " or reduce the feature set if the selected importance values stay sparse."))
    }

    unique(recommendations)
  }

  issues <- collect_model_quality_issues(metrics_df, importance_df, params)
  blocking_issues <- c("best_iteration<=1", "single_predicted_class", "recall=0", "f1=NA", "no_positive_predictions")
  rerun_recommendations <- build_rerun_recommendations(issues, params)

  metrics_df$model_quality_flag <- if (length(issues) == 0) "ok" else "caution"
  metrics_df$interpretation_status <- if (length(issues) == 0) {
    "eligible"
  } else if (length(intersect(issues, blocking_issues)) > 0) {
    "caution_only"
  } else {
    "eligible_with_caveats"
  }
  metrics_df$primary_issue <- if (length(issues) == 0) "none" else issues[[1]]
  metrics_df$model_quality_issues <- if (length(issues) == 0) "none" else paste(issues, collapse = "; ")
  metrics_df$rerun_hint <- if (length(rerun_recommendations) == 0) {
    "No rerun changes required."
  } else {
    paste(rerun_recommendations, collapse = " | ")
  }
  metrics_df$model_quality_note <- if (length(issues) == 0) {
    "Interpretation eligible."
  } else {
    paste("Interpret with caution:", paste(issues, collapse = "; "))
  }

  if (length(issues) > 0) {
    log_warn("Model quality requires caution:", paste(issues, collapse = "; "))
    log_warn("Recommended next step:", metrics_df$rerun_hint[[1]])
  }

  metrics_df
}

build_remediation_table <- function(metrics_df) {
  build_issue_row <- function(issue_code, metrics_df) {
    issue_detail <- switch(
      issue_code,
      "best_iteration<=1" = "Training stopped at the first boosting iteration.",
      "single_predicted_class" = "Predictions collapsed to a single class on the test split.",
      "recall=0" = "The model failed to recover any positive cases on the test split.",
      "f1=NA" = "F1 is undefined because precision or recall was undefined or zero.",
      "no_positive_predictions" = "The model predicted no positive cases on the test split.",
      "gain_importance_sparse" = "Gain-based importance contains at most one non-zero feature.",
      "split_importance_sparse" = "Split-based importance contains at most one non-zero feature.",
      "No remediation required."
    )

    recommended_action <- switch(
      issue_code,
      "best_iteration<=1" = "Lower --min_data_in_leaf and verify that the selected predictors have usable signal before rerunning.",
      "single_predicted_class" = "Check class balance, feature leakage, and feature selection before using the ranking downstream.",
      "recall=0" = "Review target balance and adjust the feature set before treating the result as report-ready.",
      "f1=NA" = "Use the run for diagnostics only and rerun after fixing the collapsed prediction behavior.",
      "no_positive_predictions" = "Revisit --feature_cols or reduce regularization if the classifier predicts no positive cases.",
      "gain_importance_sparse" = "Retry with stronger predictors or switch to --importance_type split for diagnostic comparison.",
      "split_importance_sparse" = "Retry with stronger predictors or switch to --importance_type gain for the default ranking view.",
      "No rerun changes required."
    )

    suggested_rerun_change <- switch(
      issue_code,
      "best_iteration<=1" = "lower --min_data_in_leaf; review --feature_cols",
      "single_predicted_class" = "review target balance; review --feature_cols",
      "recall=0" = "review target balance; review --feature_cols",
      "f1=NA" = "rerun after restoring defined precision and recall",
      "no_positive_predictions" = "review --feature_cols; lower --min_data_in_leaf",
      "gain_importance_sparse" = "switch --importance_type split; review feature signal",
      "split_importance_sparse" = "switch --importance_type gain; review feature signal",
      "none"
    )

    data.frame(
      task_type = metrics_df$task_type[[1]],
      model_quality_flag = metrics_df$model_quality_flag[[1]],
      interpretation_status = metrics_df$interpretation_status[[1]],
      issue_code = issue_code,
      issue_detail = issue_detail,
      recommended_action = recommended_action,
      suggested_rerun_change = suggested_rerun_change,
      stringsAsFactors = FALSE
    )
  }

  issues_text <- metrics_df$model_quality_issues[[1]]
  if (!nzchar(issues_text) || identical(issues_text, "none")) {
    return(build_issue_row("none", metrics_df))
  }

  issues <- trimws(strsplit(issues_text, ";", fixed = TRUE)[[1]])
  do.call(rbind, lapply(issues, build_issue_row, metrics_df = metrics_df))
}

train_lightgbm_model <- function(prepared, split_data, params) {
  check_pkg("lightgbm")

  metric_name <- resolve_metric(prepared$task_type, params$metric)
  lgb_params <- build_lgb_params(params, prepared, metric_name)

  train_dataset_args <- list(
    data = split_data$train_matrix,
    label = split_data$train_label,
    colnames = prepared$feature_names,
    free_raw_data = FALSE
  )
  valid_dataset_args <- list(
    data = split_data$valid_matrix,
    label = split_data$valid_label,
    colnames = prepared$feature_names,
    free_raw_data = FALSE
  )

  if (length(prepared$categorical_features) > 0) {
    train_dataset_args$categorical_feature <- prepared$categorical_features
    valid_dataset_args$categorical_feature <- prepared$categorical_features
  }

  dtrain <- do.call(lightgbm::lgb.Dataset, train_dataset_args)
  dvalid <- do.call(lightgbm::lgb.Dataset, valid_dataset_args)

  log_info("Training LightGBM model with task type:", prepared$task_type)
  log_info("Primary metric:", metric_name)

  if (nrow(split_data$train_matrix) < 100 && params$min_data_in_leaf >= 10) {
    log_warn(
      "Small training split detected with a relatively large --min_data_in_leaf.",
      "Consider reducing it if the model stops early or returns zero importance."
    )
  }

  model <- tryCatch({
    lightgbm::lgb.train(
      params = lgb_params,
      data = dtrain,
      nrounds = params$nrounds,
      valids = list(valid = dvalid),
      early_stopping_rounds = params$early_stopping_rounds,
      verbose = -1
    )
  }, error = function(e) {
    stop("SKILL_TRAINING_FAILED: ", e$message)
  })

  list(
    model = model,
    metric_name = metric_name,
    best_iteration = model$best_iter
  )
}

binary_auc <- function(labels, scores) {
  pos_scores <- scores[labels == 1]
  neg_scores <- scores[labels == 0]

  if (length(pos_scores) == 0 || length(neg_scores) == 0) {
    return(NA_real_)
  }

  ranks <- rank(c(pos_scores, neg_scores))
  (sum(ranks[seq_along(pos_scores)]) - length(pos_scores) * (length(pos_scores) + 1) / 2) /
    (length(pos_scores) * length(neg_scores))
}

safe_logloss <- function(actual, predicted) {
  p <- pmin(pmax(predicted, 1e-15), 1 - 1e-15)
  -mean(actual * log(p) + (1 - actual) * log(1 - p))
}

multiclass_logloss <- function(actual, predicted_matrix) {
  clipped <- pmin(pmax(predicted_matrix, 1e-15), 1 - 1e-15)
  row_idx <- seq_len(nrow(clipped))
  -mean(log(clipped[cbind(row_idx, actual + 1L)]))
}

evaluate_model <- function(model, prepared, split_data, metric_name) {
  if (prepared$task_type == "regression") {
    predictions <- as.numeric(predict(model, split_data$test_matrix))
    rmse <- sqrt(mean((split_data$test_label - predictions)^2))
    mae <- mean(abs(split_data$test_label - predictions))
    sst <- sum((split_data$test_label - mean(split_data$test_label))^2)
    sse <- sum((split_data$test_label - predictions)^2)
    r_squared <- if (sst == 0) NA_real_ else 1 - (sse / sst)

    return(data.frame(
      task_type = prepared$task_type,
      metric_primary = metric_name,
      best_iteration = model$best_iter,
      train_rows = split_data$train_rows,
      valid_rows = split_data$valid_rows,
      test_rows = split_data$test_rows,
      prediction_collapse_flag = NA,
      rmse = rmse,
      mae = mae,
      r_squared = r_squared,
      stringsAsFactors = FALSE
    ))
  }

  if (prepared$task_type == "binary") {
    probabilities <- as.numeric(predict(model, split_data$test_matrix))
    predicted_class <- as.integer(probabilities >= 0.5)
    accuracy <- mean(predicted_class == split_data$test_label)
    auc_value <- binary_auc(split_data$test_label, probabilities)
    precision_den <- sum(predicted_class == 1)
    recall_den <- sum(split_data$test_label == 1)
    precision <- if (precision_den == 0) NA_real_ else sum(predicted_class == 1 & split_data$test_label == 1) / precision_den
    recall <- if (recall_den == 0) NA_real_ else sum(predicted_class == 1 & split_data$test_label == 1) / recall_den
    f1 <- if (is.na(precision) || is.na(recall) || (precision + recall) == 0) NA_real_ else 2 * precision * recall / (precision + recall)

    if (length(unique(predicted_class)) == 1) {
      log_warn("Binary predictions collapsed to a single class on the test split.")
    }

    if (precision_den == 0 || isTRUE(recall == 0)) {
      log_warn("Binary model predicted no positive cases on the test split; precision and F1 may be undefined.")
    }

    return(data.frame(
      task_type = prepared$task_type,
      metric_primary = metric_name,
      best_iteration = model$best_iter,
      train_rows = split_data$train_rows,
      valid_rows = split_data$valid_rows,
      test_rows = split_data$test_rows,
      prediction_collapse_flag = length(unique(predicted_class)) == 1,
      accuracy = accuracy,
      auc = auc_value,
      logloss = safe_logloss(split_data$test_label, probabilities),
      precision = precision,
      recall = recall,
      f1 = f1,
      stringsAsFactors = FALSE
    ))
  }

  probabilities <- predict(model, split_data$test_matrix, reshape = TRUE)
  predicted_class <- max.col(probabilities) - 1L
  accuracy <- mean(predicted_class == split_data$test_label)

  if (length(unique(predicted_class)) == 1) {
    log_warn("Multiclass predictions collapsed to a single class on the test split.")
  }

  data.frame(
    task_type = prepared$task_type,
    metric_primary = metric_name,
    best_iteration = model$best_iter,
    train_rows = split_data$train_rows,
    valid_rows = split_data$valid_rows,
    test_rows = split_data$test_rows,
    prediction_collapse_flag = length(unique(predicted_class)) == 1,
    accuracy = accuracy,
    multi_logloss = multiclass_logloss(split_data$test_label, probabilities),
    stringsAsFactors = FALSE
  )
}

collect_feature_importance <- function(model, feature_names, importance_type) {
  importance_df <- as.data.frame(lightgbm::lgb.importance(model, percentage = FALSE), stringsAsFactors = FALSE)

  if (nrow(importance_df) == 0) {
    importance_df <- data.frame(Feature = character(0), Gain = numeric(0), Cover = numeric(0), Frequency = numeric(0), stringsAsFactors = FALSE)
  }

  full_df <- data.frame(feature = feature_names, stringsAsFactors = FALSE)
  merged_df <- merge(full_df, importance_df, by.x = "feature", by.y = "Feature", all.x = TRUE, sort = FALSE)
  merged_df$Gain[is.na(merged_df$Gain)] <- 0
  merged_df$Cover[is.na(merged_df$Cover)] <- 0
  merged_df$Frequency[is.na(merged_df$Frequency)] <- 0

  merged_df$importance_type <- importance_type
  merged_df$importance_value <- if (importance_type == "gain") merged_df$Gain else merged_df$Frequency
  merged_df$gain_share <- if (sum(merged_df$Gain) == 0) 0 else merged_df$Gain / sum(merged_df$Gain)
  merged_df$split_share <- if (sum(merged_df$Frequency) == 0) 0 else merged_df$Frequency / sum(merged_df$Frequency)

  ordered_df <- merged_df[order(-merged_df$importance_value, -merged_df$Gain, -merged_df$Frequency, merged_df$feature), ]
  ordered_df$rank <- seq_len(nrow(ordered_df))

  result_df <- ordered_df[, c("feature", "Gain", "Frequency", "Cover", "importance_type", "importance_value", "rank", "gain_share", "split_share")]
  colnames(result_df) <- c("feature", "gain", "split", "cover", "importance_type", "importance_value", "rank", "gain_share", "split_share")
  result_df
}

plot_feature_importance <- function(importance_df, output_dirs, params) {
  top_n <- min(params$top_n, nrow(importance_df))
  plot_df <- importance_df[seq_len(top_n), , drop = FALSE]

  if (nrow(plot_df) == 0) {
    stop("SKILL_INVALID_DATA: No feature importance values available for plotting")
  }

  figure_file <- file.path(
    output_dirs$figure_dir,
    paste0("lightgbm_feature_importance_", params$importance_type, ".pdf")
  )

  plot_values <- rev(plot_df$importance_value)
  plot_names <- rev(plot_df$feature)
  image_height <- max(900, 80 * nrow(plot_df))

  grDevices::pdf(file = figure_file, width = 10, height = max(6, image_height / 160))
  old_par <- graphics::par(no.readonly = TRUE)
  on.exit({
    graphics::par(old_par)
    grDevices::dev.off()
  }, add = TRUE)

  left_margin <- min(24, max(8, ceiling(max(nchar(plot_names)) / 2)))
  graphics::par(mar = c(5, left_margin, 4, 3))

  bar_pos <- graphics::barplot(
    height = plot_values,
    names.arg = plot_names,
    horiz = TRUE,
    las = 1,
    col = "#4C78A8",
    border = NA,
    main = paste("Top", nrow(plot_df), "Feature Importance"),
    xlab = if (params$importance_type == "gain") "Gain importance" else "Split importance"
  )

  graphics::text(plot_values, bar_pos, labels = format(round(plot_values, 4), nsmall = 4), pos = 4, cex = 0.8, xpd = NA)
  log_info("Saved feature importance plot to:", figure_file)

  figure_file
}

save_encoder_metadata <- function(prepared, output_dirs, params) {
  if (length(prepared$feature_encoders) == 0) {
    return(NULL)
  }

  encoder_file <- file.path(output_dirs$data_dir, "lightgbm_categorical_levels.txt")
  lines <- unlist(lapply(names(prepared$feature_encoders), function(name) {
    paste0(name, ": ", paste(prepared$feature_encoders[[name]], collapse = ", "))
  }))
  writeLines(lines, encoder_file)
  log_info("Saved categorical encoder metadata to:", encoder_file)
  encoder_file
}
