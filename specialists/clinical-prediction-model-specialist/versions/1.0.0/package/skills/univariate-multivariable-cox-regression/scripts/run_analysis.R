run_analyze_command <- function(options) {
  check_required_packages(c("survival", "openxlsx"))
  validate_choice(options$skip_univariate, "--skip_univariate", c("true", "false"))
  features <- parse_feature_arg(options$features)
  output_paths <- create_output_dirs(options$output_dir, overwrite = isTRUE(options$overwrite))

  log_info("Loading clinical data...")
  clinical_data <- read_clinical_data(options$data_file)
  analysis_data <- prepare_analysis_data(clinical_data, features, options$time_col, options$event_col)
  saveRDS(analysis_data, file = file.path(output_paths$data, "analysis_data.rds"))

  run_params <- list(
    data_file = normalizePath(options$data_file, winslash = "/", mustWork = TRUE),
    features = paste(features, collapse = ","),
    time_col = options$time_col,
    event_col = options$event_col,
    skip_univariate = options$skip_univariate,
    output_dir = output_paths$root,
    overwrite = isTRUE(options$overwrite),
    seed = options$seed,
    timeout_seconds = options$timeout_seconds
  )

  if (options$skip_univariate == "false") {
    log_info("Running univariate Cox regression...")
    univariate_rows <- run_univariate_cox(analysis_data, features, options$time_col, options$event_col)
    openxlsx::write.xlsx(univariate_rows[, c("Characteristics", "Total(N)", "HR (95% CI)", "P value", "feature")], file.path(output_paths$table, "prognosis_uni_cox_results.xlsx"), overwrite = TRUE, na.string = "")
    multivariable_features <- select_multivariable_features(univariate_rows, features)
  } else {
    log_info("Skipping univariate Cox regression by user request")
    multivariable_features <- features
  }

  log_info("Running multivariable Cox regression...")
  multivariable_rows <- run_multivariable_cox(analysis_data, multivariable_features, options$time_col, options$event_col)
  openxlsx::write.xlsx(multivariable_rows[, c("Characteristics", "Total(N)", "HR (95% CI)", "P value", "feature")], file.path(output_paths$table, "prognosis_multi_cox_results.xlsx"), overwrite = TRUE, na.string = "")

  save_session_info(output_paths$root, metadata = run_params)
  log_info("Cox regression analysis completed successfully")
}

run_plot_command <- function(options, plot_type) {
  title <- if (plot_type == "univariate") "Univariate Cox forest plot" else "Multivariable Cox forest plot"
  validate_required_value(options$plot_save, "--plot_save")
  log_info(paste("Generating", plot_type, "forest plot..."))
  generate_forest_plot(options$data_file, options$plot_save, options$width, options$height, options$font_size, title)
  save_session_info(dirname(options$plot_save), metadata = list(data_file = normalizePath(options$data_file, winslash = "/", mustWork = TRUE), plot_save = options$plot_save, width = options$width, height = options$height, font_size = options$font_size, seed = options$seed, timeout_seconds = options$timeout_seconds))
  log_info("Forest plot generation completed successfully")
}

run_command <- function(command, options) {
  switch(
    command,
    analyze = run_analyze_command(options),
    `forest-plot` = run_plot_command(options, "univariate"),
    `multi-forest-plot` = run_plot_command(options, "multivariable")
  )
}
