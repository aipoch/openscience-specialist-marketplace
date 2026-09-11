test_data_path <- function(filename) {
  normalizePath(file.path("..", "data", filename), mustWork = TRUE)
}

main_script_path <- function() {
  normalizePath(file.path("..", "..", "scripts", "main.R"), mustWork = TRUE)
}

testthat::test_that("input validation catches missing files", {
  testthat::expect_error(
    check_files("missing-expression.csv", "missing-groups.csv"),
    "SKILL_FILE_NOT_FOUND"
  )
})

testthat::test_that("expression matrix rejects non-numeric values", {
  bad_expr <- tempfile(fileext = ".csv")
  on.exit(unlink(bad_expr, force = TRUE), add = TRUE)

  writeLines(
    c(
      ",Sample01,Sample02",
      "GeneA,1,2",
      "GeneB,3,not_numeric"
    ),
    bad_expr
  )

  testthat::expect_error(
    load_expression_matrix(bad_expr),
    "SKILL_INVALID_TYPE: Expression values must be numeric"
  )
})

testthat::test_that("group data rejects empty selected labels", {
  bad_group <- tempfile(fileext = ".csv")
  on.exit(unlink(bad_group, force = TRUE), add = TRUE)

  writeLines(
    c(
      "sample,batch",
      "Sample01,batch1",
      "Sample02,"
    ),
    bad_group
  )

  testthat::expect_error(
    load_group_data(bad_group, "batch"),
    "SKILL_INVALID_DATA: Selected label column contains empty values"
  )
})

testthat::test_that("expression matrix loads with expected dimensions", {
  expr_mat <- load_expression_matrix(test_data_path("sample_expression_matrix.csv"))
  testthat::expect_true(is.matrix(expr_mat))
  testthat::expect_true(is.numeric(expr_mat))
  testthat::expect_equal(ncol(expr_mat), 40)
  testthat::expect_gte(nrow(expr_mat), 2)
})

testthat::test_that("group data and sample alignment are valid", {
  expr_mat <- load_expression_matrix(test_data_path("sample_expression_matrix.csv"))
  group_df <- load_group_data(test_data_path("sample_groups.csv"), "batch")
  aligned <- align_samples(expr_mat, group_df)

  testthat::expect_equal(ncol(aligned$expr), nrow(group_df))
  testthat::expect_equal(colnames(aligned$expr), group_df$sample_id)
  testthat::expect_equal(aligned$groups$label[1], "batch1")
})

testthat::test_that("clustering order is reproducible", {
  expr_mat <- load_expression_matrix(test_data_path("sample_expression_matrix.csv"))
  group_df <- load_group_data(test_data_path("sample_groups.csv"), "batch")
  aligned <- align_samples(expr_mat, group_df)

  set.seed(42)
  distance_1 <- build_distance_matrix(aligned$expr, "euclidean")
  hc_1 <- build_clustering(distance_1, "complete")

  set.seed(42)
  distance_2 <- build_distance_matrix(aligned$expr, "euclidean")
  hc_2 <- build_clustering(distance_2, "complete")

  testthat::expect_equal(hc_1$order, hc_2$order)
})

testthat::test_that("timeout errors are normalized to skill timeout code", {
  timeout_error <- simpleError("reached elapsed time limit")

  testthat::expect_equal(
    normalize_error(timeout_error),
    "SKILL_TIMEOUT: Computation exceeded time limit"
  )
})

testthat::test_that("memory logging uses total gc memory and emits warnings at threshold", {
  mocked_gc <- matrix(
    c(100, 1.5, 200, 2.5),
    nrow = 2,
    byrow = TRUE,
    dimnames = list(c("Ncells", "Vcells"), c("used", "(Mb)"))
  )

  testthat::expect_equal(current_memory_used_mb(mocked_gc), 4)

  assign("gc", function(verbose = FALSE) mocked_gc, envir = .GlobalEnv)
  on.exit(rm(gc, envir = .GlobalEnv), add = TRUE)

  testthat::expect_warning(
    log_memory_usage("mock stage", warn_threshold_mb = 3),
    "SKILL_MEMORY_WARNING: Memory usage reached 4.00 MB after mock stage"
  )
})

testthat::test_that("full pipeline writes expected outputs", {
  out_dir <- tempfile(pattern = "hc-test-")
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(out_dir, recursive = TRUE, force = TRUE), add = TRUE)

  run_clustering_analysis(
    input_file = test_data_path("sample_expression_matrix.csv"),
    group_file = test_data_path("sample_groups.csv"),
      output_dir = out_dir,
      distance_method = "euclidean",
      linkage_method = "complete",
      label_column = "batch",
      label_cex = 0.8
    )

  expected_files <- c(
    "sample_distance_matrix.csv",
    "clustering_order.csv",
    "matched_samples.csv",
    "hierarchical_clustering_plot.pdf"
  )
  for (file_name in expected_files)
    testthat::expect_true(file.exists(file.path(out_dir, file_name)))
})

testthat::test_that("CLI run writes log and session outputs", {
  out_dir <- tempfile(pattern = "hc-cli-")
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(out_dir, recursive = TRUE, force = TRUE), add = TRUE)

  cmd_output <- system2(
    "Rscript",
    c(
      main_script_path(),
      "-i", test_data_path("sample_expression_matrix.csv"),
      "-g", test_data_path("sample_groups.csv"),
      "-o", out_dir,
      "-l", "batch"
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  cmd_status <- attr(cmd_output, "status")
  if (is.null(cmd_status))
    cmd_status <- 0L

  testthat::expect_equal(
    cmd_status,
    0L,
    info = paste(cmd_output, collapse = "\n")
  )
  testthat::expect_true(file.exists(file.path(out_dir, "hierarchical_clustering_plot.pdf")))
  testthat::expect_true(file.exists(file.path(out_dir, "session_info.txt")))
  testthat::expect_false(file.exists(file.path(out_dir, "analysis.log")))
  testthat::expect_false(file.exists(file.path(out_dir, "warnings.log")))
})

testthat::test_that("invalid label CLI run does not create output artifacts", {
  out_dir <- tempfile(pattern = "hc-invalid-")
  on.exit(unlink(out_dir, recursive = TRUE, force = TRUE), add = TRUE)

  cmd_output <- suppressWarnings(system2(
    "Rscript",
    c(
      main_script_path(),
      "-i", test_data_path("sample_expression_matrix.csv"),
      "-g", test_data_path("sample_groups.csv"),
      "-o", out_dir,
      "-l", "missing_label"
    ),
    stdout = TRUE,
    stderr = TRUE
  ))
  cmd_status <- attr(cmd_output, "status")
  if (is.null(cmd_status))
    cmd_status <- 0L

  testthat::expect_equal(cmd_status, 1L)
  testthat::expect_true(any(grepl("SKILL_INVALID_PARAMETER: label column not found", cmd_output, fixed = TRUE)))
  testthat::expect_false(dir.exists(out_dir))
  testthat::expect_false(file.exists(file.path(out_dir, "session_info.txt")))
})
