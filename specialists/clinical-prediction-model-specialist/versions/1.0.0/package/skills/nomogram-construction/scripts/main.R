#!/usr/bin/env Rscript

required_packages <- c("optparse", "survival", "rms", "openxlsx", "qs")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0) {
  stop(
    sprintf("SKILL_PACKAGE_NOT_FOUND: Required packages are not installed: %s", paste(missing_packages, collapse = ", ")),
    call. = FALSE
  )
}

suppressPackageStartupMessages(library(optparse))

get_script_dir <- function() {
  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_arg_idx <- which(grepl("^--file=", cmd_args))
  if (length(file_arg_idx) > 0) {
    arg0 <- sub("^--file=", "", cmd_args[file_arg_idx[1]])
    if (!is.na(arg0) && nzchar(arg0) && file.exists(arg0)) return(dirname(normalizePath(arg0)))
  }
  normalizePath(".")
}

script_dir <- get_script_dir()
source(file.path(script_dir, "utils.R"))
source(file.path(script_dir, "validation.R"))
source(file.path(script_dir, "io.R"))
source(file.path(script_dir, "functions.R"))
source(file.path(script_dir, "run_analysis.R"))

option_list <- list(
  make_option(c("-m", "--mode"), type = "character", default = "build", help = "Execution mode: build or plot [default: %default]"),
  make_option(c("-d", "--data_file"), type = "character", default = NULL, help = "Clinical CSV file for build mode [required for build]"),
  make_option(c("-f", "--features"), type = "character", default = NULL, help = "Comma-separated prognostic features [required for build]"),
  make_option(c("-t", "--time_col"), type = "character", default = "futime", help = "Time column for survival analysis [default: %default]"),
  make_option(c("-e", "--event_col"), type = "character", default = "fustat", help = "Event column for survival analysis [default: %default]"),
  make_option(c("-y", "--years"), type = "character", default = "1,2,3", help = "Prediction time points in years [default: %default]"),
  make_option(c("-o", "--output_dir"), type = "character", default = "./output/", help = "Output directory for build mode [default: %default]"),
  make_option(c("--overwrite"), action = "store_true", default = FALSE, help = "Allow writing into a non-empty output directory [default: %default]"),
  make_option(c("-n", "--nomo_data_file"), type = "character", default = NULL, help = "Nomogram QS bundle for plot mode [required for plot]"),
  make_option(c("-p", "--plot_save"), type = "character", default = NULL, help = "Output PDF file path for plot mode [required for plot]"),
  make_option(c("-w", "--plot_width"), type = "double", default = 11, help = "Nomogram plot width in inches [default: %default]"),
  make_option(c("-H", "--plot_height"), type = "double", default = 8, help = "Nomogram plot height in inches [default: %default]"),
  make_option(c("-F", "--font_size"), type = "double", default = 8, help = "Font size for nomogram plot [default: %default]"),
  make_option(c("-l", "--line_width"), type = "double", default = 5, help = "Line width for nomogram plot [default: %default]"),
  make_option(c("--font_family"), type = "character", default = "sans", help = "Font family for nomogram plot [default: %default]"),
  make_option(c("-s", "--seed"), type = "integer", default = 42, help = "Random seed for reproducibility [default: %default]"),
  make_option(c("-T", "--timeout_seconds"), type = "integer", default = 0, help = "Elapsed time limit in seconds; 0 disables timeout [default: %default]")
)

options <- parse_args(OptionParser(option_list = option_list, description = "Nomogram construction and plotting"))
validate_choice(options$mode, "--mode", c("build", "plot"))
if (options$mode == "build") { validate_required_value(options$data_file, "--data_file"); validate_required_value(options$features, "--features") } else { validate_required_value(options$nomo_data_file, "--nomo_data_file"); validate_required_value(options$plot_save, "--plot_save") }
apply_time_limit(options$timeout_seconds)
set.seed(options$seed)

withCallingHandlers(
  tryCatch(run_analysis(options), error = function(e) {
    msg <- conditionMessage(e)
    if (grepl("reached .* time limit", msg, ignore.case = TRUE)) msg <- "SKILL_TIMEOUT: Operation exceeded the configured time limit"
    log_error(msg)
    quit(status = 1)
  }),
  warning = function(w) {
    log_warn(conditionMessage(w))
    invokeRestart("muffleWarning")
  }
)
