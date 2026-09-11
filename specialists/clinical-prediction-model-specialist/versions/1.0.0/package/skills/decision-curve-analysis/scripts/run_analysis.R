read_decision_data <- function(data_file) {
  file_path <- validate_existing_file(data_file, "--data_file", extensions = c("csv"))
  data <- tryCatch(
    utils::read.csv(file_path, row.names = 1, check.names = FALSE, stringsAsFactors = FALSE),
    error = function(e) stop_skill("SKILL_INVALID_PARAMETER", paste("Failed to read --data_file:", conditionMessage(e)))
  )
  if (nrow(data) == 0 || ncol(data) == 0)
    stop_skill("SKILL_EMPTY_DATA", "--data_file contains no usable rows or columns")
  if (any(!nzchar(rownames(data))) || anyDuplicated(rownames(data)))
    stop_skill("SKILL_INVALID_PARAMETER", "Row names must be unique non-empty sample IDs")
  data
}

normalize_analysis_options <- function(options) {
  validate_required_value(options$outcome_col, "--outcome_col")
  validate_required_value(options$predictor_col, "--predictor_col")
  validate_positive_integer(options$population_size, "--population_size")
  validate_positive_integer(options$n_cost_benefits, "--n_cost_benefits")
  validate_positive_number(options$plot_width, "--plot_width")
  validate_positive_number(options$plot_height, "--plot_height")
  validate_positive_number(options$base_cex, "--base_cex")
  options$decision_curve_color <- parse_color_list(options$decision_curve_color, "--decision_curve_color")[[1]]
  options$impact_colors <- parse_color_list(options$impact_colors, "--impact_colors")
  if (length(options$impact_colors) < 2)
    stop_skill("SKILL_INVALID_PARAMETER", "--impact_colors must contain at least two colors")
  options
}

write_analysis_outputs <- function(bundle, output_paths, options) {
  saveRDS(bundle$model, file.path(output_paths$data, "dca_model.rds"))
  writeLines(build_summary_lines(bundle$model, options$standardize_net_benefit), file.path(output_paths$table, "dca_summary.txt"))

  grDevices::pdf(file.path(output_paths$plot, "decision_curve.pdf"), width = options$plot_width, height = options$plot_height, family = options$font_family)
  graphics::par(cex = options$base_cex)
  plot_decision_curve_to_device(bundle$model, options)
  grDevices::dev.off()

  grDevices::pdf(file.path(output_paths$plot, "clinical_impact_curve.pdf"), width = options$plot_width, height = options$plot_height, family = options$font_family)
  graphics::par(cex = options$base_cex)
  plot_clinical_impact_to_device(bundle$model, options, options$impact_colors[1:2])
  grDevices::dev.off()
}

build_run_metadata <- function(options, output_paths, bundle) {
  list(
    data_file = normalizePath(options$data_file, winslash = "/", mustWork = TRUE),
    outcome_col = options$outcome_col,
    predictor_col = options$predictor_col,
    study_design = options$study_design,
    population_prevalence = options$population_prevalence,
    threshold_by = options$threshold_by,
    confidence_level = options$confidence_level,
    population_size = options$population_size,
    n_cost_benefits = options$n_cost_benefits,
    show_confidence_intervals = isTRUE(options$show_confidence_intervals),
    standardize_net_benefit = isTRUE(options$standardize_net_benefit),
    decision_curve_color = options$decision_curve_color,
    impact_colors = options$impact_colors,
    plot_width = options$plot_width,
    plot_height = options$plot_height,
    font_family = options$font_family,
    plot_title = options$plot_title,
    base_cex = options$base_cex,
    output_dir = output_paths$root,
    overwrite = isTRUE(options$overwrite),
    seed = options$seed,
    timeout_seconds = options$timeout_seconds,
    formula = bundle$formula_text,
    sample_size = bundle$sample_size,
    event_count = bundle$event_count,
    non_event_count = bundle$non_event_count,
    threshold_count = bundle$threshold_count
  )
}

run_analysis <- function(options) {
  options <- normalize_analysis_options(options)

  log_info("Loading clinical data...")
  raw_data <- read_decision_data(options$data_file)

  log_info("Preparing decision curve analysis dataset...")
  analysis_data <- prepare_decision_data(raw_data, options$outcome_col, options$predictor_col)

  log_info("Fitting decision curve model...")
  bundle <- fit_decision_curve_model(analysis_data, options)

  output_paths <- create_output_dirs(options$output_dir, overwrite = isTRUE(options$overwrite))

  log_info("Saving decision curve outputs...")
  write_analysis_outputs(bundle, output_paths, options)
  save_session_info(output_paths$root, build_run_metadata(options, output_paths, bundle))
  log_info(paste("Decision curve analysis completed successfully. Output:", output_paths$root))
}
