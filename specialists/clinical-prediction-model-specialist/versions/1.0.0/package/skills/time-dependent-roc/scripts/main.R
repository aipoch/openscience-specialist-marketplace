#!/usr/bin/env Rscript

if (!requireNamespace("optparse", quietly = TRUE)) {
  cat("SKILL_DEPENDENCY_MISSING: optparse\n", file = stderr())
  quit(save = "no", status = 1)
}

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
  "."
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
  make_option(c("-d", "--data_file"), type = "character", help = "Data file (CSV, TXT, TSV, TAB, XLS, XLSX)", metavar = "file"),
  make_option(c("-o", "--output_dir"), type = "character", default = "./TimeROC_Results", help = "Output directory [default %default]", metavar = "dir"),
  make_option(c("-m", "--marker_col"), type = "character", default = "risk_score", help = "Marker column name [default %default]", metavar = "col"),
  make_option(c("-t", "--times"), type = "character", default = "1,3,5", help = "Prediction time points as comma-separated numeric values [default %default]"),
  make_option(c("-u", "--time_unit"), type = "character", default = "year", help = "Time unit label: year, month, day [default %default]"),
  make_option(c("--auto_convert_days"), type = "logical", default = TRUE, help = "Automatically convert large futime values from days when appropriate [default %default]"),
  make_option(c("-c", "--cause"), type = "double", default = 1, help = "Event code of interest [default %default]"),
  make_option(c("-w", "--weighting"), type = "character", default = "aalen", help = "IPCW weighting: aalen, marginal, cox [default %default]"),
  make_option(c("--output_format"), type = "character", default = "csv", help = "Tabular output format: csv or txt [default %default]"),
  make_option(c("--width"), type = "double", default = 6, help = "Figure width in inches [default %default]"),
  make_option(c("--height"), type = "double", default = 6, help = "Figure height in inches [default %default]"),
  make_option(c("--diagonal_show"), type = "logical", default = TRUE, help = "Show diagonal reference line [default %default]"),
  make_option(c("--diagonal_color"), type = "character", default = "#7F7F7F", help = "Diagonal line color [default %default]"),
  make_option(c("--diagonal_size"), type = "double", default = 0.75, help = "Diagonal line size [default %default]"),
  make_option(c("--diagonal_type"), type = "character", default = "dashed", help = "Diagonal line type [default %default]"),
  make_option(c("--area_show"), type = "logical", default = FALSE, help = "Shade the area under each ROC curve [default %default]"),
  make_option(c("--area_alpha"), type = "double", default = 0.1, help = "Area transparency [default %default]"),
  make_option(c("--line_colors"), type = "character", default = "#4DBBD5,#E64B35,#00A087,#3C5488,#F39B7F,#8491B4,#91D1C2,#DC0000,#7E6148,#B09C85", help = "Curve colors as comma-separated values [default %default]"),
  make_option(c("--line_type"), type = "character", default = "solid", help = "Curve line type [default %default]"),
  make_option(c("--line_size"), type = "double", default = 0.8, help = "Curve line size [default %default]"),
  make_option(c("--line_alpha"), type = "double", default = 1, help = "Curve line alpha [default %default]"),
  make_option(c("--plot_title"), type = "character", default = "", help = "Plot title [default %default]"),
  make_option(c("--x_label"), type = "character", default = "1 - Specificity", help = "X-axis label [default %default]"),
  make_option(c("--y_label"), type = "character", default = "Sensitivity", help = "Y-axis label [default %default]"),
  make_option(c("--legend_show"), type = "logical", default = TRUE, help = "Show legend [default %default]"),
  make_option(c("--legend_title"), type = "character", default = "Time", help = "Legend title [default %default]"),
  make_option(c("--legend_position"), type = "character", default = "bottomright", help = "Legend position [default %default]"),
  make_option(c("--theme_border"), type = "logical", default = TRUE, help = "Show panel border [default %default]"),
  make_option(c("--theme_panel"), type = "logical", default = TRUE, help = "Show panel grid [default %default]"),
  make_option(c("--theme_size"), type = "double", default = 12, help = "Base theme font size [default %default]")
)

opt_parser <- OptionParser(
  option_list = option_list,
  description = "Time-dependent ROC analysis for survival data with AUC export and ROC figure generation."
)

opt <- parse_args(opt_parser)

if (is.null(opt$data_file)) {
  skill_fail("SKILL_MISSING_INPUT: Data file (-d) option is required", show_help = TRUE, opt_parser = opt_parser)
}

params <- list(
  data_file = opt$data_file,
  output_dir = opt$output_dir,
  marker_col = opt$marker_col,
  times = parse_csv_numeric(opt$times, "times"),
  time_unit = opt$time_unit,
  auto_convert_days = opt$auto_convert_days,
  cause = opt$cause,
  weighting = opt$weighting,
  output_format = opt$output_format,
  width = opt$width,
  height = opt$height,
  diagonal_show = opt$diagonal_show,
  diagonal_color = opt$diagonal_color,
  diagonal_size = opt$diagonal_size,
  diagonal_type = opt$diagonal_type,
  area_show = opt$area_show,
  area_alpha = opt$area_alpha,
  line_colors = parse_csv_character(opt$line_colors),
  line_type = opt$line_type,
  line_size = opt$line_size,
  line_alpha = opt$line_alpha,
  plot_title = opt$plot_title,
  x_label = opt$x_label,
  y_label = opt$y_label,
  legend_show = opt$legend_show,
  legend_title = opt$legend_title,
  legend_position = opt$legend_position,
  theme_border = opt$theme_border,
  theme_panel = opt$theme_panel,
  theme_size = opt$theme_size
)

params <- tryCatch({
  validate_parameters_opt(params)
}, error = function(e) {
  skill_fail(e$message, show_help = TRUE, opt_parser = opt_parser)
})

results <- tryCatch({
  analysis_result <- time_dependent_roc_analysis(params)
  save_session_info(params$output_dir)
  analysis_result
}, error = function(e) {
  skill_fail(e$message)
})

log_info("Analysis completed successfully")
log_info("Marker column used: ", results$marker_col)
