#!/usr/bin/env Rscript

prepare_heatmap_palette <- function(mat, colors_string) {
  colors <- trimws(strsplit(colors_string, ",", fixed = TRUE)[[1]])
  colors <- colors[nzchar(colors)]
  if (length(colors) < 2) stop_skill("SKILL_INVALID_PARAMETER", "--colors must contain at least two comma-separated colors.")
  max_abs <- max(abs(mat), na.rm = TRUE)
  if (!is.finite(max_abs) || max_abs == 0) max_abs <- 1
  list(hm_colors = grDevices::colorRampPalette(colors)(100), breaks = seq(-max_abs, max_abs, length.out = 101))
}

trim_label <- function(label, max_chars) if (nchar(label) <= max_chars) label else paste0(substr(label, 1, max_chars - 3), "...")

apply_heatmap_labels <- function(mat, diff_df, append_stats, label_max_chars) {
  labels <- rownames(mat)
  if (append_stats && !is.null(diff_df)) {
    diff_map <- diff_df[match(labels, diff_df$geneset), , drop = FALSE]
    labels <- ifelse(is.na(diff_map$adj.P.Val), labels, sprintf("%s | logFC=%.2f | FDR=%.3g", labels, diff_map$logFC, diff_map$adj.P.Val))
  }
  rownames(mat) <- vapply(labels, trim_label, character(1), max_chars = label_max_chars)
  mat
}

finalize_heatmap_pdf <- function(heatmap_obj) {
  grid::grid.newpage()
  grid::grid.draw(heatmap_obj$gtable)
}
