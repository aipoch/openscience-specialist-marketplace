#!/usr/bin/env Rscript

scale_text_cex <- function(g, cex = 1) {
  if (is.null(g)) {
    return(g)
  }
  if (inherits(g, "text")) {
    if (is.null(g$gp)) {
      g$gp <- grid::gpar()
    }
    g$gp$cex <- (g$gp$cex %||% 1) * cex
    return(g)
  }
  if (!is.null(g$children) && length(g$children) > 0) {
    for (i in seq_along(g$children)) {
      g$children[[i]] <- scale_text_cex(g$children[[i]], cex)
    }
  }
  if (!is.null(g$grobs) && length(g$grobs) > 0) {
    for (i in seq_along(g$grobs)) {
      g$grobs[[i]] <- scale_text_cex(g$grobs[[i]], cex)
    }
  }
  g
}

sanitize_plot_filename <- function(plot_file) {
  plot_file <- trimws(plot_file %||% "")
  normalized <- gsub("\\\\", "/", plot_file)
  if (!nzchar(normalized)) {
    stop_skill("SKILL_INVALID_PARAMETER", "--plot_file must be a non-empty file name.")
  }
  if (grepl("^(/|[A-Za-z]:)", normalized) || grepl("(^|/)\\.\\.(/|$)", normalized) || grepl("/", normalized)) {
    stop_skill(
      "SKILL_INVALID_PARAMETER",
      "--plot_file must be a file name only and cannot contain path separators or parent directory segments."
    )
  }
  basename(normalized)
}

apply_heatmap_labels <- function(mat, diff_df, append_stats, label_max_chars) {
  labels <- gsub("^KEGG_", "", rownames(mat))
  labels <- gsub("_", " ", labels)
  if (isTRUE(append_stats) && !is.null(diff_df)) {
    row_map <- match(rownames(mat), diff_df$geneset)
    labels <- paste0(
      labels,
      " (FDR=", signif(diff_df$adj.P.Val[row_map], 2),
      ", logFC=", signif(diff_df$logFC[row_map], 2), ")"
    )
  }
  if (!is.null(label_max_chars) && label_max_chars > 10) {
    labels <- ifelse(nchar(labels) > label_max_chars,
                     paste0(substr(labels, 1, label_max_chars - 3), "..."),
                     labels)
  }
  rownames(mat) <- labels
  mat
}

prepare_heatmap_palette <- function(mat, colors) {
  palette_values <- trimws(strsplit(colors, ",", fixed = TRUE)[[1]])
  if (length(palette_values) < 2) {
    stop_skill("SKILL_INVALID_PARAMETER", "--colors must contain at least two comma-separated colors.")
  }
  lim <- max(abs(mat), na.rm = TRUE)
  if (!is.finite(lim) || lim == 0) {
    lim <- 1
  }
  list(
    hm_colors = grDevices::colorRampPalette(palette_values)(100),
    breaks = seq(-lim, lim, length.out = 101)
  )
}

finalize_heatmap_pdf <- function(output_file, heatmap_obj, legend_cex) {
  legend_idx <- which(heatmap_obj$gtable$layout$name == "legend")
  if (length(legend_idx) == 1 && !is.na(legend_cex) && legend_cex != 1) {
    heatmap_obj$gtable$grobs[[legend_idx]] <- scale_text_cex(
      heatmap_obj$gtable$grobs[[legend_idx]],
      cex = legend_cex
    )
  }
  grid::grid.newpage()
  grid::grid.draw(heatmap_obj$gtable)
}
