#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(optparse)
})

get_script_dir <- function() {
  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_arg_idx <- which(grepl("^--file=", cmd_args))
  if (length(file_arg_idx) > 0) {
    arg0 <- sub("^--file=", "", cmd_args[file_arg_idx])
    if (!is.na(arg0) && nzchar(arg0) && file.exists(arg0)) {
      return(dirname(normalizePath(arg0)))
    }
  }
  "."
}

script_dir <- get_script_dir()
source(file.path(script_dir, "utils.R"))
source(file.path(script_dir, "functions.R"))
source(file.path(script_dir, "run_analysis.R"))

skill_fail <- function(message, show_help = FALSE, opt_parser = NULL) {
  cat(paste0(message, "\n"), file = stderr())
  recovery_hint <- build_recovery_hint(message)
  if (!is.null(recovery_hint)) {
    cat(paste0(recovery_hint, "\n"), file = stderr())
  }
  if (show_help && !is.null(opt_parser)) {
    cat("\n", file = stderr())
    print_help(opt_parser)
  }
  quit(save = "no", status = 1)
}

option_list <- list(
  make_option(c("-d", "--data_file"), type = "character",
              help = "Data file (CSV, TXT, TSV format)", metavar = "file"),
  make_option(c("-t", "--target_var"), type = "character",
              help = "Target column name", metavar = "var"),
  make_option(c("-o", "--output_dir"), type = "character", default = "./XGBoost_Results",
              help = "Output directory [default %default]", metavar = "dir"),
  make_option(c("-k", "--task_type"), type = "character", default = "auto",
              help = "Task type: auto, classification, regression [default %default]"),
  make_option(c("-i", "--ignore_vars"), type = "character", default = NULL,
              help = "Comma-separated columns to ignore", metavar = "vars"),
  make_option(c("--positive_class"), type = "character", default = NULL,
              help = "Positive class label for binary classification", metavar = "label"),
  make_option(c("--test_size"), type = "double", default = 0.2,
              help = "Test set proportion [default %default]"),
  make_option(c("--seed"), type = "integer", default = 123,
              help = "Random seed [default %default]"),
  make_option(c("--nrounds"), type = "integer", default = 300,
              help = "Maximum boosting rounds [default %default]"),
  make_option(c("--max_depth"), type = "integer", default = 6,
              help = "Maximum tree depth [default %default]"),
  make_option(c("--eta"), type = "double", default = 0.1,
              help = "Learning rate [default %default]"),
  make_option(c("--subsample"), type = "double", default = 0.8,
              help = "Row sampling ratio [default %default]"),
  make_option(c("--colsample_bytree"), type = "double", default = 0.8,
              help = "Column sampling ratio [default %default]"),
  make_option(c("--min_child_weight"), type = "double", default = 1,
              help = "Minimum child weight [default %default]"),
  make_option(c("--gamma"), type = "double", default = 0,
              help = "Minimum split loss reduction [default %default]"),
  make_option(c("--lambda"), type = "double", default = 1,
              help = "L2 regularization [default %default]"),
  make_option(c("--alpha"), type = "double", default = 0,
              help = "L1 regularization [default %default]"),
  make_option(c("--early_stopping_rounds"), type = "integer", default = 20,
              help = "Early stopping rounds [default %default]"),
  make_option(c("--importance_metric"), type = "character", default = "gain",
              help = "Importance metric: gain, cover, frequency [default %default]"),
  make_option(c("--top_n"), type = "integer", default = 20,
              help = "Number of features to plot [default %default]"),
  make_option(c("-f", "--output_format"), type = "character", default = "csv",
              help = "Output format: csv, txt [default %default]"),
  make_option(c("-p", "--output_prefix"), type = "character", default = "xgboost",
              help = "Output file prefix [default %default]")
)

opt_parser <- OptionParser(
  option_list = option_list,
  description = "XGBoost Modeling And Feature Importance Ranking"
)
opt <- parse_args(opt_parser)

if (is.null(opt$data_file) || !nzchar(opt$data_file)) {
  skill_fail("SKILL_MISSING_INPUT: Data file (-d) option is required", show_help = TRUE, opt_parser = opt_parser)
}

if (is.null(opt$target_var) || !nzchar(opt$target_var)) {
  skill_fail("SKILL_MISSING_INPUT: Target variable (-t) option is required", show_help = TRUE, opt_parser = opt_parser)
}

params <- list(
  data_file = opt$data_file,
  target_var = opt$target_var,
  output_dir = opt$output_dir,
  task_type = opt$task_type,
  ignore_vars = opt$ignore_vars,
  positive_class = opt$positive_class,
  test_size = opt$test_size,
  seed = opt$seed,
  nrounds = opt$nrounds,
  max_depth = opt$max_depth,
  eta = opt$eta,
  subsample = opt$subsample,
  colsample_bytree = opt$colsample_bytree,
  min_child_weight = opt$min_child_weight,
  gamma = opt$gamma,
  lambda = opt$lambda,
  alpha = opt$alpha,
  early_stopping_rounds = opt$early_stopping_rounds,
  importance_metric = opt$importance_metric,
  top_n = opt$top_n,
  output_format = opt$output_format,
  output_prefix = opt$output_prefix
)

params <- tryCatch({
  validate_parameters_opt(params)
}, error = function(e) {
  skill_fail(e$message, show_help = TRUE, opt_parser = opt_parser)
})

tryCatch({
  xgboost_analysis(params)
  save_session_info(params$output_dir)
}, error = function(e) {
  skill_fail(e$message)
})
