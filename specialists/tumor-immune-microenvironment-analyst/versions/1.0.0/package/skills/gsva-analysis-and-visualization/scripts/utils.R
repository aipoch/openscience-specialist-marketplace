#!/usr/bin/env Rscript

timestamp_now <- function() {
  format(Sys.time(), "%Y-%m-%d %H:%M:%S")
}

log_message <- function(level, message_text) {
  message(sprintf("[%s] %s | %s", level, timestamp_now(), message_text))
}

log_info <- function(message_text) {
  log_message("INFO", message_text)
}

log_warn <- function(message_text) {
  log_message("WARN", message_text)
}

stop_skill <- function(code, message_text) {
  stop(sprintf("%s: %s", code, message_text), call. = FALSE)
}

check_required_packages <- function(packages) {
  missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing) > 0) {
    stop_skill(
      "SKILL_PACKAGE_NOT_FOUND",
      sprintf("Missing required packages: %s", paste(missing, collapse = ", "))
    )
  }
}

ensure_dir <- function(path) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
}

validate_existing_file <- function(path, label) {
  if (is.null(path) || !nzchar(path)) {
    stop_skill("SKILL_INVALID_PARAMETER", sprintf("%s is required.", label))
  }
  if (!file.exists(path)) {
    stop_skill("SKILL_FILE_NOT_FOUND", sprintf("%s does not exist: %s", label, path))
  }
}

validate_numeric_range <- function(value, lower, upper, label) {
  if (is.na(value) || value < lower || value > upper) {
    stop_skill(
      "SKILL_INVALID_PARAMETER",
      sprintf("%s must be between %s and %s.", label, lower, upper)
    )
  }
}

enable_timeout <- function(timeout_seconds) {
  if (!is.null(timeout_seconds) && timeout_seconds > 0) {
    setTimeLimit(cpu = timeout_seconds, elapsed = timeout_seconds, transient = TRUE)
    log_info(sprintf("Timeout enabled: %s seconds", timeout_seconds))
  }
}

save_session_info <- function(output_dir) {
  session_file <- file.path(output_dir, "session_info.txt")
  sink(session_file)
  on.exit(sink(), add = TRUE)
  print(sessionInfo())
}

normalize_species <- function(species) {
  species_key <- tolower(trimws(species))
  if (species_key %in% c("human", "homo", "homo sapiens")) {
    return("Homo sapiens")
  }
  if (species_key %in% c("mouse", "mus", "mus musculus")) {
    return("Mus musculus")
  }
  species
}

read_delimited_table <- function(path, row_names = FALSE) {
  if (grepl("\\.csv$", path, ignore.case = TRUE)) {
    read.csv(path, header = TRUE, row.names = if (row_names) 1 else NULL,
             stringsAsFactors = FALSE, check.names = FALSE)
  } else {
    read.table(path, header = TRUE, sep = "\t", row.names = if (row_names) 1 else NULL,
               stringsAsFactors = FALSE, check.names = FALSE)
  }
}

get_script_dir <- function() {
  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", cmd_args, value = TRUE)
  if (length(file_arg) > 0) {
    return(dirname(normalizePath(sub("^--file=", "", file_arg), winslash = "/", mustWork = FALSE)))
  }
  "."
}

`%||%` <- function(a, b) if (!is.null(a)) a else b
