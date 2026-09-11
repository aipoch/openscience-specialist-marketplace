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

check_required_packages <- function(packages) {
  missing_packages <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing_packages) > 0)
    stop_skill("SKILL_PACKAGE_NOT_FOUND", paste("Required packages are not installed:", paste(missing_packages, collapse = ", ")))
  invisible(packages)
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
    "ROC Diagnostic Performance Session Information",
    "==========================================",
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
