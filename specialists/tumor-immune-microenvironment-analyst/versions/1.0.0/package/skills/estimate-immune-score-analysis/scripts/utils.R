#!/usr/bin/env Rscript

timestamp_now <- function() {
  format(Sys.time(), "%Y-%m-%d %H:%M:%S")
}

log_message <- function(level, message_text) {
  message(sprintf("[%s] %s | %s", level, timestamp_now(), message_text))
}

log_info <- function(message_text) {
  log_message("INFO", message_text)
}

log_warn <- function(message_text) {
  log_message("WARN", message_text)
}

stop_skill <- function(code, message_text) {
  stop(sprintf("%s: %s", code, message_text), call. = FALSE)
}

`%||%` <- function(value, fallback) {
  if (is.null(value) || length(value) == 0 || is.na(value)) fallback else value
}

ensure_dir <- function(path) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
}

validate_existing_file <- function(path, label) {
  if (is.null(path) || !nzchar(path)) {
    stop_skill("SKILL_INVALID_PARAMETER", sprintf("%s is required.", label))
  }
  if (!file.exists(path)) {
    stop_skill("SKILL_FILE_NOT_FOUND", sprintf("%s does not exist: %s", label, path))
  }
}

validate_choice <- function(value, choices, label) {
  if (!value %in% choices) {
    stop_skill(
      "SKILL_INVALID_PARAMETER",
      sprintf("%s must be one of: %s.", label, paste(choices, collapse = ", "))
    )
  }
}

validate_safe_filename <- function(value, label) {
  if (is.null(value) || !nzchar(value)) {
    stop_skill("SKILL_INVALID_PARAMETER", sprintf("%s must not be empty.", label))
  }
  if (grepl("[/\\\\]", value)) {
    stop_skill("SKILL_INVALID_PARAMETER", sprintf("%s must be a file name only.", label))
  }
}

validate_positive_integer <- function(value, label, allow_zero = FALSE) {
  lower <- if (allow_zero) 0 else 1
  if (is.na(value) || value < lower || value != as.integer(value)) {
    stop_skill(
      "SKILL_INVALID_PARAMETER",
      sprintf("%s must be an integer >= %s.", label, lower)
    )
  }
}

build_install_hint <- function(package_name) {
  if (identical(package_name, "estimate")) {
    return(paste(
      "Install with:",
      "if (!requireNamespace('BiocManager', quietly = TRUE)) install.packages('BiocManager');",
      "BiocManager::install('estimate')"
    ))
  }
  sprintf("Install with: install.packages('%s')", package_name)
}

check_required_packages <- function(packages, min_versions = NULL) {
  package_names <- unique(packages)
  missing <- package_names[!vapply(package_names, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing) > 0) {
    install_lines <- vapply(missing, build_install_hint, character(1))
    stop_skill(
      "SKILL_PACKAGE_NOT_FOUND",
      sprintf(
        "Missing required packages: %s. %s",
        paste(missing, collapse = ", "),
        paste(install_lines, collapse = " ")
      )
    )
  }

  if (!is.null(min_versions)) {
    version_failures <- character(0)
    for (package_name in names(min_versions)) {
      required_version <- min_versions[[package_name]]
      if (!package_name %in% package_names || is.null(required_version) || is.na(required_version)) {
        next
      }
      if (utils::packageVersion(package_name) < numeric_version(required_version)) {
        version_failures <- c(
          version_failures,
          sprintf(
            "%s >= %s required (found %s)",
            package_name,
            required_version,
            as.character(utils::packageVersion(package_name))
          )
        )
      }
    }
    if (length(version_failures) > 0) {
      stop_skill(
        "SKILL_PACKAGE_NOT_FOUND",
        sprintf("Package version requirements not met: %s", paste(version_failures, collapse = "; "))
      )
    }
  }
}

enable_timeout <- function(timeout_seconds) {
  if (!is.null(timeout_seconds) && timeout_seconds > 0) {
    setTimeLimit(cpu = timeout_seconds, elapsed = timeout_seconds, transient = FALSE)
    log_info(sprintf("Timeout enabled: %s seconds", timeout_seconds))
  }
}

disable_timeout <- function() {
  setTimeLimit(cpu = Inf, elapsed = Inf, transient = FALSE)
}

normalize_error_message <- function(message_text, timeout_seconds = NULL) {
  if (grepl("reached .* time limit", message_text, ignore.case = TRUE)) {
    if (!is.null(timeout_seconds) && timeout_seconds > 0) {
      return(sprintf("SKILL_TIMEOUT: Analysis exceeded the configured %s second time limit.", timeout_seconds))
    }
    return("SKILL_TIMEOUT: Analysis exceeded the configured time limit.")
  }
  message_text
}

save_session_info <- function(output_dir) {
  session_file <- file.path(output_dir, "session_info.txt")
  sink(session_file)
  on.exit(sink(), add = TRUE)
  print(sessionInfo())
  session_file
}

read_delimited_table <- function(path) {
  if (grepl("\\.csv$", path, ignore.case = TRUE)) {
    read.csv(path, header = TRUE, stringsAsFactors = FALSE, check.names = FALSE)
  } else {
    read.table(
      path,
      header = TRUE,
      sep = "\t",
      stringsAsFactors = FALSE,
      check.names = FALSE,
      quote = ""
    )
  }
}
