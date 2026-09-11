extract_coefficients <- function(cv_fit, lambda_choice) {
  coef_matrix <- as.matrix(stats::coef(cv_fit, s = lambda_choice))
  data.frame(feature = rownames(coef_matrix), coefficient = unname(coef_matrix[, 1]), stringsAsFactors = FALSE)
}

extract_selected_features <- function(coefficients, selected_alpha, coefficient_tolerance = 1e-8) {
  selected <- coefficients[
    coefficients$feature != "(Intercept)" & abs(coefficients$coefficient) > coefficient_tolerance,
    ,
    drop = FALSE
  ]
  if (isTRUE(is.finite(selected_alpha)) && abs(selected_alpha) <= coefficient_tolerance) {
    return(selected[0, , drop = FALSE])
  }
  selected[order(abs(selected$coefficient), decreasing = TRUE), , drop = FALSE]
}

build_feature_matrix <- function(groups, x) {
  data.frame(sample = groups$sample_id, group = groups$group, x, check.names = FALSE, stringsAsFactors = FALSE)
}

write_output_csv <- function(data, output_file) {
  tryCatch({
    utils::write.csv(data, output_file, row.names = FALSE)
  }, error = function(e) {
    stop(sprintf("SKILL_RUNTIME_ERROR: failed to write output file %s", output_file), call. = FALSE)
  })
}

save_coefficient_path_plot <- function(fit, output_dir) {
  grDevices::pdf(file.path(output_dir, "coefficient_path.pdf"))
  plot(fit, xvar = "lambda", label = TRUE)
  grDevices::dev.off()
}

save_cv_curve_plot <- function(cv_fit, output_dir) {
  grDevices::pdf(file.path(output_dir, "cv_curve.pdf"))
  plot(cv_fit)
  graphics::abline(v = log(c(cv_fit$lambda.min, cv_fit$lambda.1se)), lty = "dashed")
  grDevices::dev.off()
}

write_analysis_outputs <- function(output_dir, alpha_tuning, coefficients, selected, feature_matrix, fit, cv_fit) {
  ensure_dir(output_dir)
  write_output_csv(alpha_tuning, file.path(output_dir, "alpha_tuning.csv"))
  write_output_csv(coefficients, file.path(output_dir, "model_coefficients.csv"))
  write_output_csv(selected, file.path(output_dir, "selected_features.csv"))
  write_output_csv(feature_matrix, file.path(output_dir, "feature_matrix.csv"))
  save_coefficient_path_plot(fit, output_dir)
  save_cv_curve_plot(cv_fit, output_dir)
  c(
    "alpha_tuning.csv",
    "model_coefficients.csv",
    "selected_features.csv",
    "feature_matrix.csv",
    "coefficient_path.pdf",
    "cv_curve.pdf"
  )
}
