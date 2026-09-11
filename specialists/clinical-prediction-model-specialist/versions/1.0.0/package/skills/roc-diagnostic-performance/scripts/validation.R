validate_existing_file <- function(path, arg_name, extensions = character(0)) {
  if (is.null(path) || !nzchar(path))
    stop_skill("SKILL_INVALID_PARAMETER", paste(arg_name, "must be provided"))
  if (!file.exists(path))
    stop_skill("SKILL_FILE_NOT_FOUND", paste(arg_name, "does not exist:", path))
  if (length(extensions) > 0) {
    ext <- tolower(tools::file_ext(path))
    if (!ext %in% tolower(extensions))
      stop_skill("SKILL_INVALID_PARAMETER", paste(arg_name, "must use one of:", paste(extensions, collapse = ", ")))
  }
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

apply_time_limit <- function(timeout_seconds) {
  validate_positive_number(timeout_seconds, "--timeout_seconds", allow_zero = TRUE)
  if (timeout_seconds > 0)
    setTimeLimit(cpu = Inf, elapsed = timeout_seconds, transient = FALSE)
  invisible(timeout_seconds)
}

parse_gene_arg <- function(value) {
  genes <- trimws(unlist(strsplit(value, ",", fixed = TRUE)))
  genes <- genes[nzchar(genes)]
  if (length(genes) == 0)
    stop_skill("SKILL_INVALID_PARAMETER", "--marker_genes must contain at least one gene name")
  unique(genes)
}

parse_bool_arg <- function(value, arg_name) {
  validate_choice(value, arg_name, c("true", "false"))
  identical(value, "true")
}

parse_color_list <- function(value) {
  colors <- trimws(unlist(strsplit(value, ",", fixed = TRUE)))
  colors <- colors[nzchar(colors)]
  if (length(colors) == 0)
    stop_skill("SKILL_INVALID_PARAMETER", "--line_colors must contain at least one color")
  colors
}
