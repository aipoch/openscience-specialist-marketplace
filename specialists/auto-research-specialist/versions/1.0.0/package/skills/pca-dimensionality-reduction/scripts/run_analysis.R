save_result_tables <- function(results, prepared_data, output_dirs, params) {
  extension <- ifelse(params$output_format == "csv", ".csv", ".txt")

  table_targets <- list(
    summary = file.path(output_dirs$table_dir, paste0(params$output_prefix, "_summary", extension)),
    scores = file.path(output_dirs$table_dir, paste0(params$output_prefix, "_scores", extension)),
    loadings = file.path(output_dirs$table_dir, paste0(params$output_prefix, "_loadings", extension)),
    top_loadings = file.path(output_dirs$table_dir, paste0(params$output_prefix, "_top_loadings", extension)),
    metadata = file.path(output_dirs$table_dir, paste0(params$output_prefix, "_metadata", extension))
  )

  write_output_table(results$summary, table_targets$summary, params$output_format)
  write_output_table(results$scores, table_targets$scores, params$output_format)
  write_output_table(results$loadings, table_targets$loadings, params$output_format)
  write_output_table(results$top_loadings, table_targets$top_loadings, params$output_format)
  write_output_table(results$metadata, table_targets$metadata, params$output_format)

  input_file <- file.path(output_dirs$data_dir, paste0(params$output_prefix, "_filtered_input", extension))
  write_output_table(prepared_data$filtered_input, input_file, params$output_format)

  return(c(unlist(table_targets), filtered_input = input_file))
}

save_scree_plot <- function(summary_df, output_dirs, params) {
  figure_file <- file.path(output_dirs$figure_dir, paste0(params$output_prefix, "_scree_plot.png"))
  png(figure_file, width = 1200, height = 900, res = 150)
  on.exit(dev.off(), add = TRUE)

  barplot(
    summary_df$proportion_variance,
    names.arg = summary_df$component,
    col = "steelblue",
    border = NA,
    ylim = c(0, max(summary_df$proportion_variance) * 1.15),
    ylab = "Explained variance proportion",
    xlab = "Principal component",
    main = "PCA Scree Plot"
  )
  lines(
    x = seq_along(summary_df$cumulative_variance),
    y = summary_df$cumulative_variance,
    type = "b",
    lwd = 2,
    pch = 16,
    col = "firebrick"
  )
  legend(
    "topright",
    legend = c("Individual variance", "Cumulative variance"),
    fill = c("steelblue", NA),
    border = c(NA, NA),
    lty = c(NA, 1),
    pch = c(NA, 16),
    col = c("steelblue", "firebrick"),
    bty = "n"
  )

  log_info("Saved figure to: ", figure_file)
  invisible(figure_file)
}

save_score_plot <- function(results, output_dirs, params) {
  if (!all(c("PC1", "PC2") %in% colnames(results$scores))) {
    log_warn("Skipping score plot because fewer than 2 principal components were exported")
    return(NULL)
  }

  figure_file <- file.path(output_dirs$figure_dir, paste0(params$output_prefix, "_score_plot.png"))
  png(figure_file, width = 1200, height = 900, res = 150)
  on.exit(dev.off(), add = TRUE)

  variance_lookup <- stats::setNames(
    round(results$summary$proportion_variance * 100, 2),
    results$summary$component
  )
  xlab_text <- paste0("PC1 (", variance_lookup[["PC1"]], "%)")
  ylab_text <- paste0("PC2 (", variance_lookup[["PC2"]], "%)")

  if ("group" %in% colnames(results$scores)) {
    group_factor <- as.factor(results$scores$group)
    group_colors <- grDevices::rainbow(length(levels(group_factor)))
    point_colors <- group_colors[as.integer(group_factor)]

    plot(
      results$scores$PC1,
      results$scores$PC2,
      col = point_colors,
      pch = 19,
      xlab = xlab_text,
      ylab = ylab_text,
      main = "PCA Score Plot"
    )
    legend("topright", legend = levels(group_factor), col = group_colors, pch = 19, bty = "n")
  } else {
    plot(
      results$scores$PC1,
      results$scores$PC2,
      col = "steelblue",
      pch = 19,
      xlab = xlab_text,
      ylab = ylab_text,
      main = "PCA Score Plot"
    )
  }

  if (nrow(results$scores) <= 20) {
    text(results$scores$PC1, results$scores$PC2, labels = results$scores$sample_id, pos = 3, cex = 0.8)
  }

  log_info("Saved figure to: ", figure_file)
  invisible(figure_file)
}

pca_analysis <- function(params) {
  output_dirs <- create_output_structure(params$output_dir)

  log_info("Loading data...")
  data <- read_data(params$data_file)

  log_info("Preparing PCA input...")
  prepared_data <- prepare_pca_input(data, params)
  log_info("Using ", length(prepared_data$feature_columns), " features: ", paste(prepared_data$feature_columns, collapse = ", "))
  log_info("Samples retained after filtering: ", nrow(prepared_data$feature_matrix))

  if (prepared_data$removed_row_count > 0) {
    log_warn("Removed ", prepared_data$removed_row_count, " rows with missing or non-finite values in selected features")
  }

  log_info("Computing principal components...")
  results <- run_pca(prepared_data, params)

  log_info("Saving tables...")
  output_files <- save_result_tables(results, prepared_data, output_dirs, params)

  log_info("Saving figures...")
  scree_plot_file <- save_scree_plot(results$summary, output_dirs, params)
  score_plot_file <- save_score_plot(results, output_dirs, params)

  log_info("=== Analysis completed successfully! ===")

  return(list(
    results = results,
    prepared_data = prepared_data,
    parameters = params,
    output_dirs = output_dirs,
    output_files = c(output_files, scree_plot = scree_plot_file, score_plot = score_plot_file)
  ))
}
