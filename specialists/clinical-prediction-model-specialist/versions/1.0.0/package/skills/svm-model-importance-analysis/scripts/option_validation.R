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
  if (!is.null(opt$case_group) && !is.null(opt$control_group) && identical(trimws(opt$case_group), trimws(opt$control_group))) {
    fail("SKILL_INVALID_PARAMETER", "--case_group and --control_group must be different.")
  }

  require_positive_number(opt$seed, "--seed", integer_only = TRUE)
  require_positive_number(opt$timeout_seconds, "--timeout_seconds", integer_only = TRUE)
  require_positive_number(opt$svm_k, "--svm_k", integer_only = TRUE)
  require_positive_number(opt$svm_halve_above, "--svm_halve_above", integer_only = TRUE)
  require_positive_number(opt$svm_max_features_cap, "--svm_max_features_cap", integer_only = TRUE)
  require_positive_number(opt$svm_tol, "--svm_tol")
  require_positive_number(opt$svm_error_height, "--svm_error_height")
  require_positive_number(opt$svm_error_width, "--svm_error_width")
  require_positive_number(opt$svm_error_noinfo_lty, "--svm_error_noinfo_lty", integer_only = TRUE)
  require_positive_number(opt$svm_error_label_cex, "--svm_error_label_cex")
  require_positive_number(opt$svm_error_label_pos, "--svm_error_label_pos", integer_only = TRUE)
  require_positive_number(opt$svm_rank_top_n, "--svm_rank_top_n", integer_only = TRUE)
  require_positive_number(opt$svm_rank_width, "--svm_rank_width")
  require_positive_number(opt$svm_rank_height, "--svm_rank_height")
  if (!opt$svm_select_rule %in% c("min", "tolerance")) {
    fail("SKILL_INVALID_PARAMETER", "--svm_select_rule must be min or tolerance.")
  }

  opt$output_dir <- resolve_output_dir(opt$output_dir, skill_root)
  opt$skill_root <- skill_root
  opt
}
