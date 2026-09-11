#!/usr/bin/env Rscript

get_script_dir <- function() {
  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", cmd_args, value = TRUE)
  if (length(file_arg) > 0) return(dirname(normalizePath(sub("^--file=", "", file_arg), winslash = "/", mustWork = FALSE)))
  "."
}

script_dir <- get_script_dir()
skill_root <- normalizePath(file.path(script_dir, ".."), winslash = "/", mustWork = FALSE)
source(file.path(skill_root, "scripts", "utils.R"))
source(file.path(skill_root, "scripts", "io.R"))
source(file.path(skill_root, "scripts", "functions.R"))
source(file.path(skill_root, "scripts", "plot_helpers.R"))
source(file.path(skill_root, "scripts", "cli_options.R"))

expect_skill_error <- function(expr, code) {
  err <- tryCatch({
    force(expr)
    NULL
  }, error = function(e) e)
  if (is.null(err)) stop(sprintf("Expected error %s but expression succeeded.", code), call. = FALSE)
  if (!grepl(code, conditionMessage(err), fixed = TRUE)) {
    stop(sprintf("Expected error %s but got: %s", code, conditionMessage(err)), call. = FALSE)
  }
}

expect_true <- function(value, message_text) {
  if (!isTRUE(value)) stop(message_text, call. = FALSE)
}

expect_equal_value <- function(actual, expected, message_text) {
  if (!identical(actual, expected)) {
    stop(sprintf("%s\nExpected: %s\nActual: %s", message_text, paste(expected, collapse = ", "), paste(actual, collapse = ", ")), call. = FALSE)
  }
}

tmp_dir <- tempfile("immune-pathway-unit-")
dir.create(tmp_dir, recursive = TRUE, showWarnings = FALSE)
on.exit(unlink(tmp_dir, recursive = TRUE, force = TRUE), add = TRUE)

bad_group_cols <- file.path(tmp_dir, "bad_group_cols.csv")
writeLines(c("sample,label", "S1,Case", "S2,Control"), bad_group_cols)

dup_group <- file.path(tmp_dir, "dup_group.csv")
writeLines(c("sample,group", "S1,Case", "S1,Control"), dup_group)

empty_geneset <- file.path(tmp_dir, "empty_geneset.csv")
writeLines(c("gs_name,gene_symbol", ",", " , "), empty_geneset)

expect_skill_error(validate_cli_options(list(mode = "bad", method = "gsva", kcdf = "Gaussian", scale = "none", top_mode = "both", fdr_threshold = 0.05, width = 14, height = 8, min_sz = 2, max_sz = 5000, top_n = 20, timeout_seconds = 0, plot_file = "plot.pdf", focus_genesets = NULL)), "SKILL_INVALID_PARAMETER")
expect_skill_error(validate_cli_options(list(mode = "analyze", method = "gsva", kcdf = "Gaussian", scale = "none", top_mode = "both", fdr_threshold = 1.2, width = 14, height = 8, min_sz = 2, max_sz = 5000, top_n = 20, timeout_seconds = 0, plot_file = "plot.pdf", focus_genesets = NULL)), "SKILL_INVALID_PARAMETER")
expect_skill_error(resolve_output_dir("../outside", skill_root), "SKILL_INVALID_PARAMETER")
expect_skill_error(read_group_file(bad_group_cols), "SKILL_MISSING_COLUMNS")
expect_skill_error(read_group_file(dup_group), "SKILL_INVALID_PARAMETER")
expect_skill_error(read_geneset_table(empty_geneset, "gs_name", "gene_symbol"), "SKILL_EMPTY_DATA")

exp_mat <- matrix(c(1, 2, 3, 4), nrow = 2, dimnames = list(c("G1", "G2"), c("S1", "S2")))
groups <- c(S1 = "Case", S3 = "Control")
expect_skill_error(validate_analysis_inputs(exp_mat, groups, "Case", "Control"), "SKILL_SAMPLE_MISMATCH")
expect_skill_error(validate_dependency_versions(c(GSVA = "1.42.0", matrixStats = "1.5.0")), "SKILL_VERSION_INCOMPATIBLE")

diff_df <- data.frame(
  geneset = c("GS_A", "GS_B", "GS_C", "GS_D"),
  logFC = c(1.5, -2.0, 0.8, -0.3),
  adj.P.Val = c(0.01, 0.02, 0.20, 0.03),
  stringsAsFactors = FALSE
)
mat <- matrix(seq_len(12), nrow = 4, dimnames = list(diff_df$geneset, c("S1", "S2", "S3")))

ranked_fdr <- rank_diff_genesets(diff_df, "FDR")
expect_equal_value(ranked_fdr$diff_up$geneset, c("GS_A", "GS_C"), "FDR ranking should prioritize lower FDR among up-regulated pathways.")
expect_equal_value(ranked_fdr$diff_down$geneset, c("GS_B", "GS_D"), "FDR ranking should prioritize lower FDR among down-regulated pathways.")

ranked_abs <- rank_diff_genesets(diff_df, "absLFC")
expect_equal_value(ranked_abs$diff_up$geneset, c("GS_A", "GS_C"), "absLFC ranking should prioritize larger absolute logFC among up-regulated pathways.")
expect_equal_value(ranked_abs$diff_down$geneset, c("GS_B", "GS_D"), "absLFC ranking should prioritize larger absolute logFC among down-regulated pathways.")

selected <- select_heatmap_genesets(mat, diff_df, "both", 1L, 1L, "FDR", "GS_C")
expect_equal_value(selected, c("GS_C", "GS_A", "GS_B"), "Heatmap selection should merge focus genesets with top up/down pathways in stable order.")

selected_total <- select_heatmap_genesets(mat, diff_df, "total", 2L, 1L, "FDR", NULL)
expect_equal_value(selected_total, c("GS_A", "GS_B"), "Total mode should keep the top-ranked pathways by FDR and effect size.")

subsetted <- subset_heatmap_matrix(mat, diff_df, "both", 1L, 1L, "FDR", "GS_C")
expect_equal_value(rownames(subsetted), c("GS_C", "GS_A", "GS_B"), "Subset heatmap matrix should preserve the selected pathway order.")

labeled_mat <- apply_heatmap_labels(mat[1:2, , drop = FALSE], diff_df, TRUE, 16)
expect_true(all(grepl("logFC=", rownames(labeled_mat), fixed = TRUE)), "Heatmap labels should append statistics when requested.")
expect_true(all(nchar(rownames(labeled_mat)) <= 16), "Heatmap labels should obey the configured maximum width.")

cat("Immune pathway validation/unit checks completed successfully.\n")
