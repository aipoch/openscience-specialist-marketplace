#!/usr/bin/env Rscript

get_script_dir <- function() {
  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_arg_idx <- which(grepl("^--file=", cmd_args))
  if (length(file_arg_idx) > 0) {
    arg0 <- sub("^--file=", "", cmd_args[file_arg_idx])
    if (!is.na(arg0) && nzchar(arg0) && file.exists(arg0)) return(dirname(normalizePath(arg0)))
  }
  "."
}

test_that <- function(desc, code) {
  tryCatch({
    force(code)
    message(sprintf("[PASS] %s", desc))
  }, error = function(e) {
    message(sprintf("[FAIL] %s", desc))
    message(conditionMessage(e))
    quit(save = "no", status = 1)
  })
}

expect_true <- function(x, msg = "Expected condition to be TRUE") {
  if (!isTRUE(x)) stop(msg, call. = FALSE)
}

expect_equal <- function(x, y, msg = NULL) {
  if (!identical(x, y)) {
    if (is.null(msg)) msg <- sprintf("Expected %s but got %s", deparse(y), deparse(x))
    stop(msg, call. = FALSE)
  }
}

expect_file_exists <- function(path, msg = NULL) {
  if (!file.exists(path)) {
    if (is.null(msg)) msg <- sprintf("Expected file to exist: %s", path)
    stop(msg, call. = FALSE)
  }
}

expect_false <- function(x, msg = "Expected condition to be FALSE") {
  if (isTRUE(x)) stop(msg, call. = FALSE)
}

expect_error_code <- function(expr, code) {
  err <- tryCatch({
    force(expr)
    NULL
  }, error = function(e) e)
  if (is.null(err)) {
    stop(sprintf("Expected error containing %s", code), call. = FALSE)
  }
  if (!grepl(code, conditionMessage(err), fixed = TRUE)) {
    stop(sprintf("Expected error containing %s but got: %s", code, conditionMessage(err)), call. = FALSE)
  }
}

script_dir <- normalizePath(file.path(get_script_dir(), "..", "scripts"))
source(file.path(script_dir, "utils.R"))
source(file.path(script_dir, "functions.R"))
source(file.path(script_dir, "diff_methods.R"))
source(file.path(script_dir, "diff_visualization.R"))

tests_dir <- normalizePath(file.path(script_dir, "..", "tests", "data"))
expr_file <- file.path(tests_dir, "oa_exp.csv")
group_file <- file.path(tests_dir, "oa_group.csv")

test_that("load_data loads bundled example files", {
  dat <- load_data(expr_file, group_file, "OA", "control")
  expect_true(is.matrix(dat$mat), "Expression matrix should be a matrix")
  expect_equal(nrow(dat$map), ncol(dat$mat), "Sample map should align with expression columns")
})

test_that("filter_results keeps zero-DEG results instead of failing", {
  diff_data <- data.frame(
    gene_id = c("gene1", "gene2"),
    logFC = c(0.2, -0.3),
    Pvalue = c(0.9, 0.8),
    Padj = c(0.95, 0.9),
    stringsAsFactors = FALSE
  )
  filtered <- filter_results(diff_data, p_threshold = 0.05, logfc_threshold = 1, p_adjust = TRUE)
  expect_equal(filtered$significant, 0L, "Expected zero significant genes")
  expect_true(all(filtered$data$group == "no"), "All genes should be labeled as no")
})

test_that("build_volcano_plot_data respects p_type semantics", {
  diff_data <- data.frame(
    name = c("gene1", "gene2"),
    logFC = c(2.0, -2.0),
    P.value = c(0.001, 0.2),
    P.adj = c(0.2, 0.001),
    stringsAsFactors = FALSE
  )

  raw_mode <- build_volcano_plot_data(diff_data, p_threshold = 0.05, logfc_threshold = 1, p_adjust = FALSE)
  adj_mode <- build_volcano_plot_data(diff_data, p_threshold = 0.05, logfc_threshold = 1, p_adjust = TRUE)

  expect_equal(raw_mode$change, c("Up-regulated", "Not significant"), "Raw p-value mode should use P.value")
  expect_equal(adj_mode$change, c("Not significant", "Down-regulated"), "Adjusted p-value mode should use P.adj")
})

test_that("load_data reports sample mismatches with a SKILL error", {
  bad_group <- tempfile(fileext = ".csv")
  writeLines(c("sample,group", "X1,control", "X2,control", "X3,OA", "X4,OA"), bad_group)
  expect_error_code(load_data(expr_file, bad_group, "OA", "control"), "SKILL_SAMPLE_MISMATCH")
})

test_that("with_timeout maps elapsed-limit failures to SKILL_TIMEOUT", {
  expect_error_code(with_timeout({ Sys.sleep(2) }, timeout_seconds = 1), "SKILL_TIMEOUT")
})

