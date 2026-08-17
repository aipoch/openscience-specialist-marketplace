#!/usr/bin/env Rscript

if (!requireNamespace("optparse", quietly = TRUE)) {
  stop("SKILL_PACKAGE_NOT_FOUND: Required package not installed: optparse", call. = FALSE)
}
suppressPackageStartupMessages(library(optparse))

get_script_dir <- function() {
  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_arg_idx <- which(grepl("^--file=", cmd_args))
  if (length(file_arg_idx) > 0) {
    arg0 <- sub("^--file=", "", cmd_args[file_arg_idx])
    if (!is.na(arg0) && length(arg0) > 0 && file.exists(arg0))
      return(dirname(normalizePath(arg0)))
  }
  return(".")
}

script_dir <- get_script_dir()
source(file.path(script_dir, "utils.R"))
source(file.path(script_dir, "functions.R"))
source(file.path(script_dir, "run_analysis.R"))

# Define command line arguments for both analysis and plotting
option_list <- list(
  # Analysis parameters
  make_option(c("-o", "--outdir"), type="character", default="GSEA_analysis",
              help="Output directory path for analysis [default: %default]"),
  make_option(c("-i", "--input"), type="character", default=NULL,
              help="Input file path (CSV format with gene names and logFC)"),
  make_option(c("-g", "--gene_col"), type="character", default="name",
              help="Column name for gene symbols [default: %default]"),
  make_option(c("-f", "--fc_col"), type="character", default="logFC",
              help="Column name for log fold change [default: %default]"),
  make_option(c("-t", "--type"), type="character", default="KEGG",
              help="Gene set type: KEGG, HALLMARKS, GO_BP, GO_MF, GO_CC [default: %default]"),
  make_option(c("-p", "--pvalue_cutoff"), type="numeric", default=0.05,
              help="P-value cutoff for enrichment [default: %default]"),
  make_option(c("-m", "--method"), type="character", default="fgsea",
              help="GSEA method: fgsea, DOSE [default: %default]"),
  make_option(c("-c", "--chunk_size"), type="numeric", default=1000,
              help="Chunk size for parallel processing [default: %default]"),
  make_option(c("-v", "--verbose"), action="store_true", default=FALSE,
              help="Print verbose output"),
  make_option(c("-s", "--species"), type="character", default="human",
              help="Species: human, mouse, rat [default: %default]"),
  make_option(c("-r", "--rds_path"), type="character", default=NULL,
              help="Path to pre-saved RDS file with gene sets [default: %default]"),
  make_option(c("--seed"), type = "integer", default = 42,
              help = "Random seed for reproducibility [default: %default]"),
  make_option(c("--timeout"), type = "integer", default = 300,
              help = "Timeout in seconds, <=0 disables timeout [default: %default]"),
  
  # Plotting parameters
  make_option(c("--running_file"), type="character", default=NULL,
              help="Path to gsea_running_scores.csv file (required for plotting)"),
  make_option(c("--enrich_file"), type="character", default=NULL,
              help="Path to enrichGSEA.csv file (required for plotting)"),
  make_option(c("--plot_output"), type="character", default="gsea_plot.pdf",
              help="Output plot file path [default: %default]"),
  make_option(c("--plot_width"), type="numeric", default=8,
              help="Plot width in inches [default: %default]"),
  make_option(c("--plot_height"), type="numeric", default=6,
              help="Plot height in inches [default: %default]"),
  make_option(c("--plot_format"), type="character", default="pdf",
              help="Output format: pdf or png [default: %default]"),
  make_option(c("--top_n"), type="numeric", default=1,
              help="Number of top pathways to plot when geneSetID not specified [default: %default]"),
  make_option(c("--rank_by"), type="character", default="p.adjust",
              help="Column name to rank pathways by (e.g., 'p.adjust', 'NES') [default: %default]"),
  make_option(c("--geneSetID"), type="character", default="",
              help="Comma-separated pathway IDs to plot (overrides top_n) [default: %default]"),
  make_option(c("--plot_title"), type="character", default="",
              help="Plot title (if empty, auto-generated from pathway) [default: %default]"),
  make_option(c("--colors"), type="character", default="#4DBBD5,#E64B35,#00A087,#F39B7F,#3C5488,#8491B4",
              help="Comma-separated color palette for pathways [default: %default]"),
  make_option(c("--base_size"), type="numeric", default=11,
              help="Base font size for plot theme [default: %default]"),
  make_option(c("--subplots"), type="character", default="1,2,3",
              help="Comma-separated which subplots to show (1,2,3) [default: %default]"),
  make_option(c("--rel_heights"), type="character", default="1.5,0.8,1",
              help="Comma-separated relative heights of subplots [default: %default]"),
  make_option(c("--NES_table"), action="store_true", default=TRUE,
              help="Show NES/p.adj/FDR annotation (default: TRUE)"),
  make_option(c("--no_NES_table"), action="store_false", dest="NES_table",
              help="Hide NES/p.adj/FDR annotation"),
  make_option(c("--NES_label_size"), type="numeric", default=4,
              help="Font size for NES annotation [default: %default]"),
  make_option(c("--NES_label_x"), type="numeric", default=0.75,
              help="NES label x position (fraction) [default: %default]"),
  make_option(c("--NES_label_y"), type="numeric", default=0.75,
              help="NES label y position (fraction) [default: %default]"),
  make_option(c("--NES_label_color"), type="character", default="black",
              help="NES label color [default: %default]"),
  make_option(c("--NES_label_hjust"), type="numeric", default=0,
              help="NES label horizontal justification [default: %default]"),
  make_option(c("--NES_label_vjust"), type="numeric", default=1,
              help="NES label vertical justification [default: %default]"),
  make_option(c("--line_width"), type="numeric", default=1,
              help="Line width when ES_geom=line [default: %default]"),
  make_option(c("--dot_size"), type="numeric", default=1.2,
              help="Point size when ES_geom=dot [default: %default]"),
  make_option(c("--legend_position"), type="character", default="auto",
              help="Legend position: auto, inside, right, none [default: %default]"),
  make_option(c("--legend_x"), type="numeric", default=0.02,
              help="Inside legend x position in [0,1] [default: %default]"),
  make_option(c("--legend_y"), type="numeric", default=0.02,
              help="Inside legend y position in [0,1] [default: %default]"),
  make_option(c("--legend_just_x"), type="numeric", default=0,
              help="Legend justification x [default: %default]"),
  make_option(c("--legend_just_y"), type="numeric", default=0,
              help="Legend justification y [default: %default]"),
  make_option(c("--legend_text_size"), type="numeric", default=9,
              help="Legend text size [default: %default]"),
  make_option(c("--legend_key_size"), type="numeric", default=0.6,
              help="Legend key size in lines [default: %default]"),
  make_option(c("--legend_bg_alpha"), type="numeric", default=0,
              help="Legend background alpha [0,1] [default: %default]"),
  make_option(c("--grid_major_color"), type="character", default="grey92",
              help="Major grid color [default: %default]"),
  make_option(c("--grid_minor_color"), type="character", default="grey92",
              help="Minor grid color [default: %default]"),
  make_option(c("--ylab_es"), type="character", default="Enrichment Score",
              help="Y label for ES panel [default: %default]"),
  make_option(c("--ylab_rank"), type="character", default="Ranked List Metric",
              help="Y label for rank panel [default: %default]"),
  make_option(c("--xlab_rank"), type="character", default="Rank in Ordered Dataset",
              help="X label for rank panel [default: %default]"),
  make_option(c("--hit_height"), type="numeric", default=1,
              help="Hit bar height [default: %default]"),
  make_option(c("--hit_gap"), type="numeric", default=0,
              help="Gap between hit bars [default: %default]"),
  make_option(c("--hit_linewidth"), type="numeric", default=0.5,
              help="Hit bar linewidth [default: %default]"),
  make_option(c("--rank_bar_alpha"), type="numeric", default=0.9,
              help="Single-path rank bar alpha [default: %default]"),
  make_option(c("--rank_bar_height_ratio"), type="numeric", default=0.3,
              help="Single-path rank bar height ratio [default: %default]"),
  make_option(c("--rank_metric_segment_color"), type="character", default="grey",
              help="Rank metric segment color [default: %default]"),
  make_option(c("--rank_metric_segment_width"), type="numeric", default=0.3,
              help="Rank metric segment width [default: %default]"),
  make_option(c("--rank_metric_segment_alpha"), type="numeric", default=1,
              help="Rank metric segment alpha [default: %default]"),
  make_option(c("--pvalue_table"), action="store_true", default=FALSE,
              help="Show p-value table overlay (default: FALSE)"),
  make_option(c("--ES_geom"), type="character", default="line",
              help="ES geometry: line or dot [default: %default]"),
  make_option(c("-h", "--help"), action="store_true", default=FALSE,
              help="Show this help message")
)

