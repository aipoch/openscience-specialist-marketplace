validate_existing_file <- function(path, arg_name, extensions = character(0)) {
  if (is.null(path) || !nzchar(path))
    stop_skill("SKILL_INVALID_PARAMETER", paste(arg_name, "must be provided"))
  if (!file.exists(path))
    stop_skill("SKILL_FILE_NOT_FOUND", paste(arg_name, "does not exist:", path))
  if (file.info(path)$size == 0)
    stop_skill("SKILL_EMPTY_DATA", paste(arg_name, "is empty:", path))
  if (length(extensions) > 0 && !tolower(tools::file_ext(path)) %in% tolower(extensions))
    stop_skill("SKILL_INVALID_PARAMETER", paste(arg_name, "must use one of:", paste(extensions, collapse = ", ")))
  normalizePath(path, winslash = "/", mustWork = TRUE)
}

validate_required_value <- function(value, arg_name) {
  if (is.null(value) || !nzchar(value))
    stop_skill("SKILL_INVALID_PARAMETER", paste(arg_name, "must be provided"))
  invisible(value)
}

validate_positive_number <- function(value, arg_name, allow_zero = FALSE) {
  if (!is.numeric(value) || length(value) != 1 || is.na(value) || value < 0 || (!allow_zero && value == 0)) {
    comparator <- if (allow_zero) "a non-negative number" else "a positive number"
    stop_skill("SKILL_INVALID_PARAMETER", paste(arg_name, "must be", comparator))
  }
  invisible(value)
}

validate_choice <- function(value, arg_name, choices) {
  if (!value %in% choices)
    stop_skill("SKILL_INVALID_PARAMETER", paste(arg_name, "must be one of", paste(choices, collapse = ", ")))
  invisible(value)
}

validate_pdf_output <- function(path, arg_name) {
  validate_required_value(path, arg_name)
  if (!identical(tolower(tools::file_ext(path)), "pdf"))
    stop_skill("SKILL_INVALID_PARAMETER", paste(arg_name, "must point to a .pdf file"))
  invisible(path)
}

parse_feature_arg <- function(value) {
  features <- trimws(unlist(strsplit(value, ",", fixed = TRUE)))
  features <- features[nzchar(features)]
  if (length(features) < 3)
    stop_skill("SKILL_INSUFFICIENT_DATA", "At least 3 prognostic features are required for nomogram construction")
  unique(features)
}

parse_year_arg <- function(value) {
  years <- suppressWarnings(as.numeric(trimws(unlist(strsplit(value, ",", fixed = TRUE)))))
  years <- years[!is.na(years)]
  if (length(years) == 0 || any(years <= 0))
    stop_skill("SKILL_INVALID_PARAMETER", "--years must contain positive numeric time points")
  sort(unique(years))
}

apply_time_limit <- function(timeout_seconds) {
  validate_positive_number(timeout_seconds, "--timeout_seconds", allow_zero = TRUE)
  if (timeout_seconds > 0)
    setTimeLimit(cpu = Inf, elapsed = timeout_seconds, transient = FALSE)
  invisible(timeout_seconds)
}
