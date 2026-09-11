project_root <- getOption("consensus.skill.root", default = normalizePath(file.path(getwd(), "..", "..")))
source(file.path(project_root, "scripts", "utils.R"))
source(file.path(project_root, "scripts", "io_utils.R"))
source(file.path(project_root, "scripts", "functions_analysis.R"))

testthat::test_that("load_gene_list handles headered csv-style input", {
  gene_file <- tempfile(fileext = ".csv")
  on.exit(unlink(gene_file), add = TRUE)
  writeLines(c("gene", "TNMD", "DPM1"), gene_file)

  testthat::expect_equal(load_gene_list(gene_file), c("TNMD", "DPM1"))
})

testthat::test_that("get_method_grid excludes unsupported combinations", {
  method_grid <- build_method_grid()

  testthat::expect_false(any(method_grid$clusterAlg == "km" & method_grid$dist != "euclidean"))
  testthat::expect_false(any(method_grid$clusterAlg == "hc" & method_grid$dist %in% c("maximum", "minkowski")))
  testthat::expect_true(any(method_grid$clusterAlg == "pam" & method_grid$dist == "pearson"))
})

testthat::test_that("validate_cli_options rejects invalid max_k", {
  opt <- list(
    input_file = file.path(project_root, "tests", "data", "expression_matrix.csv"),
    group_file = file.path(project_root, "tests", "data", "groups.csv"),
    gene_selection = "highly_variable",
    gene_list = NULL,
    max_k = 2,
    top_n = 100,
    reps = 20,
    timeout_seconds = 120,
    p_item = 0.8,
    p_feature = 1.0
  )

  testthat::expect_error(validate_cli_options(opt), "SKILL_INVALID_PARAMETER")
})

testthat::test_that("prepare_analysis_data returns disease-only matrix", {
  testthat::skip_if_not_installed("data.table")
  matrix_data <- load_expression_matrix(file.path(project_root, "tests", "data", "expression_matrix.csv"))
  group_data <- standardize_group_table(load_group_table(file.path(project_root, "tests", "data", "groups.csv")))
  prepared <- filter_disease_matrix(matrix_data, group_data, disease_group = "case", max_k = 3)

  testthat::expect_true(is.matrix(prepared$matrix))
  testthat::expect_equal(prepared$disease_group, "case")
  testthat::expect_true(all(prepared$disease_samples %in% colnames(prepared$matrix)))
  testthat::expect_gte(ncol(prepared$matrix), 3)
})
