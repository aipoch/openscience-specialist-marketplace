#!/usr/bin/env Rscript

prepare_heatmap_inputs <- function(gsva_result, opt) {
  mat <- if (!is.null(gsva_result$gsva_scores_top)) {
    as.matrix(gsva_result$gsva_scores_top)
  } else {
    as.matrix(gsva_result$gsva_scores)
  }

  groups <- gsva_result$groups
  annotation_col <- NULL
  gaps_col <- NULL

  if (!is.null(groups)) {
    common_samples <- intersect(colnames(mat), names(groups))
    if (length(common_samples) == 0) {
      stop_skill("SKILL_SAMPLE_MISMATCH", "No overlapping samples between GSVA scores and group metadata.")
    }
    mat <- mat[, common_samples, drop = FALSE]
    groups <- groups[common_samples]
    ordered_samples <- c(
      names(groups)[groups == gsva_result$case],
      names(groups)[groups == gsva_result$control],
      setdiff(names(groups), c(
        names(groups)[groups == gsva_result$case],
        names(groups)[groups == gsva_result$control]
      ))
    )
    mat <- mat[, ordered_samples, drop = FALSE]
    groups <- groups[ordered_samples]
    annotation_col <- data.frame(Group = factor(groups), row.names = names(groups))
    gaps_col <- sum(groups == gsva_result$case)
  }

  if (!is.null(gsva_result$GSVA_diff)) {
    mat <- subset_heatmap_matrix(
      mat = mat,
      diff_df = gsva_result$GSVA_diff,
      top_mode = opt$top_mode,
      top_up = opt$top_up,
      top_down = opt$top_down,
      sort_by = opt$sort_by
    )
  }

  mat <- apply_heatmap_labels(mat, gsva_result$GSVA_diff, opt$append_stats, opt$label_max_chars)

  list(mat = mat, annotation_col = annotation_col, gaps_col = gaps_col)
}

generate_heatmap_plot <- function(output_dir, gsva_result, opt) {
  heatmap_inputs <- prepare_heatmap_inputs(gsva_result, opt)
  mat <- heatmap_inputs$mat
  annotation_col <- heatmap_inputs$annotation_col
  gaps_col <- heatmap_inputs$gaps_col

  palette_info <- prepare_heatmap_palette(mat, opt$colors)

  plot_dir <- file.path(output_dir, "plot")
  ensure_dir(plot_dir)
  output_file <- file.path(plot_dir, sanitize_plot_filename(opt$plot_file))

  grDevices::pdf(output_file, width = opt$width, height = opt$height)
  device_closed <- FALSE
  close_pdf_device <- function() {
    if (!device_closed && grDevices::dev.cur() > 1) {
      grDevices::dev.off()
      device_closed <<- TRUE
    }
  }
  on.exit(close_pdf_device(), add = TRUE)

  heatmap_obj <- pheatmap::pheatmap(
    mat,
    color = palette_info$hm_colors,
    breaks = palette_info$breaks,
    scale = opt$scale,
    cluster_rows = opt$cluster_rows,
    cluster_cols = opt$cluster_cols,
    show_rownames = opt$show_rownames,
    show_colnames = opt$show_colnames,
    fontsize = opt$fontsize,
    fontsize_row = opt$fontsize_row,
    fontsize_col = opt$fontsize_col,
    annotation_col = annotation_col,
    gaps_col = gaps_col,
    main = opt$plot_title,
    silent = TRUE
  )

  finalize_heatmap_pdf(output_file, heatmap_obj, opt$legend_cex)
  close_pdf_device()
  if (!file.exists(output_file)) {
    stop_skill("SKILL_FILE_NOT_FOUND", sprintf("Heatmap output was not created: %s", output_file))
  }

  output_file
}
