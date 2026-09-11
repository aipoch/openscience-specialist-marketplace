#!/usr/bin/env Rscript
configure_runtime_threads <- function() {
  Sys.setenv(
    OMP_NUM_THREADS = "1",
    OMP_THREAD_LIMIT = "1",
    OPENBLAS_NUM_THREADS = "1",
    MKL_NUM_THREADS = "1",
    BLIS_NUM_THREADS = "1",
    GOTO_NUM_THREADS = "1",
    VECLIB_MAXIMUM_THREADS = "1",
    NUMEXPR_NUM_THREADS = "1",
    RCPP_PARALLEL_NUM_THREADS = "1"
  )
}

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

configure_runtime_threads()
suppressPackageStartupMessages(library(optparse))
script_dir <- get_script_dir()
source(file.path(script_dir, "utils.R"))
source(file.path(script_dir, "cli_options.R"))
source(file.path(script_dir, "io.R"))
source(file.path(script_dir, "functions.R"))
source(file.path(script_dir, "deconvolution.R"))
source(file.path(script_dir, "visualization.R"))
source(file.path(script_dir, "recording_helpers.R"))
source(file.path(script_dir, "recording_reports.R"))
source(file.path(script_dir, "recording.R"))
source(file.path(script_dir, "run_analysis.R"))

check_required_packages(c("optparse", "preprocessCore", "e1071", "ggplot2", "pheatmap"))
suppressPackageStartupMessages({
  library(preprocessCore)
  library(parallel)
  library(e1071)
  library(ggplot2)
  library(pheatmap)
  library(grid)
})
opt <- parse_main_args(script_dir)
run_start_time <- Sys.time()
run_start_proc <- proc.time()

tryCatch(
  {
    run_analysis(opt, start_time = run_start_time, start_proc = run_start_proc)
    log_info("CIBERSORT-like immune infiltration analysis completed successfully.", opt$verbose)
    quit(status = 0)
  },
  error = function(e) {
    err_msg <- conditionMessage(e)
    if (grepl("time limit", err_msg, ignore.case = TRUE)) {
      err_msg <- paste("SKILL_TIMEOUT:", err_msg)
    }
    failure_notes <- character(0)
    if (!is.null(opt$perm) && identical(opt$perm, 0L)) {
      failure_notes <- c(failure_notes, "perm=0 disables empirical p-value estimation; P-value columns would be recorded as NA on a successful run.")
    }
    runtime_info <- capture_runtime_info(run_start_time, run_start_proc, notes = failure_notes)
    try(write_failure_run_record(opt$output_dir, opt, runtime_info, err_msg), silent = TRUE)
    try(write_failure_manifest(opt$output_dir, opt, runtime_info, err_msg), silent = TRUE)
    log_message("ERROR", err_msg, TRUE)
    quit(status = 1)
  }
)
