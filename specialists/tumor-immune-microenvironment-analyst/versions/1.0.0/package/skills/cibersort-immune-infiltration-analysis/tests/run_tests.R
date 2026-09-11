#!/usr/bin/env Rscript
cmd_args <- commandArgs(trailingOnly = FALSE)
file_arg_idx <- which(grepl("^--file=", cmd_args))
script_file <- if (length(file_arg_idx) > 0) sub("^--file=", "", cmd_args[file_arg_idx[1]]) else "tests/run_tests.R"
skill_root <- normalizePath(file.path(dirname(script_file), ".."), winslash = "/", mustWork = FALSE)
output_dir <- if (length(commandArgs(trailingOnly = TRUE)) >= 1) commandArgs(trailingOnly = TRUE)[[1]] else file.path(skill_root, "tests", "output")
main_script <- file.path(skill_root, "scripts", "main.R")

if (dir.exists(output_dir)) {
  unlink(output_dir, recursive = TRUE, force = TRUE)
}

build_cmd <- function(out_dir, case_group = "Tumor", control_group = "Healthy", qn = "false") {
  c(
    main_script,
    "-i", file.path(skill_root, "tests", "data", "expression_matrix.csv"),
    "-g", file.path(skill_root, "tests", "data", "group_info.csv"),
    "-a", case_group,
    "-b", control_group,
    "--signature_file", file.path(skill_root, "tests", "data", "LM22.txt"),
    "-o", out_dir,
    "--perm", "25",
    "--qn", qn,
    "--svm_cores", "1",
    "--seed", "42"
  )
}

build_bad_signature_cmd <- function(out_dir) {
  c(
    main_script,
    "-i", file.path(skill_root, "tests", "data", "expression_matrix.csv"),
    "-g", file.path(skill_root, "tests", "data", "group_info.csv"),
    "-a", "Tumor",
    "-b", "Healthy",
    "--signature_file", file.path(skill_root, "tests", "data", "bad_signature_matrix.csv"),
    "-o", out_dir,
    "--perm", "5",
    "--qn", "false",
    "--svm_cores", "1",
    "--seed", "42"
  )
}

run_capture <- function(cmd) {
  out <- suppressWarnings(system2("Rscript", cmd, stdout = TRUE, stderr = TRUE))
  status <- attr(out, "status")
  list(status = if (is.null(status)) 0L else as.integer(status), output = out)
}

assert_failed_with <- function(cmd, code, label) {
  res <- run_capture(cmd)
  if (identical(res$status, 0L)) {
    stop(sprintf("%s unexpectedly succeeded.", label), call. = FALSE)
  }
  if (!any(grepl(code, res$output, fixed = TRUE))) {
    stop(sprintf("%s did not emit %s.", label, code), call. = FALSE)
  }
}

cmd <- build_cmd(output_dir)

status <- system2("Rscript", cmd)
if (!identical(status, 0L)) {
  stop("Primary CIBERSORT test run failed.", call. = FALSE)
}

status_reuse <- system2("Rscript", cmd)
if (!identical(status_reuse, 0L)) {
  stop("Reuse-output-dir CIBERSORT test run failed.", call. = FALSE)
}

manifest_file <- file.path(output_dir, "output_manifest.txt")
record_file <- file.path(output_dir, "run_record.txt")
manifest_lines <- readLines(manifest_file, warn = FALSE)
record_lines <- readLines(record_file, warn = FALSE)

if (sum(grepl("^Output Files$", manifest_lines)) < 2) {
  stop("output_manifest.txt does not preserve multiple run sections.", call. = FALSE)
}
if (sum(grepl("^Run Record$", record_lines)) < 2) {
  stop("run_record.txt does not preserve multiple run sections.", call. = FALSE)
}

assert_failed_with(build_cmd(output_dir, case_group = "MissingGroup"), "SKILL_INVALID_PARAMETER", "Same-output-dir preservation test")
if (!file.exists(file.path(output_dir, "table", "CIBERSORT_Results.csv"))) {
  stop("Failed rerun cleared prior successful payload files.", call. = FALSE)
}
manifest_lines <- readLines(manifest_file, warn = FALSE)
record_lines <- readLines(record_file, warn = FALSE)
if (!any(grepl("Run Mode: analysis_failed", manifest_lines, fixed = TRUE))) {
  stop("output_manifest.txt does not record failed runs.", call. = FALSE)
}
if (!any(grepl("- status: failed", record_lines, fixed = TRUE))) {
  stop("run_record.txt does not record failed runs.", call. = FALSE)
}

assert_failed_with(build_cmd(file.path(skill_root, "tests", "invalid_bool_output"), qn = "maybe"), "SKILL_INVALID_PARAMETER", "Invalid boolean regression test")
assert_failed_with(build_cmd(file.path(skill_root, "tests", "missing_group_output"), case_group = "MissingGroup"), "SKILL_INVALID_PARAMETER", "Missing group regression test")
assert_failed_with(build_bad_signature_cmd(file.path(skill_root, "tests", "bad_signature_output")), "SKILL_INVALID_PARAMETER", "Invalid signature matrix regression test")

cat(sprintf("CIBERSORT scaffold test completed successfully: %s\n", output_dir))
