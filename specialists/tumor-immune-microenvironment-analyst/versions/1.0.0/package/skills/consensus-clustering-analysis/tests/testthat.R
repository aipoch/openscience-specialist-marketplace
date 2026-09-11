REQUIRED_TEST_PACKAGES <- c("testthat")
missing_packages <- REQUIRED_TEST_PACKAGES[!vapply(REQUIRED_TEST_PACKAGES, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0L)
  stop(sprintf("SKILL_DEPENDENCY_MISSING: %s", paste(missing_packages, collapse = ", ")))

get_script_dir <- function() {
  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_arg_idx <- which(grepl("^--file=", cmd_args))
  if (length(file_arg_idx) > 0L) {
    arg0 <- sub("^--file=", "", cmd_args[file_arg_idx])
    if (!is.na(arg0) && nzchar(arg0) && file.exists(arg0))
      return(dirname(normalizePath(arg0)))
  }
  normalizePath("tests")
}

run_testthat <- function() {
  old_dir <- getwd()
  on.exit(setwd(old_dir), add = TRUE)
  setwd(dirname(get_script_dir()))
  options(consensus.skill.root = getwd())
  testthat::test_dir("tests/testthat", reporter = "summary")
}

run_testthat()
