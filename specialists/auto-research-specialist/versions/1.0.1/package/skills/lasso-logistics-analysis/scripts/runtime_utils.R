create_temp_registry <- function() {
  registry <- new.env(parent = emptyenv())
  registry$files <- character(0)
  registry
}

register_temp_file <- function(registry, target_path) {
  tmpdir <- dirname(target_path)
  dir.create(tmpdir, recursive = TRUE, showWarnings = FALSE)
  temp_file <- tempfile(pattern = "lasso_", tmpdir = tmpdir, fileext = paste0(".", tools::file_ext(target_path)))
  registry$files <- c(registry$files, temp_file)
  temp_file
}

cleanup_temp_files <- function(registry) {
  for (file_path in registry$files) {
    if (file.exists(file_path))
      unlink(file_path, force = TRUE)
  }
  invisible(TRUE)
}

finalize_output_file <- function(temp_file, target_path, registry) {
  ok <- file.rename(temp_file, target_path)
  if (!isTRUE(ok))
    stop(sprintf("SKILL_FILE_WRITE_ERROR: Failed to finalize output file: %s", target_path))
  registry$files <- setdiff(registry$files, temp_file)
  invisible(target_path)
}

write_csv_atomic <- function(data, file_path, registry, row_names = FALSE) {
  temp_file <- register_temp_file(registry, file_path)
  write.csv(data, temp_file, row.names = row_names, quote = TRUE)
  finalize_output_file(temp_file, file_path, registry)
}

write_lines_atomic <- function(lines, file_path, registry) {
  temp_file <- register_temp_file(registry, file_path)
  writeLines(lines, temp_file)
  finalize_output_file(temp_file, file_path, registry)
}

save_plot_atomic <- function(plot_fun, file_path, registry) {
  temp_file <- register_temp_file(registry, file_path)
  plot_fun(temp_file)
  finalize_output_file(temp_file, file_path, registry)
}

run_with_timeout <- function(timeout_seconds, expr) {
  setTimeLimit(elapsed = timeout_seconds, transient = FALSE)
  on.exit(setTimeLimit(), add = TRUE)
  withCallingHandlers(
    expr,
    warning = function(w) {
      message(format_log("WARN", conditionMessage(w)))
      invokeRestart("muffleWarning")
    }
  )
}

normalize_runtime_error <- function(e) {
  message_text <- conditionMessage(e)
  if (grepl("reached .* time limit", message_text, ignore.case = TRUE))
    return("SKILL_TIMEOUT: Analysis exceeded the configured time limit")
  if (grepl("cannot allocate vector|memory", message_text, ignore.case = TRUE) && !grepl("SKILL_", message_text))
    return(paste("SKILL_MEMORY_ERROR:", message_text))
  if (grepl("SKILL_", message_text))
    return(message_text)
  paste("SKILL_RUNTIME_ERROR:", message_text)
}
