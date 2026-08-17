#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(testthat))

get_script_dir <- function() {
  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_arg_idx <- which(grepl("^--file=", cmd_args))
  if (length(file_arg_idx) > 0) {
    arg0 <- sub("^--file=", "", cmd_args[file_arg_idx[1]])
    if (!is.na(arg0) && nzchar(arg0) && file.exists(arg0))
      return(dirname(normalizePath(arg0)))
  }
  normalizePath("tests")
}

test_dir_path <- get_script_dir()
root_dir <- normalizePath(file.path(test_dir_path, ".."), winslash = "/", mustWork = TRUE)
Sys.setenv(EXTERNAL_MODEL_VALIDATION_ROOT = root_dir)

testthat::test_dir(
  file.path(root_dir, "tests", "testthat"),
  reporter = "summary",
  stop_on_failure = TRUE
)
