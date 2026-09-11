log_msg <- function(level, msg, use_stderr = FALSE) {
  line <- sprintf("[%s] %s | %s", toupper(level), format(Sys.time(), "%Y-%m-%d %H:%M:%S"), msg)
  cat(line, "\n", sep = "", file = if (use_stderr) stderr() else stdout())
}

log_info <- function(msg) log_msg("info", msg)
log_warn <- function(msg) log_msg("warn", msg)
log_error <- function(msg) log_msg("error", msg, use_stderr = TRUE)

stop_skill <- function(code, message) {
  stop(sprintf("%s: %s", code, message), call. = FALSE)
}

validate_required_value <- function(value, arg_name) {
  if (is.null(value) || !nzchar(value))
    stop_skill("SKILL_INVALID_PARAMETER", paste(arg_name, "must be provided"))
  invisible(value)
}

validate_existing_file <- function(path, arg_name, extensions = character(0)) {
  validate_required_value(path, arg_name)
  if (!file.exists(path))
    stop_skill("SKILL_FILE_NOT_FOUND", paste(arg_name, "does not exist:", path))
  if (length(extensions) > 0) {
    ext <- tolower(tools::file_ext(path))
    if (!ext %in% tolower(extensions))
      stop_skill("SKILL_INVALID_PARAMETER", paste(arg_name, "must use one of:", paste(extensions, collapse = ", ")))
  }
  normalizePath(path, winslash = "/", mustWork = TRUE)
}

validate_choice <- function(value, arg_name, choices) {
  if (!value %in% choices)
    stop_skill("SKILL_INVALID_PARAMETER", paste(arg_name, "must be one of:", paste(choices, collapse = ", ")))
  invisible(value)
}

validate_positive_number <- function(value, arg_name, allow_zero = FALSE) {
  if (!is.numeric(value) || length(value) != 1 || is.na(value) || value < 0 || (!allow_zero && value == 0)) {
    comparator <- if (allow_zero) "a non-negative number" else "a positive number"
    stop_skill("SKILL_INVALID_PARAMETER", paste(arg_name, "must be", comparator))
  }
  invisible(value)
}

validate_positive_integer <- function(value, arg_name, allow_zero = FALSE) {
  validate_positive_number(value, arg_name, allow_zero = allow_zero)
  if (value != as.integer(value))
    stop_skill("SKILL_INVALID_PARAMETER", paste(arg_name, "must be an integer"))
  invisible(as.integer(value))
}

validate_probability <- function(value, arg_name) {
  if (!is.numeric(value) || length(value) != 1 || is.na(value) || value <= 0 || value >= 1)
    stop_skill("SKILL_INVALID_PARAMETER", paste(arg_name, "must be between 0 and 1"))
  invisible(value)
}

parse_color_list <- function(value, arg_name) {
  tokens <- trimws(unlist(strsplit(value, ",", fixed = TRUE)))
  tokens <- tokens[nzchar(tokens)]
  if (length(tokens) == 0)
    stop_skill("SKILL_INVALID_PARAMETER", paste(arg_name, "must contain at least one color"))
  unique(tokens)
}

apply_time_limit <- function(timeout_seconds) {
  validate_positive_integer(timeout_seconds, "--timeout_seconds", allow_zero = TRUE)
  if (timeout_seconds > 0)
    setTimeLimit(cpu = Inf, elapsed = timeout_seconds, transient = FALSE)
  invisible(timeout_seconds)
}

create_output_dirs <- function(output_dir, overwrite = FALSE) {
  validate_required_value(output_dir, "--output_dir")
  if (dir.exists(output_dir)) {
    existing_entries <- list.files(output_dir, all.files = TRUE, no.. = TRUE)
    if (length(existing_entries) > 0 && !isTRUE(overwrite)) {
      stop_skill(
        "SKILL_INVALID_PARAMETER",
        paste("--output_dir already exists and is not empty:", normalizePath(output_dir, winslash = "/", mustWork = TRUE),
              "Use --overwrite to replace previous results")
      )
    }
    if (length(existing_entries) > 0)
      unlink(file.path(output_dir, existing_entries), recursive = TRUE, force = TRUE)
  }
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  for (subdir in c("data", "table", "plot"))
    dir.create(file.path(output_dir, subdir), recursive = TRUE, showWarnings = FALSE)
  list(
    root = normalizePath(output_dir, winslash = "/", mustWork = TRUE),
    data = file.path(output_dir, "data"),
    table = file.path(output_dir, "table"),
    plot = file.path(output_dir, "plot")
  )
}

save_session_info <- function(output_dir, metadata = list()) {
  session_file <- file.path(output_dir, "session_info.txt")
  lines <- c(
    "Decision Curve Analysis Session Information",
    "=========================================",
    paste("Generated:", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
    ""
  )
  if (length(metadata) > 0) {
    lines <- c(lines, "Parameters:")
    for (name in names(metadata))
      lines <- c(lines, paste("-", name, ":", paste(metadata[[name]], collapse = ",")))
    lines <- c(lines, "")
  }
  writeLines(c(lines, capture.output(sessionInfo())), session_file)
  invisible(session_file)
}
