#!/usr/bin/env Rscript

cmd_args <- commandArgs(trailingOnly = FALSE)
file_arg_idx <- which(grepl("^--file=", cmd_args))
script_file <- if (length(file_arg_idx) > 0) sub("^--file=", "", cmd_args[file_arg_idx[1]]) else "tests/run_tests.R"
script_dir <- normalizePath(dirname(script_file), winslash = "/", mustWork = FALSE)
skill_root <- normalizePath(file.path(script_dir, ".."), winslash = "/", mustWork = FALSE)
scripts_dir <- normalizePath(file.path(script_dir, "..", "scripts"), winslash = "/", mustWork = FALSE)
output_root <- normalizePath(file.path(skill_root, "tests", "output"), winslash = "/", mustWork = FALSE)

args <- commandArgs(trailingOnly = TRUE)
main_script <- file.path(skill_root, "scripts", "main.R")
input_file <- file.path(skill_root, "tests", "data", "expression_matrix.csv")
test_script <- file.path(skill_root, "tests", "test_skill.R")
single_sample_input <- file.path(skill_root, "tests", "data", "single_sample_matrix.csv")
non_finite_input <- file.path(skill_root, "tests", "data", "non_finite_matrix.csv")
negative_input <- file.path(skill_root, "tests", "data", "negative_matrix.csv")
utils_script <- file.path(scripts_dir, "utils.R")

resolve_output_dir <- function(arg_path = NULL) {
  if (is.null(arg_path) || !nzchar(arg_path)) {
    return(output_root)
  }
  if (grepl("^(/|[A-Za-z]:|\\\\\\\\)", arg_path)) {
    return(normalizePath(arg_path, winslash = "/", mustWork = FALSE))
  }
  normalizePath(file.path(output_root, arg_path), winslash = "/", mustWork = FALSE)
}

validate_output_dir <- function(path) {
  prefix <- paste0(output_root, "/")
  if (!(identical(path, output_root) || startsWith(path, prefix))) {
    stop(sprintf("Test output directory must stay within %s: %s", output_root, path), call. = FALSE)
  }
}

base_output_dir <- resolve_output_dir(if (length(args) >= 1) args[[1]] else NULL)
validate_output_dir(base_output_dir)

if (dir.exists(base_output_dir)) {
  unlink(base_output_dir, recursive = TRUE, force = TRUE)
}
dir.create(base_output_dir, recursive = TRUE, showWarnings = FALSE)

run_case <- function(name, extra_args) {
  out_dir <- file.path(base_output_dir, name)
  cmd <- c(
    main_script,
    "--input_file", input_file,
    "--output_dir", out_dir,
    "--seed", "42",
    extra_args
  )
  status <- system2("Rscript", cmd)
  if (!identical(status, 0L)) {
    stop(sprintf("Normalization test failed for case: %s", name), call. = FALSE)
  }
}

expect_failure <- function(cmd_args, expected_patterns, label) {
  res <- suppressWarnings(system2("Rscript", cmd_args, stdout = TRUE, stderr = TRUE))
  status <- attr(res, "status")
  if (is.null(status)) {
    stop(sprintf("%s unexpectedly succeeded.", label), call. = FALSE)
  }
  for (pattern in expected_patterns) {
    if (!any(grepl(pattern, res, fixed = TRUE))) {
      stop(sprintf("%s did not emit expected text: %s", label, pattern), call. = FALSE)
    }
  }
}

expect_timeout_mapping <- function() {
  source(utils_script)
  timeout_res <- tryCatch({
    rethrow_with_timeout_code(simpleError("reached elapsed time limit"), timeout_seconds = 1, context = "Normalization")
    "no-error"
  }, error = function(e) conditionMessage(e))
  if (!grepl("^SKILL_TIMEOUT: Normalization exceeded --timeout_seconds=1\\.$", timeout_res)) {
    stop("Timeout error mapping regression test did not emit the expected SKILL_TIMEOUT message.", call. = FALSE)
  }
}

run_case("log2", c("--method", "log2", "--pseudo_count", "1"))
run_case("zscore", c("--method", "zscore", "--margin", "column"))
run_case("minmax", c("--method", "minmax", "--margin", "row"))

single_sample_dir <- file.path(base_output_dir, "single_sample_log2")
single_sample_status <- system2("Rscript", c(
  main_script,
  "--input_file", single_sample_input,
  "--output_dir", single_sample_dir,
  "--method", "log2",
  "--pseudo_count", "1",
  "--seed", "42"
))
if (!identical(single_sample_status, 0L)) {
  stop("Single-sample regression test failed.", call. = FALSE)
}
single_feature_summary <- read.csv(file.path(single_sample_dir, "table", "feature_summary.csv"), stringsAsFactors = FALSE, check.names = FALSE)
if (anyNA(single_feature_summary$input_sd) || anyNA(single_feature_summary$normalized_sd)) {
  stop("Single-sample regression test produced NA standard deviations.", call. = FALSE)
}
if (any(single_feature_summary$input_sd != 0) || any(single_feature_summary$normalized_sd != 0)) {
  stop("Single-sample regression test expected zero standard deviations per feature.", call. = FALSE)
}

expect_failure(c(
  main_script,
  "--input_file", non_finite_input,
  "--output_dir", file.path(base_output_dir, "non_finite_should_fail"),
  "--method", "log2",
  "--pseudo_count", "1",
  "--seed", "42"
), c("SKILL_INVALID_PARAMETER", "finite numeric values"), "Non-finite input regression test")

expect_failure(c(
  main_script,
  "--input_file", negative_input,
  "--output_dir", file.path(base_output_dir, "negative_should_fail"),
  "--method", "log2",
  "--pseudo_count", "1",
  "--seed", "42"
), c("SKILL_INVALID_PARAMETER", "pseudo_count", "> 0"), "Negative-value log2 regression test")

expect_timeout_mapping()

check_status <- system2("Rscript", c(test_script, base_output_dir, "--skip-prepare"))
if (!identical(check_status, 0L)) {
  stop("Output validation failed.", call. = FALSE)
}

cat(sprintf("Normalization workflow tests completed successfully: %s\n", base_output_dir))
