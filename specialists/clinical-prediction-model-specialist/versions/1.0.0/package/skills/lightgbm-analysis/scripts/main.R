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
              help = "Target column used for modeling", metavar = "column"),
  make_option(c("-o", "--output_dir"), type = "character", default = "./LightGBM_Results",
              help = "Output directory [default %default]", metavar = "dir"),
  make_option(c("--fail_if_output_exists"), action = "store_true", default = FALSE,
              help = paste(
                "Stop instead of overwriting when output_dir already contains files",
                "[default %default]"
              )),
  make_option(c("--task_type"), type = "character", default = "auto",
              help = "Task type: auto, regression, binary, multiclass [default %default]"),
  make_option(c("--feature_cols"), type = "character", default = NULL,
              help = "Comma-separated feature columns"),
  make_option(c("--drop_cols"), type = "character", default = NULL,
              help = "Comma-separated columns to exclude from modeling"),
  make_option(c("--metric"), type = "character", default = "auto",
              help = "Evaluation metric or auto [default %default]"),
  make_option(c("--test_size"), type = "double", default = 0.2,
              help = "Test-set proportion [default %default]"),
  make_option(c("--valid_size"), type = "double", default = 0.2,
              help = "Validation proportion from the training partition [default %default]"),
  make_option(c("--importance_type"), type = "character", default = "gain",
              help = "Feature importance type: gain, split [default %default]"),
  make_option(c("--top_n"), type = "integer", default = 20,
              help = "Top N features shown in the figure [default %default]"),
  make_option(c("--nrounds"), type = "integer", default = 500,
              help = "Maximum boosting rounds [default %default]"),
  make_option(c("--learning_rate"), type = "double", default = 0.05,
              help = "Learning rate [default %default]"),
  make_option(c("--num_leaves"), type = "integer", default = 31,
              help = "Maximum leaves per tree [default %default]"),
  make_option(c("--max_depth"), type = "integer", default = -1,
              help = "Maximum tree depth [default %default]"),
  make_option(c("--min_data_in_leaf"), type = "integer", default = 5,
              help = "Minimum data in leaf [default %default]"),
  make_option(c("--feature_fraction"), type = "double", default = 0.8,
              help = "Feature sampling fraction [default %default]"),
  make_option(c("--bagging_fraction"), type = "double", default = 0.8,
              help = "Row bagging fraction [default %default]"),
  make_option(c("--bagging_freq"), type = "integer", default = 1,
              help = "Bagging frequency [default %default]"),
  make_option(c("--lambda_l1"), type = "double", default = 0,
              help = "L1 regularization [default %default]"),
  make_option(c("--lambda_l2"), type = "double", default = 0,
              help = "L2 regularization [default %default]"),
  make_option(c("--early_stopping_rounds"), type = "integer", default = 50,
              help = "Early stopping rounds [default %default]"),
  make_option(c("--seed"), type = "integer", default = 42,
              help = "Random seed [default %default]"),
  make_option(c("-f", "--output_format"), type = "character", default = "csv",
              help = "Output format for tables: csv, txt [default %default]")
)

opt_parser <- OptionParser(
  option_list = option_list,
  description = paste(
    "LightGBM Analysis:",
    "Train a LightGBM model and export feature importance ranking tables and figures."
  )
)

opt <- parse_args(opt_parser)

if (is.null(opt$data_file)) {
  skill_fail("SKILL_MISSING_INPUT: Data file (-d) option is required", show_help = TRUE, opt_parser = opt_parser)
}

if (is.null(opt$target_var)) {
  skill_fail("SKILL_MISSING_INPUT: Target variable (-t) option is required", show_help = TRUE, opt_parser = opt_parser)
}

params <- list(
  data_file = opt$data_file,
  target_var = opt$target_var,
  output_dir = opt$output_dir,
  fail_if_output_exists = opt$fail_if_output_exists,
  task_type = opt$task_type,
  feature_cols = opt$feature_cols,
  drop_cols = opt$drop_cols,
  metric = opt$metric,
  test_size = opt$test_size,
  valid_size = opt$valid_size,
  importance_type = opt$importance_type,
  top_n = opt$top_n,
  nrounds = opt$nrounds,
  learning_rate = opt$learning_rate,
  num_leaves = opt$num_leaves,
  max_depth = opt$max_depth,
  min_data_in_leaf = opt$min_data_in_leaf,
  feature_fraction = opt$feature_fraction,
  bagging_fraction = opt$bagging_fraction,
  bagging_freq = opt$bagging_freq,
  lambda_l1 = opt$lambda_l1,
  lambda_l2 = opt$lambda_l2,
  early_stopping_rounds = opt$early_stopping_rounds,
  seed = opt$seed,
  output_format = opt$output_format
)

params <- tryCatch({
  validate_parameters_opt(params)
}, error = function(e) {
  skill_fail(e$message, show_help = TRUE, opt_parser = opt_parser)
})

tryCatch({
  lightgbm_analysis(params)
}, error = function(e) {
  skill_fail(e$message)
})
