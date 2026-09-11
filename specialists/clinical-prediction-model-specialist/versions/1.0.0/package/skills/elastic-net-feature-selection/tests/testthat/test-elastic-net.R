test_data_path <- function(filename) {
  normalizePath(file.path(getOption("elastic.skill.root"), "tests", "data", filename), mustWork = TRUE)
}

main_script_path <- function() {
  normalizePath(file.path(getOption("elastic.skill.root"), "scripts", "main.R"), mustWork = TRUE)
}

run_rscript <- function(args, workdir = ".") {
  rscript_bin <- Sys.which("Rscript")
  testthat::skip_if(rscript_bin == "", "Rscript is not available")
  old_dir <- getwd()
  on.exit(setwd(old_dir), add = TRUE)
  setwd(workdir)
  output <- suppressWarnings(system2(rscript_bin, args = args, stdout = TRUE, stderr = TRUE))
  list(output = output, status = attr(output, "status") %||% 0L)
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

testthat::test_that("expression matrix loader returns numeric matrix", {
  expr <- read_expression_matrix(test_data_path("expression_matrix.csv"))
  testthat::expect_true(is.matrix(expr))
  testthat::expect_true(is.numeric(expr))
  testthat::expect_equal(dim(expr), c(10L, 20L))
})

testthat::test_that("group loader validates required columns", {
  bad_file <- tempfile(fileext = ".csv")
  on.exit(unlink(bad_file, force = TRUE), add = TRUE)
  writeLines(c("sample,batch", "S1,b1", "S2,b2", "S3,b3", "S4,b4"), bad_file)
  testthat::expect_error(read_group_file(bad_file), "SKILL_MISSING_COLUMNS")
})

testthat::test_that("cli option validation catches invalid timeout", {
  opt <- list(
    input_file = "a.csv",
    group_file = "b.csv",
    case_group = "case",
    control_group = "control",
    alpha = "0.5",
    alpha_grid = "0,0.5,1",
    nfolds = 5,
    lambda_choice = "lambda.min",
    standardize = TRUE,
    timeout_seconds = 0
  )
  testthat::expect_error(validate_cli_options(opt), "SKILL_INVALID_PARAMETER")
})

testthat::test_that("alpha parsing supports fixed and auto modes", {
  testthat::expect_equal(parse_alpha_spec("0.5")$value, 0.5)
  testthat::expect_equal(parse_alpha_spec("auto")$mode, "auto")
  testthat::expect_equal(parse_alpha_grid("0,0.5,1"), c(0, 0.5, 1))
  testthat::expect_error(parse_alpha_spec("bad"), "SKILL_INVALID_PARAMETER")
})

testthat::test_that("ridge coefficients are not exported as selected features", {
  coefficients <- data.frame(
    feature = c("(Intercept)", "GeneA", "GeneB"),
    coefficient = c(0.1, 1e-4, -2e-4),
    stringsAsFactors = FALSE
  )

  selected <- extract_selected_features(coefficients, selected_alpha = 0)

  testthat::expect_equal(nrow(selected), 0L)
  testthat::expect_equal(names(selected), c("feature", "coefficient"))
})

testthat::test_that("run_analysis writes expected outputs", {
  testthat::skip_if_not_installed("glmnet")
  out_dir <- tempfile(pattern = "elastic-net-")
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(out_dir, recursive = TRUE, force = TRUE), add = TRUE)

  result <- run_analysis(list(
    input_file = test_data_path("expression_matrix.csv"),
    group_file = test_data_path("groups.csv"),
    output_dir = out_dir,
    feature_file = test_data_path("genes.csv"),
    case_group = "case",
    control_group = "control",
    alpha = "0.5",
    alpha_grid = "0,0.5,1",
    nfolds = 5,
    lambda_choice = "lambda.min",
    standardize = TRUE,
    timeout_seconds = 600,
    seed = 42
  ))

  expected <- c(
    "alpha_tuning.csv",
    "model_coefficients.csv",
    "selected_features.csv",
    "feature_matrix.csv",
    "coefficient_path.pdf",
    "cv_curve.pdf"
  )

  testthat::expect_true(is.list(result))
  testthat::expect_true(all(file.exists(file.path(out_dir, expected))))
  testthat::expect_false(file.exists(file.path(out_dir, "elastic_net_summary.csv")))
})

testthat::test_that("run_analysis supports automatic alpha selection", {
  testthat::skip_if_not_installed("glmnet")
  out_dir <- tempfile(pattern = "elastic-net-auto-")
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(out_dir, recursive = TRUE, force = TRUE), add = TRUE)

  result <- run_analysis(list(
    input_file = test_data_path("expression_matrix.csv"),
    group_file = test_data_path("groups.csv"),
    output_dir = out_dir,
    feature_file = test_data_path("genes.csv"),
    case_group = "case",
    control_group = "control",
    alpha = "auto",
    alpha_grid = "0,0.5,1",
    nfolds = 5,
    lambda_choice = "lambda.min",
    standardize = TRUE,
    timeout_seconds = 600,
    seed = 42
  ))

  testthat::expect_equal(result$alpha_mode, "auto")
  testthat::expect_true(result$selected_alpha %in% c(0, 0.5, 1))
  testthat::expect_true(file.exists(file.path(out_dir, "alpha_tuning.csv")))
})

