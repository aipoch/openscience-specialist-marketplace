plot_composition <- function(scores_long, output_dir) {
  plot_dir <- file.path(output_dir, "plot")
  ensure_dir(plot_dir)
  plot_df <- dplyr::group_by(scores_long, .data$sample, .data$group)
  plot_df <- dplyr::mutate(
    plot_df,
    shifted = .data$ssgsea_score - min(.data$ssgsea_score),
    shifted_sum = sum(.data$shifted),
    frac = dplyr::if_else(.data$shifted_sum > 0, .data$shifted / .data$shifted_sum, 1 / dplyr::n())
  )
  plot_df <- dplyr::ungroup(plot_df)
  plot_df$label <- ifelse(is.na(plot_df$cell_type_label) | plot_df$cell_type_label == "", plot_df$cell_type, plot_df$cell_type_label)
  p <- ggplot2::ggplot(plot_df, ggplot2::aes(x = sample, y = frac, fill = label)) +
    ggplot2::geom_col(width = 0.95) + ggplot2::theme_bw(base_size = 10) +
    ggplot2::theme(axis.text.x = ggplot2::element_blank(), axis.ticks.x = ggplot2::element_blank(), legend.position = "bottom") +
    ggplot2::labs(x = "Sample", y = "Fraction (normalized within sample)", fill = "Cell type")
  ggplot2::ggsave(file.path(plot_dir, "immune_cell_composition_sample.pdf"), p, width = 16, height = 10, units = "in")
}

plot_group_boxplot <- function(scores_long, output_dir) {
  plot_dir <- file.path(output_dir, "plot")
  ensure_dir(plot_dir)
  scores_long$label <- ifelse(is.na(scores_long$cell_type_label) | scores_long$cell_type_label == "", scores_long$cell_type, scores_long$cell_type_label)
  stat_df <- dplyr::summarise(dplyr::group_by(scores_long, .data$label), ymax = max(.data$ssgsea_score), ymin = min(.data$ssgsea_score), .groups = "drop")
  p <- ggplot2::ggplot(scores_long, ggplot2::aes(x = label, y = ssgsea_score, fill = group)) +
    ggplot2::geom_boxplot(outlier.size = 0.6) + ggplot2::theme_bw(base_size = 10) +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)) +
    ggplot2::labs(x = "Immune cell", y = "ssGSEA score", fill = NULL)
  ggplot2::ggsave(file.path(plot_dir, "immune_group_boxplot.pdf"), p, width = 18, height = 10, units = "in")
}

plot_correlation_heatmap <- function(cor_mat, p_mat, cell_anno, output_dir, filename = "immune_correlation_heatmap.pdf") {
  plot_dir <- file.path(output_dir, "plot")
  ensure_dir(plot_dir)
  labels <- cell_anno$cell_type_label[match(rownames(cor_mat), cell_anno$cell_type)]
  labels[is.na(labels) | labels == ""] <- rownames(cor_mat)[is.na(labels) | labels == ""]
  rownames(cor_mat) <- labels
  colnames(cor_mat) <- labels
  rownames(p_mat) <- labels
  colnames(p_mat) <- labels
  hm <- pheatmap::pheatmap(cor_mat, silent = TRUE, border_color = NA, display_numbers = ifelse(p_mat <= 0.05, "*", ""), fontsize = 8)
  grDevices::pdf(file.path(plot_dir, filename), width = 10, height = 9)
  grid::grid.newpage()
  grid::grid.draw(hm$gtable)
  grDevices::dev.off()
}

plot_gene_scatter <- function(ssgsea_list, output_dir) {
  plot_dir <- file.path(output_dir, "plot")
  ensure_dir(plot_dir)
  scores <- ssgsea_list$scores
  exp_mat <- ssgsea_list$exp_mat_used
  group_map <- ssgsea_list$group
  gene_means <- rowMeans(exp_mat)
  gene_id <- names(sort(gene_means, decreasing = TRUE))[1]
  cor_vals <- apply(scores, 1, function(x) abs(suppressWarnings(stats::cor(as.numeric(exp_mat[gene_id, ]), as.numeric(x), method = "spearman"))))
  cell_type <- names(sort(cor_vals, decreasing = TRUE))[1]
  label <- ssgsea_list$cell_anno$cell_type_label[match(cell_type, ssgsea_list$cell_anno$cell_type)]
  if (is.na(label) || label == "") label <- cell_type
  plot_df <- data.frame(sample = colnames(exp_mat), gene_expr = as.numeric(exp_mat[gene_id, ]), immune_score = as.numeric(scores[cell_type, ]), group = unname(group_map[colnames(exp_mat)]))
  p <- ggplot2::ggplot(plot_df, ggplot2::aes(x = gene_expr, y = immune_score, color = group)) +
    ggplot2::geom_point(alpha = 0.7, size = 2) + ggplot2::geom_smooth(method = "lm", se = TRUE, linewidth = 0.8) +
    ggplot2::theme_bw(base_size = 11) + ggplot2::labs(x = gene_id, y = label, color = NULL, title = paste(gene_id, "vs", label))
  file_tag <- paste0("gene_immune_correlation_scatter_", sanitize_filename(gene_id), "_", sanitize_filename(cell_type), ".pdf")
  ggplot2::ggsave(file.path(plot_dir, file_tag), p, width = 7, height = 6, units = "in")
  list(gene = gene_id, cell_type = cell_type, file = file_tag)
}
