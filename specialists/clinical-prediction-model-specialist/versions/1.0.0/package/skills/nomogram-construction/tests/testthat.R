#!/usr/bin/env Rscript

if (!requireNamespace("testthat", quietly = TRUE)) {
  stop("SKILL_PACKAGE_NOT_FOUND: Required package is not installed: testthat", call. = FALSE)
}

testthat::test_dir("tests/testthat", reporter = "summary")
