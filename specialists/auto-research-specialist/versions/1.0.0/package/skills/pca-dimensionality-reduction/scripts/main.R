#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(optparse)
})

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

skill_fail <- function(message, show_help = FALSE, opt_parser = NULL) {
  cat(paste0(message, "\n"), file = stderr())
  if (show_help && !is.null(opt_parser)) {
    cat("\n", file = stderr())
    print_help(opt_parser)
  }
  quit(save = "no", status = 1)
}

option_list <- list(
  make_option(c("-d", "--data_file"), type = "character",
              help = "Data file (CSV, TXT, TSV format)", metavar = "file"),
  make_option(c("-o", "--output_dir"), type = "character", default = "./PCA_Results",
              help = "Output directory [default %default]", metavar = "dir"),
  make_option(c("-f", "--feature_columns"), type = "character", default = NULL,
              help = "Comma-separated numeric feature columns used for PCA [default all numeric columns]", metavar = "cols"),
  make_option(c("-s", "--sample_id_column"), type = "character", default = NULL,
              help = "Optional sample ID column [default auto-detect first non-numeric unique column]", metavar = "col"),
  make_option(c("-g", "--group_column"), type = "character", default = NULL,
              help = "Optional grouping column carried into scores and figures", metavar = "col"),
  make_option(c("-n", "--n_components"), type = "integer", default = 5,
              help = "Maximum number of components to export [default %default]"),
  make_option(c("-c", "--center_data"), type = "character", default = "true",
              help = "Center variables before PCA: true or false [default %default]"),
  make_option(c("-z", "--scale_data"), type = "character", default = "true",
              help = "Scale variables before PCA: true or false [default %default]"),
  make_option(c("-t", "--top_loadings"), type = "integer", default = 10,
              help = "Top absolute loadings exported per component [default %default]"),
  make_option(c("-m", "--output_format"), type = "character", default = "csv",
              help = "Output format: csv, txt [default %default]"),
  make_option(c("-p", "--output_prefix"), type = "character", default = "pca",
              help = "Output file prefix [default %default]")
)

opt_parser <- OptionParser(
  option_list = option_list,
  description = "PCA Dimensionality Reduction: Perform principal component analysis with standardized outputs."
)
opt <- parse_args(opt_parser)

if (is.null(opt$data_file)) {
  skill_fail("SKILL_MISSING_INPUT: Data file (-d) option is required", show_help = TRUE, opt_parser = opt_parser)
}

params <- list(
  data_file = opt$data_file,
  output_dir = opt$output_dir,
  feature_columns = opt$feature_columns,
  sample_id_column = opt$sample_id_column,
  group_column = opt$group_column,
  n_components = opt$n_components,
  center_data = opt$center_data,
  scale_data = opt$scale_data,
  top_loadings = opt$top_loadings,
  output_format = opt$output_format,
  output_prefix = opt$output_prefix
)

params <- tryCatch({
  validate_parameters_opt(params)
}, error = function(e) {
  skill_fail(e$message, show_help = TRUE, opt_parser = opt_parser)
})

tryCatch({
  pca_analysis(params)
  save_session_info(params$output_dir)
}, error = function(e) {
  skill_fail(e$message)
})
