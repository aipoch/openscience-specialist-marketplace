validate_main_args <- function(opt) {
  if (is.null(opt$input_file) || is.null(opt$group_file) || is.null(opt$case_group) || is.null(opt$control_group)) {
    skill_stop("SKILL_INVALID_PARAMETER", "--input_file, --group_file, --case_group, and --control_group are required.")
  }
  if (is.na(opt$seed)) {
    skill_stop("SKILL_INVALID_PARAMETER", "--seed must be a valid integer.")
  }
  if (!(opt$method %in% c("ssgsea", "gsva"))) {
    skill_stop("SKILL_INVALID_PARAMETER", "Unsupported --method.")
  }
  if (!(opt$kcdf %in% c("Gaussian", "Poisson"))) {
    skill_stop("SKILL_INVALID_PARAMETER", "Unsupported --kcdf.")
  }
  if (!(opt$gene_id_case %in% c("asis", "upper", "lower"))) {
    skill_stop("SKILL_INVALID_PARAMETER", "Unsupported --gene_id_case.")
  }
  if (is.na(opt$timeout_seconds) || opt$timeout_seconds < 0) {
    skill_stop("SKILL_INVALID_PARAMETER", "--timeout_seconds must be >= 0.")
  }
  if (is.na(opt$min_sz) || opt$min_sz < 1) {
    skill_stop("SKILL_INVALID_PARAMETER", "--min_sz must be >= 1.")
  }
  if (is.na(opt$max_sz) || opt$max_sz < opt$min_sz) {
    skill_stop("SKILL_INVALID_PARAMETER", "--max_sz must be >= --min_sz.")
  }
  if (is.na(opt$parallel_sz) || opt$parallel_sz < 1) {
    skill_stop("SKILL_INVALID_PARAMETER", "--parallel_sz must be >= 1.")
  }
  if (is.na(opt$tau) || opt$tau < 0) {
    skill_stop("SKILL_INVALID_PARAMETER", "--tau must be >= 0.")
  }
  if (!is.null(opt$sample_col) && is.numeric(opt$sample_col) && opt$sample_col < 1) {
    skill_stop("SKILL_INVALID_PARAMETER", "--sample_col index must be >= 1.")
  }
  if (!is.null(opt$group_col) && is.numeric(opt$group_col) && opt$group_col < 1) {
    skill_stop("SKILL_INVALID_PARAMETER", "--group_col index must be >= 1.")
  }
}

