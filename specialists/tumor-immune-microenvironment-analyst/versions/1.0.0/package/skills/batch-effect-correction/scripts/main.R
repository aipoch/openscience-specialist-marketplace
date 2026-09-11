#!/usr/bin/env Rscript
Sys.setenv(
  OMP_NUM_THREADS = "1",
  OPENBLAS_NUM_THREADS = "1",
  MKL_NUM_THREADS = "1",
  VECLIB_MAXIMUM_THREADS = "1",
  NUMEXPR_NUM_THREADS = "1"
)

required_packages <- c("optparse", "data.table", "sva", "limma", "ggplot2")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0) {
  message(sprintf("[ERROR]  %s | SKILL_DEPENDENCY_MISSING: Missing package(s): %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), paste(missing_packages, collapse = ", ")))
  quit(status = 1)
}

suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(sva))
suppressPackageStartupMessages(library(limma))

get_script_dir <- function() {
  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_arg_idx <- which(grepl("^--file=", cmd_args))
  if (length(file_arg_idx) > 0) {
    arg0 <- sub("^--file=", "", cmd_args[file_arg_idx])
    if (!is.na(arg0) && nzchar(arg0) && file.exists(arg0))
      return(dirname(normalizePath(arg0)))
  }
  return(".")
}

script_dir <- get_script_dir()
source(file.path(script_dir, "utils.R"))
source(file.path(script_dir, "input_functions.R"))
source(file.path(script_dir, "functions.R"))
source(file.path(script_dir, "plotting.R"))
source(file.path(script_dir, "output_utils.R"))
source(file.path(script_dir, "run_analysis.R"))

option_list <- list(
  make_option(c("-i", "--input_file"), type = "character", default = NULL,
              help = "Expression matrix file (genes as rows, samples as columns) [required]", metavar = "file"),
  make_option(c("-g", "--group_file"), type = "character", default = NULL,
              help = "Sample metadata file with sample, group, and batch columns [required]", metavar = "file"),
  make_option(c("-o", "--output_dir"), type = "character", default = "./output/",
              help = "Output directory [default %default]", metavar = "dir"),
  make_option(c("-b", "--batch_column"), type = "character", default = "batch",
              help = "Batch column name in metadata [default %default]"),
  make_option(c("-c", "--group_column"), type = "character", default = "group",
              help = "Biological group column name in metadata [default %default]"),
  make_option(c("-n", "--sample_column"), type = "character", default = "sample",
              help = "Sample ID column name in metadata [default %default]"),
  make_option(c("-l", "--log_transform"), type = "character", default = "auto",
              help = "Log transform mode: auto, yes, no [default %default]"),
  make_option(c("-t", "--timeout_seconds"), type = "integer", default = 600,
              help = "Elapsed time limit in seconds [default %default]"),
  make_option(c("-s", "--seed"), type = "integer", default = 42,
              help = "Random seed for reproducibility [default %default]")
)

parser <- OptionParser(option_list = option_list, description = "Batch Effect Correction with ComBat")
opt <- parse_args(parser)

if (is.null(opt$input_file) || is.null(opt$group_file)) {
  print_help(parser)
  message(sprintf("[ERROR]  %s | SKILL_INVALID_PARAMETER: Both --input_file and --group_file are required", format(Sys.time(), "%Y-%m-%d %H:%M:%S")))
  quit(status = 1)
}

tryCatch({
  withCallingHandlers({
    validate_cli_options(opt)
    create_output_dir(opt$output_dir)
    set.seed(opt$seed)

    log_info("==========================================")
    log_info("Batch Effect Correction")
    log_info("==========================================")
    log_info(sprintf("Input: %s", opt$input_file))
    log_info(sprintf("Metadata: %s", opt$group_file))
    log_info(sprintf("Output: %s", opt$output_dir))
    log_info(sprintf("Seed: %d", opt$seed))
    log_info(sprintf("Timeout seconds: %d", opt$timeout_seconds))

    result <- run_batch_correction(opt)
    gc_snapshot <- format_gc_snapshot()
    log_info(sprintf("GC snapshot (Ncells): %s", gc_snapshot$ncells))
    log_info(sprintf("GC snapshot (Vcells): %s", gc_snapshot$vcells))
    save_session_info(opt$output_dir)

    log_info(sprintf("All results saved in: %s", opt$output_dir))
    log_info("Analysis completed")
  }, warning = function(w) {
    log_warn(conditionMessage(w))
    invokeRestart("muffleWarning")
  })
}, error = function(e) {
  log_error(normalize_skill_error(conditionMessage(e)))
  quit(status = 1)
})
