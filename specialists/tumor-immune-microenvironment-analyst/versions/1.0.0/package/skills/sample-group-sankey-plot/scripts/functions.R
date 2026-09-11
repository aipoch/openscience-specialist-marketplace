parse_selected_columns <- function(columns_arg, available_columns) {
  if (is.null(columns_arg) || !nzchar(trimws(columns_arg))) {
    return(available_columns)
  }

  selected_columns <- trimws(strsplit(columns_arg, ",", fixed = TRUE)[[1]])
  selected_columns <- selected_columns[selected_columns != ""]

  if (length(selected_columns) != length(unique(selected_columns))) {
    stop_skill("SKILL_INVALID_PARAMETER", "--columns contains duplicate column names")
  }

  selected_columns
}

validate_annotation_data <- function(data, selected_columns) {
  if (!is.data.frame(data) || nrow(data) == 0) {
    stop_skill("SKILL_EMPTY_DATA", "Input table has no data rows")
  }

  if (length(colnames(data)) < 2) {
    stop_skill("SKILL_MISSING_COLUMNS", "At least 2 columns are required to build a Sankey plot")
  }

  if (length(selected_columns) < 2) {
    stop_skill("SKILL_INVALID_PARAMETER", "At least 2 columns must be selected")
  }

  missing_columns <- setdiff(selected_columns, colnames(data))
  if (length(missing_columns) > 0) {
    stop_skill(
      "SKILL_MISSING_COLUMNS",
      paste(missing_columns, collapse = ", ")
    )
  }

  selected_data <- data[, selected_columns, drop = FALSE]
  colnames(selected_data) <- selected_columns
  selected_data
}

normalize_stage_values <- function(data, missing_label) {
  normalized <- data
  for (column_name in colnames(normalized)) {
    values <- as.character(normalized[[column_name]])
    values[is.na(values) | trimws(values) == ""] <- missing_label
    normalized[[column_name]] <- values
  }
  normalized
}

prepare_sankey_data <- function(selected_data, missing_label) {
  normalized <- normalize_stage_values(selected_data, missing_label)
  normalized$sample_id <- sprintf("sample_%s", seq_len(nrow(normalized)))

  axes <- seq_len(ncol(selected_data))
  lodes_df <- ggalluvial::to_lodes_form(
    normalized[, c(colnames(selected_data), "sample_id")],
    axes = axes,
    id = "sample_id"
  )

  list(
    selected_data = normalized[, colnames(selected_data), drop = FALSE],
    lodes_df = lodes_df
  )
}

build_sankey_plot <- function(lodes_df, axis_labels, alpha, label_size, title) {
  plot_obj <- ggplot2::ggplot(
    data = lodes_df,
    ggplot2::aes(
      x = x,
      fill = stratum,
      stratum = stratum,
      alluvium = sample_id
    )
  ) +
    ggalluvial::geom_flow(
      width = 0.3,
      curve_type = "sine",
      alpha = alpha,
      color = "white",
      linewidth = 0.1
    ) +
    ggalluvial::geom_stratum(width = 0.28) +
    ggalluvial::stat_stratum(
      ggplot2::aes(label = ggplot2::after_stat(stratum)),
      geom = "text",
      size = label_size,
      color = "black"
    ) +
    ggplot2::scale_x_discrete(limits = axis_labels, expand = c(0.05, 0.05)) +
    ggplot2::theme_void() +
    ggplot2::theme(legend.position = "none")

  if (nzchar(title)) {
    plot_obj <- plot_obj + ggplot2::ggtitle(title)
  }

  plot_obj
}

write_outputs <- function(selected_data, lodes_df, plot_obj, dirs, output_prefix, width, height) {
  selected_output <- file.path(dirs$table, "selected_annotations.csv")
  lodes_output <- file.path(dirs$table, "sankey_lodes.csv")
  plot_output <- file.path(dirs$plot, sprintf("%s.pdf", output_prefix))

  utils::write.csv(selected_data, selected_output, row.names = FALSE)
  utils::write.csv(lodes_df, lodes_output, row.names = FALSE)
  ggplot2::ggsave(plot_output, plot = plot_obj, width = width, height = height, units = "in")

  list(
    selected_output = selected_output,
    lodes_output = lodes_output,
    plot_output = plot_output
  )
}
