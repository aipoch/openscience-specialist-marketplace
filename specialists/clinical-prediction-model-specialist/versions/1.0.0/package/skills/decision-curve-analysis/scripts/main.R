#!/usr/bin/env Rscript

REQUIRED_PACKAGES <- c("optparse", "rmda")

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
                help = "Clinical CSV file [required]"),
    make_option(c("--outcome_col"), type = "character", default = "fustat",
                help = "Binary outcome column [default: %default]"),
    make_option(c("--predictor_col"), type = "character", default = "riskScore",
                help = "Numeric predictor column [default: %default]"),
    make_option(c("--study_design"), type = "character", default = "case-control",
                help = "Study design: case-control or cohort [default: %default]"),
    make_option(c("--population_prevalence"), type = "double", default = 0.3,
                help = "Population prevalence for case-control design [default: %default]"),
    make_option(c("--threshold_by"), type = "double", default = 0.01,
                help = "Threshold step size [default: %default]"),
    make_option(c("--confidence_level"), type = "double", default = 0.95,
                help = "Confidence level for DCA [default: %default]"),
    make_option(c("--population_size"), type = "integer", default = 1000,
                help = "Population size for clinical-impact plot [default: %default]"),
    make_option(c("--n_cost_benefits"), type = "integer", default = 8,
                help = "Cost-benefit labels in clinical-impact plot [default: %default]"),
    make_option(c("--show_confidence_intervals"), action = "store_true", default = FALSE,
                help = "Show confidence intervals on the decision curve [default: %default]"),
    make_option(c("--standardize_net_benefit"), action = "store_true", default = FALSE,
                help = "Use standardized net benefit in summary and decision curve [default: %default]")
  )
}

create_plot_option_list <- function() {
  list(
    make_option(c("--decision_curve_color"), type = "character", default = "#E64B35",
                help = "Decision-curve color [default: %default]"),
    make_option(c("--impact_colors"), type = "character", default = "#E64B35,#4DBBD5",
                help = "Two clinical-impact colors [default: %default]"),
    make_option(c("--plot_width"), type = "double", default = 6,
                help = "PDF width in inches [default: %default]"),
    make_option(c("--plot_height"), type = "double", default = 5.5,
                help = "PDF height in inches [default: %default]"),
    make_option(c("--font_family"), type = "character", default = "sans",
                help = "PDF font family [default: %default]"),
    make_option(c("--plot_title"), type = "character", default = "Decision Curve Analysis",
                help = "Decision-curve plot title [default: %default]"),
    make_option(c("--base_cex"), type = "double", default = 0.9,
                help = "Base text-size multiplier [default: %default]"),
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

create_parser <- function() {
  optparse::OptionParser(
    description = "Decision curve analysis for binary prediction models",
    option_list = c(create_core_option_list(), create_plot_option_list())
  )
}

withCallingHandlers(
  tryCatch(
    {
      missing_packages <- REQUIRED_PACKAGES[!vapply(REQUIRED_PACKAGES, requireNamespace, logical(1), quietly = TRUE)]
      if (length(missing_packages) > 0)
        stop_skill("SKILL_PACKAGE_NOT_FOUND", paste("Required packages are not installed:", paste(missing_packages, collapse = ", ")))

      suppressPackageStartupMessages(library(optparse))
      options <- parse_args(create_parser())
      validate_required_value(options$data_file, "--data_file")
      validate_choice(options$study_design, "--study_design", c("case-control", "cohort"))
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
