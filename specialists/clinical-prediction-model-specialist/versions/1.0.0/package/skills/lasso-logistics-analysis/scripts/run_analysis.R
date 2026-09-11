prepare_analysis_context <- function(opt) {
  log_info("Reading input files...")
  expr_mat <- load_expression_matrix(opt$input_file)
  group_df <- load_group_data(opt$group_file)
  feature_list <- parse_feature_input(opt$feature)
  log_memory_usage("input loading")

  log_info("Preparing the modeling matrix...")
  prepared <- prepare_model_inputs(
    expr_mat = expr_mat,
    group_df = group_df,
    case_group = opt$case_group,
    control_group = opt$control_group,
    feature_list = feature_list,
    nfolds = opt$nfolds
  )
  log_info(sprintf("Loaded %d samples and %d features.", nrow(prepared$x), ncol(prepared$x)))
  log_memory_usage("matrix preparation")
  prepared
}

fit_analysis_models <- function(prepared, opt) {
  log_info("Fitting the LASSO logistic regression model...")
  models <- fit_lasso_models(prepared$x, prepared$y, opt$nfolds, opt$seed)
  coefficients <- extract_coefficients(models$fit, models$cv_fit)
  selected <- coefficients$feature[coefficients$coefficient != 0 & coefficients$feature != "(Intercept)"]
  log_info(sprintf("Selected %d non-intercept features at lambda.min.", length(selected)))
  log_memory_usage("model fitting")
  list(models = models, coefficients = coefficients, selected = selected)
}

write_analysis_outputs <- function(prepared, fitted, output_dir, registry) {
  log_info("Writing output tables...")
  write_csv_atomic(fitted$coefficients, file.path(output_dir, "coefficient.csv"), registry)
  write_csv_atomic(prepared$feature_matrix, file.path(output_dir, "feature_matrix.csv"), registry)
  if (length(prepared$missing_features) > 0) {
    write_lines_atomic(prepared$missing_features, file.path(output_dir, "missing_features.txt"), registry)
    log_warn("Some requested features were not present in the expression matrix.")
  }
  if (length(fitted$selected) > 0)
    write_lines_atomic(fitted$selected, file.path(output_dir, "selected_features.txt"), registry)
}

write_plot_outputs <- function(fitted, opt, registry) {
  log_info("Generating PDF plots...")
  save_plot_atomic(
    function(path) save_cv_plot(fitted$models$cv_fit, path, opt$cv_title),
    file.path(opt$output_dir, "lasso_lambda_binary_plot.pdf"),
    registry
  )
  save_plot_atomic(
    function(path) save_coefficient_path_plot(fitted$models$fit, fitted$models$cv_fit, path, opt$path_title),
    file.path(opt$output_dir, "lasso_var_binary_plot.pdf"),
    registry
  )
  log_memory_usage("plot generation")
}

run_analysis <- function(opt) {
  set.seed(opt$seed)
  create_output_dir(opt$output_dir)

  registry <- create_temp_registry()
  on.exit(cleanup_temp_files(registry), add = TRUE)

  run_with_timeout(opt$timeout_seconds, {
    prepared <- prepare_analysis_context(opt)
    fitted <- fit_analysis_models(prepared, opt)
    write_analysis_outputs(prepared, fitted, opt$output_dir, registry)
    write_plot_outputs(fitted, opt, registry)
  })

  write_session_info(opt$output_dir)
}

run_lasso_analysis <- function(input_file,
                               group_file,
                               case_group,
                               control_group,
                               output_dir,
                               feature = NULL,
                               nfolds = 10,
                               cv_title = "",
                               path_title = "",
                               timeout_seconds = 1800,
                               seed = 42) {
  opt <- list(
    input_file = input_file,
    group_file = group_file,
    case_group = case_group,
    control_group = control_group,
    output_dir = output_dir,
    feature = feature,
    nfolds = nfolds,
    cv_title = cv_title,
    path_title = path_title,
    timeout_seconds = timeout_seconds,
    seed = seed
  )

  run_analysis(opt)
}
