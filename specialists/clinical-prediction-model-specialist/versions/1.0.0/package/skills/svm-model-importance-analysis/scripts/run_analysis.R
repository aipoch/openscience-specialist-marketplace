validate_plot_only_bundle <- function(bundle, bundle_path) {
  if (!is.list(bundle)) {
    fail("SKILL_INVALID_PARAMETER", sprintf("Plot-only mode requires a valid model bundle. Rerun the full analysis to regenerate: %s", bundle_path))
  }

  required_fields <- c("case_group", "control_group", "group_factor", "svm_res")
  missing_fields <- required_fields[!vapply(required_fields, function(field) !is.null(bundle[[field]]), logical(1))]
  if (length(missing_fields) > 0) {
    fail(
      "SKILL_INVALID_PARAMETER",
      sprintf(
        "Plot-only mode requires a complete model bundle. Missing field(s): %s. Rerun the full analysis to regenerate: %s",
        paste(missing_fields, collapse = ", "),
        bundle_path
      )
    )
  }

  if (!is.list(bundle$svm_res) || is.null(bundle$svm_res$error_rates) || is.null(bundle$svm_res$full_ranking)) {
    fail(
      "SKILL_INVALID_PARAMETER",
      sprintf("Plot-only mode requires svm_res$error_rates and svm_res$full_ranking in the saved bundle. Rerun the full analysis to regenerate: %s", bundle_path)
    )
  }

  invisible(bundle)
}

load_plot_only_bundle <- function(bundle_path) {
  bundle <- tryCatch(
    readRDS(bundle_path),
    error = function(e) {
      fail(
        "SKILL_INVALID_PARAMETER",
        sprintf("Plot-only mode requires a readable model bundle. %s Rerun the full analysis to regenerate: %s", conditionMessage(e), bundle_path)
      )
    }
  )
  validate_plot_only_bundle(bundle, bundle_path)
  bundle
}

run_analysis <- function(options) {
  ensure_dir(options$output_dir)
  ensure_dir(file.path(options$output_dir, "data"))
  ensure_dir(file.path(options$output_dir, "table"))
  ensure_dir(file.path(options$output_dir, "plot"))

  bundle_path <- file.path(options$output_dir, "data", "svm_result.rds")

  if (isTRUE(options$plot_only)) {
    if (!file.exists(bundle_path)) fail("SKILL_FILE_NOT_FOUND", sprintf("Plot-only mode requires an existing model file: %s", bundle_path))
    bundle <- load_plot_only_bundle(bundle_path)
    input_summary <- c("Plot-only mode: TRUE", sprintf("Existing model file: %s", bundle_path), sprintf("Stored case group: %s", bundle$case_group), sprintf("Stored control group: %s", bundle$control_group))
    result_summary <- c("Model tables were reused from the existing svm_result.rds bundle.")
  } else {
    log_info("Reading input files.")
    group_df <- read_group_data(options$group_file, options$case_group, options$control_group)
    expression_df <- read_expression_data(options$input_file)
    aligned <- align_input_data(expression_df, group_df, options$case_group, options$control_group)

    log_info("Running SVM-RFE analysis.")
    bundle <- build_result_bundle(aligned$expression, aligned$group, options, options$case_group, options$control_group)
    saveRDS(bundle, bundle_path)
    save_table(bundle$svm_res$results, file.path(options$output_dir, "table", "svm_rfe_features.csv"))
    save_table(bundle$svm_res$full_ranking, file.path(options$output_dir, "table", "svm_rfe_full_ranking.csv"))

    input_summary <- c(aligned$input_summary, sprintf("Expression file: %s", options$input_file), sprintf("Group file: %s", options$group_file))
    result_summary <- build_result_summary(bundle)
  }

  baseline_error <- min(prop.table(table(bundle$group_factor)))
  log_info("Generating plots.")
  save_svm_error_plot(bundle$svm_res$error_rates, baseline_error, options, file.path(options$output_dir, "plot", "svm_rfe_error_plot.pdf"))
  save_svm_ranking_plot(bundle$svm_res$full_ranking, options, file.path(options$output_dir, "plot", "svm_rfe_ranking_plot.pdf"))

  list(input_summary = input_summary, result_summary = result_summary)
}
