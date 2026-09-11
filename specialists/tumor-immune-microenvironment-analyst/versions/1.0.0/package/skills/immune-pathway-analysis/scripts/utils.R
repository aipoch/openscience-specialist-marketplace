#!/usr/bin/env Rscript

timestamp_now <- function() format(Sys.time(), "%Y-%m-%d %H:%M:%S")
log_message <- function(level, message_text) message(sprintf("[%s] %s | %s", level, timestamp_now(), message_text))
log_info <- function(message_text) log_message("INFO", message_text)
log_warn <- function(message_text) log_message("WARN", message_text)
stop_skill <- function(code, message_text) stop(sprintf("%s: %s", code, message_text), call. = FALSE)
`%||%` <- function(a, b) if (!is.null(a)) a else b

check_required_packages <- function(packages) {
  missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing) > 0) stop_skill("SKILL_PACKAGE_NOT_FOUND", sprintf("Missing required packages: %s", paste(missing, collapse = ", ")))
}

validate_dependency_versions <- function(versions = NULL) {
  if (is.null(versions)) {
    tracked <- c("GSVA", "limma", "matrixStats", "Matrix", "optparse", "pheatmap")
    installed <- tracked[vapply(tracked, requireNamespace, logical(1), quietly = TRUE)]
    versions <- stats::setNames(vapply(installed, function(pkg) as.character(utils::packageVersion(pkg)), character(1)), installed)
  }
  if (length(versions) > 0) {
    log_info(sprintf("Detected package versions: %s", paste(sprintf("%s=%s", names(versions), unname(versions)), collapse = ", ")))
  }
  if (all(c("GSVA", "matrixStats") %in% names(versions)) && utils::compareVersion(versions[["GSVA"]], "1.42.0") == 0 && utils::compareVersion(versions[["matrixStats"]], "1.2.0") >= 0) {
    stop_skill("SKILL_VERSION_INCOMPATIBLE", sprintf("Detected GSVA %s with matrixStats %s. In the validated R 4.1.x environment, downgrade matrixStats to 1.1.0.", versions[["GSVA"]], versions[["matrixStats"]]))
  }
  invisible(versions)
}

ensure_dir <- function(path) dir.create(path, recursive = TRUE, showWarnings = FALSE)

normalize_compare_path <- function(path) {
  normalized <- gsub("\\\\", "/", normalizePath(path, winslash = "/", mustWork = FALSE))
  drive_prefix <- ""
  if (grepl("^[A-Za-z]:", normalized)) {
    drive_prefix <- substr(normalized, 1, 2)
    normalized <- substring(normalized, 3)
  }
  is_absolute <- startsWith(normalized, "/")
  segments <- strsplit(normalized, "/", fixed = TRUE)[[1]]
  collapsed <- character()
  for (segment in segments) {
    if (segment %in% c("", ".")) next
    if (segment == "..") {
      if (length(collapsed) > 0) {
        collapsed <- collapsed[-length(collapsed)]
      } else if (!is_absolute) {
        collapsed <- c(collapsed, segment)
      }
      next
    }
    collapsed <- c(collapsed, segment)
  }
  collapsed_path <- paste(collapsed, collapse = "/")
  prefix <- if (nzchar(drive_prefix)) {
    paste0(drive_prefix, if (is_absolute) "/" else "")
  } else if (is_absolute) {
    "/"
  } else {
    ""
  }
  result <- paste0(prefix, collapsed_path)
  tolower(if (nzchar(result)) result else if (is_absolute) prefix else ".")
}

is_path_within <- function(child_path, parent_path) {
  child_norm <- normalize_compare_path(child_path)
  parent_norm <- normalize_compare_path(parent_path)
  identical(child_norm, parent_norm) || startsWith(child_norm, paste0(parent_norm, "/"))
}

resolve_output_dir <- function(output_dir, skill_root) {
  if (is.null(output_dir) || !nzchar(trimws(output_dir))) stop_skill("SKILL_INVALID_PARAMETER", "--output_dir is required.")
  candidate <- trimws(output_dir)
  if (!grepl("^([A-Za-z]:|/|\\\\)", candidate)) candidate <- file.path(skill_root, candidate)
  if (!is_path_within(candidate, skill_root)) stop_skill("SKILL_INVALID_PARAMETER", "output_dir must stay inside the skill directory.")
  normalizePath(candidate, winslash = "/", mustWork = FALSE)
}

validate_existing_file <- function(path, label) {
  if (is.null(path) || !nzchar(trimws(path))) stop_skill("SKILL_INVALID_PARAMETER", sprintf("%s is required.", label))
  if (!file.exists(path)) stop_skill("SKILL_FILE_NOT_FOUND", sprintf("%s does not exist: %s", label, path))
}

validate_numeric_range <- function(value, lower, upper, label) {
  if (is.na(value) || value < lower || value > upper) stop_skill("SKILL_INVALID_PARAMETER", sprintf("%s must be between %s and %s.", label, lower, upper))
}

enable_timeout <- function(timeout_seconds) {
  if (!is.null(timeout_seconds) && timeout_seconds > 0) {
    setTimeLimit(cpu = timeout_seconds, elapsed = timeout_seconds, transient = TRUE)
    log_info(sprintf("Timeout enabled: %s seconds", timeout_seconds))
  }
}

save_session_info <- function(output_dir) {
  session_file <- file.path(output_dir, "session_info.txt")
  sink(session_file)
  on.exit(sink(), add = TRUE)
  print(sessionInfo())
}

read_delimited_table <- function(path, row_names = FALSE) {
  if (grepl("\\.csv$", path, ignore.case = TRUE)) read.csv(path, header = TRUE, row.names = if (row_names) 1 else NULL, stringsAsFactors = FALSE, check.names = FALSE) else read.table(path, header = TRUE, sep = "\t", row.names = if (row_names) 1 else NULL, stringsAsFactors = FALSE, check.names = FALSE)
}

sanitize_plot_filename <- function(filename) {
  value <- trimws(filename %||% "")
  if (!nzchar(value) || grepl("[/\\\\]", value)) stop_skill("SKILL_INVALID_PARAMETER", "--plot_file must be a file name without path separators.")
  value
}
