parse_color_vector <- function(color_text) {
  colors <- trimws(strsplit(color_text, ",", fixed = TRUE)[[1]])
  colors[nzchar(colors)]
}

parse_border_fill <- function(fill_text) {
  if (is.null(fill_text)) {
    return(NA)
  }

  normalized <- toupper(trimws(fill_text))
  if (normalized == "NA") return(NA)
  if (normalized == "NULL") return(NULL)
  fill_text
}

save_rf_error_plot <- function(rf_model, options, save_path) {
  if (is.null(rf_model$err.rate)) {
    fail("SKILL_EMPTY_DATA", "Random forest model does not contain error-rate information.")
  }

  err_df <- as.data.frame(rf_model$err.rate)
  err_df$Trees <- seq_len(nrow(err_df))
  err_long <- tidyr::pivot_longer(err_df, cols = -Trees, names_to = "Type", values_to = "Error")
  line_colors <- parse_color_vector(options$rf_error_line_color)
  curve_types <- unique(err_long$Type)
  palette <- c("black", line_colors)

  if (length(palette) < length(curve_types)) {
    palette <- c(palette, grDevices::hcl.colors(length(curve_types) - length(palette), palette = "Dark 3"))
  }

  color_map <- stats::setNames(palette[seq_along(curve_types)], curve_types)
  linetype_map <- stats::setNames(rep(options$rf_error_line_type, length(curve_types)), curve_types)
  oob_index <- grep("OOB", curve_types, ignore.case = TRUE)
  if (length(oob_index) > 0) linetype_map[oob_index] <- options$rf_error_line_oob_type

  plot_obj <- ggplot2::ggplot(err_long, ggplot2::aes(x = Trees, y = Error, color = Type, linetype = Type)) +
    ggplot2::geom_line(linewidth = options$rf_error_line_size, alpha = options$rf_error_line_alpha) +
    ggplot2::labs(x = options$rf_error_xlab, y = options$rf_error_ylab) +
    ggplot2::theme_classic(base_size = options$rf_error_base_size) +
    ggplot2::theme(
      panel.border = ggplot2::element_rect(
        color = options$rf_error_border_color,
        fill = parse_border_fill(options$rf_error_border_fill),
        linewidth = options$rf_error_border_size
      ),
      panel.background = ggplot2::element_blank(),
      plot.background = ggplot2::element_blank(),
      legend.position = options$rf_error_legend_position
    ) +
    ggplot2::scale_color_manual(values = color_map) +
    ggplot2::scale_linetype_manual(values = linetype_map)

  ggplot2::ggsave(
    filename = save_path,
    plot = plot_obj,
    width = options$rf_error_width,
    height = options$rf_error_height
  )
}

save_rf_importance_plot <- function(rf_model, options, save_path) {
  if (is.null(rf_model$importance) || nrow(rf_model$importance) == 0) {
    fail("SKILL_EMPTY_DATA", "Random forest model does not contain variable-importance values.")
  }

  total_features <- nrow(rf_model$importance)
  top_n <- min(options$rf_importance_top_n, total_features)
  if (top_n < options$rf_importance_top_n) {
    log_warn(sprintf(
      "--rf_importance_top_n exceeded the number of available features. Using %d instead.",
      top_n
    ))
  }

  grDevices::pdf(save_path, width = options$rf_importance_width, height = options$rf_importance_height)
  on.exit(grDevices::dev.off(), add = TRUE)

  randomForest::varImpPlot(
    rf_model,
    sort = options$rf_importance_sort,
    n.var = top_n,
    color = options$rf_importance_label_color,
    lcolor = options$rf_importance_line_color,
    offset = options$rf_importance_theme_offset,
    xaxt = if (options$rf_importance_label_x_ann) "s" else "n",
    frame.plot = options$rf_importance_theme_border,
    cex = options$rf_importance_label_cex,
    pt.cex = options$rf_importance_point_cex,
    pch = options$rf_importance_point_shape,
    bg = options$rf_importance_point_fill,
    main = options$rf_importance_title,
    ann = options$rf_importance_title_x_ann
  )
}
