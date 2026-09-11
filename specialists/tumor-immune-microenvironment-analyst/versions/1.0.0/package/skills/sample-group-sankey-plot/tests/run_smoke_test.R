#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
file_arg_idx <- which(grepl("^--file=", args))
script_file <- if (length(file_arg_idx) > 0) {
  normalizePath(sub("^--file=", "", args[file_arg_idx][1]))
} else {
  normalizePath("tests/run_smoke_test.R")
}

project_dir <- normalizePath(file.path(dirname(script_file), ".."))
main_script <- file.path(project_dir, "scripts", "main.R")
input_file <- file.path(project_dir, "tests", "data", "sample_annotations.csv")
output_dir <- file.path(project_dir, "tests", "smoke_output")

if (dir.exists(output_dir)) {
  unlink(output_dir, recursive = TRUE, force = TRUE)
}

command_args <- c(
  main_script,
  "--input_file", input_file,
  "--output_dir", output_dir,
  "--columns", "risk,Responder,Subtype",
  "--timeout", "600"
)

status <- system2("Rscript", command_args)
if (!identical(status, 0L)) {
  stop(sprintf("SKILL_SMOKE_TEST_FAILED: main.R exited with status %s", status))
}

expected_files <- c(
  file.path(output_dir, "table", "selected_annotations.csv"),
  file.path(output_dir, "table", "sankey_lodes.csv"),
  file.path(output_dir, "plot", "sankey_plot.pdf"),
  file.path(output_dir, "data", "session_info.txt")
)

missing_files <- expected_files[!file.exists(expected_files)]
if (length(missing_files) > 0) {
  stop(
    sprintf(
      "SKILL_SMOKE_TEST_FAILED: Missing expected files: %s",
      paste(missing_files, collapse = ", ")
    )
  )
}

cat("Smoke test passed.\n")
