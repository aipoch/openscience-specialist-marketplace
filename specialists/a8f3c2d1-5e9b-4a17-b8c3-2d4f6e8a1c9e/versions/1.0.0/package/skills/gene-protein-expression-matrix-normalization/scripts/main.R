#!/usr/bin/env Rscript

get_script_dir <- function() {
  cmd_args <- commandArgs(trailingOnly = FALSE)

  for (arg in cmd_args) {
    if (grepl("^--file=", arg)) {
      script_path <- sub("^--file=", "", arg)
      if (nzchar(script_path) && file.exists(script_path)) {
        return(dirname(normalizePath(script_path, winslash = "/", mustWork = TRUE)))
      }
    }
  }

  for (arg in cmd_args) {
    if (grepl("(^|/)main\\.R$", arg) && file.exists(arg)) {
      return(dirname(normalizePath(arg, winslash = "/", mustWork = TRUE)))
    }
  }

  normalizePath(".", winslash = "/", mustWork = FALSE)
}

script_dir <- get_script_dir()

source(file.path(script_dir, "utils.R"))
source(file.path(script_dir, "cli_options.R"))
source(file.path(script_dir, "functions.R"))
source(file.path(script_dir, "io.R"))
source(file.path(script_dir, "recording.R"))
source(file.path(script_dir, "run_analysis.R"))

opt <- parse_main_args()
run_analysis(opt)
