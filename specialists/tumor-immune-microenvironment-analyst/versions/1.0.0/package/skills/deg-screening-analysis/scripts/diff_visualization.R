build_volcano_plot_data <- function(dif, p_threshold = 0.05, logfc_threshold = 1, p_adjust = TRUE) {
  p_col <- if (isTRUE(p_adjust)) "P.adj" else "P.value"
  dif$p_value <- dif[[p_col]]
  dif$neg_log10_pval <- -log10(dif$p_value)
  dif$change <- ifelse(dif$logFC > logfc_threshold & dif$p_value < p_threshold, "Up-regulated",
                       ifelse(dif$logFC < -logfc_threshold & dif$p_value < p_threshold, "Down-regulated", "Not significant"))
  dif
}

read_heatmap_data <- function(file_path) {
  check_pkg("data.table")
  check_file_exists(file_path, "heatmap file")

  data <- data.table::fread(file_path, skip = 1, data.table = FALSE)
  validate_non_empty(data, "Heatmap table")
  rownames(data) <- data[[1]]
  data <- data[, -1, drop = FALSE]

  con <- file(file_path, "r")
  on.exit(close(con), add = TRUE)
  groups <- strsplit(readLines(con, n = 1), ",", fixed = TRUE)[[1]][-1]
  annotation_col <- data.frame(Group = groups, row.names = colnames(data))
  list(data = data, annotation_col = annotation_col, unique_groups = unique(groups))
}

validate_heatmap_payload <- function(data_list) {
  if (is.null(data_list$data) || nrow(data_list$data) < 2 || ncol(data_list$data) < 2) {
    skill_stop("SKILL_MISSING_COLUMNS", "Heatmap input must contain at least 2 genes and 2 samples")
  }
  if (nrow(data_list$annotation_col) != ncol(data_list$data)) {
    skill_stop("SKILL_MISSING_COLUMNS", "Heatmap annotation does not match sample columns")
  }
  invisible(TRUE)
}

process_heatmap_data <- function(data, transform_method = "none", scale_method = "row") {
  if (transform_method == "log2p1") data <- log2(data + 1)
  if (transform_method == "log2") data <- log2(data)
  if (transform_method == "log10") data <- log10(data)
  if (scale_method == "row") data <- t(scale(t(data)))
  if (scale_method == "column") data <- scale(data)
  if (scale_method == "row_trunc") { data <- t(scale(t(data))); data[data > 3] <- 3; data[data < -3] <- -3 }
  if (scale_method == "column_trunc") { data <- scale(data); data[data > 3] <- 3; data[data < -3] <- -3 }
  data
}

generate_volcano <- function(diff_input, output_dir, p_threshold = 0.05, logfc_threshold = 1, p_adjust = TRUE,
                             color_down = "#3B82F6", color_ns = "#B0B0B0", color_up = "#EF4444") {
  check_pkg("ggplot2")
  check_pkg("data.table")
  ensure_dir(output_dir)

  dif <- if (is.character(diff_input)) {
    check_file_exists(diff_input, "volcano input file")
    data.table::fread(diff_input, data.table = FALSE)
  } else {
    as.data.frame(diff_input)
  }

  required <- c("name", "logFC", "P.value", "P.adj")
  missing_cols <- setdiff(required, colnames(dif))
  if (length(missing_cols) > 0) {
    skill_stop("SKILL_MISSING_COLUMNS", paste("Volcano input missing columns:", paste(missing_cols, collapse = ", ")))
  }
  validate_non_empty(dif, "Volcano input")

  dif <- build_volcano_plot_data(dif, p_threshold = p_threshold, logfc_threshold = logfc_threshold, p_adjust = p_adjust)
  y_label <- if (isTRUE(p_adjust)) "-log10(adjusted p-value)" else "-log10(raw p-value)"

  p <- ggplot2::ggplot(dif, ggplot2::aes(logFC, neg_log10_pval, color = change)) +
    ggplot2::geom_point(alpha = 0.65, size = 1.5) +
    ggplot2::theme_bw() +
    ggplot2::labs(x = "log2(Fold Change)", y = y_label, color = NULL) +
    ggplot2::geom_hline(yintercept = -log10(p_threshold), linetype = 2, color = "#888888") +
    ggplot2::geom_vline(xintercept = c(-logfc_threshold, logfc_threshold), linetype = 2, color = "#888888") +
    ggplot2::scale_color_manual(values = c("Down-regulated" = color_down, "Not significant" = color_ns, "Up-regulated" = color_up)) +
    ggplot2::ggtitle("Volcano Plot") +
    ggplot2::theme(
      plot.title = ggplot2::element_text(hjust = 0.5, size = 16),
      panel.grid = ggplot2::element_blank(),
      legend.position = "top"
    )

  ggplot2::ggsave(file.path(output_dir, "volcano_plot.pdf"), p, width = 5, height = 5)
}

generate_heatmap <- function(heatmap_input, output_dir) {
  check_pkg("pheatmap")
  ensure_dir(output_dir)

  data_list <- if (is.character(heatmap_input) && length(heatmap_input) == 1) {
    read_heatmap_data(heatmap_input)
  } else {
    groups <- as.character(heatmap_input[1, -1])
    samples <- as.character(heatmap_input[2, -1])
    data <- as.data.frame(heatmap_input[-c(1, 2), , drop = FALSE], stringsAsFactors = FALSE)
    rownames(data) <- data[[1]]
    data <- data[, -1, drop = FALSE]
    colnames(data) <- samples
    data[] <- lapply(data, as.numeric)
    list(
      data = data,
      annotation_col = data.frame(Group = groups, row.names = samples),
      unique_groups = unique(groups)
    )
  }

  validate_heatmap_payload(data_list)

  data_processed <- process_heatmap_data(data_list$data)

  grDevices::pdf(file.path(output_dir, "heatmap.pdf"), width = 10, height = 9)
  pheatmap::pheatmap(
    data_processed,
    scale = "none",
    annotation_col = data_list$annotation_col,
    border_color = NA,
    show_colnames = TRUE,
    angle_col = 45
  )
  grDevices::dev.off()
}
