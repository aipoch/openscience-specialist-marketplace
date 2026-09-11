build_heatmap_rendering_metadata <- function(cor_mat, p_mat, plot_enabled = TRUE) {
  list(
    plot_enabled = isTRUE(plot_enabled),
    non_finite_values_replaced = sum(!is.finite(cor_mat)),
    replacement_value = 0,
    replacement_scope = "plot_only",
    significant_marker_count = sum(is.finite(p_mat) & p_mat <= 0.05)
  )
}

plot_composition <- function(long_df, output_dir, width = 16, height = 10) {
  plot_dir <- file.path(output_dir, "plot")
  ensure_dir(plot_dir)
  p <- ggplot2::ggplot(long_df, ggplot2::aes(x = sample, y = fraction, fill = cell_type)) +
    ggplot2::geom_col(width = 0.95) +
    ggplot2::theme_bw(base_size = 10) +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 90, hjust = 1, vjust = 0.5),
      legend.position = "bottom"
    ) +
    ggplot2::labs(x = "Sample", y = "Estimated fraction", fill = "Cell type")
  ggplot2::ggsave(file.path(plot_dir, "immune_cell_composition_sample.pdf"), p, width = width, height = height, units = "in")
}

plot_group_boxplot <- function(long_df, output_dir, width = 16, height = 10) {
  plot_dir <- file.path(output_dir, "plot")
  ensure_dir(plot_dir)
  p <- ggplot2::ggplot(long_df, ggplot2::aes(x = cell_type, y = fraction, fill = group)) +
    ggplot2::geom_boxplot(outlier.size = 0.5) +
    ggplot2::theme_bw(base_size = 10) +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)) +
    ggplot2::labs(x = "Immune cell type", y = "Estimated fraction", fill = NULL)
  ggplot2::ggsave(file.path(plot_dir, "immune_group_boxplot.pdf"), p, width = width, height = height, units = "in")
}

plot_correlation_heatmap <- function(cor_mat, p_mat, output_dir, filename = "immune_correlation_heatmap.pdf") {
  plot_dir <- file.path(output_dir, "plot")
  ensure_dir(plot_dir)
  rendering_meta <- build_heatmap_rendering_metadata(cor_mat, p_mat, plot_enabled = TRUE)
  plot_mat <- cor_mat
  replaced_n <- rendering_meta$non_finite_values_replaced
  if (replaced_n > 0) {
    log_warn(sprintf("Replaced %d non-finite correlation values with 0 for heatmap visualization only.", replaced_n))
  }
  plot_mat[!is.finite(plot_mat)] <- 0
  display_numbers <- matrix("", nrow = nrow(p_mat), ncol = ncol(p_mat), dimnames = dimnames(p_mat))
  display_numbers[is.finite(p_mat) & p_mat <= 0.05] <- "*"
  hm <- pheatmap::pheatmap(
    plot_mat,
    silent = TRUE,
    border_color = NA,
    display_numbers = display_numbers,
    fontsize = 8
  )
  grDevices::pdf(file.path(plot_dir, filename), width = 10, height = 9)
  grid::grid.newpage()
  grid::grid.draw(hm$gtable)
  grDevices::dev.off()
  invisible(rendering_meta)
}
