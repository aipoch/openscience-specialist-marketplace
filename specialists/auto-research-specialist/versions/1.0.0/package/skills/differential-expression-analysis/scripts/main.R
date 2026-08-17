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
source(file.path(script_dir, "diff_methods.R"))
source(file.path(script_dir, "diff_visualization.R"))
source(file.path(script_dir, "run_analysis.R"))

option_list <- list(
  make_option(c("-i", "--input_file"), type = "character", default = NULL,
              help = "Expression matrix file (genes as rows, samples as columns) [required]", metavar = "file"),
  make_option(c("-g", "--group_file"), type = "character", default = NULL,
              help = "Group information file with sample and group columns [required]", metavar = "file"),
  make_option(c("-o", "--output_dir"), type = "character", default = "./output/",
              help = "Output directory [default %default]", metavar = "dir"),
  make_option(c("-m", "--diff_method"), type = "character", default = "limma",
              help = "Differential expression method: limma, deseq2, edger, t, wilcox [default %default]"),
  make_option(c("-n", "--norm_method"), type = "character", default = "TMM",
              help = "Normalization method for edgeR: TMM, RLE, upperquartile [default %default]"),
  make_option(c("-p", "--p_threshold"), type = "numeric", default = 0.05,
              help = "P-value threshold [default %default]"),
  make_option(c("-f", "--logfc_threshold"), type = "numeric", default = 0.1,
              help = "Log fold change threshold [default %default]"),
  make_option(c("-s", "--seed"), type = "integer", default = 42,
              help = "Random seed for reproducibility [default %default]")
)

opt <- parse_args(OptionParser(option_list = option_list, description = "Differential Gene Expression Analysis"))

if (is.null(opt$input_file) || is.null(opt$group_file)) {
  print_help(OptionParser(option_list = option_list))
  stop("SKILL_INVALID_PARAMETER: Both --input_file and --group_file are required")
}

set.seed(opt$seed)

dir.create(opt$output_dir, recursive = TRUE, showWarnings = FALSE)
check_files(opt$input_file, opt$group_file)

log_info("==========================================")
log_info("Differential Expression Analysis")
log_info("==========================================")
log_info(paste("Method:", opt$diff_method))
log_info(paste("Input:", opt$input_file))
log_info(paste("Group:", opt$group_file))
log_info(paste("Output:", opt$output_dir))
log_info(paste("Seed:", opt$seed))

save_session_info(opt$output_dir)

temp_files <- character(0)
on.exit({ cleanup_temp_files(temp_files) }, add = TRUE)

run_diff_analysis(
  input_file = opt$input_file,
  group_file = opt$group_file,
  output_dir = opt$output_dir,
  method = opt$diff_method,
  norm_method = opt$norm_method,
  p_threshold = opt$p_threshold,
  logfc_threshold = opt$logfc_threshold,
  p_adjust = TRUE
)

log_info(paste("All results in:", opt$output_dir))
