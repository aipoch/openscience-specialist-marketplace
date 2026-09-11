timestamp_now <- function() {
  format(Sys.time(), "%Y-%m-%d %H:%M:%S")
}

write_log <- function(level, message_text) {
  line <- sprintf("[%s] %s | %s", toupper(level), timestamp_now(), message_text)
  target <- if (toupper(level) == "ERROR") stderr() else stdout()
  cat(line, "\n", sep = "", file = target)
}

log_info <- function(message_text) write_log("INFO", message_text)
log_warn <- function(message_text) write_log("WARN", message_text)
log_error <- function(message_text) write_log("ERROR", message_text)

fail <- function(code, message_text) {
  stop(sprintf("%s: %s", code, message_text), call. = FALSE)
}

check_required_packages <- function(packages) {
  missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing) > 0) {
    fail(
      "SKILL_PACKAGE_NOT_FOUND",
      sprintf("Missing required package(s): %s", paste(missing, collapse = ", "))
    )
  }
}

format_option_value <- function(value) {
  if (length(value) == 0 || is.null(value)) {
    return("NULL")
  }
  if (length(value) > 1) {
    return(paste(value, collapse = ", "))
  }
  if (is.logical(value)) {
    return(ifelse(is.na(value), "NA", ifelse(value, "TRUE", "FALSE")))
  }
  if (is.na(value)) {
    return("NA")
  }
  as.character(value)
}

set_timeout_limit <- function(timeout_seconds) {
  setTimeLimit(elapsed = timeout_seconds, transient = TRUE)
  invisible(TRUE)
}
