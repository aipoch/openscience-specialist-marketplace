#!/usr/bin/env Rscript

REQUIRED_PACKAGES <- c("optparse", "survival", "rms", "qs", "openxlsx")

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

bootstrap_log_error <- function(msg) {
  line <- sprintf("[ERROR] %s | %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), msg)
  cat(line, "\n", sep = "", file = stderr())
}

source(file.path(script_dir, "utils.R"))
source(file.path(script_dir, "functions.R"))
source(file.path(script_dir, "run_analysis.R"))

create_core_option_list <- function() {
  list(
    make_option(c("-d", "--data_file"), type = "character", default = NULL,
                help = "Clinical data file in CSV format [required]"),
    make_option(c("-f", "--features"), type = "character", default = NULL,
                help = "Comma-separated model features [required]"),
    make_option(c("-t", "--time_col"), type = "character", default = "futime",
                help = "Survival time column [default: %default]"),
    make_option(c("-e", "--event_col"), type = "character", default = "fustat",
                help = "Event indicator column [default: %default]"),
    make_option(c("-y", "--years"), type = "character", default = "1,2,3",
                help = "Prediction horizons in time-column units [default: %default]"),
    make_option(c("-b", "--bootstrap_reps"), type = "integer", default = 1000,
                help = "Bootstrap replications [default: %default]"),
    make_option(c("-o", "--output_dir"), type = "character", default = "./output/",
                help = "Output directory [default: %default]"),
    make_option(c("--overwrite"), action = "store_true", default = FALSE,
                help = "Allow writing into a non-empty output directory [default: %default]"),
    make_option(c("-s", "--seed"), type = "integer", default = 42,
                help = "Random seed [default: %default]"),
    make_option(c("-T", "--timeout_seconds"), type = "integer", default = 0,
                help = "Elapsed time limit in seconds; 0 disables timeout [default: %default]")
  )
}

create_plot_option_list <- function() {
  list(
    make_option(c("--plot_width"), type = "double", default = 6,
                help = "Plot width in inches [default: %default]"),
    make_option(c("--plot_height"), type = "double", default = 6,
                help = "Plot height in inches [default: %default]"),
    make_option(c("--font_family"), type = "character", default = "sans",
                help = "PDF font family [default: %default]"),
    make_option(c("--line_width"), type = "double", default = 1.5,
                help = "Calibration curve line width [default: %default]"),
    make_option(c("--colors"), type = "character", default = "#0073C2,#EFC000,#868686,#CD534C,#7AA6DD",
                help = "Comma-separated curve colors [default: %default]"),
    make_option(c("--plot_title"), type = "character", default = "Calibration Curve",
                help = "Plot title [default: %default]"),
    make_option(c("--base_cex"), type = "double", default = 0.9,
                help = "Base text-size multiplier [default: %default]")
  )
}

create_parser <- function() {
  OptionParser(
    description = "Calibration curve analysis for survival models",
    option_list = c(create_core_option_list(), create_plot_option_list())
  )
}

withCallingHandlers(
  tryCatch(
    {
      missing_packages <- REQUIRED_PACKAGES[!vapply(REQUIRED_PACKAGES, requireNamespace, logical(1), quietly = TRUE)]
      if (length(missing_packages) > 0) {
        stop_skill(
          "SKILL_PACKAGE_NOT_FOUND",
          paste("Required packages are not installed:", paste(missing_packages, collapse = ", "))
        )
      }

      suppressPackageStartupMessages(library(optparse))

      options <- parse_args(create_parser())
      validate_required_value(options$data_file, "--data_file")
      validate_required_value(options$features, "--features")
      apply_time_limit(options$timeout_seconds)
      set.seed(options$seed)
      run_analysis(options)
    },
    error = function(e) {
      if (exists("log_error", mode = "function", inherits = TRUE)) {
        log_error(conditionMessage(e))
      } else {
        bootstrap_log_error(conditionMessage(e))
      }
      quit(status = 1)
    }
  ),
  warning = function(w) {
    log_warn(conditionMessage(w))
    invokeRestart("muffleWarning")
  }
)
