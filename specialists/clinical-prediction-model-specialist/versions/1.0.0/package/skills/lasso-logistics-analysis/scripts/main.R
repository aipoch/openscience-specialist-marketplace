#!/usr/bin/env Rscript

REQUIRED_PACKAGES <- c("optparse", "glmnet")

check_required_packages <- function(packages) {
  missing_packages <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing_packages) > 0L) {
    stop(sprintf(
      "SKILL_DEPENDENCY_MISSING: Install required packages before running: %s",
      paste(missing_packages, collapse = ", ")
    ), call. = FALSE)
  }
}

get_script_dir <- function() {
  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_arg_idx <- which(grepl("^--file=", cmd_args))
  if (length(file_arg_idx) > 0L) {
    arg0 <- sub("^--file=", "", cmd_args[file_arg_idx])
    if (!is.na(arg0) && nzchar(arg0) && file.exists(arg0))
      return(dirname(normalizePath(arg0)))
  }
  "."
}

check_required_packages(REQUIRED_PACKAGES)
suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(glmnet))

script_dir <- get_script_dir()
source(file.path(script_dir, "utils.R"))
source(file.path(script_dir, "runtime_utils.R"))
source(file.path(script_dir, "cli_utils.R"))
source(file.path(script_dir, "io.R"))
source(file.path(script_dir, "modeling.R"))
source(file.path(script_dir, "plotting.R"))
source(file.path(script_dir, "run_analysis.R"))

main <- function() {
  tryCatch({
    opt <- parse_cli_options()
    log_run_header(opt)
    result <- run_analysis(opt)
    message(format_log("INFO", "Analysis completed"))
    message(format_log("INFO", paste("All results saved to:", opt$output_dir)))
    invisible(result)
  }, error = function(e) {
    message(format_log("ERROR", normalize_runtime_error(e)))
    quit(status = 1)
  }, warning = function(w) {
    message(format_log("WARN", conditionMessage(w)))
  })
}

main()
