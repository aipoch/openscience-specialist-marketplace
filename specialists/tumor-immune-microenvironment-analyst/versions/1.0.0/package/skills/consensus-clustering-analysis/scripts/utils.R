build_log_prefix <- function(level) {
  padding <- paste(rep(" ", max(1L, 6L - nchar(level))), collapse = "")
  sprintf("[%s]%s%s | ", level, padding, format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
}

log_line <- function(level, message_text) {
  message(paste0(build_log_prefix(level), message_text))
}

log_info <- function(message_text) log_line("INFO", message_text)
log_warn <- function(message_text) log_line("WARN", message_text)
log_error <- function(message_text) log_line("ERROR", message_text)

is_known_benign_warning <- function(warning_text) {
  identical(warning_text, "the condition has length > 1 and only the first element will be used")
}

with_suppressed_benign_warnings <- function(expr) {
  withCallingHandlers(expr, warning = function(w) {
    if (is_known_benign_warning(conditionMessage(w)))
      invokeRestart("muffleWarning")
  })
}

stop_skill <- function(code, details) {
  stop(sprintf("%s: %s", code, details), call. = FALSE)
}

classify_runtime_error <- function(err) {
  message_text <- conditionMessage(err)
  if (grepl("^SKILL_", message_text))
    return(message_text)
  if (grepl("reached .*time limit|elapsed time limit|Time limit reached|时间限制|流逝时间", message_text, ignore.case = TRUE)) {
    return("SKILL_TIMEOUT: Execution exceeded the configured time limit.")
  }
  sprintf("SKILL_ERROR: %s", message_text)
}

ensure_file_exists <- function(path, label) {
  if (!file.exists(path))
    stop_skill("SKILL_FILE_NOT_FOUND", sprintf("%s not found: %s", label, path))
}

ensure_dir <- function(path) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  invisible(path)
}

check_runtime_packages <- function(packages) {
  missing_packages <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing_packages) > 0) {
    stop_skill("SKILL_DEPENDENCY_MISSING", paste(missing_packages, collapse = ", "))
  }
}

apply_timeout <- function(timeout_seconds) {
  setTimeLimit(elapsed = timeout_seconds, transient = FALSE)
}

release_timeout <- function() {
  setTimeLimit(cpu = Inf, elapsed = Inf, transient = FALSE)
}

save_session_info <- function(output_dir) {
  session_file <- file.path(output_dir, "session_info.txt")
  sink(session_file)
  on.exit(sink(), add = TRUE)
  print(sessionInfo())
}

suppress_package_output <- function(run_fn) {
  result_object <- NULL
  suppressMessages(utils::capture.output({
    result_object <- run_fn()
  }, file = nullfile()))
  result_object
}

log_memory_usage <- function(label) {
  gc_info <- gc(verbose = FALSE)
  used_mb <- as.numeric(gc_info[2, "used"]) / 1024
  trigger_mb <- as.numeric(gc_info[2, "gc trigger"]) / 1024
  log_info(sprintf("%s memory usage: %.2f MB / %.2f MB trigger", label, used_mb, trigger_mb))
}

warn_if_output_dir_nonempty <- function(path) {
  if (!dir.exists(path))
    return(invisible(TRUE))
  entries <- list.files(path, all.files = TRUE, no.. = TRUE)
  if (length(entries) > 0) {
    log_warn(sprintf("Output directory already contains %d item(s); files may be overwritten.", length(entries)))
  }
  invisible(TRUE)
}

write_csv_output <- function(data_object, path) {
  utils::write.csv(data_object, path, row.names = FALSE)
}

save_result_object <- function(result_object, path) {
  save(result_object, file = path)
}

remove_generated_logs <- function(path) {
  log_files <- list.files(path, pattern = "\\.log\\.csv$", full.names = TRUE)
  if (length(log_files) > 0L)
    unlink(log_files, force = TRUE)
}

load_result_object <- function(path) {
  result_object <- NULL
  load(path)
  if (is.null(result_object)) {
    stop_skill("SKILL_INVALID_DATA", sprintf("result_object missing in %s", basename(path)))
  }
  result_object
}
