#!/usr/bin/env Rscript

validate_expression_matrix <- function(expr_df) {
  gene_column <- expr_df[[1]]
  sample_names <- colnames(expr_df)[-1]

  if (length(sample_names) == 0) {
    stop_skill("SKILL_EMPTY_DATA", "The expression matrix must contain at least one sample column.")
  }
  if (anyNA(gene_column) || any(trimws(gene_column) == "")) {
    stop_skill("SKILL_MISSING_COLUMNS", "The gene identifier column contains missing values.")
  }
  if (anyDuplicated(sample_names) > 0) {
    stop_skill("SKILL_INVALID_PARAMETER", "Sample column names must be unique.")
  }

  numeric_matrix <- suppressWarnings(as.matrix(data.frame(lapply(expr_df[-1], as.numeric), check.names = FALSE)))
  if (anyNA(numeric_matrix)) {
    stop_skill("SKILL_INVALID_PARAMETER", "All expression values must be numeric and non-missing.")
  }

  list(
    genes = nrow(expr_df),
    samples = length(sample_names),
    first_gene_column = colnames(expr_df)[1]
  )
}

run_estimate_pipeline <- function(prepared_input_file, estimate_input_gct, estimate_score_gct, gene_id_type, platform) {
  estimate::filterCommonGenes(
    input.f = prepared_input_file,
    output.f = estimate_input_gct,
    id = gene_id_type
  )

  if (!file.exists(estimate_input_gct)) {
    stop_skill("SKILL_EMPTY_DATA", "estimate_input.gct was not created by filterCommonGenes.")
  }

  estimate::estimateScore(
    input.ds = estimate_input_gct,
    output.ds = estimate_score_gct,
    platform = platform
  )

  if (!file.exists(estimate_score_gct)) {
    stop_skill("SKILL_EMPTY_DATA", "estimate_score.gct was not created by estimateScore.")
  }

  estimate_score_gct
}

build_output_items <- function(paths) {
  items <- list(
    list(
      path = paths$prepared_input_file,
      description = "Tab-delimited expression matrix formatted for ESTIMATE.",
      content = "First column renamed to the selected gene identifier type and remaining columns are samples."
    ),
    list(
      path = paths$estimate_input_gct,
      description = "Filtered ESTIMATE input GCT file.",
      content = "Expression matrix reduced to genes compatible with the ESTIMATE reference."
    ),
    list(
      path = paths$estimate_score_gct,
      description = "Raw ESTIMATE score output in GCT format.",
      content = "Contains StromalScore, ImmuneScore, ESTIMATEScore, and related score rows emitted by estimateScore."
    ),
    list(
      path = paths$score_table,
      description = "Sample-by-score summary table.",
      content = "Tab-delimited score table with one row per sample and one column per ESTIMATE score."
    ),
    list(
      path = paths$session_info_file,
      description = "R session and package version record.",
      content = "sessionInfo() output captured for reproducibility."
    ),
    list(
      path = paths$heatmap_file,
      description = "ESTIMATE score heatmap.",
      content = "Heatmap of StromalScore, ImmuneScore, ESTIMATEScore, and TumorPurity across samples."
    )
  )
  if (!is.null(paths$plot_file)) {
    items <- c(
      items,
      list(
        list(
          path = paths$plot_file,
          description = "ESTIMATE score group comparison boxplot.",
          content = "Boxplots for StromalScore, ImmuneScore, and ESTIMATEScore across the supplied sample groups."
        ),
        list(
          path = paths$stats_file,
          description = "Group-wise significance summary for ESTIMATE scores.",
          content = "Per-score p-values and the group with the higher median score."
        )
      )
    )
  }
  items
}

collect_existing_output_items <- function(output_dir, opt) {
  paths <- list(
    prepared_input_file = file.path(output_dir, "data", "expression_input.tsv"),
    estimate_input_gct = file.path(output_dir, "data", "estimate_input.gct"),
    estimate_score_gct = file.path(output_dir, "data", "estimate_score.gct"),
    score_table = file.path(output_dir, "table", "estimate_scores.tsv"),
    session_info_file = file.path(output_dir, "session_info.txt"),
    heatmap_file = file.path(output_dir, "plot", opt$heatmap_file)
  )

  plot_file <- file.path(output_dir, "plot", opt$plot_file)
  stats_file <- file.path(output_dir, "table", "estimate_score_group_stats.csv")
  if (file.exists(plot_file) && file.exists(stats_file)) {
    paths$plot_file <- plot_file
    paths$stats_file <- stats_file
  }

  output_items <- build_output_items(paths)
  Filter(function(item) file.exists(item$path), output_items)
}

collect_partial_input_info <- function(opt) {
  info <- list()
  expr_sample_names <- character(0)

  expr_info <- tryCatch(
    {
      expr_df <- load_expression_matrix(opt$input_file, opt$input_delimiter)
      expr_sample_names <<- colnames(expr_df)[-1]
      validate_expression_matrix(expr_df)
    },
    error = function(e) NULL
  )
  if (!is.null(expr_info)) {
    info <- utils::modifyList(info, expr_info)
  }

  if (!is.null(opt$group_file) && nzchar(opt$group_file)) {
    group_info <- tryCatch(
      {
        group_df <- load_group_file(opt$group_file, opt$group_delimiter)
        if (opt$sample_column %in% colnames(group_df) && opt$group_column %in% colnames(group_df)) {
          group_samples <- as.character(group_df[[opt$sample_column]])
          list(
            matched_group_samples = length(intersect(stats::na.omit(group_samples), expr_sample_names)),
            group_levels = paste(sort(unique(stats::na.omit(as.character(group_df[[opt$group_column]])))), collapse = ", ")
          )
        } else {
          NULL
        }
      },
      error = function(e) NULL
    )
    if (!is.null(group_info)) {
      info <- utils::modifyList(info, group_info)
    }
  }

  info
}
