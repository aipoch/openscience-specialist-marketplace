#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
output_dir <- if (length(args) >= 1) args[[1]] else "tests/output"

if (dir.exists(output_dir)) {
  unlink(output_dir, recursive = TRUE, force = TRUE)
}

main_args <- c(
  "scripts/main.R",
  "--input_file", "tests/data/expression_matrix.csv",
  "--group_file", "tests/data/group_info.csv",
  "--output_dir", output_dir,
  "--gene_id_type", "GeneSymbol",
  "--platform", "affymetrix",
  "--seed", "42"
)

status <- system2("Rscript", args = main_args)
if (!identical(status, 0L)) {
  stop("ESTIMATE demo workflow failed.", call. = FALSE)
}

check_status <- system2("Rscript", args = c("tests/test_skill.R", output_dir))
if (!identical(check_status, 0L)) {
  stop("ESTIMATE output validation failed.", call. = FALSE)
}

cat(sprintf("ESTIMATE immune score test completed successfully: %s\n", output_dir))
