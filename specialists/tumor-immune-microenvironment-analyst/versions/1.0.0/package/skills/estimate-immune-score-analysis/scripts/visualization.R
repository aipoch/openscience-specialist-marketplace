#!/usr/bin/env Rscript

prepare_score_plot_data <- function(score_df, group_df, sample_column, group_column) {
  if (!sample_column %in% colnames(group_df)) {
    stop_skill("SKILL_MISSING_COLUMNS", sprintf("Group file is missing sample column: %s", sample_column))
  }
  if (!group_column %in% colnames(group_df)) {
    stop_skill("SKILL_MISSING_COLUMNS", sprintf("Group file is missing group column: %s", group_column))
  }

  group_info <- data.frame(
    sample = as.character(group_df[[sample_column]]),
    group = as.character(group_df[[group_column]]),
    stringsAsFactors = FALSE
  )
  group_info <- group_info[!is.na(group_info$sample) & !is.na(group_info$group), , drop = FALSE]
  if (nrow(group_info) == 0) {
    stop_skill("SKILL_EMPTY_DATA", "The group file does not contain any valid sample-group rows.")
  }

  merged <- merge(score_df, group_info, by = "sample")
  if (nrow(merged) == 0) {
    stop_skill("SKILL_SAMPLE_MISMATCH", "No sample names overlapped between the ESTIMATE score table and the group file.")
  }
  if (length(unique(merged$group)) < 2) {
    stop_skill("SKILL_INVALID_PARAMETER", "The group file must contain at least two matched group levels for boxplot comparison.")
  }

  score_columns <- intersect(c("StromalScore", "ImmuneScore", "ESTIMATEScore"), colnames(merged))
  long_data <- tidyr::pivot_longer(
    merged,
    cols = dplyr::all_of(score_columns),
    names_to = "category",
    values_to = "value"
  )

  list(
    long_data = long_data,
    group_info = group_info,
    score_columns = score_columns,
    merged = merged
  )
}

create_estimate_heatmap <- function(score_df, heatmap_file, group_df = NULL, sample_column = "sample", group_column = "group") {
  score_columns <- intersect(c("StromalScore", "ImmuneScore", "ESTIMATEScore", "TumorPurity"), colnames(score_df))
  heatmap_matrix <- t(as.matrix(score_df[, score_columns, drop = FALSE]))
  colnames(heatmap_matrix) <- score_df$sample

  annotation_col <- NULL
  annotation_colors <- NULL
  if (!is.null(group_df)) {
    if (!sample_column %in% colnames(group_df) || !group_column %in% colnames(group_df)) {
      stop_skill("SKILL_MISSING_COLUMNS", "The group file is missing the sample or group column required for heatmap annotation.")
    }
    group_info <- data.frame(
      sample = as.character(group_df[[sample_column]]),
      group = as.character(group_df[[group_column]]),
      stringsAsFactors = FALSE
    )
    group_lookup <- stats::setNames(group_info$group, group_info$sample)
    group_values <- unname(group_lookup[colnames(heatmap_matrix)])
    group_values[is.na(group_values)] <- "Unassigned"
    if (length(unique(group_values)) > 0) {
      annotation_col <- data.frame(group = group_values, row.names = colnames(heatmap_matrix))
      palette_colors <- c("#E64B35", "#4DBBD5", "#00A087", "#3C5488", "#F39B7F")
      group_levels <- unique(annotation_col$group)
      annotation_colors <- list(group = stats::setNames(colorRampPalette(palette_colors)(length(group_levels)), group_levels))
      order_idx <- order(annotation_col$group)
      heatmap_matrix <- heatmap_matrix[, order_idx, drop = FALSE]
      annotation_col <- annotation_col[order_idx, , drop = FALSE]
    }
  }

  grDevices::pdf(heatmap_file, width = 6, height = 4.5)
  device_id <- grDevices::dev.cur()
  on.exit({
    open_devices <- grDevices::dev.list()
    if (!is.null(open_devices) && device_id %in% open_devices) {
      grDevices::dev.off(which = device_id)
    }
  }, add = TRUE)
  pheatmap::pheatmap(
    mat = heatmap_matrix,
    scale = "row",
    show_colnames = FALSE,
    cluster_cols = is.null(annotation_col),
    cluster_rows = TRUE,
    annotation_col = annotation_col,
    annotation_colors = annotation_colors,
    fontsize = 8,
    color = colorRampPalette(c("#4DBBD5", "white", "#E64B35"))(50)
  )
  heatmap_file
}

run_group_tests <- function(long_data) {
  split_data <- split(long_data, long_data$category)
  results <- lapply(split_data, function(df) {
    groups <- unique(df$group)
    if (length(groups) < 2) {
      return(data.frame(category = unique(df$category), p.value = NA_real_, up_group = NA_character_))
    }
    if (length(groups) == 2) {
      test_result <- wilcox.test(value ~ group, data = df)
      medians <- tapply(df$value, df$group, median, na.rm = TRUE)
      up_group <- names(which.max(medians))[1]
    } else {
      test_result <- kruskal.test(value ~ group, data = df)
      medians <- tapply(df$value, df$group, median, na.rm = TRUE)
      up_group <- names(which.max(medians))[1]
    }
    data.frame(category = unique(df$category), p.value = test_result$p.value, up_group = up_group)
  })
  do.call(rbind, results)
}

save_group_statistics <- function(test_results, output_file) {
  write.csv(test_results, file = output_file, row.names = FALSE)
  output_file
}

create_estimate_boxplot <- function(long_data, plot_file) {
  palette_colors <- c("#E64B35", "#4DBBD5", "#00A087", "#3C5488", "#F39B7F")
  group_levels <- unique(long_data$group)
  fill_values <- stats::setNames(colorRampPalette(palette_colors)(length(group_levels)), group_levels)

  p <- ggplot2::ggplot(long_data, ggplot2::aes(category, value, fill = group)) +
    ggplot2::geom_boxplot(outlier.shape = 21, outlier.color = NA, outlier.size = 0.8, alpha = 0.6) +
    ggplot2::labs(x = "", y = "TME score") +
    ggplot2::scale_fill_manual(values = fill_values) +
    ggpubr::stat_compare_means(
      ggplot2::aes(group = group, label = ..p.signif..),
      bracket.size = 0.6,
      size = 3,
      label.y = max(long_data$value, na.rm = TRUE) - 0.02,
      hide.ns = TRUE,
      method = ifelse(length(unique(long_data$group)) == 2, "wilcox.test", "kruskal.test")
    ) +
    ggplot2::theme(
      plot.title = ggplot2::element_blank(),
      plot.subtitle = ggplot2::element_blank(),
      plot.background = ggplot2::element_blank(),
      plot.margin = ggplot2::margin(t = 2, r = 2, b = 2, l = 2, unit = "pt"),
      panel.border = ggplot2::element_rect(linewidth = 0.5, fill = NA, colour = "black"),
      panel.background = ggplot2::element_blank(),
      panel.grid = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_text(angle = 45, vjust = 1, hjust = 1, size = 7, colour = "black"),
      axis.title = ggplot2::element_text(size = 7, colour = "black"),
      axis.text.y = ggplot2::element_text(size = 6, colour = "black"),
      legend.background = ggplot2::element_blank(),
      legend.key = ggplot2::element_blank(),
      legend.title = ggplot2::element_text(size = 7),
      legend.text = ggplot2::element_text(size = 7),
      legend.position = "top"
    )

  ggplot2::ggsave(filename = plot_file, plot = p, width = 6, height = 4, units = "cm", scale = 1.5)
  plot_file
}
