run_analysis <- function(input_file,
                         output_dir,
                         columns,
                         output_prefix,
                         width,
                         height,
                         alpha,
                         label_size,
                         missing_label,
                         title,
                         seed) {
  check_required_packages(c("ggplot2", "ggalluvial"))
  dirs <- ensure_output_dirs(output_dir)

  log_info(sprintf("Reading input table: %s", input_file))
  annotation_data <- read_annotation_table(input_file)

  selected_columns <- parse_selected_columns(columns, colnames(annotation_data))
  log_info(sprintf("Selected columns: %s", paste(selected_columns, collapse = ", ")))

  # Readability advisories
  if (length(selected_columns) > 5) {
    log_warn(sprintf(
      "More than 5 stages selected (%d); plot may be hard to read. Consider filtering.",
      length(selected_columns)
    ))
  }
  for (col in selected_columns) {
    if (col %in% colnames(annotation_data)) {
      n_unique <- length(unique(annotation_data[[col]]))
      if (n_unique > 8) {
        log_warn(sprintf(
          "Stage '%s' has %d unique values; consider aggregating for readability.",
          col, n_unique
        ))
      }
    }
  }

  selected_data <- validate_annotation_data(annotation_data, selected_columns)
  sankey_data <- prepare_sankey_data(selected_data, missing_label)

  log_info("Building Sankey plot")
  plot_obj <- build_sankey_plot(
    lodes_df = sankey_data$lodes_df,
    axis_labels = selected_columns,
    alpha = alpha,
    label_size = label_size,
    title = title
  )

  log_info("Writing output files")
  outputs <- write_outputs(
    selected_data = sankey_data$selected_data,
    lodes_df = sankey_data$lodes_df,
    plot_obj = plot_obj,
    dirs = dirs,
    output_prefix = output_prefix,
    width = width,
    height = height
  )

  write_session_info(
    output_file = file.path(dirs$data, "session_info.txt"),
    parameters = list(
      input_file = normalizePath(input_file),
      output_dir = normalizePath(output_dir, mustWork = FALSE),
      columns = paste(selected_columns, collapse = ","),
      output_prefix = output_prefix,
      width = width,
      height = height,
      alpha = alpha,
      label_size = label_size,
      missing_label = missing_label,
      title = title,
      seed = seed
    )
  )

  log_info(sprintf("Selected annotations written to %s", outputs$selected_output))
  log_info(sprintf("Sankey lodes written to %s", outputs$lodes_output))
  log_info(sprintf("Plot written to %s", outputs$plot_output))
  log_info(sprintf("Session info written to %s", file.path(dirs$data, "session_info.txt")))

  invisible(outputs)
}
