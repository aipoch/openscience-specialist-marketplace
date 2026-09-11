run_analysis <- function(options) {
  ensure_dir(options$output_dir)
  ensure_dir(file.path(options$output_dir, "data"))
  ensure_dir(file.path(options$output_dir, "table"))
  ensure_dir(file.path(options$output_dir, "plot"))

  model_path <- file.path(options$output_dir, "data", "rf_result.rds")

  if (isTRUE(options$plot_only)) {
    if (!file.exists(model_path)) {
      fail("SKILL_FILE_NOT_FOUND", sprintf("Plot-only mode requires an existing model file: %s", model_path))
    }

    bundle <- readRDS(model_path)
    input_summary <- c(
      sprintf("Plot-only mode: TRUE"),
      sprintf("Existing model file: %s", model_path),
      sprintf("Stored case group: %s", bundle$case_group),
      sprintf("Stored control group: %s", bundle$control_group)
    )
    result_summary <- c("Model tables were reused from the existing rf_result.rds bundle.")
  } else {
    log_info("Reading input files.")
    group_df <- read_group_data(options$group_file, options$case_group, options$control_group)
    expression_df <- read_expression_data(options$input_file)
    aligned <- align_input_data(expression_df, group_df, options$case_group, options$control_group)

    log_info("Training random forest model.")
    model_frame <- build_model_frame(aligned$expression, aligned$group)
    rf_model <- run_random_forest_model(model_frame, options)
    importance_results <- extract_importance_results(rf_model, options)

    bundle <- list(
      model = rf_model,
      case_group = options$case_group,
      control_group = options$control_group,
      seed = options$seed,
      input_summary = aligned$input_summary,
      importance_results = importance_results
    )

    log_info("Saving model objects and tables.")
    saveRDS(bundle, model_path)
    save_table(importance_results$ranked_table, file.path(options$output_dir, "table", "rf_feature_importance.csv"))
    save_table(importance_results$top_features, file.path(options$output_dir, "table", "rf_top_features.csv"))
    input_summary <- c(
      aligned$input_summary,
      sprintf("Expression file: %s", options$input_file),
      sprintf("Group file: %s", options$group_file)
    )
    result_summary <- build_result_summary(importance_results, rf_model)
  }

  rf_model <- bundle$model
  log_info("Generating plots.")
  save_rf_error_plot(rf_model, options, file.path(options$output_dir, "plot", "rf_error_plot.pdf"))
  save_rf_importance_plot(rf_model, options, file.path(options$output_dir, "plot", "rf_importance_plot.pdf"))

  list(
    input_summary = input_summary,
    result_summary = result_summary
  )
}
