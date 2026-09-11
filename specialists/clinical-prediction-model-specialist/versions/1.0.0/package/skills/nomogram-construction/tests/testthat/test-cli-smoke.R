testthat::test_that("nomogram CLI smoke workflow succeeds", {
  skill_root <- normalizePath(testthat::test_path("..", ".."), winslash = "/")
  output_dir <- file.path(tempdir(), "nomogram_testthat_output")
  unlink(output_dir, recursive = TRUE, force = TRUE)

  build_status <- system2("Rscript", c(file.path(skill_root, "scripts", "main.R"), "--mode", "build", "--data_file", file.path(skill_root, "tests", "data", "yuhou_cli_data.csv"), "--features", "age,gender,risk", "--output_dir", output_dir, "--overwrite"), stdout = TRUE, stderr = TRUE)
  testthat::expect_true(is.null(attr(build_status, "status")) || attr(build_status, "status") == 0)

  plot_status <- system2("Rscript", c(file.path(skill_root, "scripts", "main.R"), "--mode", "plot", "--nomo_data_file", file.path(output_dir, "data", "Nomogram_list.qs"), "--plot_save", file.path(output_dir, "plot", "nomogram_plot.pdf")), stdout = TRUE, stderr = TRUE)
  testthat::expect_true(is.null(attr(plot_status, "status")) || attr(plot_status, "status") == 0)

  testthat::expect_true(file.exists(file.path(output_dir, "data", "Nomogram_list.qs")))
  testthat::expect_true(file.exists(file.path(output_dir, "table", "nomogram_c_index.xlsx")))
  testthat::expect_true(file.exists(file.path(output_dir, "plot", "nomogram_plot.pdf")))
})
