#!/usr/bin/env Rscript
REQUIRED_PACKAGES <- c(glmnet = NA_character_)
if (!requireNamespace("optparse", quietly = TRUE)) {
  stop(
    "SKILL_DEPENDENCY_MISSING: Package 'optparse' is required. Install with install.packages('optparse')",
    call. = FALSE
  )
}
suppressPackageStartupMessages(library(optparse))

get_script_dir <- function() {
  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_arg_idx <- which(grepl("^--file=", cmd_args))
  if (length(file_arg_idx) > 0L) {
    arg0 <- sub("^--file=", "", cmd_args[file_arg_idx])
    if (!is.na(arg0) && nzchar(arg0) && file.exists(arg0)) {
      return(dirname(normalizePath(arg0)))
    }
  }
  "."
}

script_dir <- get_script_dir()
source(file.path(script_dir, "utils.R"))
source(file.path(script_dir, "validation.R"))
source(file.path(script_dir, "io.R"))
source(file.path(script_dir, "functions.R"))
source(file.path(script_dir, "modeling.R"))
source(file.path(script_dir, "output.R"))
source(file.path(script_dir, "run_analysis.R"))

option_list <- list(
  make_option(c("-i", "--input_file"), type = "character", default = NULL, help = "Expression matrix file (genes x samples) [required]"),
  make_option(c("-g", "--group_file"), type = "character", default = NULL, help = "Group file with sample and group columns [required]"),
  make_option(c("-f", "--feature_file"), type = "character", default = NULL, help = "Optional feature list file [default %default]"),
  make_option(c("-c", "--case_group"), type = "character", default = "case", help = "Positive class label [default %default]"),
  make_option(c("-d", "--control_group"), type = "character", default = "control", help = "Negative class label [default %default]"),
  make_option(c("-a", "--alpha"), type = "character", default = "0.5", help = "Elastic net alpha between 0 and 1, or 'auto' [default %default]"),
  make_option(c("--alpha_grid"), type = "character", default = "0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1", help = "Comma-separated alpha candidates used when --alpha auto [default %default]"),
  make_option(c("-n", "--nfolds"), type = "integer", default = 5, help = "Cross-validation folds [default %default]"),
  make_option(c("-l", "--lambda_choice"), type = "character", default = "lambda.min", help = "lambda.min or lambda.1se [default %default]"),
  make_option(c("-z", "--standardize"), type = "logical", default = TRUE, help = "Whether glmnet standardizes features [default %default]"),
  make_option(c("-t", "--timeout_seconds"), type = "integer", default = 600, help = "Elapsed timeout in seconds [default %default]"),
  make_option(c("-o", "--output_dir"), type = "character", default = "./output/", help = "Output directory [default %default]"),
  make_option(c("-s", "--seed"), type = "integer", default = 42, help = "Random seed [default %default]")
)

run_main <- function() {
  parser <- OptionParser(option_list = option_list, description = "Elastic net feature selection for binary expression data")
  opt <- parse_args(parser)
  save_runtime_artifacts_safely <- function(output_dir) {
    if (is.null(output_dir) || !nzchar(output_dir)) {
      return(invisible(FALSE))
    }
    tryCatch({
      save_session_info(output_dir)
      TRUE
    }, error = function(e) FALSE)
  }

  tryCatch({
    if (is.null(opt$input_file) || is.null(opt$group_file)) {
      print_help(parser)
      stop("SKILL_INVALID_PARAMETER: --input_file and --group_file are required", call. = FALSE)
    }
    validate_cli_options(opt)
    check_runtime_packages(REQUIRED_PACKAGES)
    ensure_dir(opt$output_dir)
    reset_warning_state()
    set.seed(opt$seed)
    apply_timeout(opt$timeout_seconds)
    log_cli_context(opt)

    result <- withCallingHandlers(run_analysis(opt), warning = function(w) {
      log_warn(conditionMessage(w))
      invokeRestart("muffleWarning")
    })
    save_session_info(opt$output_dir)
    release_timeout()
    log_info("Analysis completed.")
    log_info(sprintf("Output files: %s", paste(c(result$output_files, "session_info.txt"), collapse = ", ")))
    log_info(sprintf("GC snapshot (Ncells): %s", result$gc_snapshot$ncells))
    log_info(sprintf("GC snapshot (Vcells): %s", result$gc_snapshot$vcells))
  }, error = function(e) {
    release_timeout()
    save_runtime_artifacts_safely(opt$output_dir)
    log_error(classify_runtime_error(e))
    quit(status = 1)
  }, warning = function(w) {
    log_warn(conditionMessage(w))
  })
}

run_main()
quit(status = 0)
