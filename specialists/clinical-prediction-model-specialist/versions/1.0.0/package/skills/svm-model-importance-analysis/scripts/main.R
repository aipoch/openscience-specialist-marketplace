#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(optparse))

get_script_dir <- function() {
  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", cmd_args, value = TRUE)
  if (length(file_arg) > 0) return(dirname(normalizePath(sub("^--file=", "", file_arg[1]), winslash = "/")))
  "."
}

script_dir <- get_script_dir()
source(file.path(script_dir, "utils.R"))
source(file.path(script_dir, "path_utils.R"))
source(file.path(script_dir, "validation_utils.R"))
source(file.path(script_dir, "core_option_groups.R"))
source(file.path(script_dir, "plot_option_groups.R"))
source(file.path(script_dir, "cli_options.R"))
source(file.path(script_dir, "option_validation.R"))
source(file.path(script_dir, "io.R"))
source(file.path(script_dir, "svm_helpers.R"))
source(file.path(script_dir, "functions.R"))
source(file.path(script_dir, "visualization.R"))
source(file.path(script_dir, "recording.R"))
source(file.path(script_dir, "run_analysis.R"))

main <- function() {
  check_required_packages(c("optparse", "e1071", "ggplot2"))
  parser <- optparse::OptionParser(option_list = build_option_list(), description = "Run SVM-RFE feature ranking with reproducible plots.")
  options <- validate_options(optparse::parse_args(parser), get_skill_root(script_dir))

  ensure_dir(options$output_dir)
  log_info("Starting svm-model-importance-analysis.")
  log_info(sprintf("Output directory: %s", options$output_dir))

  withCallingHandlers({
    set.seed(options$seed)
    set_timeout_limit(options$timeout_seconds)
    run_analysis(options)
    write_session_info(options$output_dir)
    log_info("Analysis completed successfully.")
    0L
  }, warning = function(w) {
    log_warn(conditionMessage(w))
    invokeRestart("muffleWarning")
  })
}

status_code <- tryCatch(main(), error = function(e) {
  log_error(conditionMessage(e))
  1L
})

quit(save = "no", status = status_code)
