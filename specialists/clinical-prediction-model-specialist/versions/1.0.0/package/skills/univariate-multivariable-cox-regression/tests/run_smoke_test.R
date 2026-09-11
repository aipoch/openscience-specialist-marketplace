#!/usr/bin/env Rscript

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

run_command <- function(args) {
  output <- system2("Rscript", args = args, stdout = TRUE, stderr = TRUE)
  status <- attr(output, "status")
  if (!is.null(status) && status != 0)
    stop(paste(c("Smoke test command failed:", paste("Rscript", paste(args, collapse = " ")), output), collapse = "\n"), call. = FALSE)
  invisible(output)
}

assert_exists <- function(path) {
  if (!file.exists(path))
    stop(sprintf("Expected file was not created: %s", path), call. = FALSE)
}

assert_non_empty <- function(path) {
  assert_exists(path)
  if (!isTRUE(file.info(path)$size > 0))
    stop(sprintf("Expected non-empty file: %s", path), call. = FALSE)
}

script_dir <- get_script_dir()
root_dir <- normalizePath(file.path(script_dir, ".."), winslash = "/")
output_dir <- file.path(root_dir, "tests", "expected_output")
main_script <- file.path(root_dir, "scripts", "main.R")
data_file <- file.path(root_dir, "tests", "data", "sample_clinical_survival_data.csv")

if (dir.exists(output_dir))
  unlink(output_dir, recursive = TRUE, force = TRUE)

run_command(c(main_script, "analyze", "--data_file", data_file, "--output_dir", output_dir, "--overwrite"))
run_command(c(main_script, "forest-plot", "--data_file", file.path(output_dir, "table", "prognosis_uni_cox_results.xlsx"), "--plot_save", file.path(output_dir, "plot", "uni_forest_plot.pdf")))
run_command(c(main_script, "multi-forest-plot", "--data_file", file.path(output_dir, "table", "prognosis_multi_cox_results.xlsx"), "--plot_save", file.path(output_dir, "plot", "multi_forest_plot.pdf")))

assert_exists(file.path(output_dir, "table", "prognosis_uni_cox_results.xlsx"))
assert_exists(file.path(output_dir, "table", "prognosis_multi_cox_results.xlsx"))
assert_exists(file.path(output_dir, "data", "analysis_data.rds"))
assert_non_empty(file.path(output_dir, "session_info.txt"))
assert_non_empty(file.path(output_dir, "plot", "session_info.txt"))
assert_non_empty(file.path(output_dir, "plot", "uni_forest_plot.pdf"))
assert_non_empty(file.path(output_dir, "plot", "multi_forest_plot.pdf"))

cat(sprintf("Smoke test passed. Output: %s\n", output_dir))
