log_msg <- function(level, msg, use_stderr = FALSE) {
  line <- sprintf("[%s] %s | %s", toupper(level), format(Sys.time(), "%Y-%m-%d %H:%M:%S"), msg)
  cat(line, "\n", sep = "", file = if (use_stderr) stderr() else stdout())
}

log_info <- function(msg) log_msg("info", msg)
log_warn <- function(msg) log_msg("warn", msg)
log_error <- function(msg) log_msg("error", msg, use_stderr = TRUE)

stop_skill <- function(code, message) stop(sprintf("%s: %s", code, message), call. = FALSE)

check_required_packages <- function(packages) {
  missing_packages <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing_packages) > 0)
    stop_skill("SKILL_PACKAGE_NOT_FOUND", paste("Required packages are not installed:", paste(missing_packages, collapse = ", ")))
  invisible(packages)
}

memory_guard <- function() {
  gc_info <- gc()
  if (sum(gc_info[, 2]) > 10000)
    log_warn("High memory usage detected; forcing garbage collection")
  invisible(gc())
}
