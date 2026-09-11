validate_main_args <- function(opt) {
  required_fields <- c("input_file", "group_file", "case_group", "control_group", "output_dir")
  for (field_name in required_fields) {
    if (is.null(opt[[field_name]]) || !nzchar(trim_ws(opt[[field_name]]))) {
      skill_stop("SKILL_INVALID_PARAMETER", sprintf("--%s is required.", field_name))
    }
  }
  if (!(opt$gene_id_case %in% c("asis", "upper", "lower"))) {
    skill_stop("SKILL_INVALID_PARAMETER", "Unsupported --gene_id_case value.")
  }
  if (is.na(opt$min_mean_expression) || opt$min_mean_expression < 0) {
    skill_stop("SKILL_INVALID_PARAMETER", "--min_mean_expression must be >= 0.")
  }
  if (is.na(opt$perm) || opt$perm < 0) {
    skill_stop("SKILL_INVALID_PARAMETER", "--perm must be >= 0.")
  }
  if (is.na(opt$svm_cores) || opt$svm_cores < 1) {
    skill_stop("SKILL_INVALID_PARAMETER", "--svm_cores must be >= 1.")
  }
  if (is.na(opt$timeout_seconds) || opt$timeout_seconds < 0) {
    skill_stop("SKILL_INVALID_PARAMETER", "--timeout_seconds must be >= 0.")
  }
}

