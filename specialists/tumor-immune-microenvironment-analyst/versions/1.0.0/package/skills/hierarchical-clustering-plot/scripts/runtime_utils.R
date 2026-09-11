set_analysis_timeout <- function(timeout_seconds) {
  validate_scalar_numeric(timeout_seconds, "timeout_seconds", lower_bound = 0)
  setTimeLimit(elapsed = timeout_seconds, transient = FALSE)
  invisible(timeout_seconds)
}

reset_time_limit <- function() {
  setTimeLimit(cpu = Inf, elapsed = Inf, transient = FALSE)
  invisible(TRUE)
}

normalize_error <- function(e) {
  msg <- conditionMessage(e)
  if (grepl("reached .*time limit", msg, ignore.case = TRUE))
    return("SKILL_TIMEOUT: Computation exceeded time limit")
  msg
}

create_temp_workspace <- function(prefix = "hierarchical-clustering-") {
  temp_dir <- tempfile(pattern = prefix)
  dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)
  if (!dir.exists(temp_dir))
    stop("SKILL_WRITE_ERROR: Failed to create temporary workspace", call. = FALSE)
  temp_dir
}

cleanup_temp_resources <- function(temp_files = character(0), temp_dirs = character(0)) {
  for (file_path in temp_files)
    if (file.exists(file_path)) file.remove(file_path)
  for (dir_path in temp_dirs)
    if (dir.exists(dir_path)) unlink(dir_path, recursive = TRUE, force = TRUE)
  invisible(TRUE)
}

copy_output_file <- function(source_file, output_dir, filename) {
  target_file <- file.path(output_dir, filename)
  ok <- file.copy(source_file, target_file, overwrite = TRUE)
  if (!ok)
    stop("SKILL_WRITE_ERROR: Failed to write output file: ", target_file, call. = FALSE)
  invisible(target_file)
}

save_session_info <- function(output_dir) {
  session_file <- file.path(output_dir, "session_info.txt")
  sink(session_file)
  on.exit(if (sink.number() > 0) sink(), add = TRUE)
  print(sessionInfo())
  invisible(session_file)
}
