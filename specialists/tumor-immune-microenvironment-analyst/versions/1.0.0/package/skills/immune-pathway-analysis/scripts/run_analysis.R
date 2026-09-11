#!/usr/bin/env Rscript

run_analysis_mode <- function(opt) {
  log_info("Loading expression matrix.")
  exp_mat <- read_expression_matrix(opt$input_file)
  log_info("Loading group file.")
  groups <- read_group_file(opt$group_file)
  validated <- validate_analysis_inputs(exp_mat, groups, opt$case_group, opt$control_group)
  exp_mat <- validated$exp_mat
  groups <- validated$groups
  opt$case_group <- validated$case_group
  opt$control_group <- validated$control_group
  log_info("Loading immune gene-set table.")
  geneset_df <- read_geneset_table(opt$geneset_file, opt$geneset_column, opt$gene_column)
  log_info("Building immune gene sets from the local table.")
  gene_sets <- build_gene_sets(geneset_df, exp_mat, opt$min_sz, opt$max_sz)
  geneset_summary <- build_geneset_summary(gene_sets)
  log_info("Running GSVA scoring.")
  gsva_scores <- run_gsva_scores(exp_mat, gene_sets, opt)
  log_info("Running limma differential analysis.")
  diff_df <- run_limma_diff(gsva_scores, groups, opt$case_group, opt$control_group)
  top_pathways <- select_top_pathways(diff_df, opt$top_n, opt$fdr_threshold)
  top_scores <- gsva_scores[top_pathways, , drop = FALSE]
  result_object <- list(case = opt$case_group, control = opt$control_group, gsva_scores = gsva_scores, gsva_scores_top = top_scores, pathway_diff = diff_df, groups = groups, geneset_summary = geneset_summary, params = list(geneset_file = opt$geneset_file, geneset_column = opt$geneset_column, gene_column = opt$gene_column, method = opt$method, kcdf = opt$kcdf, min_sz = opt$min_sz, max_sz = opt$max_sz, parallel_sz = opt$parallel_sz, mx_diff = opt$mx_diff, tau = opt$tau, fdr_threshold = opt$fdr_threshold, top_n = opt$top_n, seed = opt$seed))
  save_analysis_outputs(opt$output_dir, gsva_scores, top_scores, diff_df, geneset_summary, result_object)
  list(input_info = list(genes = nrow(exp_mat), samples = ncol(exp_mat), case_samples = sum(groups == opt$case_group), control_samples = sum(groups == opt$control_group), genesets_retained = nrow(geneset_summary), matched_genes = length(unique(unlist(gene_sets)))), result_summary = list(significant_pathways = sum(diff_df$adj.P.Val <= opt$fdr_threshold, na.rm = TRUE), reported_top_pathways = nrow(top_scores), fdr_threshold = opt$fdr_threshold, method = opt$method), diff_file = file.path(opt$output_dir, "table", "immune_pathway_diff.csv"), scores_file = file.path(opt$output_dir, "table", "immune_pathway_scores.csv"), top_scores_file = file.path(opt$output_dir, "table", "immune_pathway_scores_top.csv"), geneset_summary_file = file.path(opt$output_dir, "table", "immune_gene_set_summary.csv"), rds_file = file.path(opt$output_dir, "data", "immune_pathway_result.rds"))
}

run_visualization_mode <- function(opt) {
  gsva_result <- load_gsva_result(opt$output_dir)
  diff_df <- gsva_result$pathway_diff
  list(plot_file = generate_heatmap_plot(opt$output_dir, gsva_result, opt), result_summary = list(significant_pathways = sum(diff_df$adj.P.Val <= opt$fdr_threshold, na.rm = TRUE), reported_top_pathways = nrow(gsva_result$gsva_scores_top %||% gsva_result$gsva_scores), fdr_threshold = opt$fdr_threshold, method = gsva_result$params$method %||% "unknown"))
}
