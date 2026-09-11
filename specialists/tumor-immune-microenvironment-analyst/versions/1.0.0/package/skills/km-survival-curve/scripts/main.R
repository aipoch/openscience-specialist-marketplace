#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(optparse)
})

get_script_dir <- function() {
  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_arg_idx <- which(grepl("^--file=", cmd_args))
  if (length(file_arg_idx) > 0) {
    arg0 <- sub("^--file=", "", cmd_args[file_arg_idx])
    if (!is.na(arg0) && length(arg0) > 0 && file.exists(arg0)) {
      return(dirname(normalizePath(arg0)))
    }
  }
  return(".")
}

script_dir <- get_script_dir()
source(file.path(script_dir, "utils.R"))
source(file.path(script_dir, "functions.R"))
source(file.path(script_dir, "run_analysis.R"))

skill_fail <- function(message, show_help = FALSE, opt_parser = NULL) {
  cat(paste0(message, "\n"), file = stderr())
  if (show_help && !is.null(opt_parser)) {
    cat("\n", file = stderr())
    print_help(opt_parser)
  }
  quit(save = "no", status = 1)
}

option_list <- list(
  make_option(c("-d", "--input_file"), type = "character",
              help = "Input data file (CSV or tab-delimited TXT/TSV)", metavar = "file"),
  make_option(c("-o", "--output_dir"), type = "character", default = "./KM_Results",
              help = "Output directory [default %default]", metavar = "dir"),
  make_option(c("-t", "--time_col"), type = "character", default = "futime",
              help = "Time column name [default %default]", metavar = "col"),
  make_option(c("-s", "--status_col"), type = "character", default = "fustat",
              help = "Status column name [default %default]", metavar = "col"),
  make_option(c("-r", "--risk_col"), type = "character", default = "risk_group",
              help = "Risk group column name [default %default]", metavar = "col"),
  make_option(c("-u", "--time_unit"), type = "character", default = "year",
              help = "Time unit label: year, month, day [default %default]"),
  make_option(c("--auto_convert_days"), type = "character", default = "true",
              help = "Heuristically convert large time values from days when time_unit is year or month: true or false [default %default]"),
  make_option(c("-m", "--statistics_method"), type = "character", default = "logrank",
              help = "Statistical method: logrank, wald [default %default]"),
  make_option(c("--figure_width"), type = "double", default = 10,
              help = "Figure width in inches [default %default]"),
  make_option(c("--figure_height"), type = "double", default = 7,
              help = "Figure height in inches [default %default]"),
  make_option(c("--figure_family"), type = "character", default = "sans",
              help = "Font family [default %default]"),
  make_option(c("--title_x"), type = "character", default = "Time",
              help = "X-axis title [default %default]"),
  make_option(c("--title_y"), type = "character", default = "Survival probability",
              help = "Y-axis title [default %default]"),
  make_option(c("--title_main"), type = "character", default = "",
              help = "Main plot title [default %default]"),
  make_option(c("--legend_position"), type = "character", default = "top",
              help = "Legend position: top, bottom, left, right, none [default %default]"),
  make_option(c("--legend_show"), type = "character", default = "true",
              help = "Show legend: true or false [default %default]"),
  make_option(c("--legend_title"), type = "character", default = "",
              help = "Legend title [default %default]"),
  make_option(c("--line_type"), type = "character", default = "solid",
              help = "Line type: solid, dashed, dotted, dotdash, longdash, twodash [default %default]"),
  make_option(c("--line_size"), type = "double", default = 1,
              help = "Line size [default %default]"),
  make_option(c("--line_colors"), type = "character", default = paste(DEFAULT_LINE_COLORS, collapse = ","),
              help = "Comma-separated line colors; provide at least one color per retained group [default %default]"),
  make_option(c("--censor_show"), type = "character", default = "true",
              help = "Show censor markers: true or false [default %default]"),
  make_option(c("--censor_size"), type = "double", default = 7,
              help = "Censor marker size [default %default]"),
  make_option(c("--confidence_show"), type = "character", default = "true",
              help = "Show confidence interval: true or false [default %default]"),
  make_option(c("--confidence_alpha"), type = "double", default = 0.2,
              help = "Confidence interval alpha [default %default]"),
  make_option(c("--risk_table_show"), type = "character", default = "true",
              help = "Show risk table: true or false [default %default]"),
  make_option(c("--risk_table_border"), type = "character", default = "true",
              help = "Show risk table border: true or false [default %default]"),
  make_option(c("--risk_table_panel"), type = "character", default = "false",
              help = "Show risk table panel: true or false [default %default]"),
  make_option(c("--risk_table_size"), type = "double", default = 6,
              help = "Risk table font size [default %default]"),
  make_option(c("--axis_title_size"), type = "double", default = 12,
              help = "Axis title font size [default %default]"),
  make_option(c("--axis_text_size"), type = "double", default = 10,
              help = "Axis text font size [default %default]"),
  make_option(c("--legend_text_size"), type = "double", default = 11,
              help = "Legend text font size [default %default]")
)

opt_parser <- OptionParser(
  option_list = option_list,
  description = "Kaplan-Meier Survival Curve Analysis: Generate a Kaplan-Meier survival curve and save a single PDF figure."
)
opt <- parse_args(opt_parser)

if (is.null(opt$input_file)) {
  skill_fail("SKILL_MISSING_INPUT: Input file (-d) option is required", show_help = TRUE, opt_parser = opt_parser)
}

params <- list(
  input_file = opt$input_file,
  output_dir = opt$output_dir,
  time_col = opt$time_col,
  status_col = opt$status_col,
  risk_col = opt$risk_col,
  time_unit = opt$time_unit,
  auto_convert_days = opt$auto_convert_days,
  statistics_method = opt$statistics_method,
  figure_width = opt$figure_width,
  figure_height = opt$figure_height,
  figure_family = opt$figure_family,
  title_x = opt$title_x,
  title_y = opt$title_y,
  title_main = opt$title_main,
  legend_position = opt$legend_position,
  legend_show = opt$legend_show,
  legend_title = opt$legend_title,
  line_type = opt$line_type,
  line_size = opt$line_size,
  line_colors = opt$line_colors,
  censor_show = opt$censor_show,
  censor_size = opt$censor_size,
  confidence_show = opt$confidence_show,
  confidence_alpha = opt$confidence_alpha,
  risk_table_show = opt$risk_table_show,
  risk_table_border = opt$risk_table_border,
  risk_table_panel = opt$risk_table_panel,
  risk_table_size = opt$risk_table_size,
  axis_title_size = opt$axis_title_size,
  axis_text_size = opt$axis_text_size,
  legend_text_size = opt$legend_text_size
)

params <- tryCatch({
  validate_parameters_opt(params)
}, error = function(e) {
  skill_fail(e$message, show_help = TRUE, opt_parser = opt_parser)
})

tryCatch({
  invisible(km_analysis(params))
  save_session_info(params$output_dir)
}, error = function(e) {
  skill_fail(e$message)
})
