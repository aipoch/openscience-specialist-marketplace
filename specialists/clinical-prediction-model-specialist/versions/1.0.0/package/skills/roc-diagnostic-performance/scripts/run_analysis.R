prepare_analysis_inputs <- function(options) {
  genes <- parse_gene_arg(options$marker_genes)
  options$show_diagonal <- parse_bool_arg(options$show_diagonal, "--show_diagonal")
  output_paths <- create_output_dirs(options$output_dir, overwrite = isTRUE(options$overwrite))

  log_info("Loading expression matrix and group file...")
  expression_df <- read_expression_matrix(options$expression_file)
  group_df <- read_group_file(options$group_file)

  log_info("Preparing matched analysis dataset...")
  prepared <- prepare_analysis_data(expression_df, group_df, genes, options$case_group, options$group_col)
  list(options = options, output_paths = output_paths, prepared = prepared)
}

build_analysis_bundle <- function(model, analysis_data, genes, roc_list) {
  list(
    model = model,
    genes = genes,
    data = analysis_data,
    coefficients = extract_coefficient_table(model),
    auc_summary = build_auc_summary(roc_list)
  )
}

build_run_metadata <- function(options, output_paths, prepared) {
  genes <- prepared$genes
  list(
    expression_file = normalizePath(options$expression_file, winslash = "/", mustWork = TRUE),
    group_file = normalizePath(options$group_file, winslash = "/", mustWork = TRUE),
    marker_genes = genes,
    case_group = options$case_group,
    group_col = prepared$group_col,
    output_dir = output_paths$root,
    overwrite = isTRUE(options$overwrite),
    seed = options$seed,
    timeout_seconds = options$timeout_seconds,
    plot_width = options$plot_width,
    plot_height = options$plot_height,
    font_family = options$font_family,
    line_colors = options$line_colors,
    line_width = options$line_width,
    show_diagonal = options$show_diagonal,
    diagonal_color = options$diagonal_color,
    diagonal_lty = options$diagonal_lty,
    plot_title = options$plot_title,
    x_label = options$x_label,
    y_label = options$y_label,
    base_cex = options$base_cex,
    legend_position = options$legend_position,
    legend_cex = options$legend_cex
  )
}

run_analysis <- function(options) {
  inputs <- prepare_analysis_inputs(options)
  options <- inputs$options
  output_paths <- inputs$output_paths
  prepared <- inputs$prepared
  analysis_data <- prepared$data
  genes <- prepared$genes

  log_info("Fitting diagnostic logistic regression model...")
  model <- fit_logistic_model(analysis_data, genes)
  roc_list <- build_roc_curves(model, analysis_data, genes)
  bundle <- build_analysis_bundle(model, analysis_data, genes, roc_list)

  log_info("Saving tabular outputs...")
  write_analysis_outputs(bundle, output_paths)

  log_info("Rendering ROC PDF...")
  render_roc_plot(roc_list, file.path(output_paths$plot, "roc_curve.pdf"), options)

  save_session_info(output_paths$root, metadata = build_run_metadata(options, output_paths, prepared))
  log_info(paste("Analysis completed successfully. Output:", output_paths$root))
}
