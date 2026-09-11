#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(optparse))

get_script_dir <- function() {
  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_arg_idx <- which(grepl("^--file=", cmd_args))
  if (length(file_arg_idx) > 0) {
    arg0 <- sub("^--file=", "", cmd_args[file_arg_idx[1]])
    if (!is.na(arg0) && nzchar(arg0) && file.exists(arg0))
      return(dirname(normalizePath(arg0)))
  }
  normalizePath(".")
}

script_dir <- get_script_dir()
source(file.path(script_dir, "utils.R"))
source(file.path(script_dir, "io.R"))
source(file.path(script_dir, "functions.R"))
source(file.path(script_dir, "plotting.R"))
source(file.path(script_dir, "run_analysis.R"))

option_list <- list(
  make_option(c("-e", "--exp_file"), type = "character", default = NULL,
              help = "Expression matrix CSV (genes as rows, samples as columns) [required]"),
  make_option(c("-c", "--cli_file"), type = "character", default = NULL,
              help = "Clinical metadata CSV with OS and OS.time columns [required]"),
  make_option(c("-m", "--model_file"), type = "character", default = NULL,
              help = "Model coefficient CSV with Gene and Coef columns [required]"),
  make_option(c("-o", "--output_dir"), type = "character", default = "./output/",
              help = "Output directory [default: %default]"),
  make_option(c("--overwrite"), action = "store_true", default = FALSE,
              help = "Allow writing into a non-empty output directory [default: %default]"),
  make_option(c("-u", "--time_unit"), type = "character", default = "month",
              help = "Input survival time unit: day, month, year [default: %default]"),
  make_option(c("--col_high"), type = "character", default = "#E64B35",
              help = "High-risk color [default: %default]"),
  make_option(c("--col_low"), type = "character", default = "#4DBBD5",
              help = "Low-risk color [default: %default]"),
  make_option(c("--roc_cols"), type = "character", default = "#E64B35,#00A087,#3C5488",
              help = "Comma-separated ROC colors [default: %default]"),
  make_option(c("--roc_times"), type = "character", default = "1,3,5",
              help = "Comma-separated ROC time points in years [default: %default]"),
  make_option(c("--roc_pos"), type = "character", default = "bottomright",
              help = "Legend position for ROC plot [default: %default]"),
  make_option(c("--km_breaks"), type = "integer", default = 0,
              help = "KM x-axis break in years; use 0 for automatic [default: %default]"),
  make_option(c("-s", "--seed"), type = "integer", default = 42,
              help = "Random seed for reproducibility [default: %default]"),
  make_option(c("--timeout_seconds"), type = "integer", default = 3600,
              help = "Elapsed timeout limit in seconds [default: %default]")
)

parser <- OptionParser(option_list = option_list, description = "External model validation for prognostic risk signatures")
opt <- parse_args(parser)

required_args <- c("exp_file", "cli_file", "model_file")
missing_args <- required_args[vapply(required_args, function(arg_name) is.null(opt[[arg_name]]) || !nzchar(opt[[arg_name]]), logical(1))]
if (length(missing_args) > 0) {
  print_help(parser)
  stop_skill("SKILL_INVALID_PARAMETER", paste("Missing required arguments:", paste(paste0("--", missing_args), collapse = ", ")))
}

set.seed(opt$seed)
validate_choice(opt$time_unit, c("day", "month", "year"), "--time_unit")
validate_choice(opt$roc_pos, c("bottomright", "bottom", "bottomleft", "left", "topleft", "top", "topright", "right", "center"), "--roc_pos")
validate_positive_integer(opt$seed, "--seed")
validate_positive_integer(opt$timeout_seconds, "--timeout_seconds")
validate_positive_integer(opt$km_breaks, "--km_breaks", allow_zero = TRUE)
validate_existing_file(opt$exp_file, "--exp_file")
validate_existing_file(opt$cli_file, "--cli_file")
validate_existing_file(opt$model_file, "--model_file")
validate_color(opt$col_high, "--col_high")
validate_color(opt$col_low, "--col_low")

roc_times <- unique(parse_csv_arg(opt$roc_times, "--roc_times", mode = "numeric"))
if (any(roc_times <= 0))
  stop_skill("SKILL_INVALID_PARAMETER", "--roc_times must contain positive numeric values")
roc_colors <- parse_csv_arg(opt$roc_cols, "--roc_cols", mode = "character")
invisible(vapply(roc_colors, validate_color, character(1), arg_name = "--roc_cols"))
if (length(roc_colors) < length(roc_times))
  roc_colors <- rep(roc_colors, length.out = length(roc_times))

output_paths <- create_output_dirs(opt$output_dir, overwrite = isTRUE(opt$overwrite))
set_log_file(output_paths$root)
on.exit(close_log_file(), add = TRUE)
enable_timeout(opt$timeout_seconds)
on.exit(disable_timeout(), add = TRUE)

analysis_config <- list(
  exp_file = normalizePath(opt$exp_file, winslash = "/", mustWork = TRUE),
  cli_file = normalizePath(opt$cli_file, winslash = "/", mustWork = TRUE),
  model_file = normalizePath(opt$model_file, winslash = "/", mustWork = TRUE),
  output_paths = output_paths,
  time_unit = opt$time_unit,
  col_high = opt$col_high,
  col_low = opt$col_low,
  roc_times = roc_times,
  roc_colors = roc_colors,
  roc_pos = opt$roc_pos,
  km_breaks = opt$km_breaks,
  run_parameters = list(
    exp_file = normalizePath(opt$exp_file, winslash = "/", mustWork = TRUE),
    cli_file = normalizePath(opt$cli_file, winslash = "/", mustWork = TRUE),
    model_file = normalizePath(opt$model_file, winslash = "/", mustWork = TRUE),
    output_dir = output_paths$root,
    overwrite = isTRUE(opt$overwrite),
    time_unit = opt$time_unit,
    col_high = opt$col_high,
    col_low = opt$col_low,
    roc_cols = paste(roc_colors, collapse = ","),
    roc_times = paste(roc_times, collapse = ","),
    roc_pos = opt$roc_pos,
    km_breaks = opt$km_breaks,
    seed = opt$seed,
    timeout_seconds = opt$timeout_seconds
  )
)

log_info("==========================================")
log_info("External Model Validation")
log_info("==========================================")
log_info(paste("Expression file:", analysis_config$exp_file))
log_info(paste("Clinical file:", analysis_config$cli_file))
log_info(paste("Model file:", analysis_config$model_file))
log_info(paste("Output directory:", analysis_config$output_paths$root))
log_info(paste("Time unit:", analysis_config$time_unit))
log_info(paste("Seed:", opt$seed))
log_info(paste("Timeout seconds:", opt$timeout_seconds))

withCallingHandlers(
  tryCatch(
    {
      run_external_model_validation(analysis_config)
      quit(status = 0)
    },
    error = function(e) {
      metadata_dir <- analysis_config$output_paths$root
      if (!file.exists(file.path(metadata_dir, "run_parameters.tsv")))
        save_run_parameters(analysis_config$run_parameters, metadata_dir)
      if (!file.exists(file.path(metadata_dir, "session_info.txt")))
        save_session_info(metadata_dir)
      log_error(conditionMessage(e))
      quit(status = 1)
    }
  ),
  warning = function(w) {
    log_warn(conditionMessage(w))
    invokeRestart("muffleWarning")
  }
)
