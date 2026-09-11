format_log <- function(level, msg) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  spacer <- strrep(" ", max(1, 6 - nchar(level)))
  sprintf("[%s]%s%s | %s", level, spacer, timestamp, msg)
}

current_memory_used_mb <- function(gc_info = gc(verbose = FALSE)) {
  if (!is.matrix(gc_info) || ncol(gc_info) < 2)
    stop("gc_info must be a matrix with an MB column", call. = FALSE)

  sum(as.numeric(gc_info[, 2]), na.rm = TRUE)
}

log_info <- function(msg) {
  message(format_log("INFO", msg))
}

log_warn <- function(msg) {
  message(format_log("WARN", msg))
}

log_error <- function(msg) {
  message(format_log("ERROR", msg))
}

log_memory_usage <- function(stage, warn_threshold_mb = 4096) {
  mem_used_mb <- current_memory_used_mb()
  log_info(sprintf("Memory used after %s: %.2f MB", stage, mem_used_mb))
  if (mem_used_mb >= warn_threshold_mb) {
    warning(
      sprintf("SKILL_MEMORY_WARNING: Memory usage reached %.2f MB after %s", mem_used_mb, stage),
      call. = FALSE
    )
  }
  invisible(mem_used_mb)
}
