xgboost_analysis <- function(params) {
  check_pkg("xgboost")

  log_info("Reading input data")
  data <- read_data(params$data_file)

  log_info("Preparing modeling data")
  model_data <- prepare_model_data(data, params)

  if (length(model_data$auto_excluded) > 0) {
    log_info("Automatically excluded identifier-like columns:", paste(model_data$auto_excluded, collapse = ", "))
  }

  split_info <- create_split_indices(model_data$label, model_data$task_type, params$test_size, params$seed)

  output_dirs <- create_output_structure(params$output_dir)

  train_matrix <- model_data$feature_matrix[split_info$train_idx, , drop = FALSE]
  test_matrix <- model_data$feature_matrix[split_info$test_idx, , drop = FALSE]
  train_label <- model_data$label[split_info$train_idx]
  test_label <- model_data$label[split_info$test_idx]

  dtrain <- xgboost::xgb.DMatrix(data = train_matrix, label = train_label, missing = NA)
  dtest <- xgboost::xgb.DMatrix(data = test_matrix, label = test_label, missing = NA)

  xgb_params <- build_xgb_params(params, model_data$task_type, model_data$nclass)

  log_info("Training XGBoost model for task type", model_data$task_type)
  model <- xgboost::xgb.train(
    params = xgb_params,
    data = dtrain,
    watchlist = list(train = dtrain, eval = dtest),
    nrounds = params$nrounds,
    early_stopping_rounds = params$early_stopping_rounds,
    verbose = 0
  )

  log_info("Generating predictions and metrics")
  train_prediction <- predict_xgb(model, dtrain, model_data$task_type, model_data$nclass)
  test_prediction <- predict_xgb(model, dtest, model_data$task_type, model_data$nclass)

  train_metrics <- compute_metrics(train_label, train_prediction, model_data$task_type, model_data$nclass)
  test_metrics <- compute_metrics(test_label, test_prediction, model_data$task_type, model_data$nclass)
  train_metrics$Dataset <- "train"
  test_metrics$Dataset <- "test"
  performance_df <- rbind(train_metrics, test_metrics)
  best_iteration <- if (is.null(model$best_iteration)) params$nrounds else model$best_iteration

  performance_df <- performance_df[, c("Dataset", "Metric", "Value")]

  performance_df$TaskType <- model_data$task_type
  performance_df$BestIteration <- best_iteration

  if (model_data$task_type == "classification") {
    performance_df$ClassLevels <- paste(model_data$class_levels, collapse = "|")
  } else {
    performance_df$ClassLevels <- NA_character_
  }

  performance_df <- performance_df[, c("Dataset", "Metric", "Value", "TaskType", "BestIteration", "ClassLevels")]

  log_info("Calculating feature importance")
  importance_encoded <- xgboost::xgb.importance(
    feature_names = colnames(model_data$feature_matrix),
    model = model
  )

  importance_aggregated <- aggregate_importance(importance_encoded, model_data$feature_map, params$importance_metric)

  performance_path <- table_output_path(output_dirs$table_dir, params$output_prefix, "model_performance", params$output_format)
  importance_path <- table_output_path(output_dirs$table_dir, params$output_prefix, "feature_importance", params$output_format)
  figure_path <- file.path(
    output_dirs$figure_dir,
    sprintf("%s_feature_importance_%s.png", params$output_prefix, params$importance_metric)
  )

  save_table(performance_df, performance_path, params$output_format)
  save_table(importance_aggregated, importance_path, params$output_format)
  create_importance_plot(importance_aggregated, figure_path, params$importance_metric, params$top_n)

  log_info("Analysis completed successfully")
  log_info("Performance table:", performance_path)
  log_info("Feature importance table:", importance_path)
  log_info("Feature importance figure:", figure_path)

  list(
    model = model,
    performance = performance_df,
    importance_table = importance_aggregated,
    output_dirs = output_dirs,
    output_files = list(
      performance = performance_path,
      importance = importance_path,
      figure = figure_path
    )
  )
}
