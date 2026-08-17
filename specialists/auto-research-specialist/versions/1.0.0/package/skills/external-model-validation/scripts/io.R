clear_previous_outputs <- function(output_dir) {
  unlink(file.path(output_dir, c("analysis.log", "run_parameters.tsv", "session_info.txt")), force = TRUE)
  unlink(file.path(output_dir, c("data", "plot", "table")), recursive = TRUE, force = TRUE)
  invisible(TRUE)
}

create_output_dirs <- function(output_dir, overwrite = FALSE) {
  if (is.null(output_dir) || !nzchar(output_dir))
    stop_skill("SKILL_INVALID_PARAMETER", "--output_dir must be provided")
  if (dir.exists(output_dir)) {
    existing_entries <- list.files(output_dir, all.files = TRUE, no.. = TRUE)
    if (length(existing_entries) > 0 && !isTRUE(overwrite)) {
      stop_skill(
        "SKILL_INVALID_PARAMETER",
        paste("--output_dir already exists and is not empty:", normalizePath(output_dir, winslash = "/", mustWork = TRUE),
              "Use --overwrite to replace the retained output files")
      )
    }
    if (length(existing_entries) > 0 && isTRUE(overwrite))
      clear_previous_outputs(output_dir)
  }
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  subdirs <- c(data = "data", plot = "plot", table = "table")
  for (name in names(subdirs))
    dir.create(file.path(output_dir, subdirs[[name]]), recursive = TRUE, showWarnings = FALSE)
  list(
    root = normalizePath(output_dir, winslash = "/", mustWork = TRUE),
    data = file.path(output_dir, "data"),
    plot = file.path(output_dir, "plot"),
    table = file.path(output_dir, "table")
  )
}

write_risk_outputs <- function(risk_data, output_paths) {
  rds_file <- file.path(output_paths$data, "risk_data.rds")
  table_file <- file.path(output_paths$table, "out_varifyRisk.txt")
  saveRDS(risk_data, file = rds_file)
  write.table(risk_data, file = table_file, sep = "\t", quote = FALSE, row.names = FALSE)
  log_info(paste("Saved risk data to", rds_file))
  log_info(paste("Saved risk table to", table_file))
  list(rds_file = rds_file, table_file = table_file)
}

save_session_info <- function(output_dir) {
  session_file <- file.path(output_dir, "session_info.txt")
  writeLines(capture.output(sessionInfo()), session_file)
  log_info(paste("Saved session info to", session_file))
  invisible(session_file)
}

save_run_parameters <- function(params, output_dir) {
  values <- vapply(params, function(x) paste(x, collapse = ","), character(1))
  param_df <- data.frame(parameter = names(values), value = unname(values), stringsAsFactors = FALSE)
  param_file <- file.path(output_dir, "run_parameters.tsv")
  write.table(param_df, file = param_file, sep = "\t", quote = FALSE, row.names = FALSE)
  log_info(paste("Saved run parameters to", param_file))
  invisible(param_file)
}
