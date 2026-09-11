build_roc_curves <- function(model, analysis_data, genes) {
  check_required_packages(c("pROC"))
  roc_list <- list()
  roc_list[["Full Model"]] <- pROC::roc(analysis_data$outcome, stats::predict(model, type = "response"), quiet = TRUE)
  for (gene in genes)
    roc_list[[gene]] <- pROC::roc(analysis_data$outcome, analysis_data[[gene]], quiet = TRUE)
  roc_list
}

build_auc_summary <- function(roc_list) {
  data.frame(
    model = names(roc_list),
    auc = vapply(roc_list, function(curve) as.numeric(pROC::auc(curve)), numeric(1)),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

render_roc_plot <- function(roc_list, plot_file, options) {
  validate_positive_number(options$plot_width, "--plot_width")
  validate_positive_number(options$plot_height, "--plot_height")
  validate_positive_number(options$line_width, "--line_width")
  validate_positive_number(options$base_cex, "--base_cex")
  validate_positive_number(options$legend_cex, "--legend_cex")
  dir.create(dirname(plot_file), recursive = TRUE, showWarnings = FALSE)

  line_colors <- parse_color_list(options$line_colors)
  if (length(roc_list) > length(line_colors))
    line_colors <- grDevices::colorRampPalette(line_colors)(length(roc_list))
  line_colors <- line_colors[seq_along(roc_list)]

  grDevices::pdf(plot_file, width = options$plot_width, height = options$plot_height, family = options$font_family)
  on.exit(grDevices::dev.off(), add = TRUE)
  graphics::par(mar = c(4, 4, 3, 2) + 0.1)
  for (idx in seq_along(roc_list)) {
    is_first <- idx == 1
    pROC::plot.roc(
      roc_list[[idx]],
      add = !is_first,
      col = line_colors[[idx]],
      lwd = options$line_width,
      legacy.axes = TRUE,
      identity = is_first && isTRUE(options$show_diagonal),
      identity.col = options$diagonal_color,
      identity.lty = options$diagonal_lty,
      main = if (is_first) options$plot_title else "",
      xlab = if (is_first) options$x_label else "",
      ylab = if (is_first) options$y_label else "",
      cex.axis = options$base_cex,
      cex.lab = options$base_cex,
      print.auc = FALSE
    )
  }
  legend_text <- vapply(seq_along(roc_list), function(idx) sprintf("%s (AUC: %.3f)", names(roc_list)[[idx]], as.numeric(pROC::auc(roc_list[[idx]]))), character(1))
  graphics::legend(options$legend_position, legend = legend_text, col = line_colors, lwd = options$line_width, lty = 1, bty = "n", cex = options$legend_cex)
  invisible(plot_file)
}
