test_data_path <- function(filename) {
  normalizePath(file.path(getOption("batch.skill.root"), "tests", "data", filename), mustWork = TRUE)
}

main_script_path <- function() {
  normalizePath(file.path(getOption("batch.skill.root"), "scripts", "main.R"), mustWork = TRUE)
}

testthat::test_that("expression matrix loader returns numeric matrix", {
  expr_mat <- read_expression_matrix(test_data_path("expression_matrix_merged.csv"))

  testthat::expect_true(is.matrix(expr_mat))
  testthat::expect_true(is.numeric(expr_mat))
  testthat::expect_gte(nrow(expr_mat), 50)
  testthat::expect_equal(ncol(expr_mat), 79)
})

testthat::test_that("metadata loader validates required columns", {
  bad_meta <- tempfile(fileext = ".csv")
  on.exit(unlink(bad_meta, force = TRUE), add = TRUE)
  writeLines(c("sample,batch", "S1,b1"), bad_meta)

  testthat::expect_error(
    read_sample_metadata(bad_meta, "sample", "group", "batch"),
    "SKILL_MISSING_COLUMNS"
  )
})

testthat::test_that("file validation rejects empty inputs", {
  empty_file <- tempfile(fileext = ".csv")
  on.exit(unlink(empty_file, force = TRUE), add = TRUE)
  file.create(empty_file)

  testthat::expect_error(validate_existing_file(empty_file, "Expression matrix"), "SKILL_EMPTY_FILE")
})

testthat::test_that("automatic log transform does not double-log bundled test data", {
  expr_mat <- read_expression_matrix(test_data_path("expression_matrix_merged.csv"))
  testthat::expect_false(should_log_transform(expr_mat, "auto"))
})

testthat::test_that("sample alignment preserves metadata order", {
  expr_mat <- read_expression_matrix(test_data_path("expression_matrix_merged.csv"))
  meta <- read_sample_metadata(test_data_path("sample_info.csv"), "sample", "group", "batch")
  aligned <- align_inputs(expr_mat, meta)

  testthat::expect_equal(colnames(aligned$expr), meta$sample_id)
  testthat::expect_equal(nrow(aligned$metadata), ncol(aligned$expr))
})

testthat::test_that("sample alignment warns and subsets when metadata covers a cohort subset", {
  expr_mat <- read_expression_matrix(test_data_path("expression_matrix_merged.csv"))
  full_meta <- utils::read.csv(test_data_path("sample_info.csv"), stringsAsFactors = FALSE)
  custom_meta <- full_meta[seq_len(8), c("sample", "group", "batch")]
  colnames(custom_meta) <- c("sample_id", "condition", "platform_batch")

  custom_meta_file <- tempfile(fileext = ".csv")
  on.exit(unlink(custom_meta_file, force = TRUE), add = TRUE)
  utils::write.csv(custom_meta, custom_meta_file, row.names = FALSE)

  meta <- read_sample_metadata(custom_meta_file, "sample_id", "condition", "platform_batch")

  log_output <- capture.output(aligned <- align_inputs(expr_mat, meta))

  testthat::expect_true(any(grepl("Ignoring 71 expression columns absent from metadata", log_output)))
  testthat::expect_equal(colnames(aligned$expr), meta$sample_id)
  testthat::expect_equal(ncol(aligned$expr), 8)
})

testthat::test_that("ellipse gating skips batches with fewer than four samples", {
  plot_data <- data.frame(
    PC1 = c(-1, -0.1, 0.7, 1.2, 2.4, 3.1),
    PC2 = c(0.2, 0.5, 1.1, 1.6, 2.1, 3.0),
    batch = factor(c("A", "A", "A", "B", "B", "B"))
  )

  testthat::expect_equal(get_ellipse_batches(plot_data), character())
})

testthat::test_that("ellipse eligibility skips low-rank PCA batches", {
  plot_data <- data.frame(
    PC1 = c(1, 1, 1, 3, 3, 3),
    PC2 = c(0, 0, 0, 2, 2, 2),
    batch = factor(c("A", "A", "A", "B", "B", "B"))
  )

  testthat::expect_equal(get_ellipse_batches(plot_data), character())
})

testthat::test_that("timeout errors are normalized to skill timeout code", {
  testthat::expect_equal(
    normalize_timeout_error("reached elapsed time limit"),
    "SKILL_TIMEOUT: Analysis exceeded the configured time limit"
  )
})

testthat::test_that("session info output stays free of operational log lines", {
  out_dir <- tempfile(pattern = "session-info-")
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(out_dir, recursive = TRUE, force = TRUE), add = TRUE)

  session_file <- save_session_info(out_dir)
  session_lines <- readLines(session_file, warn = FALSE)

  testthat::expect_true(any(grepl("^R version ", session_lines)))
  testthat::expect_false(any(grepl("^\\[INFO\\]", session_lines)))
})

testthat::test_that("full pipeline writes expected outputs", {
  testthat::skip_if_not_installed("sva")
  testthat::skip_if_not_installed("limma")
  testthat::skip_if_not_installed("ggplot2")

  out_dir <- tempfile(pattern = "batch-correction-")
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(out_dir, recursive = TRUE, force = TRUE), add = TRUE)

  opt <- list(
    input_file = test_data_path("expression_matrix_merged.csv"),
    group_file = test_data_path("sample_info.csv"),
    output_dir = out_dir,
    sample_column = "sample",
    batch_column = "batch",
    group_column = "group",
    log_transform = "auto",
    timeout_seconds = 600,
    seed = 42
  )
  result <- run_batch_correction(opt)

  expected_files <- c(
    "corrected_expression_matrix.csv",
    "matched_sample_info.csv",
    "batch_before_boxplot.pdf",
    "batch_after_boxplot.pdf",
    "batch_before_pca.pdf",
    "batch_after_pca.pdf",
    "batch_before_clustering.pdf",
    "batch_after_clustering.pdf"
  )

  testthat::expect_true(is.list(result))
  testthat::expect_true(all(file.exists(file.path(out_dir, expected_files))))
})

testthat::test_that("CLI run produces corrected matrix and session info", {
  testthat::skip_if_not_installed("sva")
  testthat::skip_if_not_installed("limma")
  testthat::skip_if_not_installed("optparse")
  testthat::skip_if_not_installed("ggplot2")

  out_dir <- tempfile(pattern = "batch-cli-")
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(out_dir, recursive = TRUE, force = TRUE), add = TRUE)

  cmd_output <- system2(
    "Rscript",
    c(
      main_script_path(),
      "-i", test_data_path("expression_matrix_merged.csv"),
      "-g", test_data_path("sample_info.csv"),
      "-o", out_dir
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  cmd_status <- attr(cmd_output, "status")
  if (is.null(cmd_status))
    cmd_status <- 0L

  testthat::expect_equal(cmd_status, 0L, info = paste(cmd_output, collapse = "\n"))
  testthat::expect_true(file.exists(file.path(out_dir, "corrected_expression_matrix.csv")))
  testthat::expect_true(file.exists(file.path(out_dir, "session_info.txt")))
  testthat::expect_true(file.exists(file.path(out_dir, "matched_sample_info.csv")))
})
