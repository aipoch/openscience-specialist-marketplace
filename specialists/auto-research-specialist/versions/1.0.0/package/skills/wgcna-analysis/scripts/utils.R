log_msg <- function(level, msg, stream = c("stdout", "stderr")) {
  stream <- match.arg(stream)
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  line <- sprintf("[%s] %s | %s", toupper(level), timestamp, msg)
  if (stream == "stderr") {
    cat(line, "\n", file = stderr(), sep = "")
  } else {
    cat(line, "\n", sep = "")
  }
}

log_info <- function(msg) log_msg("INFO", msg, "stdout")
log_warn <- function(msg) log_msg("WARN", msg, "stderr")
log_error <- function(msg) log_msg("ERROR", msg, "stderr")

log_header <- function(title) {
  log_info("==========================================")
  log_info(title)
  log_info("==========================================")
}

skill_stop <- function(code, msg) {
  stop(sprintf("SKILL_%s: %s", toupper(code), msg), call. = FALSE)
}

check_pkg <- function(pkg, min_ver = NULL) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    skill_stop("PACKAGE_NOT_FOUND", sprintf("Required package is not installed: %s", pkg))
  }
  suppressPackageStartupMessages(
    library(pkg, character.only = TRUE, quietly = TRUE, warn.conflicts = FALSE)
  )
  if (!is.null(min_ver) && utils::packageVersion(pkg) < min_ver) {
    skill_stop("INVALID_PARAMETER", sprintf("Package %s must be >= %s", pkg, min_ver))
  }
  invisible(TRUE)
}

check_pkgs <- function(pkgs) {
  invisible(lapply(pkgs, check_pkg))
}

ensure_dir <- function(path) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  normalizePath(path, winslash = "/", mustWork = FALSE)
}

assert_file_exists <- function(path, label) {
  if (is.null(path) || identical(path, "")) {
    skill_stop("INVALID_PARAMETER", sprintf("%s path is empty", label))
  }
  if (!file.exists(path)) {
    skill_stop("FILE_NOT_FOUND", sprintf("%s not found: %s", label, path))
  }
  normalizePath(path, winslash = "/", mustWork = TRUE)
}

assert_choice <- function(value, choices, name) {
  if (length(value) != 1 || is.na(value) || !(value %in% choices)) {
    skill_stop("INVALID_PARAMETER", sprintf("%s must be one of: %s", name, paste(choices, collapse = ", ")))
  }
  invisible(TRUE)
}

assert_positive_integer <- function(value, name, allow_zero = FALSE) {
  is_int <- !is.na(value) && length(value) == 1 && is.numeric(value) && value == as.integer(value)
  if (!is_int) {
    skill_stop("INVALID_PARAMETER", sprintf("%s must be an integer", name))
  }
  if (allow_zero && value < 0) {
    skill_stop("INVALID_PARAMETER", sprintf("%s must be >= 0", name))
  }
  if (!allow_zero && value <= 0) {
    skill_stop("INVALID_PARAMETER", sprintf("%s must be > 0", name))
  }
  invisible(TRUE)
}

assert_numeric_range <- function(value, lower, upper, name, inclusive = TRUE) {
  if (!is.numeric(value) || length(value) != 1 || is.na(value)) {
    skill_stop("INVALID_PARAMETER", sprintf("%s must be numeric", name))
  }
  is_valid <- if (inclusive) value >= lower && value <= upper else value > lower && value < upper
  if (!is_valid) {
    bracket_l <- if (inclusive) "[" else "("
    bracket_r <- if (inclusive) "]" else ")"
    skill_stop("INVALID_PARAMETER", sprintf("%s must be in %s%s, %s%s", name, bracket_l, lower, upper, bracket_r))
  }
  invisible(TRUE)
}

assert_unique_values <- function(values, label, max_show = 10) {
  dup_values <- unique(values[duplicated(values)])
  if (length(dup_values) > 0) {
    skill_stop(
      "INVALID_PARAMETER",
      sprintf("%s contains duplicated values: %s", label, paste(head(dup_values, max_show), collapse = ", "))
    )
  }
  invisible(TRUE)
}

save_session_info <- function(output_dir) {
  session_file <- file.path(ensure_dir(output_dir), "session_info.txt")
  writeLines(capture.output(sessionInfo()), session_file)
  log_info(sprintf("Session info saved to %s", session_file))
}

apply_time_limit <- function(timeout_seconds) {
  assert_positive_integer(timeout_seconds, "timeout_seconds", allow_zero = TRUE)
  if (timeout_seconds > 0) {
    setTimeLimit(elapsed = timeout_seconds, transient = FALSE)
    log_info(sprintf("Timeout enabled: %s seconds", timeout_seconds))
  }
}

run_main <- function(main_fun) {
  status <- withCallingHandlers(
    tryCatch({
      main_fun()
      0
    }, error = function(e) {
      log_error(conditionMessage(e))
      1
    }),
    warning = function(w) {
      log_warn(conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  quit(save = "no", status = status)
}
