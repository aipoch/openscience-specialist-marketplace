log_msg <- function(level, msg) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  cat(paste0("[", timestamp, "] ", toupper(level), ": ", msg, "\n"))
}

log_info <- function(msg) log_msg("info", msg)
log_error <- function(msg) log_msg("error", msg)
log_warn <- function(msg) log_msg("warn", msg)

check_pkg <- function(pkg, min_ver = NULL) {
  if (!requireNamespace(pkg, quietly = TRUE))
    stop(paste("SKILL_DEPENDENCY_MISSING:", pkg))
  library(pkg, character.only = TRUE, warn.conflicts = FALSE)
  if (!is.null(min_ver) && packageVersion(pkg) < min_ver)
    stop(paste("SKILL_PKG_VERSION:", pkg, "needs >=", min_ver))
}

check_files <- function(input_file, group_file) {
  if (!file.exists(input_file))
    stop(paste("SKILL_FILE_NOT_FOUND: Expression matrix file does not exist:", input_file))
  if (!file.exists(group_file))
    stop(paste("SKILL_FILE_NOT_FOUND: Group file does not exist:", group_file))
  invisible(TRUE)
}

validate_groups <- function(group_df, min_per_group = 2) {
  group_col <- group_df[[2]]
  group_counts <- table(group_col)
  if (length(group_counts) < 2)
    stop("SKILL_INVALID_DATA: At least 2 groups required")
  min_count <- min(group_counts)
  if (min_count < min_per_group)
    stop("SKILL_INVALID_DATA: Each group must have at least ", min_per_group, " samples")
  invisible(TRUE)
}

save_session_info <- function(output_dir) {
  session_file <- file.path(output_dir, "session_info.txt")
  writeLines(capture.output(sessionInfo()), session_file)
  log_info(paste("Session info saved to:", session_file))
}

cleanup_temp_files <- function(temp_files) {
  for (f in temp_files)
    if (file.exists(f)) file.remove(f)
}
