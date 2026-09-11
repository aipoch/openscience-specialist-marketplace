validate_options <- function(opt, skill_root) {
  if (!isTRUE(opt$plot_only)) {
    opt$input_file <- resolve_existing_input(opt$input_file, "--input_file")
    opt$group_file <- resolve_existing_input(opt$group_file, "--group_file")
    if (is.null(opt$case_group) || !nzchar(trimws(opt$case_group))) {
      fail("SKILL_INVALID_PARAMETER", "--case_group is required when --plot_only is FALSE.")
    }
    if (is.null(opt$control_group) || !nzchar(trimws(opt$control_group))) {
      fail("SKILL_INVALID_PARAMETER", "--control_group is required when --plot_only is FALSE.")
    }
  }

  if (!is.null(opt$case_group) && !is.null(opt$control_group) &&
      identical(trimws(opt$case_group), trimws(opt$control_group))) {
    fail("SKILL_INVALID_PARAMETER", "--case_group and --control_group must be different.")
  }

  require_positive_number(opt$seed, "--seed", integer_only = TRUE)
  require_positive_number(opt$timeout_seconds, "--timeout_seconds", integer_only = TRUE)
  require_positive_number(opt$rf_ntree, "--rf_ntree", integer_only = TRUE)
  require_positive_number(opt$rf_imp_type, "--rf_imp_type", integer_only = TRUE)
  require_positive_number(opt$rf_top_n, "--rf_top_n", integer_only = TRUE)
  require_positive_number(opt$rf_error_line_size, "--rf_error_line_size")
  require_probability(opt$rf_error_line_alpha, "--rf_error_line_alpha")
  require_positive_number(opt$rf_error_border_size, "--rf_error_border_size")
  require_positive_number(opt$rf_error_base_size, "--rf_error_base_size")
  require_positive_number(opt$rf_error_width, "--rf_error_width")
  require_positive_number(opt$rf_error_height, "--rf_error_height")
  require_positive_number(opt$rf_importance_top_n, "--rf_importance_top_n", integer_only = TRUE)
  require_positive_number(opt$rf_importance_label_cex, "--rf_importance_label_cex")
  require_positive_number(opt$rf_importance_point_cex, "--rf_importance_point_cex")
  require_positive_number(opt$rf_importance_point_shape, "--rf_importance_point_shape", integer_only = TRUE)
  require_positive_number(opt$rf_importance_theme_offset, "--rf_importance_theme_offset")
  require_positive_number(opt$rf_importance_width, "--rf_importance_width")
  require_positive_number(opt$rf_importance_height, "--rf_importance_height")

  if (!is.na(opt$rf_mtry)) require_positive_number(opt$rf_mtry, "--rf_mtry", integer_only = TRUE)
  if (!is.na(opt$rf_nodesize)) require_positive_number(opt$rf_nodesize, "--rf_nodesize", integer_only = TRUE)
  if (!opt$rf_imp_type %in% c(1L, 2L)) {
    fail("SKILL_INVALID_PARAMETER", "--rf_imp_type must be 1 or 2.")
  }

  opt$output_dir <- resolve_output_dir(opt$output_dir, skill_root)
  opt$skill_root <- skill_root
  opt
}
