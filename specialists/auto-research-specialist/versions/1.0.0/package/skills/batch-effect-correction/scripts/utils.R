log_message <- function(level, msg) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  cat(sprintf("[%s]  %s | %s\n", toupper(level), timestamp, msg))
}

log_info <- function(msg) log_message("INFO", msg)
log_warn <- function(msg) log_message("WARN", msg)
log_error <- function(msg) log_message("ERROR", msg)

validate_non_empty_string <- function(value, arg_name) {
  if (!is.character(value) || length(value) != 1 || !nzchar(trimws(value)))
    stop(sprintf("SKILL_INVALID_PARAMETER: %s must be a non-empty string", arg_name), call. = FALSE)
  invisible(TRUE)
}

validate_existing_file <- function(file_path, label) {
  validate_non_empty_string(file_path, label)
  if (!file.exists(file_path))
    stop(sprintf("SKILL_FILE_NOT_FOUND: %s does not exist: %s", label, file_path), call. = FALSE)
  if (isTRUE(file.info(file_path)$isdir))
    stop(sprintf("SKILL_INVALID_PARAMETER: %s must be a file path: %s", label, file_path), call. = FALSE)
  if (is.na(file.info(file_path)$size) || file.info(file_path)$size == 0)
    stop(sprintf("SKILL_EMPTY_FILE: %s is empty: %s", label, file_path), call. = FALSE)
  invisible(TRUE)
}

validate_cli_options <- function(opt) {
  validate_existing_file(opt$input_file, "--input_file")
  validate_existing_file(opt$group_file, "--group_file")
  validate_non_empty_string(opt$output_dir, "--output_dir")
  validate_non_empty_string(opt$sample_column, "--sample_column")
  validate_non_empty_string(opt$group_column, "--group_column")
  validate_non_empty_string(opt$batch_column, "--batch_column")

  if (!opt$log_transform %in% c("auto", "yes", "no"))
    stop("SKILL_INVALID_PARAMETER: --log_transform must be one of auto, yes, no", call. = FALSE)
  if (!is.numeric(opt$seed) || length(opt$seed) != 1 || is.na(opt$seed) || opt$seed < 0)
    stop("SKILL_INVALID_PARAMETER: --seed must be a non-negative integer", call. = FALSE)
  if (!is.numeric(opt$timeout_seconds) || length(opt$timeout_seconds) != 1 || is.na(opt$timeout_seconds) || opt$timeout_seconds < 0)
    stop("SKILL_INVALID_PARAMETER: --timeout_seconds must be >= 0", call. = FALSE)

  invisible(TRUE)
}

create_output_dir <- function(output_dir) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  if (!dir.exists(output_dir))
    stop(sprintf("SKILL_RUNTIME_ERROR: Failed to create output directory: %s", output_dir), call. = FALSE)
  invisible(output_dir)
}

save_session_info <- function(output_dir) {
  session_file <- file.path(output_dir, "session_info.txt")
  tryCatch({
    sink(session_file)
    on.exit({
      while (sink.number() > 0)
        sink()
    }, add = TRUE)
    print(sessionInfo())
    sink()
  }, error = function(e) {
    stop(sprintf("SKILL_RUNTIME_ERROR: Failed to write session information: %s", conditionMessage(e)), call. = FALSE)
  })
  log_info(sprintf("Session information saved to: %s", session_file))
  invisible(session_file)
}

normalize_skill_error <- function(message_text) {
  if (grepl("reached .*time limit|reached elapsed time limit", message_text, ignore.case = TRUE))
    return("SKILL_TIMEOUT: Analysis exceeded the configured time limit")
  if (grepl("^SKILL_", message_text))
    return(message_text)
  sprintf("SKILL_RUNTIME_ERROR: %s", message_text)
}

normalize_timeout_error <- function(message_text) {
  normalize_skill_error(message_text)
}

format_gc_entry <- function(gc_info, row_index, used_col, mb_col) {
  sprintf("used %s (%.1f Mb)", format(gc_info[row_index, used_col[1]], big.mark = ","), gc_info[row_index, mb_col[1]])
}

format_gc_snapshot <- function() {
  gc_info <- gc(verbose = FALSE)
  mb_col <- which(colnames(gc_info) == "(Mb)")
  used_col <- which(colnames(gc_info) == "used")
  if (length(mb_col) >= 1 && length(used_col) >= 1) {
    return(list(
      ncells = format_gc_entry(gc_info, 1, used_col, mb_col),
      vcells = format_gc_entry(gc_info, 2, used_col, mb_col)
    ))
  }
  list(ncells = "unavailable", vcells = "unavailable")
}
