run_external_model_validation <- function(config) {
  log_info("Checking package dependencies...")
  check_required_packages(c("optparse", "survival", "survminer", "timeROC", "pheatmap", "ggplot2"))

  log_info("Step 1/4: Loading input data...")
  exp_data <- read_expression_data(config$exp_file)
  cli_data <- read_clinical_data(config$cli_file)
  model_data <- read_model_data(config$model_file)
  log_info(sprintf(
    "Loaded expression matrix with %d genes x %d samples, clinical table with %d rows, and model with %d genes",
    nrow(exp_data), ncol(exp_data), nrow(cli_data), nrow(model_data)
  ))
  log_memory_checkpoint("input loading")

  log_info("Step 2/4: Calculating risk scores and matched validation table...")
  risk_data <- prepare_analysis_dataset(exp_data, cli_data, model_data, config$time_unit)
  output_files <- write_risk_outputs(risk_data, config$output_paths)
  log_info(sprintf(
    "Prepared %d matched samples (%d low risk / %d high risk)",
    nrow(risk_data), sum(risk_data$risk == "low"), sum(risk_data$risk == "high")
  ))
  log_memory_checkpoint("risk score calculation")

  log_info("Step 3/4: Generating survival, risk, heatmap, and ROC plots...")
  plot_files <- generate_all_plots(
    risk_data = risk_data,
    output_paths = config$output_paths,
    col_high = config$col_high,
    col_low = config$col_low,
    roc_times = config$roc_times,
    roc_colors = config$roc_colors,
    roc_pos = config$roc_pos,
    km_breaks = config$km_breaks
  )
  log_memory_checkpoint("plot generation")

  log_info("Step 4/4: Writing metadata files...")
  session_file <- save_session_info(config$output_paths$root)
  param_file <- save_run_parameters(config$run_parameters, config$output_paths$root)

  result <- list(
    sample_count = nrow(risk_data),
    risk_files = output_files,
    plot_files = plot_files,
    session_file = session_file,
    parameter_file = param_file
  )
  log_info("Analysis completed successfully")
  invisible(result)
}
