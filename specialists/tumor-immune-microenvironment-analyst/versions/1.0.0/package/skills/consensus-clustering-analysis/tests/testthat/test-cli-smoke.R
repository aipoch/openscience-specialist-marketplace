run_rscript <- function(args, workdir = ".") {
  rscript_bin <- Sys.which("Rscript")
  testthat::skip_if(rscript_bin == "", "Rscript is not available")

  old_dir <- getwd()
  on.exit(setwd(old_dir), add = TRUE)
  setwd(workdir)

  output <- suppressWarnings(system2(rscript_bin, args = args, stdout = TRUE, stderr = TRUE))

  list(
    output = output,
    status = attr(output, "status") %||% 0L
  )
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

project_root <- getOption("consensus.skill.root", default = normalizePath(file.path(getwd(), "..", "..")))

testthat::test_that("CLI help renders successfully", {
  testthat::skip_if_not_installed("optparse")

  res <- run_rscript(c("scripts/main.R", "--help"), workdir = project_root)

  testthat::expect_equal(res$status, 0L)
  testthat::expect_true(any(grepl("--input_file", res$output, fixed = TRUE)))
  testthat::expect_true(any(grepl("--group_file", res$output, fixed = TRUE)))
})

testthat::test_that("CLI invalid option returns SKILL_INVALID_PARAMETER", {
  testthat::skip_if_not_installed("optparse")

  res <- run_rscript(c("scripts/main.R", "--badflag"), workdir = project_root)

  testthat::expect_equal(res$status, 1L)
  testthat::expect_true(any(grepl("SKILL_INVALID_PARAMETER", res$output, fixed = TRUE)))
})

testthat::test_that("CLI smoke run produces key outputs", {
  testthat::skip_if_not_installed("optparse")
  testthat::skip_if_not_installed("ConsensusClusterPlus")

  output_dir <- file.path(tempdir(), paste0("consensus-smoke-", as.integer(Sys.time())))
  on.exit(unlink(output_dir, recursive = TRUE, force = TRUE), add = TRUE)

  res <- run_rscript(c(
    "scripts/main.R",
    "--input_file", "tests/data/expression_matrix.csv",
    "--group_file", "tests/data/groups.csv",
    "--disease_group", "case",
    "--max_k", "3",
    "--reps", "20",
    "--output_dir", output_dir,
    "--seed", "42"
  ), workdir = project_root)

  testthat::expect_equal(res$status, 0L)
  testthat::expect_true(file.exists(file.path(output_dir, "Consensus Matrix Plot.pdf")))
  testthat::expect_true(file.exists(file.path(output_dir, "CDF curve Plot.pdf")))
  testthat::expect_true(file.exists(file.path(output_dir, "session_info.txt")))
  testthat::expect_true(file.exists(file.path(output_dir, "Cluster_res.csv")))
  testthat::expect_true(file.exists(file.path(output_dir, "genes_for_clustering.csv")))
  testthat::expect_true(file.exists(file.path(output_dir, "samples_for_clustering.csv")))
  testthat::expect_true(file.exists(file.path(output_dir, "result_pearson_hc", "PAC_scores.csv")))
  testthat::expect_false(dir.exists(file.path(output_dir, "data")))
  testthat::expect_false(dir.exists(file.path(output_dir, "table")))
  testthat::expect_false(dir.exists(file.path(output_dir, "plot")))
  testthat::expect_false(file.exists(file.path(output_dir, "optimal_params.csv")))
  testthat::expect_length(list.files(output_dir, pattern = "\\.Rdata$", recursive = TRUE), 0L)
  testthat::expect_false(file.exists(file.path(output_dir, "run.log")))
  testthat::expect_false(file.exists(file.path(output_dir, "warnings.log")))
  testthat::expect_false(file.exists(file.path(output_dir, "table", "analysis_summary.txt")))
  testthat::expect_length(list.files(output_dir, pattern = "\\.log\\.csv$", recursive = TRUE), 0L)
  cluster_res <- utils::read.csv(file.path(output_dir, "Cluster_res.csv"), stringsAsFactors = FALSE)
  testthat::expect_equal(colnames(cluster_res), c("dist", "clusterAlg", "bestK", "PAC", "is_best"))
  testthat::expect_equal(sum(cluster_res$is_best), 1)
  testthat::expect_true(any(cluster_res$is_best & !is.na(cluster_res$PAC)))
})

testthat::test_that("CLI stress run stays free of repeated benign warnings", {
  testthat::skip_if_not_installed("optparse")
  testthat::skip_if_not_installed("ConsensusClusterPlus")

  output_dir <- file.path(tempdir(), paste0("consensus-stress-", as.integer(Sys.time())))
  on.exit(unlink(output_dir, recursive = TRUE, force = TRUE), add = TRUE)

  res <- run_rscript(c(
    "scripts/main.R",
    "--input_file", "tests/data/expression_matrix.csv",
    "--group_file", "tests/data/groups.csv",
    "--disease_group", "case",
    "--max_k", "4",
    "--reps", "30",
    "--top_n", "10",
    "--p_item", "0.8",
    "--p_feature", "0.9",
    "--output_dir", output_dir,
    "--seed", "42"
  ), workdir = project_root)

  testthat::expect_equal(res$status, 0L)
  testthat::expect_false(any(grepl("the condition has length > 1 and only the first element will be used", res$output, fixed = TRUE)))
  cluster_res <- utils::read.csv(file.path(output_dir, "Cluster_res.csv"), stringsAsFactors = FALSE)
  testthat::expect_equal(sum(cluster_res$is_best), 1)
})

testthat::test_that("CLI failed run still writes session info", {
  testthat::skip_if_not_installed("optparse")

  output_dir <- file.path(tempdir(), paste0("consensus-failed-run-", as.integer(Sys.time())))
  gene_file <- tempfile(fileext = ".csv")
  on.exit(unlink(output_dir, recursive = TRUE, force = TRUE), add = TRUE)
  on.exit(unlink(gene_file, force = TRUE), add = TRUE)
  writeLines("TNMD", gene_file)

  res <- run_rscript(c(
    "scripts/main.R",
    "--input_file", "tests/data/expression_matrix.csv",
    "--group_file", "tests/data/groups.csv",
    "--disease_group", "case",
    "--gene_selection", "custom",
    "--gene_list", gene_file,
    "--max_k", "3",
    "--reps", "20",
    "--output_dir", output_dir,
    "--seed", "42"
  ), workdir = project_root)

  testthat::expect_equal(res$status, 1L)
  testthat::expect_true(any(grepl("SKILL_INVALID_DATA", res$output, fixed = TRUE)))
  testthat::expect_true(file.exists(file.path(output_dir, "session_info.txt")))
})
