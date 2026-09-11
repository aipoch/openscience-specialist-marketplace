#!/usr/bin/env Rscript

run_analysis_mode <- function(opt) {
  log_info("Loading expression matrix.")
  exp_mat <- read_expression_matrix(opt$input_file)

  log_info("Loading group file.")
  groups <- read_group_file(opt$group_file)

  validated <- validate_analysis_inputs(exp_mat, groups, opt$case_group, opt$control_group)
  exp_mat <- validated$exp_mat
  groups <- validated$groups

  log_info("Loading MSigDB gene sets.")
  gene_sets <- load_gene_sets(opt$species, opt$category, opt$subcategory)

  log_info("Running GSVA scoring.")
  gsva_scores <- run_gsva_scores(exp_mat, gene_sets, opt)

  log_info("Running limma differential analysis.")
  diff_df <- run_limma_diff(gsva_scores, groups, opt$case_group, opt$control_group)
  top_pathways <- select_top_pathways(diff_df, opt$top_n, opt$fdr_threshold)
  top_scores <- gsva_scores[top_pathways, , drop = FALSE]

  gsva_result <- list(
    case = opt$case_group,
    control = opt$control_group,
    gsva_scores = gsva_scores,
    gsva_scores_top = top_scores,
    GSVA_diff = diff_df,
    groups = groups,
    params = list(
      species = opt$species,
      category = opt$category,
      subcategory = opt$subcategory,
      method = opt$method,
      kcdf = opt$kcdf,
      min_sz = opt$min_sz,
      max_sz = opt$max_sz,
      parallel_sz = opt$parallel_sz,
      mx_diff = opt$mx_diff,
      tau = opt$tau,
      fdr_threshold = opt$fdr_threshold,
      top_n = opt$top_n,
      seed = opt$seed
    )
  )

  save_analysis_outputs(opt$output_dir, gsva_scores, top_scores, diff_df, gsva_result)
  save_session_info(opt$output_dir)

  list(
    input_info = list(
      genes = nrow(exp_mat),
      samples = ncol(exp_mat),
      case_samples = sum(groups == opt$case_group),
      control_samples = sum(groups == opt$control_group)
    ),
    diff_file = file.path(opt$output_dir, "table", "GSVA_diff.csv"),
    scores_file = file.path(opt$output_dir, "table", "GSVA_enrichment_results.csv"),
    top_scores_file = file.path(opt$output_dir, "table", "GSVA_enrichment_results_topN.csv"),
    rda_file = file.path(opt$output_dir, "data", "GSVA_list.rda")
  )
}

run_visualization_mode <- function(opt) {
  gsva_result <- load_gsva_result(opt$output_dir)
  plot_file <- generate_heatmap_plot(opt$output_dir, gsva_result, opt)
  list(plot_file = plot_file)
}
