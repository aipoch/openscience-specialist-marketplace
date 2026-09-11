log_msg <- function(level, ...) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  msg <- paste(..., collapse = " ")
  cat(sprintf("[%s] %s: %s\n", timestamp, toupper(level), msg))
}

log_info <- function(...) log_msg("info", ...)
log_warn <- function(...) log_msg("warn", ...)
log_error <- function(...) log_msg("error", ...)

build_recovery_hint <- function(message_text) {
  if (grepl("^SKILL_MISSING_INPUT:", message_text)) {
    return("Next step: provide both --data_file and --target_var, or run `Rscript scripts/main.R --help`. See references/troubleshooting.md.")
  }

  if (grepl("^SKILL_FILE_NOT_FOUND:", message_text)) {
    return("Next step: verify the --data_file path exists and is readable. See references/troubleshooting.md.")
  }

  if (grepl("^SKILL_MISSING_COLUMNS:", message_text)) {
    return("Next step: check the input header row and make sure --target_var matches it exactly. See references/troubleshooting.md.")
  }

  if (grepl("^SKILL_INVALID_PARAMETER:", message_text)) {
    return("Next step: review the argument value and rerun `Rscript scripts/main.R --help`. See references/troubleshooting.md.")
  }

  if (grepl("^SKILL_INVALID_DATA:", message_text)) {
    return("Next step: inspect the target column, ignored columns, and row counts, then retry. See references/troubleshooting.md.")
  }

  if (grepl("^SKILL_DEPENDENCY_MISSING:", message_text) || grepl("^SKILL_PKG_VERSION:", message_text)) {
    return("Next step: install or update the required R packages, then rerun. See references/troubleshooting.md.")
  }

  NULL
}

check_pkg <- function(pkg, min_ver = NULL) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop(sprintf("SKILL_DEPENDENCY_MISSING: %s", pkg))
  }
  suppressPackageStartupMessages(library(pkg, character.only = TRUE, warn.conflicts = FALSE))
  if (!is.null(min_ver) && utils::packageVersion(pkg) < min_ver) {
    stop(sprintf("SKILL_PKG_VERSION: %s needs >= %s", pkg, min_ver))
  }
}

split_csv_arg <- function(value) {
  if (is.null(value) || !nzchar(value)) {
    return(character(0))
  }
  parts <- trimws(unlist(strsplit(value, ",", fixed = TRUE)))
  unique(parts[nzchar(parts)])
}

validate_parameters_opt <- function(params) {
  if (!file.exists(params$data_file)) {
    stop("SKILL_FILE_NOT_FOUND: Data file not found: ", params$data_file)
  }

  if (!(params$task_type %in% c("auto", "classification", "regression"))) {
    stop("SKILL_INVALID_PARAMETER: task_type must be one of: auto, classification, regression")
  }

  if (!is.null(params$positive_class) && nzchar(params$positive_class) && identical(params$task_type, "regression")) {
    stop("SKILL_INVALID_PARAMETER: positive_class can only be used with binary classification")
  }

  if (params$test_size <= 0 || params$test_size >= 1) {
    stop("SKILL_INVALID_PARAMETER: test_size must be between 0 and 1")
  }

  if (params$nrounds < 1) {
    stop("SKILL_INVALID_PARAMETER: nrounds must be at least 1")
  }

  if (params$max_depth < 1) {
    stop("SKILL_INVALID_PARAMETER: max_depth must be at least 1")
  }

  if (params$eta <= 0 || params$eta > 1) {
    stop("SKILL_INVALID_PARAMETER: eta must be in the interval (0, 1]")
  }

  ratio_params <- c("subsample", "colsample_bytree")
  for (param_name in ratio_params) {
    param_value <- params[[param_name]]
    if (param_value <= 0 || param_value > 1) {
      stop(sprintf("SKILL_INVALID_PARAMETER: %s must be in the interval (0, 1]", param_name))
    }
  }

  if (params$min_child_weight < 0 || params$gamma < 0 || params$lambda < 0 || params$alpha < 0) {
    stop("SKILL_INVALID_PARAMETER: min_child_weight, gamma, lambda, and alpha must be non-negative")
  }

  if (params$early_stopping_rounds < 1) {
    stop("SKILL_INVALID_PARAMETER: early_stopping_rounds must be at least 1")
  }

  if (!(params$importance_metric %in% c("gain", "cover", "frequency"))) {
    stop("SKILL_INVALID_PARAMETER: importance_metric must be one of: gain, cover, frequency")
  }

  if (params$top_n < 1) {
    stop("SKILL_INVALID_PARAMETER: top_n must be at least 1")
  }

  if (!(params$output_format %in% c("csv", "txt"))) {
    stop("SKILL_INVALID_PARAMETER: output_format must be one of: csv, txt")
  }

  normalized_output_dir <- normalizePath(params$output_dir, winslash = "/", mustWork = FALSE)
  output_parent <- dirname(normalized_output_dir)
  if (!dir.exists(output_parent)) {
    stop("SKILL_FILE_NOT_FOUND: Output directory parent does not exist: ", output_parent)
  }
  if (file.access(output_parent, 2) != 0) {
    stop("SKILL_INVALID_PARAMETER: output_dir parent is not writable: ", output_parent)
  }

  params$ignore_vars <- split_csv_arg(params$ignore_vars)
  params
}

