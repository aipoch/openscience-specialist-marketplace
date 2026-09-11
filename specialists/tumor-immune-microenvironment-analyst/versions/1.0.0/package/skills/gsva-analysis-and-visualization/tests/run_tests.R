#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
output_dir <- if (length(args) >= 1) args[[1]] else "tests/output"

if (dir.exists(output_dir)) {
  unlink(output_dir, recursive = TRUE, force = TRUE)
}

main_args <- c(
  "scripts/main.R",
  "--mode", "full",
  "--input_file", "tests/data/expr_matrix.csv",
  "--group_file", "tests/data/group.csv",
  "--case_group", "Tumor",
  "--control_group", "Healthy",
  "--species", shQuote("Homo sapiens"),
  "--category", "C2",
  "--subcategory", "KEGG",
  "--output_dir", output_dir,
  "--seed", "42"
)

status <- system2("Rscript", args = main_args)
if (!identical(status, 0L)) {
  stop("GSVA full-workflow test failed.", call. = FALSE)
}

check_status <- system2("Rscript", args = c("tests/test_skill.R", output_dir))
if (!identical(check_status, 0L)) {
  stop("GSVA output validation failed.", call. = FALSE)
}

visualize_args <- c(
  "scripts/main.R",
  "--mode", "visualize",
  "--output_dir", output_dir,
  "--plot_file", "reused_heatmap.pdf",
  "--top_up", "5",
  "--top_down", "5",
  "--top_mode", "both"
)

visualize_status <- system2("Rscript", args = visualize_args)
if (!identical(visualize_status, 0L)) {
  stop("GSVA visualize-only reuse test failed.", call. = FALSE)
}

manifest_file <- file.path(output_dir, "output_manifest.txt")
record_file <- file.path(output_dir, "run_record.txt")
manifest_lines <- readLines(manifest_file, warn = FALSE)
record_lines <- readLines(record_file, warn = FALSE)

if (!file.exists(file.path(output_dir, "plot", "reused_heatmap.pdf"))) {
  stop("Visualize-only reuse did not generate the expected heatmap file.", call. = FALSE)
}

if (sum(grepl("Run Mode: full$", manifest_lines, fixed = FALSE)) < 1 ||
    sum(grepl("Run Mode: visualize$", manifest_lines, fixed = FALSE)) < 1) {
  stop("Output manifest did not preserve both full and visualize run sections.", call. = FALSE)
}

if (sum(grepl("^- mode: full$", record_lines)) < 1 ||
    sum(grepl("^- mode: visualize$", record_lines)) < 1) {
  stop("Run record did not preserve both full and visualize invocations.", call. = FALSE)
}

cat(sprintf("GSVA full-workflow test completed successfully: %s\n", output_dir))
