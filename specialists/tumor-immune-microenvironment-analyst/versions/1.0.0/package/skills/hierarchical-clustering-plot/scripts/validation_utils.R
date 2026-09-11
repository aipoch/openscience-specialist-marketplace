check_files <- function(input_file, group_file) {
  input_files <- c(input_file = input_file, group_file = group_file)
  for (file_name in names(input_files)) {
    file_path <- input_files[[file_name]]
    if (!file.exists(file_path))
      stop("SKILL_FILE_NOT_FOUND: File does not exist: ", file_path, call. = FALSE)
    if (isTRUE(file.info(file_path)$size == 0))
      stop("SKILL_EMPTY_FILE: Input file is empty: ", file_path, call. = FALSE)
  }
  invisible(TRUE)
}

check_output_dir <- function(output_dir) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  if (!dir.exists(output_dir))
    stop("SKILL_FILE_NOT_FOUND: Output directory could not be created: ", output_dir, call. = FALSE)

  probe_file <- tempfile(pattern = "write-test-", tmpdir = output_dir, fileext = ".tmp")
  ok <- tryCatch({
    writeLines("ok", probe_file)
    TRUE
  }, error = function(e) FALSE)
  if (!ok)
    stop("SKILL_WRITE_ERROR: Output directory is not writable: ", output_dir, call. = FALSE)
  if (file.exists(probe_file))
    file.remove(probe_file)

  invisible(TRUE)
}

validate_required_columns <- function(df, required_cols, dataset_name) {
  missing_cols <- setdiff(required_cols, colnames(df))
  if (length(missing_cols) > 0)
    stop(
      "SKILL_MISSING_COLUMNS: In ", dataset_name,
      ", required columns missing: ", paste(missing_cols, collapse = ", "),
      call. = FALSE
    )
  invisible(TRUE)
}

validate_scalar_numeric <- function(value, parameter_name, lower_bound = NULL) {
  if (!is.numeric(value) || length(value) != 1 || is.na(value))
    stop("SKILL_INVALID_TYPE: ", parameter_name, " must be a single numeric value", call. = FALSE)
  if (!is.null(lower_bound) && value <= lower_bound)
    stop("SKILL_INVALID_PARAMETER: ", parameter_name, " must be > ", lower_bound, call. = FALSE)
  invisible(TRUE)
}
