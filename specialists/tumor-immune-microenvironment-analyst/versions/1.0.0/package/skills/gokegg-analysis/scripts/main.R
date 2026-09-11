#!/usr/bin/env Rscript
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
source(file.path(script_dir, "dochart.R"))

option_list <- list(
  make_option(c("-o", "--output_dir"), type = "character", default = "./output/",
              help="Output directory path [default: %default]", metavar = "dir"),
  make_option(c("-f", "--feature"), type = "character", default = "",
              help="Gene list separated by commas, Chinese commas, semicolons, tabs, or newlines"),
  make_option(c("-s", "--sp"), type = "character", default = "org.Hs.eg.db",
              help="Species database: org.Hs.eg.db, org.Mm.eg.db, org.Rn.eg.db [default: %default]", metavar = "db"),
  make_option(c("-g", "--gene_type"), type = "character", default = "SYMBOL",
              help="Input gene ID type: SYMBOL, ENSEMBL, ENTREZID [default: %default]"),
  make_option(c("-p", "--pvalue_cutoff"), type = "numeric", default = 0.05,
              help="P-value cutoff for enrichment [default: %default]"),
  make_option(c("-q", "--qvalue_cutoff"), type = "numeric", default = 0.2,
              help="Q-value cutoff for enrichment [default: %default]"),
  make_option(c("-m", "--pAdjustMethod"), type = "character", default = "BH",
              help="P-value adjustment method: BH, BY, fdr, holm, hochberg, hommel, bonferroni, none [default: %default]"),
  make_option(c("--seed"), type = "integer", default = 66,
              help = "Random seed for reproducibility [default: %default]"),
  make_option(c("--go_input"), type = "character", default = NULL,
              help = "GO enrichment .rda file containing GO_list [default: auto from output_dir/temp]"),
  make_option(c("--kegg_input"), type = "character", default = NULL,
              help = "KEGG enrichment .rda file containing KEGG_list [default: auto from output_dir/temp]"),
  make_option(c("--outdir"), type = "character", default = NULL,
              help = "Plot output directory [default: output_dir/plot]"),
  make_option(c("--go_top_n"), type = "numeric", default = 3,
              help = "Top GO terms per ontology [default: %default]"),
  make_option(c("--kegg_top_n"), type = "numeric", default = 3,
              help = "Top KEGG pathways [default: %default]"),
  make_option(c("-w", "--width"), type = "numeric", default = 20,
              help = "Plot width in cm [default: %default]"),
  make_option(c("--height"), type = "numeric", default = 16,
              help = "Plot height in cm [default: %default]"),
  make_option(c("--format"), type = "character", default = "pdf",
              help = "Output format: pdf, png, svg [default: %default]"),
  make_option(c("--dpi"), type = "numeric", default = 300,
              help = "Resolution for raster formats [default: %default]"),
  make_option(c("-c", "--colors"), type = "character", default = "#E41A1C,#FFFF33,#2E86AB,#4DAF4A",
              help = "Colors for GO:BP,GO:CC,GO:MF,KEGG [default: %default]"),
  make_option(c("--title"), type = "character", default = "GO + KEGG Dot Chart",
              help = "Plot title [default: %default]"),
  make_option(c("--xlab"), type = "character", default = NULL, help = "Horizontal axis label [default: auto]"),
  make_option(c("--ylab"), type = "character", default = NULL, help = "Vertical axis label [default: auto]"),
  make_option(c("--dot_size"), type = "numeric", default = 4.5, help = "Dot size [default: %default]"),
  make_option(c("--shape"), type = "numeric", default = 19, help = "Dot shape [default: %default]"),
  make_option(c("--rotate"), action = "store_true", default = TRUE, help = "Rotate plot [default: %default]"),
  make_option(c("--no-rotate"), action = "store_false", dest = "rotate", help = "Do not rotate plot"),
  make_option(c("--sorting"), type = "character", default = "descending", help = "Sorting order [default: %default]"),
  make_option(c("--label_width"), type = "numeric", default = 35, help = "Label wrap width [default: %default]"),
  make_option(c("--title_size"), type = "numeric", default = 12, help = "Title font size [default: %default]"),
  make_option(c("--axis_title_size"), type = "numeric", default = 9, help = "Axis title font size [default: %default]"),
  make_option(c("--axis_text_size"), type = "numeric", default = 8, help = "Axis text font size [default: %default]"),
  make_option(c("--legend_title_size"), type = "numeric", default = 8, help = "Legend title font size [default: %default]"),
  make_option(c("--legend_text_size"), type = "numeric", default = 7, help = "Legend text font size [default: %default]"),
  make_option(c("--legend_position"), type = "character", default = "top", help = "Legend position [default: %default]"),
  make_option(c("--plot_margin"), type = "character", default = "10,10,10,10", help = "Plot margins [default: %default]"),
  make_option(c("--axis_line_size"), type = "numeric", default = 0.5, help = "Axis line size [default: %default]"),
  make_option(c("--axis_ticks_size"), type = "numeric", default = 0.5, help = "Axis ticks size [default: %default]"),
  make_option(c("--show_grid"), action = "store_true", default = FALSE, help = "Show grid lines [default: %default]"),
  make_option(c("-v", "--verbose"), action = "store_true", default = FALSE, help = "Verbose output")
)
opt <- parse_args(OptionParser(option_list = option_list, description = "GOKEGG Analysis"))

tryCatch({
  withCallingHandlers({
    if (is.null(opt$feature) || !nzchar(trimws(opt$feature))) {
      print_help(OptionParser(option_list = option_list))
      skill_stop("SKILL_INVALID_PARAMETER", "--feature is required")
    }

    set.seed(opt$seed)
    dir.create(opt$output_dir, recursive = TRUE, showWarnings = FALSE)
    check_feature_input(opt$feature)
    validate_main_options(opt)

    log_info("GOKEGG Analysis started")
    log_info(paste("feature:", opt$feature))
    log_info(paste("output_dir:", opt$output_dir))
    log_info(paste("sp:", opt$sp))
    log_info(paste("seed:", opt$seed))

    temp_files <- character(0)
    on.exit({ cleanup_temp_files(temp_files) }, add = TRUE)

    run_gokegg_analysis(
      feature = opt$feature,
      output_dir = opt$output_dir,
      sp = opt$sp,
      pAdjustMethod = opt$pAdjustMethod,
      gene_type = opt$gene_type,
      pvalue_cutoff = opt$pvalue_cutoff,
      qvalue_cutoff = opt$qvalue_cutoff
    )

    if (is.null(opt$go_input)) opt$go_input <- file.path(opt$output_dir, "temp", "GO_list.rda")
    if (is.null(opt$kegg_input)) opt$kegg_input <- file.path(opt$output_dir, "temp", "KEGG_list.rda")
    if (is.null(opt$outdir)) opt$outdir <- file.path(opt$output_dir, "plot")

    generate_dot_chart(opt)
    save_session_info(opt$output_dir)
    emit_run_summary(opt$feature, opt$output_dir, opt$format)
    log_info(paste("Analysis completed. Output directory:", opt$output_dir))
    quit(status = 0)
  }, warning = function(w) {
    log_warn(conditionMessage(w))
    invokeRestart("muffleWarning")
  })
}, error = function(e) {
  log_error(conditionMessage(e))
  quit(status = 1)
})