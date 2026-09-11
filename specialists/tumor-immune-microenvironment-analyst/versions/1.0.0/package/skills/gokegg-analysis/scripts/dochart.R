#!/usr/bin/env Rscript

load_go_data <- function(path, top_n) {
  go_list <- load_rda_object(path, "GO_list", "GO")
  go_df <- go_list$ego_df
  if (is.null(go_df) || nrow(go_df) == 0) {
    return(NULL)
  }

  go_df <- prepare_plot_df(go_df, "GO")
  if (is.null(go_df)) {
    return(NULL)
  }

  if ("ONTOLOGY" %in% colnames(go_df)) {
    go_df <- go_df %>%
      group_by(ONTOLOGY) %>%
      slice_max(n = top_n, order_by = LOG10pvalue, with_ties = FALSE) %>%
      ungroup() %>%
      mutate(Category = paste0("GO:", ONTOLOGY))
  } else {
    go_df <- go_df %>%
      slice_max(n = top_n, order_by = LOG10pvalue, with_ties = FALSE) %>%
      mutate(Category = "GO")
  }

  go_df %>%
    transmute(
      Source = "GO",
      Category = Category,
      Description = Description,
      p.adjust = p.adjust,
      LOG10pvalue = LOG10pvalue
    )
}

load_kegg_data <- function(path, top_n) {
  kegg_list <- load_rda_object(path, "KEGG_list", "KEGG")
  kegg_df <- kegg_list$kk_df
  if (is.null(kegg_df) || nrow(kegg_df) == 0) {
    return(NULL)
  }

  kegg_df <- prepare_plot_df(kegg_df, "KEGG")
  if (is.null(kegg_df)) {
    return(NULL)
  }

  kegg_df %>%
    slice_max(n = top_n, order_by = LOG10pvalue, with_ties = FALSE) %>%
    transmute(
      Source = "KEGG",
      Category = "KEGG",
      Description = Description,
      p.adjust = p.adjust,
      LOG10pvalue = LOG10pvalue
    )
}

validate_input_paths <- function(go_input, kegg_input) {
  if (is.null(go_input) && is.null(kegg_input)) {
    skill_stop("SKILL_INVALID_PARAMETER", "At least one of --go_input or --kegg_input must be provided")
  }
  if (!is.null(go_input)) validate_existing_file(go_input, "GO input")
  if (!is.null(kegg_input)) validate_existing_file(kegg_input, "KEGG input")
}

generate_dot_chart <- function(opt) {
  if (missing(opt) || is.null(opt)) {
    skill_stop("SKILL_INVALID_PARAMETER", "Plotting options are required")
  }
  check_pkgs(c('ggplot2', 'dplyr', 'stringr', 'ggpubr'))
  validate_input_paths(opt$go_input, opt$kegg_input)
  log_info("Generating combined GO/KEGG dot chart...")

  plot_list <- list()

  if (!is.null(opt$go_input)) {
    log_info(paste("Loading GO results from:", opt$go_input))
    go_part <- load_go_data(opt$go_input, opt$go_top_n)
    if (!is.null(go_part)) plot_list[[length(plot_list) + 1]] <- go_part
  }

  if (!is.null(opt$kegg_input)) {
    log_info(paste("Loading KEGG results from:", opt$kegg_input))
    kegg_part <- load_kegg_data(opt$kegg_input, opt$kegg_top_n)
    if (!is.null(kegg_part)) plot_list[[length(plot_list) + 1]] <- kegg_part
  }

  if (length(plot_list) == 0) {
    skill_stop("SKILL_EMPTY_DATA", "No GO or KEGG enrichment results to visualize")
  }

  plot_df <- bind_rows(plot_list)

  if (!dir.exists(opt$outdir)) {
    dir.create(opt$outdir, recursive = TRUE, showWarnings = FALSE)
    log_info(paste("Created output directory:", opt$outdir))
  }

  plot_bundle <- list(
    plot_df = plot_df,
    parameters = as.list(opt)
  )
  save_analysis_outputs(
    obj = plot_bundle,
    csv_df = plot_df,
    prefix = "gokegg_dot_chart",
    output_dir = opt$outdir,
    csv_suffix = "_data.csv",
    rda_suffix = "_data.rda"
  )

  axis_labels <- get_axis_labels(opt$rotate, opt$xlab, opt$ylab)
  p <- create_dot_chart(
    plot_df = plot_df,
    colors = opt$colors,
    title = opt$title,
    xlab = axis_labels$x,
    ylab = axis_labels$y,
    dot_size = opt$dot_size,
    shape = opt$shape,
    rotate = opt$rotate,
    sorting = opt$sorting,
    label_width = opt$label_width,
    title_size = opt$title_size,
    axis_title_size = opt$axis_title_size,
    axis_text_size = opt$axis_text_size,
    legend_title_size = opt$legend_title_size,
    legend_text_size = opt$legend_text_size,
    legend_position = opt$legend_position,
    plot_margin = opt$plot_margin,
    axis_line_size = opt$axis_line_size,
    axis_ticks_size = opt$axis_ticks_size,
    show_grid = opt$show_grid
  )

  filename <- file.path(opt$outdir, paste0("gokegg_dot_chart.", opt$format))
  save_plot_file(filename, p, opt$format, opt$width, opt$height, opt$dpi)

  if (file.exists(filename)) {
    Sys.chmod(filename, mode = '0777')
  }

  log_info(paste("Saved combined dot chart to:", filename))
  log_info(paste("Saved combined plot data to:", file.path(opt$outdir, "gokegg_dot_chart_data.csv")))
  log_info(paste("Saved combined plot bundle to:", file.path(opt$outdir, "gokegg_dot_chart_data.rda")))
  if (opt$verbose) {
    log_info(paste("Total plotted items:", nrow(plot_df)))
    log_info(paste("Categories:", paste(unique(plot_df$Category), collapse = ", ")))
  }

  invisible(filename)
}
