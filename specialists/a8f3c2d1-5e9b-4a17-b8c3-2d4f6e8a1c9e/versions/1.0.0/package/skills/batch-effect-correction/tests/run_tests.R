#!/usr/bin/env Rscript
required_packages <- c("testthat", "data.table")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0)
  stop(sprintf("SKILL_DEPENDENCY_MISSING: %s", paste(missing_packages, collapse = ", ")), call. = FALSE)

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
project_root <- normalizePath(file.path(test_dir, ".."))
setwd(project_root)
options(batch.skill.root = project_root)

testthat::test_dir(file.path(test_dir, "testthat"), reporter = "summary")
