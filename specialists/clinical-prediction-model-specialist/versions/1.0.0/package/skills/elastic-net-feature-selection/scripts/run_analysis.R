build_analysis_inputs <- function(opt) {
  log_info("Loading input files...")
  expr <- read_expression_matrix(opt$input_file)
  groups <- read_group_file(opt$group_file)
  feature_list <- read_feature_list(opt$feature_file)

  log_info("Preparing the modeling matrix...")
  aligned <- align_inputs(expr, groups, opt$case_group, opt$control_group)
  filtered_expr <- filter_expression_features(aligned$expr, feature_list)
  x <- build_design_matrix(filtered_expr)
  y <- encode_response(aligned$groups, opt$case_group, opt$control_group)
  list(aligned = aligned, x = x, y = y)
}

log_feature_selection_warnings <- function(selected, selected_alpha, coefficient_tolerance, lambda_choice) {
  if (abs(selected_alpha) <= coefficient_tolerance) {
    log_warn(
      paste(
        sprintf("Selected alpha %.3f corresponds to ridge regularization.", selected_alpha),
        "selected_features.csv will be written empty because ridge does not perform sparse feature selection.",
        sprintf("Use model_coefficients.csv for coefficient ranking or rerun with alpha > %.0e.", coefficient_tolerance)
      )
    )
    return(invisible(NULL))
  }
  if (nrow(selected) == 0L) {
    log_warn(
      sprintf(
        "No feature coefficients exceeded the selection tolerance (|coefficient| > %.0e) at %s.",
        coefficient_tolerance,
        lambda_choice
      )
    )
  }
}

run_analysis <- function(opt) {
  coefficient_tolerance <- 1e-8
  inputs <- build_analysis_inputs(opt)
  log_info("Fitting the elastic net model...")
  model <- fit_elastic_net_model(
    inputs$x,
    inputs$y,
    parse_alpha_spec(opt$alpha),
    parse_alpha_grid(opt$alpha_grid),
    opt$nfolds,
    opt$standardize
  )
  coefficients <- extract_coefficients(model$cv_fit, opt$lambda_choice)
  selected <- extract_selected_features(coefficients, model$selected_alpha, coefficient_tolerance)
  log_feature_selection_warnings(selected, model$selected_alpha, coefficient_tolerance, opt$lambda_choice)

  log_info("Writing output files...")
  output_files <- write_analysis_outputs(
    output_dir = opt$output_dir,
    alpha_tuning = model$alpha_tuning,
    coefficients = coefficients,
    selected = selected,
    feature_matrix = build_feature_matrix(inputs$aligned$groups, inputs$x),
    fit = model$fit,
    cv_fit = model$cv_fit
  )
  list(
    selected_alpha = model$selected_alpha,
    alpha_mode = model$alpha_mode,
    output_files = output_files,
    gc_snapshot = capture_gc_snapshot()
  )
}
