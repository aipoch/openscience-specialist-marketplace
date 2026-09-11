#!/usr/bin/env Rscript
required_packages <- c("testthat", "data.table")

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

ensure_installed_packages(required_packages)
suppressPackageStartupMessages(library(testthat))

get_test_dir <- function() {
  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_arg_idx <- which(grepl("^--file=", cmd_args))
  if (length(file_arg_idx) > 0) {
    arg0 <- sub("^--file=", "", cmd_args[file_arg_idx])
    if (!is.na(arg0) && nzchar(arg0) && file.exists(arg0))
      return(dirname(normalizePath(arg0)))
  }
  normalizePath(".")
}

test_dir <- get_test_dir()
repo_root <- normalizePath(file.path(test_dir, ".."))
setwd(repo_root)
scripts_dir <- file.path(repo_root, "scripts")

source(file.path(scripts_dir, "logging_utils.R"))
source(file.path(scripts_dir, "validation_utils.R"))
source(file.path(scripts_dir, "runtime_utils.R"))
source(file.path(scripts_dir, "input_functions.R"))
source(file.path(scripts_dir, "clustering_functions.R"))
source(file.path(scripts_dir, "output_utils.R"))
source(file.path(scripts_dir, "run_analysis.R"))

testthat::test_dir(file.path(test_dir, "testthat"), reporter = "summary")
