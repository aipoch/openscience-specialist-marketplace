log_run_configuration <- function(opt) {
  log_info("==========================================")
  log_info("Hierarchical Clustering Plot")
  log_info("==========================================")
  log_info(paste("Input:", opt$input_file))
  log_info(paste("Group:", opt$group_file))
  log_info(paste("Output:", opt$output_dir))
  log_info(paste("Distance:", opt$distance_method))
  log_info(paste("Linkage:", opt$linkage_method))
  log_info(paste("Label column:", ifelse(nzchar(opt$label_column), opt$label_column, "<second column>")))
  log_info(paste("Timeout (seconds):", opt$timeout_seconds))
  log_info(paste("Seed:", opt$seed))
}

build_output_paths <- function(output_dir) {
  list(
    distance = file.path(output_dir, "sample_distance_matrix.csv"),
    order = file.path(output_dir, "clustering_order.csv"),
    matched = file.path(output_dir, "matched_samples.csv"),
    plot = file.path(output_dir, "hierarchical_clustering_plot.pdf")
  )
}

write_analysis_outputs <- function(paths, aligned, distance_obj, hc, label_cex, distance_method, linkage_method) {
  save_distance_matrix(distance_obj, paths$distance)
  save_clustering_order(build_clustering_order(hc, aligned$groups), paths$order)
  save_matched_samples(aligned$groups, paths$matched)
  plot_clustering_pdf(
    hc = hc,
    labels = aligned$groups$label,
    output_file = paths$plot,
    label_cex = label_cex,
    distance_method = distance_method,
    linkage_method = linkage_method
  )
}

run_analysis_cli <- function(opt) {
  validate_scalar_numeric(opt$label_cex, "label_cex", lower_bound = 0)
  validate_scalar_numeric(opt$timeout_seconds, "timeout_seconds", lower_bound = 0)
  validate_scalar_numeric(opt$seed, "seed")
  check_files(opt$input_file, opt$group_file)
  set.seed(opt$seed)
  set_analysis_timeout(opt$timeout_seconds)
  on.exit(reset_time_limit(), add = TRUE)
  log_run_configuration(opt)
  result <- run_clustering_analysis(
    input_file = opt$input_file,
    group_file = opt$group_file,
    output_dir = opt$output_dir,
    distance_method = opt$distance_method,
    linkage_method = opt$linkage_method,
    label_column = opt$label_column,
    label_cex = opt$label_cex
  )
  log_info(paste("All results saved to:", opt$output_dir))
  invisible(result)
}

run_clustering_analysis <- function(input_file, group_file, output_dir, distance_method,
                                    linkage_method, label_column, label_cex) {
  temp_dir <- create_temp_workspace()
  on.exit(cleanup_temp_resources(temp_dirs = temp_dir), add = TRUE)
  paths <- build_output_paths(temp_dir)

  log_info("Step 1/4: Loading and validating data...")
  expr_mat <- load_expression_matrix(input_file)
  group_df <- load_group_data(group_file, label_column)
  log_memory_usage("loading data")

  log_info("Step 2/4: Aligning samples...")
  aligned <- align_samples(expr_mat, group_df)
  log_info(paste("Matched samples:", ncol(aligned$expr)))
  log_info(paste("Features used:", nrow(aligned$expr)))

  check_output_dir(output_dir)

  log_info("Step 3/4: Running hierarchical clustering...")
  distance_obj <- build_distance_matrix(aligned$expr, distance_method)
  hc <- build_clustering(distance_obj, linkage_method)
  log_memory_usage("clustering")

  log_info("Step 4/4: Writing outputs...")
  write_analysis_outputs(paths, aligned, distance_obj, hc, label_cex, distance_method, linkage_method)
  copy_output_file(paths$distance, output_dir, "sample_distance_matrix.csv")
  copy_output_file(paths$order, output_dir, "clustering_order.csv")
  copy_output_file(paths$matched, output_dir, "matched_samples.csv")
  copy_output_file(paths$plot, output_dir, "hierarchical_clustering_plot.pdf")
  save_session_info(output_dir)
  log_memory_usage("writing outputs")
  invisible(list(distance = distance_obj, clustering = hc))
}
