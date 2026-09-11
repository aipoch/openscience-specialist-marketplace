enrichGO_analysis <- function(genes_id, sp, pvalue_cutoff, qvalue_cutoff, pAdjustMethod) {
  log_info("GO enrichment analysis")
  tryCatch({
    enrichGO(gene = genes_id$ENTREZID, OrgDb = sp, keyType = 'ENTREZID', ont = "ALL",
             pAdjustMethod = pAdjustMethod, pvalueCutoff = pvalue_cutoff,
             qvalueCutoff = qvalue_cutoff, readable = TRUE)
  }, error = function(e) {
    skill_stop("SKILL_ANALYSIS_FAILED", paste("GO enrichment failed", e$message))
  })
}

enrichKEGG_analysis <- function(genes_id, kegg_org, pvalue_cutoff, qvalue_cutoff, pAdjustMethod) {
  log_info("KEGG enrichment analysis")
  tryCatch({
    enrichKEGG(gene = genes_id$ENTREZID, organism = kegg_org, keyType = 'kegg',
               pAdjustMethod = pAdjustMethod, pvalueCutoff = pvalue_cutoff,
               qvalueCutoff = qvalue_cutoff, use_internal_data = TRUE)
  }, error = function(e) {
    skill_stop("SKILL_ANALYSIS_FAILED", paste("KEGG enrichment failed", e$message))
  })
}

load_rda_object <- function(path, object_name, label) {
  validate_existing_file(path, label)
  e <- new.env()
  tryCatch(load(path, envir = e), error = function(e) skill_stop("SKILL_FILE_FORMAT_ERROR", paste("Failed to read", label, path, e$message)))

  if (exists(object_name, envir = e)) {
    return(get(object_name, envir = e))
  } else if (exists("obj", envir = e)) {
    log_warn(sprintf("Found legacy 'obj' instead of '%s' in %s", object_name, path))
    return(get("obj", envir = e))
  } else {
    skill_stop("SKILL_MISSING_COLUMNS", sprintf("%s file does not contain %s object (or fallback 'obj')", label, object_name))
  }
}

prepare_plot_df <- function(df, label) {
  required_cols <- c("Description", "p.adjust")
  missing_cols <- setdiff(required_cols, colnames(df))
  if (length(missing_cols) > 0) {
    skill_stop("SKILL_MISSING_COLUMNS", sprintf("%s results missing required columns: %s", label, paste(missing_cols, collapse = ", ")))
  }

  df <- df %>%
    filter(!is.na(Description), !is.na(p.adjust), is.finite(p.adjust), p.adjust > 0) %>%
    mutate(LOG10pvalue = -log10(p.adjust))

  if (nrow(df) == 0) {
    skill_warn("SKILL_EMPTY_DATA", paste(label, "results are empty after filtering"))
    return(NULL)
  }

  df
}

parse_margin <- function(plot_margin) {
  margin_values <- as.numeric(strsplit(plot_margin, ",")[[1]])
  if (length(margin_values) != 4 || any(is.na(margin_values))) {
    skill_stop("SKILL_INVALID_PARAMETER", paste("Invalid --plot_margin value:", plot_margin, "Expected four numeric values separated by commas"))
  }
  margin_values
}

get_axis_labels <- function(rotate, xlab, ylab) {
  x_var_label <- "GO Term / KEGG Pathway"
  y_var_label <- "-log10(Adjusted p-value)"

  if (rotate) {
    if (!is.null(xlab)) y_var_label <- xlab
    if (!is.null(ylab)) x_var_label <- ylab
  } else {
    if (!is.null(xlab)) x_var_label <- xlab
    if (!is.null(ylab)) y_var_label <- ylab
  }

  list(x = x_var_label, y = y_var_label)
}

save_plot_file <- function(filename, p, format, width, height, dpi) {
  if (format == "pdf") {
    ggsave(filename, p, width = width / 2.54, height = height / 2.54)
  } else {
    ggsave(filename, p, width = width / 2.54, height = height / 2.54, dpi = dpi)
  }
}

create_dot_chart <- function(plot_df, colors, title, xlab, ylab, dot_size, shape,
                             rotate, sorting, label_width, title_size,
                             axis_title_size, axis_text_size, legend_title_size,
                             legend_text_size, legend_position, plot_margin,
                             axis_line_size, axis_ticks_size, show_grid) {
  color_palette <- trimws(strsplit(colors, ",")[[1]])
  category_levels <- unique(plot_df$Category)
  default_order <- c("GO:BP", "GO:CC", "GO:MF", "GO", "KEGG")

  if (length(color_palette) < length(category_levels)) {
    skill_stop("SKILL_INVALID_PARAMETER", paste("Not enough colors for categories:", paste(category_levels, collapse = ", ")))
  }

  mapped_colors <- setNames(color_palette[seq_along(category_levels)], category_levels)
  known_levels <- intersect(default_order, category_levels)
  if (length(known_levels) > 0) {
    mapped_colors[known_levels] <- color_palette[seq_along(known_levels)]
  }

  margin_values <- parse_margin(plot_margin)

  base_theme <- theme_pubr() +
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold", size = title_size),
      plot.background = element_blank(),
      plot.margin = margin(
        t = margin_values[1], r = margin_values[2],
        b = margin_values[3], l = margin_values[4], unit = "pt"
      ),
      axis.ticks = element_line(linewidth = axis_ticks_size),
      axis.line = element_line(linewidth = axis_line_size),
      panel.background = element_blank(),
      axis.text.y = element_text(size = axis_text_size, colour = "black"),
      axis.text.x = element_text(size = axis_text_size, colour = "black"),
      axis.title.x = element_text(size = axis_title_size, colour = "black"),
      axis.title.y = element_text(size = axis_title_size, colour = "black"),
      legend.title = element_text(size = legend_title_size),
      legend.text = element_text(size = legend_text_size, colour = "black"),
      legend.background = element_blank(),
      legend.key = element_blank(),
      legend.position = legend_position,
      legend.margin = margin(t = 0, r = 0, b = 0, l = 0, unit = "pt"),
      legend.box.spacing = unit(5, "pt")
    )

  if (!show_grid) {
    base_theme <- base_theme + theme(panel.grid = element_blank())
  }

  p <- ggdotchart(
    plot_df,
    x = "Description",
    y = "LOG10pvalue",
    color = "Category",
    palette = unname(mapped_colors),
    sorting = sorting,
    add = "segments",
    xlab = xlab,
    ylab = ylab,
    rotate = rotate,
    dot.size = dot_size,
    shape = shape,
    ggtheme = base_theme
  ) +
    scale_x_discrete(labels = function(x) str_wrap(x, width = label_width)) +
    guides(color = guide_legend(title = "Source"))

  if (title != "") {
    p <- p + labs(title = title)
  }

  p
}