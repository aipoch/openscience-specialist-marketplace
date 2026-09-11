warning_state <- new.env(parent = emptyenv())
warning_state$seen <- character(0)

format_log_line <- function(level, message_text) {
  prefix <- switch(level,
                   INFO = "[INFO] ",
                   WARN = "[WARN] ",
                   ERROR = "[ERROR]",
                   DEBUG = "[DEBUG]",
                   "[INFO] ")
  sprintf("%s %s | %s", prefix, format(Sys.time(), "%Y-%m-%d %H:%M:%S"), message_text)
}

log_info <- function(message_text) {
  message(format_log_line("INFO", message_text))
}

log_warn <- function(message_text) {
  if (message_text %in% warning_state$seen) {
    return(invisible(NULL))
  }
  warning_state$seen <- c(warning_state$seen, message_text)
  message(format_log_line("WARN", message_text))
}

log_error <- function(message_text) {
  message(format_log_line("ERROR", message_text))
}

ensure_dir <- function(path) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
}

validate_file_exists <- function(path) {
  if (is.null(path) || !nzchar(path) || !file.exists(path)) {
    stop(sprintf("SKILL_FILE_NOT_FOUND: File not found %s", path), call. = FALSE)
  }
}

check_runtime_packages <- function(packages) {
  for (pkg in names(packages)) {
    min_version <- packages[[pkg]]
    if (!requireNamespace(pkg, quietly = TRUE)) {
      stop(sprintf(
        "SKILL_DEPENDENCY_MISSING: Package '%s' is required. Install with install.packages('%s')",
        pkg, pkg
      ), call. = FALSE)
    }
    if (!is.na(min_version) && packageVersion(pkg) < numeric_version(min_version)) {
      stop(sprintf(
        "SKILL_PKG_VERSION: Package '%s' version %s or higher required",
        pkg, min_version
      ), call. = FALSE)
    }
    suppressPackageStartupMessages(library(pkg, character.only = TRUE, warn.conflicts = FALSE))
  }
}

log_cli_context <- function(opt) {
  log_info("==========================================")
  log_info("Elastic Net Feature Selection")
  log_info("==========================================")
  log_info(sprintf("Input: %s", opt$input_file))
  log_info(sprintf("Groups: %s", opt$group_file))
  log_info(sprintf("Features: %s", if (is.null(opt$feature_file)) "all matrix rows" else opt$feature_file))
  log_info(sprintf("Alpha: %s", opt$alpha))
  if (tolower(trimws(opt$alpha)) == "auto") {
    log_info(sprintf("Alpha grid: %s", opt$alpha_grid))
  }
  log_info(sprintf("Lambda choice: %s", opt$lambda_choice))
  log_info(sprintf("Output: %s", opt$output_dir))
  log_info(sprintf("Seed: %d", opt$seed))
}

save_session_info <- function(output_dir) {
  ensure_dir(output_dir)
  sink(file.path(output_dir, "session_info.txt"))
  print(sessionInfo())
  sink()
}

apply_timeout <- function(timeout_seconds) {
  setTimeLimit(elapsed = timeout_seconds, transient = FALSE)
}

release_timeout <- function() {
  setTimeLimit(cpu = Inf, elapsed = Inf, transient = FALSE)
}

capture_gc_snapshot <- function() {
  gc_info <- gc(verbose = FALSE)
  list(
    ncells = sprintf("used %s (%.1f Mb)", format(gc_info[1, 1], big.mark = ","), gc_info[1, 2]),
    vcells = sprintf("used %s (%.1f Mb)", format(gc_info[2, 1], big.mark = ","), gc_info[2, 2])
  )
}

reset_warning_state <- function() {
  warning_state$seen <- character(0)
}

classify_runtime_error <- function(e) {
  message_text <- conditionMessage(e)
  if (grepl("reached .* time limit", message_text)) {
    return("SKILL_TIMEOUT: Analysis exceeded the configured time limit")
  }
  if (grepl("^SKILL_[A-Z_]+", message_text)) {
    return(message_text)
  }
  sprintf("SKILL_RUNTIME_ERROR: %s", message_text)
}
