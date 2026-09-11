run_batch_correction <- function(opt) {
  if (opt$timeout_seconds > 0) {
    setTimeLimit(elapsed = opt$timeout_seconds, transient = FALSE)
    on.exit(setTimeLimit(cpu = Inf, elapsed = Inf, transient = FALSE), add = TRUE)
  }

  log_info("Step 1/4: Reading input files...")
  expr_mat <- read_expression_matrix(opt$input_file)
  metadata <- read_sample_metadata(opt$group_file, opt$sample_column, opt$group_column, opt$batch_column)
  aligned <- align_inputs(expr_mat, metadata)
  validate_design(aligned$metadata)

  log_info("Step 2/4: Preparing expression matrix...")
  apply_log_transform <- should_log_transform(aligned$expr, opt$log_transform)
  prepared_expr <- prepare_expression_matrix(aligned$expr, apply_log_transform)
  log_info(sprintf("Log transform applied: %s", apply_log_transform))

  log_info("Step 3/4: Running ComBat batch correction...")
  corrected_expr <- run_combat_correction(prepared_expr, aligned$metadata)

  log_info("Step 4/4: Writing output files...")
  write_core_outputs(corrected_expr, aligned$metadata, opt$output_dir)
  write_qc_outputs(prepared_expr, corrected_expr, aligned$metadata, opt$output_dir)

  invisible(list(corrected_matrix = corrected_expr, metadata = aligned$metadata))
}