read_data <- function(file_path) {
  check_pkg("data.table")

  if (!file.exists(file_path)) {
    stop("SKILL_FILE_NOT_FOUND: Data file not found: ", file_path)
  }

  file_ext <- tolower(tools::file_ext(file_path))
  log_info("Loading data from", file_path)

  if (file_ext == "csv") {
    data <- data.table::fread(file_path, header = TRUE, check.names = FALSE)
  } else if (file_ext %in% c("txt", "tsv")) {
    if (file_ext == "tsv") {
      data <- data.table::fread(file_path, header = TRUE, sep = "\t", check.names = FALSE)
    } else {
      data <- data.table::fread(file_path, header = TRUE, sep = "\t", check.names = FALSE)
      if (ncol(data) <= 1) {
        data <- data.table::fread(file_path, header = TRUE, sep = "", check.names = FALSE)
      }
    }
  } else if (file_ext == "") {
    data <- data.table::fread(file_path, header = TRUE, sep = "\t", check.names = FALSE)
  } else {
    stop("SKILL_INVALID_PARAMETER: Unsupported file format: ", file_ext,
         ". Supported formats: .csv, .txt, .tsv")
  }

  log_info("Data loaded with", nrow(data), "rows and", ncol(data), "columns")
  data
}

create_output_structure <- function(base_dir) {
  dir.create(base_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(base_dir, "data"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(base_dir, "table"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(base_dir, "figure"), recursive = TRUE, showWarnings = FALSE)

  list(
    base_dir = base_dir,
    data_dir = file.path(base_dir, "data"),
    table_dir = file.path(base_dir, "table"),
    figure_dir = file.path(base_dir, "figure")
  )
}

save_table <- function(df, output_file, output_format) {
  if (output_format == "csv") {
    utils::write.csv(df, output_file, row.names = FALSE)
  } else {
    utils::write.table(df, output_file, row.names = FALSE, sep = "\t", quote = FALSE)
  }
  output_file
}

table_output_path <- function(output_dir, prefix, suffix, output_format) {
  ext <- ifelse(output_format == "csv", "csv", "txt")
  file.path(output_dir, sprintf("%s_%s.%s", prefix, suffix, ext))
}

importance_metric_column <- function(metric_name) {
  switch(metric_name,
         gain = "Gain",
         cover = "Cover",
         frequency = "Frequency")
}

save_session_info <- function(output_dir) {
  session_file <- file.path(output_dir, "session_info.txt")
  writeLines(capture.output(sessionInfo()), session_file)
  log_info("Session info saved to", session_file)
}
