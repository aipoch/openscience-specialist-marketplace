save_results <- function(metrics_df, importance_df, remediation_df, output_dirs, params) {
  extension <- if (params$output_format == "csv") "csv" else "txt"

  metrics_file <- file.path(output_dirs$table_dir, paste0("lightgbm_model_metrics.", extension))
  importance_file <- file.path(output_dirs$table_dir, paste0("lightgbm_feature_importance.", extension))
  remediation_file <- file.path(output_dirs$table_dir, paste0("lightgbm_remediation.", extension))

  write_table_file(metrics_df, metrics_file, params$output_format)
  write_table_file(importance_df, importance_file, params$output_format)
  write_table_file(remediation_df, remediation_file, params$output_format)

  log_info("Saved model metrics to:", metrics_file)
  log_info("Saved feature importance table to:", importance_file)
  log_info("Saved remediation guidance to:", remediation_file)

  list(
    metrics_file = metrics_file,
    importance_file = importance_file,
    remediation_file = remediation_file
  )
}

save_run_summary <- function(metrics_df, importance_df, output_dirs, result_files, figure_file, encoder_file) {
  metric_fields <- c("rmse", "mae", "r_squared", "accuracy", "auc", "logloss", "precision", "recall", "f1", "multi_logloss")
  available_metrics <- metric_fields[metric_fields %in% names(metrics_df)]
  encoder_value <- if (is.null(encoder_file) || !nzchar(encoder_file)) "none" else encoder_file
  metric_lines <- vapply(available_metrics, function(field) {
    value <- metrics_df[[field]][[1]]
    if (is.na(value)) {
      return(paste0(field, ": NA"))
    }
    paste0(field, ": ", format(signif(value, 6), trim = TRUE, scientific = FALSE))
  }, character(1))

  top_n <- min(5, nrow(importance_df))
  top_features <- if (top_n == 0) "none" else paste(importance_df$feature[seq_len(top_n)], collapse = ", ")
  summary_file <- file.path(output_dirs$data_dir, "lightgbm_run_summary.txt")
  summary_lines <- c(
    paste0("task_type: ", metrics_df$task_type[[1]]),
    paste0("metric_primary: ", metrics_df$metric_primary[[1]]),
    paste0("best_iteration: ", metrics_df$best_iteration[[1]]),
    paste0("model_quality_flag: ", metrics_df$model_quality_flag[[1]]),
    paste0("interpretation_status: ", metrics_df$interpretation_status[[1]]),
    paste0("primary_issue: ", metrics_df$primary_issue[[1]]),
    paste0("model_quality_issues: ", metrics_df$model_quality_issues[[1]]),
    paste0("rerun_hint: ", metrics_df$rerun_hint[[1]]),
    paste0("top_features: ", top_features),
    paste0("metrics_file: ", result_files$metrics_file),
    paste0("importance_file: ", result_files$importance_file),
    paste0("remediation_file: ", result_files$remediation_file),
    paste0("figure_file: ", figure_file),
    paste0("encoder_file: ", encoder_value),
    "metrics:",
    paste0("- ", metric_lines)
  )

  writeLines(summary_lines, summary_file)
  log_info("Saved run summary to:", summary_file)
  summary_file
}

lightgbm_analysis <- function(params) {
  log_info("Starting LightGBM analysis")
  data <- read_data(params$data_file)

  prepared <- prepare_model_input(data, params)
  check_pkg("lightgbm")
  log_info("Resolved task type:", prepared$task_type)
  log_info("Selected", length(prepared$feature_names), "feature columns")

  output_dirs <- create_output_structure(params$output_dir, params$fail_if_output_exists)
  split_data <- split_model_input(prepared, params)
  trained <- train_lightgbm_model(prepared, split_data, params)
  metrics_df <- evaluate_model(trained$model, prepared, split_data, trained$metric_name)
  importance_df <- collect_feature_importance(trained$model, prepared$feature_names, params$importance_type)
  validate_analysis_outputs(metrics_df, importance_df, params)
  metrics_df <- annotate_model_quality(metrics_df, importance_df, params)
  remediation_df <- build_remediation_table(metrics_df)
  result_files <- save_results(metrics_df, importance_df, remediation_df, output_dirs, params)
  figure_file <- plot_feature_importance(importance_df, output_dirs, params)
  encoder_file <- save_encoder_metadata(prepared, output_dirs, params)
  summary_file <- save_run_summary(metrics_df, importance_df, output_dirs, result_files, figure_file, encoder_file)
  save_session_info(params$output_dir)

  log_info("LightGBM analysis completed successfully")

  invisible(list(
    metrics = metrics_df,
    feature_importance = importance_df,
    output_dirs = output_dirs,
    result_files = result_files,
    figure_file = figure_file,
    encoder_file = encoder_file,
    summary_file = summary_file,
    best_iteration = trained$best_iteration,
    task_type = prepared$task_type
  ))
}
