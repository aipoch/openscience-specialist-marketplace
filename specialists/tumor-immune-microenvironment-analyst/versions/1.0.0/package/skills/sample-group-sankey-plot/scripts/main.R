#!/usr/bin/env Rscript

if (!requireNamespace("optparse", quietly = TRUE)) {
  cat(
    paste0(
      "[0000-00-00 00:00:00] ERROR: SKILL_DEPENDENCY_MISSING: ",
      "optparse is required. Install with: install.packages('optparse')\n"
    ),
    file = stderr()
  )
  quit(save = "no", status = 1)
}

suppressPackageStartupMessages(library(optparse))

get_script_dir <- function() {
  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_arg_idx <- which(grepl("^--file=", cmd_args))
  if (length(file_arg_idx) > 0) {
    arg0 <- sub("^--file=", "", cmd_args[file_arg_idx][1])
    if (!is.na(arg0) && nzchar(arg0) && file.exists(arg0)) {
      return(dirname(normalizePath(arg0)))
    }
  }
  normalizePath(".")
}

script_dir <- get_script_dir()
source(file.path(script_dir, "utils.R"))
source(file.path(script_dir, "functions.R"))
source(file.path(script_dir, "run_analysis.R"))

option_list <- list(
  make_option(c("-i", "--input_file"), type = "character", default = NULL,
              help = "Input CSV/TSV annotation file [required]"),
  make_option(c("-o", "--output_dir"), type = "character", default = "./output/",
              help = "Output directory [default: %default]"),
  make_option(c("-c", "--columns"), type = "character", default = "",
              help = "Comma-separated stage columns to plot [default: all columns]"),
  make_option(c("-p", "--output_prefix"), type = "character", default = "sankey_plot",
              help = "Output file prefix (letters, numbers, dot, underscore, hyphen only) [default: %default]"),
  make_option(c("--width"), type = "double", default = 7,
              help = "Plot width in inches [default: %default]"),
  make_option(c("--height"), type = "double", default = 5,
              help = "Plot height in inches [default: %default]"),
  make_option(c("--alpha"), type = "double", default = 0.5,
              help = "Flow transparency between 0 and 1 [default: %default]"),
  make_option(c("--label_size"), type = "double", default = 4.5,
              help = "Stratum label size [default: %default]"),
  make_option(c("--missing_label"), type = "character", default = "Missing",
              help = "Replacement label for blank or NA values [default: %default]"),
  make_option(c("--title"), type = "character", default = "",
              help = "Optional plot title [default: empty]"),
  make_option(c("-s", "--seed"), type = "integer", default = 42,
              help = "Random seed for reproducibility [default: %default]"),
  make_option(c("--timeout"), type = "integer", default = 3600,
              help = "Maximum allowed elapsed runtime in seconds; use 0 to disable [default: %default]")
)

parser <- OptionParser(
  option_list = option_list,
  description = "Generate Sankey/alluvial plots from sample annotation columns."
)
opt <- parse_args(parser)

if (is.null(opt$input_file) || !nzchar(trimws(opt$input_file))) {
  stop_skill("SKILL_INVALID_PARAMETER", "--input_file is required")
}

if (!is.finite(opt$width) || opt$width <= 0) {
  stop_skill("SKILL_INVALID_PARAMETER", "--width must be a positive number")
}

if (!is.finite(opt$height) || opt$height <= 0) {
  stop_skill("SKILL_INVALID_PARAMETER", "--height must be a positive number")
}

if (!is.finite(opt$alpha) || opt$alpha < 0 || opt$alpha > 1) {
  stop_skill("SKILL_INVALID_PARAMETER", "--alpha must be between 0 and 1")
}

if (!is.finite(opt$label_size) || opt$label_size <= 0) {
  stop_skill("SKILL_INVALID_PARAMETER", "--label_size must be a positive number")
}

if (!is.numeric(opt$seed) || is.na(opt$seed)) {
  stop_skill("SKILL_INVALID_PARAMETER", "--seed must be an integer")
}

if (!is.numeric(opt$timeout) || is.na(opt$timeout) || opt$timeout < 0) {
  stop_skill("SKILL_INVALID_PARAMETER", "--timeout must be a non-negative integer")
}

validate_output_prefix(opt$output_prefix)
set.seed(opt$seed)

tryCatch(
  {
    if (opt$timeout > 0) {
      setTimeLimit(elapsed = opt$timeout, transient = FALSE)
      on.exit(setTimeLimit(cpu = Inf, elapsed = Inf, transient = FALSE), add = TRUE)
    }

    log_info("Starting analysis")
    log_info(sprintf("Input file: %s", opt$input_file))
    log_info(sprintf("Output directory: %s", opt$output_dir))
    log_info(sprintf("Seed: %s", opt$seed))
    log_info(sprintf("Timeout (seconds): %s", opt$timeout))

    withCallingHandlers(
      {
        run_analysis(
          input_file = opt$input_file,
          output_dir = opt$output_dir,
          columns = opt$columns,
          output_prefix = opt$output_prefix,
          width = opt$width,
          height = opt$height,
          alpha = opt$alpha,
          label_size = opt$label_size,
          missing_label = opt$missing_label,
          title = opt$title,
          seed = opt$seed
        )
        log_info("Analysis complete")
        quit(save = "no", status = 0)
      },
      warning = function(w) {
        log_warn(conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    )
  },
  error = function(e) {
    log_error(conditionMessage(e))
    quit(save = "no", status = 1)
  }
)
