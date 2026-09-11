#!/usr/bin/env Rscript

build_option_parser <- function() {
  option_list <- list(
    make_option(c("-m", "--mode"), type = "character", default = "analyze", help = "Run mode: analyze, visualize, or full [default %default]"),
    make_option(c("-i", "--input_file"), type = "character", default = NULL, help = "Expression matrix file for analyze/full mode", metavar = "file"),
    make_option(c("-g", "--group_file"), type = "character", default = NULL, help = "Group file for analyze/full mode", metavar = "file"),
    make_option(c("--geneset_file"), type = "character", default = NULL, help = "Immune gene-set table for analyze/full mode", metavar = "file"),
    make_option(c("--geneset_column"), type = "character", default = "gs_name", help = "Pathway column in the gene-set table [default %default]"),
    make_option(c("--gene_column"), type = "character", default = "gene_symbol", help = "Gene column in the gene-set table [default %default]"),
    make_option(c("--focus_genesets"), type = "character", default = NULL, help = "Comma-separated pathway names to prioritize in the heatmap"),
    make_option(c("-a", "--case_group"), type = "character", default = NULL, help = "Case group label for analyze/full mode"),
    make_option(c("-c", "--control_group"), type = "character", default = NULL, help = "Control group label for analyze/full mode"),
    make_option(c("-o", "--output_dir"), type = "character", default = "./output", help = "Output directory inside the skill folder [default %default]", metavar = "dir"),
    make_option(c("--method"), type = "character", default = "gsva", help = "GSVA method: gsva or ssgsea [default %default]"),
    make_option(c("--kcdf"), type = "character", default = "Gaussian", help = "GSVA kernel: Gaussian, Poisson, or none [default %default]"),
    make_option(c("--min_sz"), type = "integer", default = 2, help = "Minimum gene set size [default %default]"),
    make_option(c("--max_sz"), type = "integer", default = 5000, help = "Maximum gene set size [default %default]"),
    make_option(c("--parallel_sz"), type = "integer", default = 1, help = "Parallel worker count for GSVA [default %default]"),
    make_option(c("--mx_diff"), type = "logical", default = TRUE, help = "GSVA mx.diff flag [default %default]"),
    make_option(c("--tau"), type = "double", default = 1, help = "GSVA tau value [default %default]"),
    make_option(c("--fdr_threshold"), type = "double", default = 0.05, help = "FDR threshold for result summaries [default %default]"),
    make_option(c("--top_n"), type = "integer", default = 20, help = "Number of pathways exported to the top matrix [default %default]"),
    make_option(c("--seed"), type = "integer", default = 42, help = "Random seed [default %default]"),
    make_option(c("--timeout_seconds"), type = "integer", default = 0, help = "Optional timeout in seconds; 0 disables timeout [default %default]"),
    make_option(c("--plot_file"), type = "character", default = "immune_pathway_heatmap.pdf", help = "Heatmap PDF filename under plot/ [default %default]"),
    make_option(c("--plot_title"), type = "character", default = "Immune Pathway GSVA Heatmap", help = "Heatmap title [default %default]"),
    make_option(c("--width"), type = "double", default = 14, help = "Heatmap width in inches [default %default]"),
    make_option(c("--height"), type = "double", default = 8, help = "Heatmap height in inches [default %default]"),
    make_option(c("--colors"), type = "character", default = "#91bfdb,#ffffbf,#fc8d59", help = "Comma-separated heatmap colors [default %default]"),
    make_option(c("--scale"), type = "character", default = "none", help = "Heatmap scale mode: none, row, or column [default %default]"),
    make_option(c("--cluster_rows"), type = "logical", default = TRUE, help = "Cluster heatmap rows [default %default]"),
    make_option(c("--cluster_cols"), type = "logical", default = FALSE, help = "Cluster heatmap columns [default %default]"),
    make_option(c("--show_rownames"), type = "logical", default = TRUE, help = "Show heatmap row names [default %default]"),
    make_option(c("--show_colnames"), type = "logical", default = FALSE, help = "Show heatmap column names [default %default]"),
    make_option(c("--fontsize"), type = "double", default = 10, help = "Heatmap base font size [default %default]"),
    make_option(c("--fontsize_row"), type = "double", default = 8, help = "Heatmap row font size [default %default]"),
    make_option(c("--fontsize_col"), type = "double", default = 9, help = "Heatmap column font size [default %default]"),
    make_option(c("--legend_cex"), type = "double", default = 1, help = "Legend text scale [default %default]"),
    make_option(c("--top_up"), type = "integer", default = NULL, help = "Number of top up-regulated pathways to keep for plotting"),
    make_option(c("--top_down"), type = "integer", default = NULL, help = "Number of top down-regulated pathways to keep for plotting"),
    make_option(c("--top_mode"), type = "character", default = "both", help = "Heatmap subset mode: both, up, down, total [default %default]"),
    make_option(c("--sort_by"), type = "character", default = "FDR", help = "Pathway ranking: FDR, absLFC, or LFC [default %default]"),
    make_option(c("--append_stats"), type = "logical", default = FALSE, help = "Append FDR and logFC to heatmap labels [default %default]"),
    make_option(c("--label_max_chars"), type = "integer", default = 90, help = "Maximum heatmap label length [default %default]")
  )
  OptionParser(option_list = option_list, description = "Immune pathway GSVA analysis skill.")
}

validate_cli_options <- function(opt) {
  opt$mode <- tolower(trimws(opt$mode))
  opt$method <- tolower(trimws(opt$method))
  opt$scale <- tolower(trimws(opt$scale))
  opt$top_mode <- tolower(trimws(opt$top_mode))
  if (!(opt$mode %in% c("analyze", "visualize", "full"))) stop_skill("SKILL_INVALID_PARAMETER", "--mode must be one of: analyze, visualize, full.")
  if (!(opt$method %in% c("gsva", "ssgsea"))) stop_skill("SKILL_INVALID_PARAMETER", "--method must be one of: gsva, ssgsea.")
  if (!(opt$kcdf %in% c("Gaussian", "Poisson", "none"))) stop_skill("SKILL_INVALID_PARAMETER", "--kcdf must be one of: Gaussian, Poisson, none.")
  if (!(opt$scale %in% c("none", "row", "column"))) stop_skill("SKILL_INVALID_PARAMETER", "--scale must be one of: none, row, column.")
  if (!(opt$top_mode %in% c("both", "up", "down", "total"))) stop_skill("SKILL_INVALID_PARAMETER", "--top_mode must be one of: both, up, down, total.")
  validate_numeric_range(opt$fdr_threshold, 0, 1, "fdr_threshold")
  validate_numeric_range(opt$width, 1, 100, "width")
  validate_numeric_range(opt$height, 1, 100, "height")
  if (opt$min_sz < 1 || opt$max_sz < opt$min_sz) stop_skill("SKILL_INVALID_PARAMETER", "--max_sz must be >= --min_sz and --min_sz must be >= 1.")
  if (opt$top_n < 1) stop_skill("SKILL_INVALID_PARAMETER", "--top_n must be >= 1.")
  if (opt$timeout_seconds < 0) stop_skill("SKILL_INVALID_PARAMETER", "--timeout_seconds must be >= 0.")
  opt$plot_file <- sanitize_plot_filename(opt$plot_file)
  if (!is.null(opt$focus_genesets) && !nzchar(trimws(opt$focus_genesets))) opt$focus_genesets <- NULL
  opt
}
