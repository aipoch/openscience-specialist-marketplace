write_corrected_matrix <- function(expr_mat, output_dir) {
  output_file <- file.path(output_dir, "corrected_expression_matrix.csv")
  output_data <- data.frame(gene_id = rownames(expr_mat), expr_mat, check.names = FALSE)
  tryCatch(
    utils::write.csv(output_data, output_file, row.names = FALSE),
    error = function(e) {
      stop(sprintf("SKILL_RUNTIME_ERROR: Failed to write corrected matrix: %s", conditionMessage(e)), call. = FALSE)
    }
  )
  output_file
}

write_matched_metadata <- function(metadata, output_dir) {
  output_file <- file.path(output_dir, "matched_sample_info.csv")
  tryCatch(
    utils::write.csv(metadata, output_file, row.names = FALSE),
    error = function(e) {
      stop(sprintf("SKILL_RUNTIME_ERROR: Failed to write matched metadata: %s", conditionMessage(e)), call. = FALSE)
    }
  )
  output_file
}

write_core_outputs <- function(corrected_expr, metadata, output_dir) {
  write_corrected_matrix(corrected_expr, output_dir)
  write_matched_metadata(metadata, output_dir)
}

write_qc_outputs <- function(before_expr, after_expr, metadata, output_dir) {
  plot_boxplot_pdf(before_expr, metadata, file.path(output_dir, "batch_before_boxplot.pdf"), "Before batch correction: boxplot")
  plot_pca_pdf(before_expr, metadata, file.path(output_dir, "batch_before_pca.pdf"), "Before batch correction: PCA")
  plot_clustering_pdf(before_expr, metadata, file.path(output_dir, "batch_before_clustering.pdf"), "Before batch correction: clustering")
  plot_boxplot_pdf(after_expr, metadata, file.path(output_dir, "batch_after_boxplot.pdf"), "After batch correction: boxplot")
  plot_pca_pdf(after_expr, metadata, file.path(output_dir, "batch_after_pca.pdf"), "After batch correction: PCA")
  plot_clustering_pdf(after_expr, metadata, file.path(output_dir, "batch_after_clustering.pdf"), "After batch correction: clustering")
}
