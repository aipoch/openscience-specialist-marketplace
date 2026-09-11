#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(optparse))

get_script_dir <- function() {
  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", cmd_args, value = TRUE)
  if (length(file_arg) > 0) {
    script_path <- sub("^--file=", "", file_arg[[1]])
    return(dirname(normalizePath(script_path, winslash = "/", mustWork = FALSE)))
  }
  "."
}

script_dir <- get_script_dir()
source(file.path(script_dir, "utils.R"))
source(file.path(script_dir, "recording.R"))
source(file.path(script_dir, "io.R"))
source(file.path(script_dir, "functions.R"))
source(file.path(script_dir, "visualization.R"))
source(file.path(script_dir, "cli_options.R"))
source(file.path(script_dir, "run_analysis.R"))

required_packages <- c("optparse", "estimate", "pheatmap")
package_min_versions <- c(ggplot2 = "3.4.0")
opt <- parse_args(build_option_parser())

main <- function(opt) {
  opt <- validate_cli_options(opt)
  extra_packages <- if (!is.null(opt$group_file) && nzchar(opt$group_file)) c("ggplot2", "ggpubr", "tidyr", "dplyr") else character(0)
  check_required_packages(c(required_packages, extra_packages), min_versions = package_min_versions)
  suppressPackageStartupMessages(library(estimate))

  ensure_dir(opt$output_dir)
  set.seed(opt$seed)
  enable_timeout(opt$timeout_seconds)
  if (!is.null(opt$timeout_seconds) && opt$timeout_seconds > 0) {
    on.exit(disable_timeout(), add = TRUE)
  }

  start_time <- Sys.time()
  start_proc <- proc.time()

  log_info("Starting ESTIMATE immune score analysis.")
  log_info(sprintf("Output directory: %s", normalizePath(opt$output_dir, winslash = "/", mustWork = FALSE)))
  log_info(sprintf("Seed: %s", opt$seed))

  analysis_result <- NULL
  run_error <- NULL

  tryCatch(
    {
      analysis_result <- run_analysis(opt)
    },
    error = function(e) {
      run_error <<- e
    }
  )

  end_time <- Sys.time()
  end_proc <- proc.time()
  runtime_info <- list(
    start_time = format(start_time, "%Y-%m-%d %H:%M:%S"),
    end_time = format(end_time, "%Y-%m-%d %H:%M:%S"),
    elapsed_seconds = as.numeric(difftime(end_time, start_time, units = "secs")),
    user_cpu_seconds = unname((end_proc - start_proc)[["user.self"]]),
    system_cpu_seconds = unname((end_proc - start_proc)[["sys.self"]]),
    gc_snapshot = capture.output(gc())
  )

  if (is.null(run_error)) {
    manifest_file <- write_output_manifest(opt$output_dir, analysis_result$output_items, opt, runtime_info, status = "success")
    record_file <- write_run_record(
      opt$output_dir,
      opt,
      runtime_info,
      analysis_result$input_info,
      analysis_result$output_items,
      status = "success"
    )

    log_info(sprintf("Score table: %s", analysis_result$score_table))
    log_info(sprintf("Output manifest: %s", manifest_file))
    log_info(sprintf("Run record: %s", record_file))
    return(invisible(NULL))
  }

  normalized_error <- normalize_error_message(conditionMessage(run_error), opt$timeout_seconds)
  partial_items <- collect_existing_output_items(opt$output_dir, opt)
  partial_input_info <- collect_partial_input_info(opt)
  manifest_file <- write_output_manifest(
    opt$output_dir,
    partial_items,
    opt,
    runtime_info,
    status = "failed",
    error_message = normalized_error
  )
  record_file <- write_run_record(
    opt$output_dir,
    opt,
    runtime_info,
    partial_input_info,
    partial_items,
    status = "failed",
    error_message = normalized_error
  )
  log_info(sprintf("Failure manifest: %s", manifest_file))
  log_info(sprintf("Failure run record: %s", record_file))
  stop(normalized_error, call. = FALSE)
}

tryCatch(
  {
    main(opt)
    log_info("ESTIMATE immune score analysis completed successfully.")
  },
  error = function(e) {
    message(sprintf("[ERROR] %s | %s", timestamp_now(), normalize_error_message(conditionMessage(e), opt$timeout_seconds)))
    quit(status = 1)
  }
)
