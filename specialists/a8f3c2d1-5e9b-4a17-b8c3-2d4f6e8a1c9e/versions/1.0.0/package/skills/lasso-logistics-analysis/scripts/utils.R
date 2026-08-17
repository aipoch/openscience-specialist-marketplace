format_log <- function(level, msg) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  sprintf("[%s]  %s | %s", level, timestamp, msg)
}

log_info <- function(msg) message(format_log("INFO", msg))
log_warn <- function(msg) message(format_log("WARN", msg))
log_error <- function(msg) message(format_log("ERROR", msg))

check_file_exists <- function(file_path, label) {
  if (!file.exists(file_path))
    stop(sprintf("SKILL_FILE_NOT_FOUND: %s does not exist: %s", label, file_path))
  if (isTRUE(file.info(file_path)$size == 0))
    stop(sprintf("SKILL_EMPTY_FILE: %s is empty: %s", label, file_path))
  invisible(TRUE)
}

create_output_dir <- function(output_dir) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  if (!dir.exists(output_dir))
    stop(sprintf("SKILL_FILE_WRITE_ERROR: Failed to create output directory: %s", output_dir))
  probe_file <- tempfile(pattern = "write_check_", tmpdir = output_dir)
  ok <- tryCatch(file.create(probe_file), error = function(e) FALSE)
  if (!isTRUE(ok))
    stop(sprintf("SKILL_FILE_WRITE_ERROR: Unable to write to output directory: %s", output_dir))
  unlink(probe_file, force = TRUE)
  invisible(output_dir)
}

write_session_info <- function(output_dir) {
  session_file <- file.path(output_dir, "session_info.txt")
  sink(session_file)
  on.exit(sink(), add = TRUE)
  print(sessionInfo())
  invisible(session_file)
}

log_run_header <- function(opt) {
  log_info("==========================================")
  log_info("LASSO Logistic Regression Analysis")
  log_info("==========================================")
  log_info(paste("Input:", opt$input_file))
  log_info(paste("Group:", opt$group_file))
  log_info(paste("Case group:", opt$case_group))
  log_info(paste("Control group:", opt$control_group))
  log_info(paste("Output:", opt$output_dir))
  log_info(paste("Seed:", opt$seed))
  log_info(paste("Timeout seconds:", opt$timeout_seconds))
}

log_memory_usage <- function(label, warn_mb = 10000) {
  gc_info <- gc(verbose = FALSE)
  mem_used <- gc_info[2, 2]
  log_info(sprintf("Memory after %s: %.2f MB", label, mem_used))
  if (is.finite(mem_used) && mem_used > warn_mb)
    log_warn(sprintf("SKILL_MEMORY_WARNING: High memory usage detected at %s (%.2f MB)", label, mem_used))
  invisible(mem_used)
}
