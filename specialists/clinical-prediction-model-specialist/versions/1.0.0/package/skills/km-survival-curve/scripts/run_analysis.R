save_km_figure <- function(plot_obj, output_dir, params) {
  figure_file <- file.path(output_dir, "km-plot.pdf")

  grDevices::pdf(figure_file, width = params$figure_width, height = params$figure_height,
                 family = params$figure_family, onefile = FALSE)

  on.exit(grDevices::dev.off(), add = TRUE)
  withCallingHandlers(
    print(plot_obj),
    message = function(m) {
      if (grepl("Ignoring unknown labels", conditionMessage(m), fixed = TRUE)) {
        invokeRestart("muffleMessage")
      }
    },
    warning = function(w) {
      if (grepl("Ignoring unknown labels", conditionMessage(w), fixed = TRUE)) {
        invokeRestart("muffleWarning")
      }
    }
  )
  log_info("Saved figure to: ", figure_file)
  invisible(figure_file)
}

km_analysis <- function(params) {
  check_pkg("data.table")
  check_pkg("survival")
  check_pkg("survminer")
  check_pkg("ggplot2")

  log_info("Loading data...")
  data <- read_data(params$input_file)

  log_info("Preparing survival input...")
  prepared_data <- prepare_survival_input(data, params)
  log_info("Groups detected: ", paste(prepared_data$group_levels, collapse = ", "))
  log_info("Samples retained after filtering: ", nrow(prepared_data$surv_data))

  if (prepared_data$removed_row_count > 0) {
    log_warn("Removed ", prepared_data$removed_row_count, " rows with missing time, status, or group values")
  }

  log_info("Fitting Kaplan-Meier model...")
  plot_result <- create_km_plot(prepared_data, params)

  log_info("Saving figure...")
  create_output_dir(params$output_dir)
  figure_file <- save_km_figure(plot_result$plot, params$output_dir, params)

  log_info("=== Analysis completed successfully! ===")

  invisible(figure_file)
}
