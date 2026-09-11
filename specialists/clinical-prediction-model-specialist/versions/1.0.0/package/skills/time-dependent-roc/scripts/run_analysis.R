write_table_file <- function(data, file_path, format = "csv") {
  if (format == "csv") {
    utils::write.csv(data, file_path, row.names = FALSE)
  } else if (format == "txt") {
    utils::write.table(data, file_path, row.names = FALSE, sep = "\t", quote = FALSE)
  } else {
    stop("SKILL_INVALID_PARAMETER: Unsupported output format: ", format)
  }
}

time_dependent_roc_analysis <- function(params) {
  check_pkg("timeROC")
  check_pkg("survival")
  check_pkg("ggplot2")

  raw_data <- read_data(params$data_file)
  prepared <- prepare_analysis_data(raw_data, marker_col = params$marker_col, cause = params$cause)
  roc_run <- run_time_dependent_roc(prepared, params)

  auc_table <- extract_auc_table(roc_run, params)
  validate_auc_table(auc_table, params)
  roc_points <- extract_roc_points(roc_run, params)
  plot_obj <- build_time_roc_plot(roc_points, params)

  output_dirs <- create_output_structure(params$output_dir)

  table_ext <- ifelse(params$output_format == "txt", "txt", "csv")
  auc_file <- file.path(output_dirs$table_dir, paste0("time_roc_auc.", table_ext))
  roc_points_file <- file.path(output_dirs$data_dir, paste0("time_roc_points.", table_ext))
  figure_file <- file.path(output_dirs$figure_dir, "time_roc.pdf")

  write_table_file(auc_table, auc_file, params$output_format)
  write_table_file(roc_points, roc_points_file, params$output_format)
  ggplot2::ggsave(filename = figure_file, plot = plot_obj, width = params$width, height = params$height, units = "in")

  log_info("Saved AUC table to: ", auc_file)
  log_info("Saved ROC points to: ", roc_points_file)
  log_info("Saved ROC figure to: ", figure_file)

  list(
    auc_table = auc_table,
    plot = plot_obj,
    output_files = list(
      auc = auc_file,
      roc_points = roc_points_file,
      figure = figure_file
    ),
    output_dirs = output_dirs,
    marker_col = roc_run$marker_col,
    conversion_note = roc_run$conversion_note
  )
}