run_analysis <- function(opt, start_time = Sys.time(), start_proc = proc.time()) {
  validate_main_args(opt)
  if (opt$timeout_seconds > 0) {
    setTimeLimit(cpu = opt$timeout_seconds, elapsed = opt$timeout_seconds, transient = TRUE)
    on.exit(setTimeLimit(cpu = Inf, elapsed = Inf, transient = FALSE), add = TRUE)
  }
  set.seed(opt$seed)
  runtime_notes <- character(0)
  if (identical(opt$perm, 0L)) {
    perm_note <- "perm=0 disables empirical p-value estimation; P-value columns will be recorded as NA."
    log_warn(perm_note, opt$verbose)
    runtime_notes <- c(runtime_notes, perm_note)
  }
  staging_dir <- make_staging_output_dir(opt$output_dir)
  on.exit(unlink(staging_dir, recursive = TRUE, force = TRUE), add = TRUE)
  exp_mat <- read_expression_matrix(opt$input_file, opt$gene_id_case, opt$min_mean_expression, opt$auto_unlog, opt$verbose)
  group_df <- read_group_info(opt$group_file, opt$case_group, opt$control_group, opt$sample_col, opt$group_col, opt$verbose)
  signature_mat <- read_signature_matrix(opt$signature_file, opt$gene_id_case, opt$verbose)
  aligned <- align_inputs(exp_mat, group_df, opt$case_group, opt$control_group, opt$verbose)
  prepared <- prepare_cibersort_inputs(aligned$exp_mat, signature_mat, opt$qn, opt$verbose)
  nulldist <- run_null_distribution(prepared$X, prepared$Y, opt$perm, opt$svm_cores, opt$verbose)
  result_df <- run_cibersort_like(prepared$X, prepared$Y, nulldist, opt$svm_cores, opt$verbose)
  split_res <- split_cibersort_output(result_df, prepared$cell_types)
  long_df <- make_fraction_long(split_res$fractions, aligned$group_map)
  compare_df <- calc_group_compare(long_df, opt$case_group, opt$control_group)
  cor_res <- calc_correlation_tables(split_res$fractions)
  rendering_metadata <- list(
    correlation_heatmap = build_heatmap_rendering_metadata(cor_res$cor_mat, cor_res$p_mat, plot_enabled = opt$make_plots)
  )
  result_rds <- list(
    cell_fractions = split_res$fractions,
    quality_metrics = split_res$quality,
    group = aligned$group_map,
    case = opt$case_group,
    control = opt$control_group,
    signature_source = opt$signature_file,
    qn = opt$qn,
    perm = opt$perm,
    rendering_metadata = rendering_metadata
  )
  saveRDS(list(X = prepared$X, Y = prepared$Y, overlap_genes = prepared$overlap_genes), file.path(staging_dir, "data", "cibersort_input.rds"))
  saveRDS(nulldist, file.path(staging_dir, "data", "cibersort_null_distribution.rds"))
  write.csv(data.frame(sample = rownames(result_df), result_df, check.names = FALSE), file.path(staging_dir, "table", "CIBERSORT_Results.csv"), row.names = FALSE, quote = TRUE)
  write.table(data.frame(Mixture = rownames(result_df), result_df, check.names = FALSE), file.path(staging_dir, "table", "CIBERSORT-Results.txt"), sep = "\t", row.names = FALSE, col.names = TRUE, quote = FALSE)
  write.csv(data.frame(sample = rownames(split_res$fractions), split_res$fractions, check.names = FALSE), file.path(staging_dir, "table", "cibersort_cell_fractions_wide.csv"), row.names = FALSE, quote = TRUE)
  write.csv(long_df, file.path(staging_dir, "table", "cibersort_cell_fractions_long.csv"), row.names = FALSE, quote = TRUE)
  write.csv(compare_df, file.path(staging_dir, "table", "cibersort_group_compare.csv"), row.names = FALSE, quote = TRUE)
  write.csv(data.frame(sample = rownames(split_res$quality), split_res$quality, check.names = FALSE), file.path(staging_dir, "table", "cibersort_quality_metrics.csv"), row.names = FALSE, quote = TRUE)
  write.csv(data.frame(cell_type = rownames(cor_res$cor_mat), cor_res$cor_mat, check.names = FALSE), file.path(staging_dir, "table", "immune_cell_correlation_matrix.csv"), row.names = FALSE, quote = TRUE)
  write.csv(data.frame(cell_type = rownames(cor_res$p_mat), cor_res$p_mat, check.names = FALSE), file.path(staging_dir, "table", "immune_cell_correlation_pvalue.csv"), row.names = FALSE, quote = TRUE)
  if (isTRUE(opt$make_plots)) {
    plot_composition(long_df, staging_dir, opt$plot_width, opt$plot_height)
    plot_group_boxplot(long_df, staging_dir, opt$plot_width, opt$plot_height)
    rendering_metadata$correlation_heatmap <- plot_correlation_heatmap(cor_res$cor_mat, cor_res$p_mat, staging_dir)
    result_rds$rendering_metadata <- rendering_metadata
  }
  saveRDS(result_rds, file.path(staging_dir, "data", "cibersort_result.rds"))
  write_session_info(staging_dir)
  input_info <- list(
    genes = nrow(prepared$Y),
    samples = ncol(prepared$Y),
    case_samples = sum(aligned$group_map == opt$case_group),
    control_samples = sum(aligned$group_map == opt$control_group),
    signature_genes = nrow(signature_mat),
    overlapping_genes = length(prepared$overlap_genes),
    cell_types = ncol(split_res$fractions)
  )
  runtime_info <- capture_runtime_info(start_time, start_proc, notes = runtime_notes)
  output_items <- list(
    list(path = "data/cibersort_input.rds", description = "Serialized aligned input matrices.", content = "Stores the standardized signature matrix, aligned mixture matrix, and overlapping genes."),
    list(path = "data/cibersort_null_distribution.rds", description = "Serialized permutation null distribution.", content = "Stores the null distribution of correlation scores used for empirical p-value estimation."),
    list(path = "data/cibersort_result.rds", description = "Serialized CIBERSORT-like result object.", content = "Stores cell fractions, quality metrics, group map, signature source, runtime settings, and heatmap rendering metadata."),
    list(path = "table/CIBERSORT_Results.csv", description = "Full deconvolution result table in CSV format.", content = "Includes immune cell fractions plus P-value, Correlation, and RMSE."),
    list(path = "table/CIBERSORT-Results.txt", description = "Full deconvolution result table in tab-delimited text format.", content = "Tab-delimited export compatible with legacy CIBERSORT-style output handling."),
    list(path = "table/cibersort_cell_fractions_wide.csv", description = "Wide-format immune cell fraction table.", content = "Rows are samples and columns are immune cell types."),
    list(path = "table/cibersort_cell_fractions_long.csv", description = "Long-format immune cell fraction table.", content = "One row per sample and immune cell type."),
    list(path = "table/cibersort_group_compare.csv", description = "Case-versus-control comparison summary.", content = "Wilcoxon statistics and BH-adjusted p-values for each immune cell type."),
    list(path = "table/cibersort_quality_metrics.csv", description = "CIBERSORT-like quality metrics.", content = "Includes P-value, Correlation, and RMSE for each sample."),
    list(path = "table/immune_cell_correlation_matrix.csv", description = "Immune-cell Spearman correlation matrix.", content = "Pairwise correlations across samples."),
    list(path = "table/immune_cell_correlation_pvalue.csv", description = "Correlation p-value matrix.", content = "Pairwise p-values aligned to the correlation matrix."),
    list(path = "session_info.txt", description = "R session information.", content = "sessionInfo() output for reproducibility."),
    list(path = "output_manifest.txt", description = "Append-only output manifest.", content = "Lists generated outputs and descriptions for each run."),
    list(path = "run_record.txt", description = "Append-only structured run record.", content = "Captures parameters, input summary, runtime, CPU time, GC note, and output summary.")
  )
  if (isTRUE(opt$make_plots)) {
    output_items <- c(output_items, list(
      list(path = "plot/immune_cell_composition_sample.pdf", description = "Sample-level composition plot.", content = "Stacked bar plot of CIBERSORT cell fractions by sample."),
      list(path = "plot/immune_group_boxplot.pdf", description = "Group comparison boxplot.", content = "Per-cell-type distribution plot stratified by case and control."),
      list(path = "plot/immune_correlation_heatmap.pdf", description = "Immune-cell correlation heatmap.", content = "Spearman correlation heatmap with significance marks.")
    ))
  }
  write_output_manifest(staging_dir, output_items, opt, runtime_info)
  write_run_record(staging_dir, opt, runtime_info, input_info, output_items, rendering_metadata)
  promote_staged_output(staging_dir, opt$output_dir)
  invisible(result_rds)
}
