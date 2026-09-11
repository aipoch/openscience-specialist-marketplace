log_connection <- NULL

log_msg <- function(level, msg, use_stderr = FALSE) {
  line <- sprintf("[%s] %s | %s", toupper(level), format(Sys.time(), "%Y-%m-%d %H:%M:%S"), msg)
  cat(line, "\n", sep = "", file = if (use_stderr) stderr() else stdout())
  if (!is.null(log_connection)) {
    writeLines(line, log_connection)
    flush(log_connection)
  }
}

log_info <- function(msg) log_msg("info", msg)
log_warn <- function(msg) log_msg("warn", msg)
log_error <- function(msg) log_msg("error", msg, use_stderr = TRUE)

set_log_file <- function(output_dir) {
  close_log_file()
  log_connection <<- file(file.path(output_dir, "analysis.log"), open = "wt")
  invisible(log_connection)
}

close_log_file <- function() {
  if (!is.null(log_connection)) {
    close(log_connection)
    log_connection <<- NULL
  }
  invisible(TRUE)
}

stop_skill <- function(code, message) {
  stop(sprintf("%s: %s", code, message), call. = FALSE)
}

check_pkg <- function(pkg, min_ver = NULL) {
  if (!requireNamespace(pkg, quietly = TRUE))
    stop_skill("SKILL_DEPENDENCY_MISSING", paste("Required package is not installed:", pkg))
  library(pkg, character.only = TRUE, warn.conflicts = FALSE)
  if (!is.null(min_ver) && packageVersion(pkg) < min_ver)
    stop_skill("SKILL_PKG_VERSION", paste(pkg, "must be >=", min_ver))
}

check_required_packages <- function(pkgs) {
  invisible(lapply(pkgs, check_pkg))
}

validate_existing_file <- function(path, label, extensions = c("csv")) {
  if (is.null(path) || !nzchar(path))
    stop_skill("SKILL_INVALID_PARAMETER", paste(label, "must be provided"))
  if (!file.exists(path))
    stop_skill("SKILL_FILE_NOT_FOUND", paste(label, "does not exist:", path))
  ext <- tolower(tools::file_ext(path))
  if (length(extensions) > 0 && !ext %in% tolower(extensions)) {
    stop_skill("SKILL_INVALID_PARAMETER",
               paste(label, "must use one of:", paste(extensions, collapse = ", ")))
  }
  invisible(normalizePath(path, winslash = "/", mustWork = TRUE))
}

validate_choice <- function(value, allowed, arg_name) {
  if (!value %in% allowed) {
    stop_skill("SKILL_INVALID_PARAMETER",
               paste(arg_name, "must be one of", paste(allowed, collapse = ", ")))
  }
  invisible(value)
}

validate_color <- function(color_value, arg_name) {
  tryCatch(
    {
      grDevices::col2rgb(color_value)
      invisible(color_value)
    },
    error = function(e) {
      stop_skill("SKILL_INVALID_PARAMETER", paste(arg_name, "is not a valid color:", color_value))
    }
  )
}

parse_csv_arg <- function(value, arg_name, mode = c("character", "numeric")) {
  mode <- match.arg(mode)
  pieces <- trimws(unlist(strsplit(value, ",", fixed = TRUE)))
  pieces <- pieces[nzchar(pieces)]
  if (length(pieces) == 0)
    stop_skill("SKILL_INVALID_PARAMETER", paste(arg_name, "must contain at least one value"))
  if (mode == "character")
    return(pieces)
  numeric_values <- suppressWarnings(as.numeric(pieces))
  if (anyNA(numeric_values))
    stop_skill("SKILL_INVALID_PARAMETER", paste(arg_name, "must contain numeric values"))
  numeric_values
}

validate_positive_integer <- function(value, arg_name, allow_zero = FALSE) {
  if (is.na(value) || value < 0 || (!allow_zero && value == 0)) {
    comparator <- if (allow_zero) "a non-negative integer" else "a positive integer"
    stop_skill("SKILL_INVALID_PARAMETER", paste(arg_name, "must be", comparator))
  }
  invisible(as.integer(value))
}

enable_timeout <- function(timeout_seconds) {
  validate_positive_integer(timeout_seconds, "--timeout_seconds")
  setTimeLimit(cpu = Inf, elapsed = timeout_seconds, transient = FALSE)
  invisible(timeout_seconds)
}

disable_timeout <- function() {
  setTimeLimit(cpu = Inf, elapsed = Inf, transient = FALSE)
  invisible(TRUE)
}

log_memory_checkpoint <- function(step_label, warn_threshold_mb = 8192) {
  gc_info <- gc()
  mem_mb <- round(sum(gc_info[, 2]), 2)
  msg <- sprintf("Memory after %s: %.2f MB", step_label, mem_mb)
  if (mem_mb >= warn_threshold_mb) {
    log_warn(paste(msg, "(high memory usage)"))
    gc()
  } else {
    log_info(msg)
  }
  invisible(mem_mb)
}
