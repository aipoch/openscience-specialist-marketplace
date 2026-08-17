validate_main_options <- function(opt) {
  if (is.null(opt$input_file) || is.null(opt$group_file)) {
    skill_stop("INVALID_PARAMETER", "Both --input_file and --group_file are required")
  }
  assert_choice(opt$network_type, c("unsigned", "signed"), "network_type")
  assert_choice(opt$cor_type, c("pearson", "bicor"), "cor_type")
  assert_numeric_range(opt$mad_quantile, 0, 1, "mad_quantile")
  assert_numeric_range(opt$min_mad, 0, Inf, "min_mad")
  assert_positive_integer(opt$max_genes, "max_genes", allow_zero = TRUE)
  assert_positive_integer(opt$min_module_size, "min_module_size")
  assert_numeric_range(opt$merge_cut_height, 0, 1, "merge_cut_height")
  assert_numeric_range(opt$soft_r2_cutoff, 0, 1, "soft_r2_cutoff")
  assert_positive_integer(opt$top_modules, "top_modules")
  assert_positive_integer(opt$tom_sample_size, "tom_sample_size")
  assert_positive_integer(opt$chunk_size, "chunk_size", allow_zero = TRUE)
  assert_positive_integer(opt$seed, "seed", allow_zero = TRUE)
  invisible(TRUE)
}

log_option_summary <- function(opt) {
  fields <- c(
    "input_file", "group_file", "output_dir", "network_type", "cor_type",
    "mad_quantile", "min_mad", "max_genes", "min_module_size",
    "merge_cut_height", "soft_r2_cutoff", "top_modules", "chunk_size", "seed"
  )
  for (field in fields) {
    log_info(sprintf("%s: %s", field, opt[[field]]))
  }
}

resolve_column <- function(df, column_name, fallback_index, label) {
  if (!is.null(column_name) && column_name %in% colnames(df)) {
    return(column_name)
  }
  if (fallback_index > ncol(df)) {
    skill_stop("MISSING_COLUMNS", sprintf("%s fallback column index %s is out of range", label, fallback_index))
  }
  if (!is.null(column_name) && !identical(column_name, "") && !(column_name %in% colnames(df))) {
    log_warn(sprintf("%s column '%s' not found; using fallback column '%s'", label, column_name, colnames(df)[fallback_index]))
  }
  colnames(df)[fallback_index]
}

standardize_group_factor <- function(group_values) {
  factor(as.character(group_values), levels = sort(unique(as.character(group_values))))
}
