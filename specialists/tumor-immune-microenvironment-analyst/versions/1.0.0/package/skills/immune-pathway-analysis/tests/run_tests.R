#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
output_dir <- if (length(args) >= 1) args[[1]] else "tests/output"
unit_status <- system2("Rscript", args = c("tests/run_unit_tests.R"))
if (!identical(unit_status, 0L)) stop("Immune pathway validation/unit checks failed.", call. = FALSE)
group_df <- read.csv("tests/data/group_info.csv", stringsAsFactors = FALSE, check.names = FALSE)
group_values <- unique(trimws(group_df[[2]]))
if (length(group_values) != 2) stop("The test group_info.csv must contain exactly two groups.", call. = FALSE)
control_group <- if ("Healthy" %in% group_values) "Healthy" else group_values[[1]]
case_group <- if ("Tumor" %in% group_values) "Tumor" else setdiff(group_values, control_group)[[1]]

main_args <- c("scripts/main.R", "--mode", "full", "--input_file", "tests/data/expression_matrix.csv", "--group_file", "tests/data/group_info.csv", "--geneset_file", "tests/data/immune_genesets.csv", "--case_group", case_group, "--control_group", control_group, "--focus_genesets", "REACTOME_INTERFERON_SIGNALING,REACTOME_ANTIGEN_PROCESSING", "--output_dir", output_dir, "--seed", "42")
status <- system2("Rscript", args = main_args)
if (!identical(status, 0L)) stop("Immune pathway full-workflow test failed.", call. = FALSE)

check_status <- system2("Rscript", args = c("tests/test_skill.R", output_dir))
if (!identical(check_status, 0L)) stop("Immune pathway output validation failed.", call. = FALSE)

visualize_args <- c("scripts/main.R", "--mode", "visualize", "--output_dir", output_dir, "--plot_file", "reused_heatmap.pdf", "--top_up", "2", "--top_down", "1", "--top_mode", "both")
visualize_status <- system2("Rscript", args = visualize_args)
if (!identical(visualize_status, 0L)) stop("Immune pathway visualize-only reuse test failed.", call. = FALSE)

manifest_lines <- readLines(file.path(output_dir, "output_manifest.txt"), warn = FALSE)
record_lines <- readLines(file.path(output_dir, "run_record.txt"), warn = FALSE)
if (!file.exists(file.path(output_dir, "plot", "reused_heatmap.pdf"))) stop("Visualize-only reuse did not generate the expected heatmap file.", call. = FALSE)
if (sum(grepl("Run Mode: full$", manifest_lines)) < 1 || sum(grepl("Run Mode: visualize$", manifest_lines)) < 1) stop("Output manifest did not preserve both full and visualize run sections.", call. = FALSE)
if (sum(grepl("^- mode: full$", record_lines)) < 1 || sum(grepl("^- mode: visualize$", record_lines)) < 1) stop("Run record did not preserve both full and visualize invocations.", call. = FALSE)

cat(sprintf("Immune pathway full-workflow test completed successfully: %s\n", output_dir))
