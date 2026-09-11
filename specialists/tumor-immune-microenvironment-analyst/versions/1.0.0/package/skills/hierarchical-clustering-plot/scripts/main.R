#!/usr/bin/env Rscript
required_packages <- c("optparse", "data.table")

ensure_installed_packages <- function(packages) {
  missing_packages <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing_packages) > 0)
    stop(
      "SKILL_DEPENDENCY_MISSING: Missing package(s): ",
      paste(missing_packages, collapse = ", "),
      call. = FALSE
    )
  invisible(packages)
}

get_script_dir <- function() {
  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_arg_idx <- which(grepl("^--file=", cmd_args))
  if (length(file_arg_idx) > 0) {
    arg0 <- sub("^--file=", "", cmd_args[file_arg_idx])
    if (!is.na(arg0) && nzchar(arg0) && file.exists(arg0))
      return(dirname(normalizePath(arg0)))
  }
  "."
}

build_parser <- function() {
  option_list <- list(
    optparse::make_option(c("-i", "--input_file"), type = "character", default = NULL,
                          help = "Expression matrix file (features as rows, samples as columns) [required]", metavar = "file"),
    optparse::make_option(c("-g", "--group_file"), type = "character", default = NULL,
                          help = "Sample annotation file with sample IDs in the first column [required]", metavar = "file"),
    optparse::make_option(c("-o", "--output_dir"), type = "character", default = "./output/",
                          help = "Output directory [default %default]", metavar = "dir"),
    optparse::make_option(c("-d", "--distance_method"), type = "character", default = "euclidean",
                          help = "Distance method for dist(): euclidean, maximum, manhattan, canberra, binary, minkowski [default %default]"),
    optparse::make_option(c("-m", "--linkage_method"), type = "character", default = "complete",
                          help = "Linkage method for hclust(): complete, single, average, mcquitty, median, centroid, ward.D, ward.D2 [default %default]"),
    optparse::make_option(c("-l", "--label_column"), type = "character", default = "",
                          help = "Column used for dendrogram labels [default: second column in group file]"),
    optparse::make_option(c("-c", "--label_cex"), type = "double", default = 0.8,
                          help = "Label size in dendrogram PDF [default %default]"),
    optparse::make_option(c("-t", "--timeout_seconds"), type = "integer", default = 300,
                          help = "Elapsed time limit in seconds [default %default]"),
    optparse::make_option(c("-s", "--seed"), type = "integer", default = 42,
                          help = "Random seed for reproducibility [default %default]")
  )
  optparse::OptionParser(option_list = option_list, description = "Hierarchical Clustering Plot for Samples")
}

ensure_installed_packages(required_packages)
suppressPackageStartupMessages(library(optparse))

script_dir <- get_script_dir()
source(file.path(script_dir, "logging_utils.R"))
source(file.path(script_dir, "validation_utils.R"))
source(file.path(script_dir, "runtime_utils.R"))
source(file.path(script_dir, "input_functions.R"))
source(file.path(script_dir, "clustering_functions.R"))
source(file.path(script_dir, "output_utils.R"))
source(file.path(script_dir, "run_analysis.R"))

parser <- build_parser()
opt <- optparse::parse_args(parser)

tryCatch({
  if (is.null(opt$input_file) || is.null(opt$group_file)) {
    print_help(parser)
    stop("SKILL_INVALID_PARAMETER: Both --input_file and --group_file are required", call. = FALSE)
  }
  result <- withCallingHandlers(
    run_analysis_cli(opt),
    warning = function(w) {
      message(format_log("WARN", conditionMessage(w)))
      invokeRestart("muffleWarning")
    }
  )
  message(format_log("INFO", "Analysis complete"))
  invisible(result)
}, error = function(e) {
  message(format_log("ERROR", normalize_error(e)))
  quit(save = "no", status = 1)
})
