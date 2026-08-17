#!/usr/bin/env Rscript

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

tests_dir <- get_script_dir()
root_dir <- normalizePath(file.path(tests_dir, ".."), winslash = "/", mustWork = TRUE)
output_dir <- file.path(root_dir, "tests", "output")

args <- c(
  file.path(root_dir, "scripts", "main.R"),
  "--exp_file", file.path(root_dir, "tests", "data", "BRCA_data.csv"),
  "--cli_file", file.path(root_dir, "tests", "data", "BRCA_clinic.csv"),
  "--model_file", file.path(root_dir, "tests", "data", "BRCA_coef.csv"),
  "--output_dir", output_dir,
  "--overwrite"
)

status <- system2("Rscript", args = args)
quit(status = if (is.null(status)) 0L else as.integer(status))