testthat::test_that("run_analysis leaves selected_features empty for ridge alpha", {
  testthat::skip_if_not_installed("glmnet")
  out_dir <- tempfile(pattern = "elastic-net-ridge-")
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(out_dir, recursive = TRUE, force = TRUE), add = TRUE)

  result <- run_analysis(list(
    input_file = test_data_path("expression_matrix.csv"),
    group_file = test_data_path("groups.csv"),
    output_dir = out_dir,
    feature_file = test_data_path("genes.csv"),
    case_group = "case",
    control_group = "control",
    alpha = "0",
    alpha_grid = "0,0.5,1",
    nfolds = 5,
    lambda_choice = "lambda.min",
    standardize = TRUE,
    timeout_seconds = 600,
    seed = 42
  ))

  selected <- read.csv(file.path(out_dir, "selected_features.csv"), stringsAsFactors = FALSE)

  testthat::expect_equal(result$selected_alpha, 0)
  testthat::expect_equal(nrow(selected), 0L)
})

testthat::test_that("CLI help renders successfully", {
  testthat::skip_if_not_installed("optparse")
  res <- run_rscript(c(main_script_path(), "--help"), workdir = getOption("elastic.skill.root"))
  testthat::expect_equal(res$status, 0L)
  testthat::expect_true(any(grepl("--input_file", res$output, fixed = TRUE)))
  testthat::expect_true(any(grepl("--group_file", res$output, fixed = TRUE)))
  testthat::expect_true(any(grepl("--timeout_seconds", res$output, fixed = TRUE)))
  testthat::expect_true(any(grepl("--alpha_grid", res$output, fixed = TRUE)))
})

testthat::test_that("CLI smoke run produces key outputs", {
  testthat::skip_if_not_installed("optparse")
  testthat::skip_if_not_installed("glmnet")
  out_dir <- tempfile(pattern = "elastic-net-cli-")
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(out_dir, recursive = TRUE, force = TRUE), add = TRUE)

  res <- run_rscript(c(
    main_script_path(),
    "--input_file", test_data_path("expression_matrix.csv"),
    "--group_file", test_data_path("groups.csv"),
    "--feature_file", test_data_path("genes.csv"),
    "--alpha", "0.5",
    "--nfolds", "5",
    "--output_dir", out_dir,
    "--seed", "42"
  ), workdir = getOption("elastic.skill.root"))

  testthat::expect_equal(res$status, 0L, info = paste(res$output, collapse = "\n"))
  testthat::expect_true(file.exists(file.path(out_dir, "selected_features.csv")))
  testthat::expect_true(file.exists(file.path(out_dir, "session_info.txt")))
  testthat::expect_false(file.exists(file.path(out_dir, "run.log")))
  testthat::expect_false(file.exists(file.path(out_dir, "warnings.log")))
  testthat::expect_false(file.exists(file.path(out_dir, "elastic_net_summary.csv")))
})

testthat::test_that("CLI supports automatic alpha selection", {
  testthat::skip_if_not_installed("optparse")
  testthat::skip_if_not_installed("glmnet")
  out_dir <- tempfile(pattern = "elastic-net-cli-auto-")
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(out_dir, recursive = TRUE, force = TRUE), add = TRUE)

  res <- run_rscript(c(
    main_script_path(),
    "--input_file", test_data_path("expression_matrix.csv"),
    "--group_file", test_data_path("groups.csv"),
    "--feature_file", test_data_path("genes.csv"),
    "--alpha", "auto",
    "--alpha_grid", "0,0.5,1",
    "--nfolds", "5",
    "--output_dir", out_dir,
    "--seed", "42"
  ), workdir = getOption("elastic.skill.root"))

  testthat::expect_equal(res$status, 0L, info = paste(res$output, collapse = "\n"))
  testthat::expect_true(file.exists(file.path(out_dir, "alpha_tuning.csv")))
})

testthat::test_that("CLI validation failures use structured error logging", {
  testthat::skip_if_not_installed("optparse")
  out_dir <- tempfile(pattern = "elastic-net-cli-invalid-")
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(out_dir, recursive = TRUE, force = TRUE), add = TRUE)

  res <- run_rscript(c(
    main_script_path(),
    "--input_file", test_data_path("expression_matrix.csv"),
    "--group_file", test_data_path("groups.csv"),
    "--alpha", "bad",
    "--output_dir", out_dir
  ), workdir = getOption("elastic.skill.root"))

  testthat::expect_equal(res$status, 1L)
  testthat::expect_true(any(grepl("^\\[ERROR\\].*SKILL_INVALID_PARAMETER", res$output)))
  testthat::expect_true(file.exists(file.path(out_dir, "session_info.txt")))
})

testthat::test_that("CLI rejects multiclass group files", {
  testthat::skip_if_not_installed("optparse")
  out_dir <- tempfile(pattern = "elastic-net-cli-multiclass-")
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(out_dir, recursive = TRUE, force = TRUE), add = TRUE)

  group_file <- tempfile(fileext = ".csv")
  on.exit(unlink(group_file, force = TRUE), add = TRUE)
  writeLines(c(
    "sample,group",
    "Sample01,case",
    "Sample02,control",
    "Sample03,other",
    "Sample04,control",
    "Sample05,case",
    "Sample06,control"
  ), group_file)

  res <- run_rscript(c(
    main_script_path(),
    "--input_file", test_data_path("expression_matrix.csv"),
    "--group_file", group_file,
    "--feature_file", test_data_path("genes.csv"),
    "--output_dir", out_dir,
    "--seed", "42"
  ), workdir = getOption("elastic.skill.root"))

  testthat::expect_equal(res$status, 1L)
  testthat::expect_true(any(grepl("SKILL_INVALID_DATA: group file contains unsupported labels", res$output, fixed = TRUE)))
  testthat::expect_true(file.exists(file.path(out_dir, "session_info.txt")))
})
