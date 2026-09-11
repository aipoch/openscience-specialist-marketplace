#!/usr/bin/env Rscript

run_analysis <- function(opt) {
  data_dir <- file.path(opt$output_dir, "data")
  table_dir <- file.path(opt$output_dir, "table")
  plot_dir <- file.path(opt$output_dir, "plot")

  ensure_dir(data_dir)
  ensure_dir(table_dir)
  ensure_dir(plot_dir)

  log_info(sprintf("Loading expression matrix: %s", opt$input_file))
  expr_df <- load_expression_matrix(opt$input_file, opt$input_delimiter)
  input_info <- validate_expression_matrix(expr_df)

  paths <- list(
    prepared_input_file = file.path(data_dir, "expression_input.tsv"),
    estimate_input_gct = file.path(data_dir, "estimate_input.gct"),
    estimate_score_gct = file.path(data_dir, "estimate_score.gct"),
    score_table = file.path(table_dir, "estimate_scores.tsv")
  )

  write_estimate_input_tsv(expr_df, paths$prepared_input_file, opt$gene_id_type)
  log_info("Running estimate::filterCommonGenes and estimate::estimateScore.")
  run_estimate_pipeline(
    prepared_input_file = paths$prepared_input_file,
    estimate_input_gct = paths$estimate_input_gct,
    estimate_score_gct = paths$estimate_score_gct,
    gene_id_type = opt$gene_id_type,
    platform = opt$platform
  )

  score_df <- read_estimate_score_gct(paths$estimate_score_gct)
  write_score_table(score_df, paths$score_table)
  paths$heatmap_file <- file.path(plot_dir, opt$heatmap_file)
  paths$session_info_file <- save_session_info(opt$output_dir)

  group_df <- NULL
  if (!is.null(opt$group_file) && nzchar(opt$group_file)) {
    log_info(sprintf("Loading group file: %s", opt$group_file))
    group_df <- load_group_file(opt$group_file, opt$group_delimiter)
  }

  create_estimate_heatmap(
    score_df = score_df,
    heatmap_file = paths$heatmap_file,
    group_df = group_df,
    sample_column = opt$sample_column,
    group_column = opt$group_column
  )

  if (!is.null(group_df)) {
    plot_data <- prepare_score_plot_data(score_df, group_df, opt$sample_column, opt$group_column)
    paths$plot_file <- file.path(plot_dir, opt$plot_file)
    paths$stats_file <- file.path(table_dir, "estimate_score_group_stats.csv")
    stats_df <- run_group_tests(plot_data$long_data)
    save_group_statistics(stats_df, paths$stats_file)
    create_estimate_boxplot(plot_data$long_data, paths$plot_file)
    input_info$matched_group_samples <- nrow(plot_data$group_info[plot_data$group_info$sample %in% score_df$sample, , drop = FALSE])
    input_info$group_levels <- paste(sort(unique(plot_data$long_data$group)), collapse = ", ")
  }

  list(
    input_info = input_info,
    output_items = build_output_items(paths),
    score_table = paths$score_table
  )
}
