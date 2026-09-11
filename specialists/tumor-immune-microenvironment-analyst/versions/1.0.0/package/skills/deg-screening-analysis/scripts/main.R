#!/usr/bin/env Rscript
suppressPackageStartupMessages(library(optparse))

get_script_dir <- function() {
  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_arg_idx <- which(grepl("^--file=", cmd_args))
  if (length(file_arg_idx) > 0) {
    arg0 <- sub("^--file=", "", cmd_args[file_arg_idx])
    if (!is.na(arg0) && nzchar(arg0) && file.exists(arg0)) return(dirname(normalizePath(arg0)))
  }
  "."
}

main <- function() {
  script_dir <- get_script_dir()
  source(file.path(script_dir, "utils.R"))
  source(file.path(script_dir, "functions.R"))
  source(file.path(script_dir, "diff_methods.R"))
  source(file.path(script_dir, "diff_visualization.R"))
  source(file.path(script_dir, "run_analysis.R"))

  option_list <- list(
    make_option(c("-i", "--input_file"), type = "character", help = "Expression matrix CSV [required]"),
    make_option(c("-g", "--group_file"), type = "character", help = "Group CSV with sample/group columns [required]"),
    make_option(c("-o", "--output_dir"), type = "character", default = "./DEG", help = "Output directory [default %default]"),
    make_option(c("--case"), type = "character", help = "Case group name [required]"),
    make_option(c("--control"), type = "character", help = "Control group name [required]"),
    make_option(c("-m", "--diff_method"), type = "character", default = "limma", help = "Differential method [default %default]"),
    make_option(c("-p", "--p_threshold"), type = "numeric", default = 0.05, help = "P-value threshold [default %default]"),
    make_option(c("-f", "--logfc_threshold"), type = "numeric", default = 1, help = "Absolute logFC threshold [default %default]"),
    make_option(c("--top_n"), type = "integer", default = 5, help = "Top N up/down genes for heatmap [default %default]"),
    make_option(c("--p_type"), type = "character", default = "p.adj", help = "P-value type: p or p.adj [default %default]"),
    make_option(c("--run_plots"), type = "logical", default = TRUE, help = "Generate plots [default %default]"),
    make_option(c("--timeout_seconds"), type = "integer", default = 3600, help = "Timeout in seconds [default %default]"),
    make_option(c("-s", "--seed"), type = "integer", default = 42, help = "Random seed [default %default]")
  )

  parser <- OptionParser(option_list = option_list, description = "RNA-seq Differential Expression Analysis")
  opt <- parse_args(parser)
  required <- c("input_file", "group_file", "case", "control")
  missing_args <- required[vapply(required, function(x) is.null(opt[[x]]) || !nzchar(opt[[x]]), logical(1))]
  if (length(missing_args) > 0) skill_stop("SKILL_INVALID_PARAMETER", paste("Missing required arguments:", paste(missing_args, collapse = ", ")))
  if (!(opt$p_type %in% c("p", "p.adj"))) skill_stop("SKILL_INVALID_PARAMETER", "p_type must be one of: p, p.adj")

  set.seed(opt$seed)
  check_file_exists(opt$input_file, "input_file")
  check_file_exists(opt$group_file, "group_file")
  validate_thresholds(opt$p_threshold, opt$logfc_threshold, opt$top_n, opt$timeout_seconds)

  log_info("==========================================")
  log_info("Differential Expression Analysis")
  log_info("==========================================")
  log_info(paste("Method:", opt$diff_method))
  log_info(paste("Input:", opt$input_file))
  log_info(paste("Group:", opt$group_file))
  log_info(paste("Case:", opt$case))
  log_info(paste("Control:", opt$control))
  log_info(paste("Output:", opt$output_dir))
  log_info(paste("Seed:", opt$seed))

  run_diff_analysis(opt$input_file, opt$group_file, opt$output_dir, opt$case, opt$control,
                    opt$diff_method, opt$p_threshold, opt$logfc_threshold, opt$top_n,
                    identical(opt$p_type, "p.adj"), opt$run_plots, opt$timeout_seconds)
}

withCallingHandlers(
  tryCatch(
    { main(); quit(save = "no", status = 0) },
    error = function(e) { message(conditionMessage(e)); quit(save = "no", status = 1) }
  ),
  warning = function(w) { message(conditionMessage(w)); invokeRestart("muffleWarning") }
)
