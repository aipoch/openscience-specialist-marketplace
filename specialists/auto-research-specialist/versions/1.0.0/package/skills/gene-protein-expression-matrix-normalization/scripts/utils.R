skill_stop <- function(code, message_text) {
  stop(sprintf("%s: %s", code, message_text), call. = FALSE)
}

log_msg <- function(level, message_text) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  message(sprintf("[%s] %s %s", toupper(level), timestamp, message_text))
}

log_info <- function(message_text) {
  log_msg("info", message_text)
}

log_warn <- function(message_text) {
  log_msg("warn", message_text)
}

log_error <- function(message_text) {
  log_msg("error", message_text)
}

is_timeout_error <- function(message_text) {
  grepl("time limit|reached elapsed time limit|reached CPU time limit", message_text, ignore.case = TRUE)
}

rethrow_with_timeout_code <- function(err, timeout_seconds = 0, context = "Operation") {
  if (is_timeout_error(conditionMessage(err))) {
    if (is.finite(timeout_seconds) && timeout_seconds > 0) {
      skill_stop("SKILL_TIMEOUT", sprintf("%s exceeded --timeout_seconds=%s.", context, timeout_seconds))
    }
    skill_stop("SKILL_TIMEOUT", sprintf("%s exceeded the configured time limit.", context))
  }
  stop(err)
}

dir_has_contents <- function(path) {
  dir.exists(path) && length(list.files(path, all.files = TRUE, no.. = TRUE)) > 0
}

ensure_dir <- function(path) {
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE, showWarnings = FALSE)
  }
}

as_bool <- function(x, default = NULL, arg_name = "boolean argument") {
  if (is.null(x) || identical(x, "")) {
    return(default)
  }
  val <- tolower(as.character(x))
  if (val %in% c("true", "t", "1", "yes", "y")) {
    return(TRUE)
  }
  if (val %in% c("false", "f", "0", "no", "n")) {
    return(FALSE)
  }
  skill_stop("SKILL_INVALID_PARAMETER", sprintf("%s must be true or false.", arg_name))
}

detect_delimiter <- function(path, delimiter = "auto") {
  if (delimiter == "csv") {
    return(",")
  }
  if (delimiter == "tsv") {
    return("\t")
  }
  if (delimiter != "auto") {
    skill_stop("SKILL_INVALID_PARAMETER", "Unsupported --delimiter.")
  }
  if (grepl("\\.tsv$|\\.txt$", path, ignore.case = TRUE)) "\t" else ","
}

format_num <- function(x, digits = 6) {
  format(round(x, digits), nsmall = 0, trim = TRUE, scientific = FALSE)
}

make_relative_path <- function(path, base_dir = getwd()) {
  path_norm <- normalizePath(path, winslash = "/", mustWork = FALSE)
  base_norm <- normalizePath(base_dir, winslash = "/", mustWork = FALSE)
  prefix <- paste0(base_norm, "/")
  if (identical(path_norm, base_norm)) {
    return(".")
  }
  if (startsWith(path_norm, prefix)) {
    return(sub(paste0("^", gsub("([][{}()+*^$.|\\\\?])", "\\\\\\1", prefix)), "", path_norm))
  }
  path
}
