#!/usr/bin/env Rscript

REQUIRED_PACKAGES <- c("optparse", "pROC")
missing_packages <- REQUIRED_PACKAGES[!vapply(REQUIRED_PACKAGES, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0) {
  stop(sprintf("SKILL_PACKAGE_NOT_FOUND: Required packages are not installed: %s", paste(missing_packages, collapse = ", ")), call. = FALSE)
}

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
source(file.path(script_dir, "validation.R"))
source(file.path(script_dir, "cli.R"))
source(file.path(script_dir, "io.R"))
source(file.path(script_dir, "functions.R"))
source(file.path(script_dir, "plotting.R"))
source(file.path(script_dir, "run_analysis.R"))

parser <- create_parser()
options <- parse_args(parser)

validate_required_value(options$expression_file, "--expression_file")
validate_required_value(options$group_file, "--group_file")
validate_required_value(options$marker_genes, "--marker_genes")
validate_required_value(options$case_group, "--case_group")
validate_choice(options$legend_position, "--legend_position", c("bottomright", "bottomleft", "topright", "topleft", "right", "left", "top", "bottom", "center"))
apply_time_limit(options$timeout_seconds)
set.seed(options$seed)

withCallingHandlers(
  tryCatch(
    run_analysis(options),
    error = function(e) {
      log_error(conditionMessage(e))
      quit(status = 1)
    }
  ),
  warning = function(w) {
    log_warn(conditionMessage(w))
    invokeRestart("muffleWarning")
  }
)