run_analysis <- function(opt) {
  validate_main_args(opt)
  if (opt$timeout_seconds > 0) {
    setTimeLimit(cpu = opt$timeout_seconds, elapsed = opt$timeout_seconds, transient = TRUE)
    on.exit(setTimeLimit(cpu = Inf, elapsed = Inf, transient = FALSE), add = TRUE)
  }
  set.seed(opt$seed)
  start_time <- Sys.time()
  ensure_dir(opt$output_dir)
  data_dir <- file.path(opt$output_dir, "data")
  table_dir <- file.path(opt$output_dir, "table")
  plot_dir <- file.path(opt$output_dir, "plot")
  ensure_dir(data_dir)
  ensure_dir(table_dir)
  ensure_dir(plot_dir)
  legacy_files <- c(
    "ssgsea_list.rds",
    "ssgsea_scores_long.csv",
    "ssgsea_scores_wide.csv",
    "ssgsea_group_compare.csv",
    "immune_cell_correlation_matrix.csv",
    "immune_cell_correlation_pvalue.csv",
    "geneset_overlap_summary.csv",
    "immune_cell_composition_sample.pdf",
    "immune_group_boxplot.pdf",
    "immune_correlation_heatmap.pdf",
    "reused_heatmap.pdf"
  )
  unlink(file.path(opt$output_dir, legacy_files), force = TRUE)
  unlink(file.path(data_dir, "*"), recursive = TRUE, force = TRUE)
  unlink(file.path(table_dir, "*"), recursive = TRUE, force = TRUE)
  unlink(file.path(plot_dir, "*.pdf"), force = TRUE)
  exp_mat <- read_expression_matrix(opt$input_file, opt$gene_id_case, opt$verbose)
  group_map <- read_group_info(opt$group_file, opt$case_group, opt$control_group, opt$sample_col, opt$group_col, opt$verbose)
  geneset_res <- read_gene_sets(opt$gene_set, opt$gene_id_case, opt$verbose)
  aligned <- align_inputs(exp_mat, group_map, opt$case_group, opt$control_group, opt$verbose)
  overlap_res <- filter_gene_sets(geneset_res$genesets, aligned$exp_mat, opt$min_sz)
  scores <- run_ssgsea_core(aligned$exp_mat, overlap_res$genesets, opt$method, opt$kcdf, opt$min_sz, opt$max_sz, opt$parallel_sz, opt$mx_diff, opt$tau)
  scores_long <- make_scores_long(scores, aligned$group_map, geneset_res$cell_anno, opt$case_group, opt$control_group)
  group_compare <- calc_group_compare(scores_long, opt$case_group, opt$control_group)
  cor_res <- calc_correlation_tables(scores)
  ssgsea_list <- list(scores = scores, group = aligned$group_map, case = opt$case_group, control = opt$control_group, exp_mat_used = aligned$exp_mat, cell_anno = geneset_res$cell_anno, geneset_summary = overlap_res$geneset_summary)
  write.csv(tibble::rownames_to_column(as.data.frame(scores), "cell_type"), file.path(table_dir, "ssgsea_scores_wide.csv"), row.names = FALSE, quote = TRUE)
  write.csv(scores_long, file.path(table_dir, "ssgsea_scores_long.csv"), row.names = FALSE, quote = TRUE)
  write.csv(group_compare, file.path(table_dir, "ssgsea_group_compare.csv"), row.names = FALSE, quote = TRUE)
  write.csv(tibble::rownames_to_column(as.data.frame(cor_res$cor_mat), "cell_type"), file.path(table_dir, "immune_cell_correlation_matrix.csv"), row.names = FALSE, quote = TRUE)
  write.csv(tibble::rownames_to_column(as.data.frame(cor_res$p_mat), "cell_type"), file.path(table_dir, "immune_cell_correlation_pvalue.csv"), row.names = FALSE, quote = TRUE)
  saveRDS(ssgsea_list, file.path(data_dir, "ssgsea_list.rds"))
  write_session_info(opt$output_dir)
  manifest <- list(
    list(file = "data/ssgsea_list.rds", description = "Serialized immune infiltration result object for downstream reuse."),
    list(file = "table/ssgsea_scores_long.csv", description = "Long-format immune infiltration scores per sample."),
    list(file = "table/ssgsea_scores_wide.csv", description = "Wide-format immune infiltration score matrix."),
    list(file = "table/ssgsea_group_compare.csv", description = "Wilcoxon group comparison summary for each immune cell."),
    list(file = "table/immune_cell_correlation_matrix.csv", description = "Spearman immune-cell correlation matrix."),
    list(file = "table/immune_cell_correlation_pvalue.csv", description = "P-value matrix paired with the immune-cell correlation matrix."),
    list(file = "session_info.txt", description = "R session information for reproducibility."),
    list(file = "run_record.txt", description = "Structured execution record with inputs, runtime, and output summary."),
    list(file = "output_manifest.txt", description = "Inventory of generated output files and their descriptions.")
  )
  if (isTRUE(opt$make_plots)) {
    plot_composition(scores_long, opt$output_dir)
    plot_group_boxplot(scores_long, opt$output_dir)
    plot_correlation_heatmap(cor_res$cor_mat, cor_res$p_mat, geneset_res$cell_anno, opt$output_dir)
    scatter_res <- plot_gene_scatter(ssgsea_list, opt$output_dir)
    manifest <- c(manifest, list(
      list(file = "plot/immune_cell_composition_sample.pdf", description = "Stacked composition plot normalized within each sample."),
      list(file = "plot/immune_group_boxplot.pdf", description = "Case-versus-control boxplot by immune cell."),
      list(file = "plot/immune_correlation_heatmap.pdf", description = "Spearman immune-cell correlation heatmap with significance marks."),
      list(file = file.path("plot", scatter_res$file), description = sprintf("Gene-versus-immune-cell scatter plot for %s and %s.", scatter_res$gene, scatter_res$cell_type))
    ))
  }
  write_output_manifest(opt$output_dir, manifest)
  runtime <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
  gc_stats <- gc()
  write_run_record(opt$output_dir, list(
    args = opt,
    input_summary = sprintf("%d genes, %d samples, %d immune gene sets kept.", nrow(aligned$exp_mat), ncol(aligned$exp_mat), sum(overlap_res$geneset_summary$kept)),
    runtime_seconds = runtime,
    cpu_summary = sprintf("Requested parallel_sz=%d; actual_parallel_sz=%d.", opt$parallel_sz, attr(scores, "actual_parallel_sz")),
    gc_note = sprintf("GC used cells: Ncells=%s, Vcells=%s.", gc_stats[1, 2], gc_stats[2, 2]),
    output_summary = sprintf("%d score rows, %d samples, plots=%s. Structured outputs under data/, table/, and plot/.", nrow(scores), ncol(scores), ifelse(opt$make_plots, "enabled", "disabled"))
  ))
  invisible(ssgsea_list)
}