# Parse arguments
opt_parser <- OptionParser(option_list=option_list, add_help_option=FALSE)
opt <- parse_args(opt_parser)
validate_timeout_value(opt$timeout)

# Determine mode: plotting if both running_file and enrich_file are provided
plot_mode <- !is.null(opt$running_file) && !is.null(opt$enrich_file)
analysis_mode <- !is.null(opt$input)

if (!plot_mode && !analysis_mode) {
  skill_stop("SKILL_INVALID_PARAMETER", "Must provide either --input (analysis mode) or both --running_file and --enrich_file (plotting mode)")
}

if (plot_mode && analysis_mode) {
  skill_warn(
    "SKILL_CONFLICTING_PARAMETERS",
    paste(
      "Conflicting mode parameters detected:",
      "both analysis (--input) and plotting (--running_file/--enrich_file) parameters were provided.",
      "Plotting mode takes precedence; analysis mode will be skipped."
    )
  )
  analysis_mode <- FALSE
}

# Set random seed (used in both modes)
set.seed(opt$seed)

if (analysis_mode) {
  # Validate GSEA options
  validate_gsea_options(opt)
  
  # Run GSEA pipeline
  tryCatch({
    run_gsea_pipeline(
      input = opt$input,
      outdir = opt$outdir,
      gene_col = opt$gene_col,
      fc_col = opt$fc_col,
      type = opt$type,
      species = opt$species,
      method = opt$method,
      pvalue_cutoff = opt$pvalue_cutoff,
      chunk_size = opt$chunk_size,
      verbose = opt$verbose,
      rds_path = opt$rds_path,
      seed = opt$seed,
      script_dir = script_dir,
      timeout_seconds = opt$timeout
    )
  }, error = function(e) {
    log_error(conditionMessage(e))
    quit(status = 1)
  })
} else {
  source(file.path(script_dir, "plot_functions.R"))
  # Plotting mode
  tryCatch({
    run_gsea_plotting(
      running_file = opt$running_file,
      enrich_file = opt$enrich_file,
      plot_output = opt$plot_output,
      plot_width = opt$plot_width,
      plot_height = opt$plot_height,
      plot_format = opt$plot_format,
      top_n = opt$top_n,
      rank_by = opt$rank_by,
      geneSetID = opt$geneSetID,
      plot_title = opt$plot_title,
      colors = opt$colors,
      base_size = opt$base_size,
      subplots = opt$subplots,
      rel_heights = opt$rel_heights,
      NES_table = opt$NES_table,
      NES_label_size = opt$NES_label_size,
      NES_label_x = opt$NES_label_x,
      NES_label_y = opt$NES_label_y,
      NES_label_color = opt$NES_label_color,
      NES_label_hjust = opt$NES_label_hjust,
      NES_label_vjust = opt$NES_label_vjust,
      line_width = opt$line_width,
      dot_size = opt$dot_size,
      legend_position = opt$legend_position,
      legend_x = opt$legend_x,
      legend_y = opt$legend_y,
      legend_just_x = opt$legend_just_x,
      legend_just_y = opt$legend_just_y,
      legend_text_size = opt$legend_text_size,
      legend_key_size = opt$legend_key_size,
      legend_bg_alpha = opt$legend_bg_alpha,
      grid_major_color = opt$grid_major_color,
      grid_minor_color = opt$grid_minor_color,
      ylab_es = opt$ylab_es,
      ylab_rank = opt$ylab_rank,
      xlab_rank = opt$xlab_rank,
      hit_height = opt$hit_height,
      hit_gap = opt$hit_gap,
      hit_linewidth = opt$hit_linewidth,
      rank_bar_alpha = opt$rank_bar_alpha,
      rank_bar_height_ratio = opt$rank_bar_height_ratio,
      rank_metric_segment_color = opt$rank_metric_segment_color,
      rank_metric_segment_width = opt$rank_metric_segment_width,
      rank_metric_segment_alpha = opt$rank_metric_segment_alpha,
      pvalue_table = opt$pvalue_table,
      ES_geom = opt$ES_geom,
      verbose = opt$verbose,
      timeout_seconds = opt$timeout
    )
  }, error = function(e) {
    log_error(conditionMessage(e))
    quit(status = 1)
  })
}