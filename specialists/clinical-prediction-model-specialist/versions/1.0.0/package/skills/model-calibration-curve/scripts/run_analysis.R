read_clinical_data <- function(data_file) {
  file_path <- validate_existing_file(data_file, "--data_file", extensions = c("csv"))
  data <- tryCatch(
    utils::read.csv(file_path, row.names = 1, check.names = FALSE, stringsAsFactors = FALSE),
    error = function(e) stop_skill("SKILL_INVALID_PARAMETER", paste("Failed to read --data_file:", conditionMessage(e)))
  )
  if (nrow(data) == 0 || ncol(data) == 0)
    stop_skill("SKILL_EMPTY_DATA", "--data_file contains no usable rows or columns")
  data
}

render_calibration_plot <- function(calibration_result, plot_file, options) {
  validate_positive_number(options$plot_width, "--plot_width")
  validate_positive_number(options$plot_height, "--plot_height")
  validate_positive_number(options$line_width, "--line_width")
  validate_positive_number(options$base_cex, "--base_cex")
  colors <- parse_color_list(options$colors)
  if (length(colors) < length(calibration_result$calibration_data))
    colors <- grDevices::colorRampPalette(colors)(length(calibration_result$calibration_data))

  grDevices::pdf(plot_file, width = options$plot_width, height = options$plot_height, family = options$font_family)
  on.exit(grDevices::dev.off(), add = TRUE)
  graphics::par(mar = c(4.5, 4.5, 3, 1.5), mgp = c(2.5, 0.8, 0), cex = options$base_cex)
  for (idx in seq_along(calibration_result$calibration_data)) {
    graphics::plot(
      calibration_result$calibration_data[[idx]],
      add = idx > 1,
      xlim = c(0, 1), ylim = c(0, 1),
      col = colors[[idx]], errbar.col = colors[[idx]], lwd = options$line_width,
      pch = 16, subtitles = FALSE,
      xlab = if (idx == 1) "Predicted Survival Probability" else "",
      ylab = if (idx == 1) "Observed Survival Probability" else "",
      main = if (idx == 1) options$plot_title else ""
    )
  }
  graphics::abline(0, 1, col = "gray50", lty = 2, lwd = 1)
  graphics::legend("topleft", legend = names(calibration_result$calibration_data), col = colors, lty = 1, lwd = options$line_width, bty = "n")
  graphics::legend("bottomright", legend = sprintf("C-index: %.3f", calibration_result$c_index), bty = "n")
  invisible(plot_file)
}

write_calibration_outputs <- function(calibration_result, output_paths, options) {
  qs::qsave(calibration_result, file.path(output_paths$data, "calibration_data.qs"))
  stats_bundle <- build_statistics_bundle(calibration_result)
  openxlsx::write.xlsx(
    list(Time_Point_Stats = stats_bundle$time_point_stats, Model_Summary = stats_bundle$model_summary),
    file = file.path(output_paths$table, "calibration_statistics.xlsx"),
    overwrite = TRUE
  )
  render_calibration_plot(calibration_result, file.path(output_paths$plot, "calibration_curve.pdf"), options)
}

build_run_metadata <- function(options, output_paths, calibration_result) {
  list(
    data_file = normalizePath(options$data_file, winslash = "/", mustWork = TRUE),
    features = calibration_result$features,
    time_col = options$time_col,
    event_col = options$event_col,
    years = calibration_result$time_points,
    bootstrap_reps = options$bootstrap_reps,
    output_dir = output_paths$root,
    overwrite = isTRUE(options$overwrite),
    seed = options$seed,
    timeout_seconds = options$timeout_seconds,
    plot_width = options$plot_width,
    plot_height = options$plot_height,
    font_family = options$font_family,
    line_width = options$line_width,
    colors = options$colors,
    plot_title = options$plot_title,
    base_cex = options$base_cex,
    c_index = round(calibration_result$c_index, 3)
  )
}

run_analysis <- function(options) {
  features <- parse_csv_tokens(options$features, "--features")
  years <- parse_years_arg(options$years)
  validate_positive_integer(options$bootstrap_reps, "--bootstrap_reps")
  output_paths <- create_output_dirs(options$output_dir, overwrite = isTRUE(options$overwrite))

  log_info("Loading clinical data...")
  raw_data <- read_clinical_data(options$data_file)
  log_info("Preparing complete-case survival modeling dataset...")
  model_data <- prepare_model_data(raw_data, features, options$time_col, options$event_col)
  log_info("Running bootstrap calibration analysis...")
  calibration_result <- build_calibration_result(model_data, features, options$time_col, options$event_col, years, options$bootstrap_reps)
  log_info("Saving calibration outputs...")
  write_calibration_outputs(calibration_result, output_paths, options)
  save_session_info(output_paths$root, build_run_metadata(options, output_paths, calibration_result))
  log_info(paste("Calibration analysis completed successfully. Output:", output_paths$root))
}
