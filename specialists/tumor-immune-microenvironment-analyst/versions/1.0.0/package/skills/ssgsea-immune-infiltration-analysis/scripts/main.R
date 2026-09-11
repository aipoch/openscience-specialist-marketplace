#!/usr/bin/env Rscript
get_script_dir <- function() {
  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_arg_idx <- which(grepl("^--file=", cmd_args))
  if (length(file_arg_idx) > 0) {
    arg0 <- sub("^--file=", "", cmd_args[file_arg_idx[1]])
    if (!is.na(arg0) && nzchar(arg0) && file.exists(arg0)) {
      return(dirname(normalizePath(arg0, winslash = "/", mustWork = TRUE)))
    }
  }
  normalizePath(".", winslash = "/", mustWork = FALSE)
}

suppressPackageStartupMessages(library(optparse))

script_dir <- get_script_dir()
source(file.path(script_dir, "utils.R"))
source(file.path(script_dir, "cli_options.R"))
source(file.path(script_dir, "io.R"))
source(file.path(script_dir, "functions.R"))
source(file.path(script_dir, "visualization.R"))
source(file.path(script_dir, "recording.R"))
source(file.path(script_dir, "run_analysis.R"))

check_required_packages(c("optparse", "GSVA", "dplyr", "tidyr", "tibble", "ggplot2", "jsonlite", "RColorBrewer", "pheatmap"))
suppressPackageStartupMessages({
  library(GSVA)
  library(dplyr)
  library(tidyr)
  library(tibble)
  library(ggplot2)
  library(jsonlite)
  library(RColorBrewer)
  library(pheatmap)
  library(grid)
})
opt <- parse_main_args(script_dir)

tryCatch(
  {
    run_analysis(opt)
    log_info("Analysis completed successfully.", opt$verbose)
    quit(status = 0)
  },
  error = function(e) {
    err_msg <- conditionMessage(e)
    if (grepl("time limit", err_msg, ignore.case = TRUE)) {
      err_msg <- paste("SKILL_TIMEOUT:", err_msg)
    }
    log_message("ERROR", err_msg, TRUE)
    quit(status = 1)
  }
)
