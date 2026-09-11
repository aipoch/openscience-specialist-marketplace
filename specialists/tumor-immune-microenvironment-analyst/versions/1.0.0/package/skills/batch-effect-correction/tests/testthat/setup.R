resolve_project_root <- function() {
  test_path <- tryCatch(testthat::test_path(), error = function(e) ".")
  normalizePath(file.path(test_path, "..", ".."), winslash = "/", mustWork = FALSE)
}

options(batch.skill.root = resolve_project_root())
