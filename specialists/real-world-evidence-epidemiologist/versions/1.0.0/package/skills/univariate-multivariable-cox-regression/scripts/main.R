#!/usr/bin/env Rscript

if (!requireNamespace("optparse", quietly = TRUE)) {
  stop("SKILL_PACKAGE_NOT_FOUND: Required package is not installed: optparse", call. = FALSE)
}

suppressPackageStartupMessages(library(optparse))

ANALYZE_REQUIRED_PACKAGES <- c("survival", "openxlsx")
PLOT_REQUIRED_PACKAGES <- c("forestplot")
PLOT_EXCEL_REQUIRED_PACKAGES <- c("readxl")

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
source(file.path(script_dir, "cox_helpers.R"))
source(file.path(script_dir, "functions.R"))
source(file.path(script_dir, "plotting.R"))
source(file.path(script_dir, "run_analysis.R"))

extract_cli_args <- function() {
  cmd_args <- commandArgs(trailingOnly = FALSE)
  args_idx <- match("--args", cmd_args)
  if (is.na(args_idx) || args_idx >= length(cmd_args))
    return(character(0))
  cmd_args[(args_idx + 1L):length(cmd_args)]
}

check_command_packages <- function(command, options) {
  if (identical(command, "analyze")) {
    check_required_packages(ANALYZE_REQUIRED_PACKAGES)
    return(invisible(NULL))
  }

  check_required_packages(PLOT_REQUIRED_PACKAGES)
  if (!is.null(options$data_file) && nzchar(options$data_file) &&
      tolower(tools::file_ext(options$data_file)) %in% c("xlsx", "xls")) {
    check_required_packages(PLOT_EXCEL_REQUIRED_PACKAGES)
  }
  invisible(NULL)
}

raw_args <- extract_cli_args()

if (length(raw_args) == 0 || raw_args[1] %in% c("--help", "-h", "help")) {
  print_main_help()
  quit(status = 0)
}

command <- raw_args[1]
command_args <- raw_args[-1]

parser <- switch(
  command,
  analyze = create_analyze_parser(),
  `forest-plot` = create_plot_parser("Univariate Cox forest plot"),
  `multi-forest-plot` = create_plot_parser("Multivariable Cox forest plot"),
  NULL
)

if (is.null(parser)) {
  log_error(sprintf("SKILL_INVALID_PARAMETER: Unknown command: %s", command))
  print_main_help()
  quit(status = 1)
}

options <- parse_args(parser, args = command_args)

set.seed(options$seed)
apply_time_limit(options$timeout_seconds)
check_command_packages(command, options)

withCallingHandlers(
  tryCatch(
    {
      run_command(command, options)
      quit(status = 0)
    },
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
