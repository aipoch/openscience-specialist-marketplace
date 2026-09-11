get_batch_colors <- function(meta) {
  batch_levels <- unique(as.character(meta$batch))
  palette_values <- grDevices::hcl.colors(length(batch_levels), palette = "Set 2")
  setNames(palette_values, batch_levels)
}

is_ellipse_eligible <- function(batch_plot_data) {
  # stat_ellipse() emits noisy warnings for valid groups with only three points,
  # so require at least four samples before attempting an ellipse fit.
  if (nrow(batch_plot_data) < 4)
    return(FALSE)

  coords <- as.matrix(batch_plot_data[, c("PC1", "PC2"), drop = FALSE])
  if (anyNA(coords) || any(!is.finite(coords)))
    return(FALSE)

  variances <- apply(coords, 2, stats::var)
  if (any(!is.finite(variances)) || any(variances <= 0))
    return(FALSE)

  eigenvalues <- tryCatch(
    eigen(stats::cov(coords), symmetric = TRUE, only.values = TRUE)$values,
    error = function(e) rep(NA_real_, 2)
  )
  all(is.finite(eigenvalues)) && min(eigenvalues) > sqrt(.Machine$double.eps)
}

get_ellipse_batches <- function(plot_data) {
  batch_groups <- split(plot_data, as.character(plot_data$batch))
  eligible <- vapply(batch_groups, is_ellipse_eligible, logical(1))
  names(eligible[eligible])
}

build_pca_plot_data <- function(expr_mat, meta) {
  pca_res <- stats::prcomp(t(expr_mat), center = TRUE, scale. = FALSE)
  variance <- (pca_res$sdev^2) / sum(pca_res$sdev^2)
  plot_data <- data.frame(
    PC1 = pca_res$x[, 1],
    PC2 = pca_res$x[, 2],
    batch = meta$batch,
    check.names = FALSE
  )
  list(plot_data = plot_data, variance = variance)
}

add_batch_ellipses <- function(p, plot_data, colors) {
  ellipse_batches <- get_ellipse_batches(plot_data)
  ellipse_data <- plot_data[plot_data$batch %in% ellipse_batches, , drop = FALSE]

  if (nrow(ellipse_data) == 0)
    return(p)

  ellipse_colors <- colors[ellipse_batches]

  p +
    ggplot2::stat_ellipse(
      data = ellipse_data,
      ggplot2::aes(group = batch, fill = batch),
      geom = "polygon",
      type = "norm",
      level = 0.95,
      alpha = 0.15,
      color = NA,
      show.legend = FALSE
    ) +
    ggplot2::stat_ellipse(
      data = ellipse_data,
      ggplot2::aes(group = batch),
      type = "norm",
      level = 0.95,
      linewidth = 0.7,
      show.legend = FALSE
    ) +
    ggplot2::scale_fill_manual(values = ellipse_colors)
}

build_pca_plot <- function(plot_data, variance, colors, title_text) {
  p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = PC1, y = PC2, color = batch)) +
    ggplot2::geom_point(size = 2.2, alpha = 0.9) +
    ggplot2::scale_color_manual(values = colors) +
    ggplot2::labs(
      x = sprintf("PC1 (%.1f%%)", variance[1] * 100),
      y = sprintf("PC2 (%.1f%%)", variance[2] * 100),
      title = title_text,
      color = "Batch"
    ) +
    ggplot2::theme_bw() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(hjust = 0.5),
      legend.title = ggplot2::element_text(face = "bold")
    )

  add_batch_ellipses(p, plot_data, colors)
}

plot_boxplot_pdf <- function(expr_mat, meta, output_file, title_text) {
  colors <- get_batch_colors(meta)
  sample_colors <- unname(colors[as.character(meta$batch)])

  grDevices::pdf(output_file, width = 10, height = 7)
  on.exit(grDevices::dev.off(), add = TRUE)
  graphics::par(mar = c(8, 4, 3, 1))
  graphics::boxplot(
    expr_mat,
    boxwex = 0.6,
    notch = FALSE,
    outline = FALSE,
    las = 2,
    col = sample_colors,
    border = sample_colors,
    main = title_text,
    ylab = "Expression"
  )
  graphics::legend(
    "topleft",
    legend = names(colors),
    fill = unname(colors),
    bty = "n",
    title = "Batch"
  )
}

plot_pca_pdf <- function(expr_mat, meta, output_file, title_text) {
  colors <- get_batch_colors(meta)
  pca_data <- build_pca_plot_data(expr_mat, meta)
  p <- build_pca_plot(pca_data$plot_data, pca_data$variance, colors, title_text)

  grDevices::pdf(output_file, width = 8, height = 7)
  on.exit(grDevices::dev.off(), add = TRUE)
  print(p)
}

plot_clustering_pdf <- function(expr_mat, meta, output_file, title_text) {
  hc <- stats::hclust(stats::dist(t(expr_mat)), method = "complete")
  labels <- sprintf("%s|%s", meta$sample_id, meta$batch)

  grDevices::pdf(output_file, width = 11, height = 7)
  on.exit(grDevices::dev.off(), add = TRUE)
  graphics::par(mar = c(8, 4, 3, 1))
  graphics::plot(hc, labels = labels, main = title_text, xlab = "", sub = "")
}
