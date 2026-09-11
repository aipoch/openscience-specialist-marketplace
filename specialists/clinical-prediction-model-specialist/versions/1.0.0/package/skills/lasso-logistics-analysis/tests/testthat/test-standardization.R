project_root <- getOption("lasso.skill.root", default = normalizePath(file.path(getwd(), "..", "..")))

testthat::test_that("load_expression_matrix rejects empty files", {
  empty_file <- tempfile(fileext = ".csv")
  on.exit(unlink(empty_file), add = TRUE)
  file.create(empty_file)

  testthat::expect_error(
    load_expression_matrix(empty_file),
    "SKILL_EMPTY_FILE"
  )
})

testthat::test_that("prepare_model_inputs rejects identical class labels", {
  expr_mat <- load_expression_matrix(file.path(project_root, "tests", "data", "expression_matrix.csv"))
  group_df <- load_group_data(file.path(project_root, "tests", "data", "groups.csv"))

  testthat::expect_error(
    prepare_model_inputs(expr_mat, group_df, "case", "case", NULL, 5),
    "SKILL_INVALID_PARAMETER"
  )
})

testthat::test_that("run_lasso_analysis produces flat reproducible outputs", {
  testthat::skip_if_not_installed("glmnet")

  out1 <- tempfile(pattern = "lasso_out1_")
  out2 <- tempfile(pattern = "lasso_out2_")
  unlink(c(out1, out2), recursive = TRUE, force = TRUE)
  on.exit(unlink(c(out1, out2), recursive = TRUE, force = TRUE), add = TRUE)

  args <- list(
    input_file = file.path(project_root, "tests", "data", "expression_matrix.csv"),
    group_file = file.path(project_root, "tests", "data", "groups.csv"),
    case_group = "case",
    control_group = "control",
    feature = file.path(project_root, "tests", "data", "genes.csv"),
    nfolds = 5,
    cv_title = "",
    path_title = "",
    seed = 42
  )

  do.call(run_lasso_analysis, c(args, list(output_dir = out1)))
  do.call(run_lasso_analysis, c(args, list(output_dir = out2)))

  expected_files <- c(
    "coefficient.csv",
    "feature_matrix.csv",
    "lasso_lambda_binary_plot.pdf",
    "lasso_var_binary_plot.pdf",
    "selected_features.txt"
  )

  testthat::expect_true(all(file.exists(file.path(out1, expected_files))))
  testthat::expect_false(any(dir.exists(file.path(out1, c("data", "plot", "table")))))

  coef1 <- utils::read.csv(file.path(out1, "coefficient.csv"), stringsAsFactors = FALSE)
  coef2 <- utils::read.csv(file.path(out2, "coefficient.csv"), stringsAsFactors = FALSE)
  testthat::expect_equal(coef1, coef2)
})