test_that("CLI smoke test produces core outputs", {
  output_dir <- tempfile(pattern = "deg-screening-")
  cmd <- c(
    "scripts/main.R",
    "--input_file", expr_file,
    "--group_file", group_file,
    "--case", "OA",
    "--control", "control",
    "--output_dir", output_dir,
    "--run_plots", "FALSE"
  )
  result <- system2("Rscript", cmd, stdout = TRUE, stderr = TRUE)
  status <- attr(result, "status")
  if (!is.null(status) && status != 0) {
    stop(paste(result, collapse = "\n"), call. = FALSE)
  }

  expect_file_exists(file.path(output_dir, "session_info.txt"))
  expect_file_exists(file.path(output_dir, "data", "DEG_list.rda"))
  expect_file_exists(file.path(output_dir, "table", "Diffanalysis.csv"))
  expect_file_exists(file.path(output_dir, "table", "DEG.csv"))
  expect_false(file.exists(file.path(output_dir, "table", "deg_volcano_xiantao.csv")), "Obsolete volcano intermediate should not be exported")
  expect_false(file.exists(file.path(output_dir, "table", "deg_heatmap_xiantao.csv")), "Obsolete heatmap intermediate should not be exported")

  diff_tbl <- utils::read.csv(file.path(output_dir, "table", "Diffanalysis.csv"), stringsAsFactors = FALSE)
  deg_tbl <- utils::read.csv(file.path(output_dir, "table", "DEG.csv"), stringsAsFactors = FALSE)
  expect_true(nrow(deg_tbl) <= nrow(diff_tbl), "DEG table should be a filtered subset of the full result table")
  if (nrow(deg_tbl) > 0) {
    expect_true(all(deg_tbl$group %in% c("up", "down")), "DEG table should only contain significant up/down genes")
  }
})

test_that("CLI accepts case-insensitive group names through plotting", {
  output_dir <- tempfile(pattern = "deg-screening-casefold-")
  cmd <- c(
    "scripts/main.R",
    "--input_file", expr_file,
    "--group_file", group_file,
    "--case", "oa",
    "--control", "CONTROL",
    "--output_dir", output_dir,
    "--p_type", "p",
    "--top_n", "3"
  )
  result <- system2("Rscript", cmd, stdout = TRUE, stderr = TRUE)
  status <- attr(result, "status")
  if (!is.null(status) && status != 0) {
    stop(paste(result, collapse = "\n"), call. = FALSE)
  }

  expect_file_exists(file.path(output_dir, "plot", "heatmap.pdf"))
  expect_file_exists(file.path(output_dir, "plot", "volcano_plot.pdf"))
  expect_false(file.exists(file.path(output_dir, "plot", "volcano_data.csv")), "Volcano CSV sidecar should not be exported")
  expect_false(file.exists(file.path(output_dir, "plot", "heatmap_data.csv")), "Heatmap CSV sidecar should not be exported")
})

test_that("CLI skips heatmap cleanly when only one DEG is selected", {
  output_dir <- tempfile(pattern = "deg-screening-one-gene-")
  cmd <- c(
    "scripts/main.R",
    "--input_file", expr_file,
    "--group_file", group_file,
    "--case", "OA",
    "--control", "control",
    "--output_dir", output_dir,
    "--logfc_threshold", "2.8"
  )
  result <- system2("Rscript", cmd, stdout = TRUE, stderr = TRUE)
  status <- attr(result, "status")
  if (!is.null(status) && status != 0) {
    stop(paste(result, collapse = "\n"), call. = FALSE)
  }

  expect_file_exists(file.path(output_dir, "plot", "volcano_plot.pdf"))
  expect_false(file.exists(file.path(output_dir, "plot", "heatmap.pdf")), "Heatmap should be skipped when fewer than two genes are available")
  expect_true(grepl("Not enough significant genes found for heatmap export; skipping heatmap",
                    paste(result, collapse = "\n"), fixed = TRUE),
              "Expected a warning explaining why the heatmap was skipped")
})

test_that("CLI same-group validation does not leave partial outputs", {
  output_dir <- tempfile(pattern = "deg-screening-same-group-")
  unlink(output_dir, recursive = TRUE, force = TRUE)
  cmd <- c(
    "scripts/main.R",
    "--input_file", expr_file,
    "--group_file", group_file,
    "--case", "OA",
    "--control", "OA",
    "--output_dir", output_dir
  )
  result <- suppressWarnings(system2("Rscript", cmd, stdout = TRUE, stderr = TRUE))
  status <- attr(result, "status")
  expect_true(!is.null(status) && status != 0, "Same-group CLI call should fail")
  expect_true(grepl("SKILL_INVALID_PARAMETER: case and control cannot be the same",
                    paste(result, collapse = "\n"), fixed = TRUE),
              "Expected same-group validation error message")
  expect_false(file.exists(output_dir), "Failed validation should not create an output directory")
})

test_that("generate_heatmap reports malformed heatmap input with SKILL code", {
  bad_heatmap <- tempfile(fileext = ".csv")
  writeLines(c("#group", "id", "Gene1"), bad_heatmap)
  expect_error_code(generate_heatmap(bad_heatmap, tempfile(pattern = "deg-heatmap-bad-")), "SKILL_MISSING_COLUMNS")
})

message("All tests passed")
