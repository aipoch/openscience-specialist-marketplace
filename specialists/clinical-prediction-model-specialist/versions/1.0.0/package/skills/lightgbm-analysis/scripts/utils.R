log_msg <- function(level, ...) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  msg <- paste(..., collapse = " ")
  cat(sprintf("[%s] %s: %s\n", timestamp, toupper(level), msg))
}

log_info <- function(...) log_msg("info", ...)
log_warn <- function(...) log_msg("warn", ...)
log_error <- function(...) log_msg("error", ...)

check_pkg <- function(pkg, min_ver = NULL) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop(paste("SKILL_DEPENDENCY_MISSING:", pkg))
  }
  library(pkg, character.only = TRUE, warn.conflicts = FALSE)
  if (!is.null(min_ver) && packageVersion(pkg) < min_ver) {
    stop(paste("SKILL_PKG_VERSION:", pkg, "needs >=", min_ver))
  }
}

validate_parameters_opt <- function(params) {
  if (!file.exists(params$data_file)) {
    stop("SKILL_FILE_NOT_FOUND: Data file not found: ", params$data_file)
  }

  if (!nzchar(trimws(params$target_var))) {
    stop("SKILL_INVALID_PARAMETER: target_var must be a non-empty column name")
  }

  if (!is.logical(params$fail_if_output_exists) || length(params$fail_if_output_exists) != 1) {
    stop("SKILL_INVALID_PARAMETER: fail_if_output_exists must be TRUE or FALSE")
  }

  if (!(params$task_type %in% c("auto", "regression", "binary", "multiclass"))) {
    stop("SKILL_INVALID_PARAMETER: task_type must be one of: auto, regression, binary, multiclass")
  }

  if (!(params$importance_type %in% c("gain", "split"))) {
    stop("SKILL_INVALID_PARAMETER: importance_type must be one of: gain, split")
  }

  if (!(params$output_format %in% c("csv", "txt"))) {
    stop("SKILL_INVALID_PARAMETER: output_format must be one of: csv, txt")
  }

  if (!is.numeric(params$test_size) || params$test_size <= 0 || params$test_size >= 0.5) {
    stop("SKILL_INVALID_PARAMETER: test_size must be between 0 and 0.5")
  }

  if (!is.numeric(params$valid_size) || params$valid_size <= 0 || params$valid_size >= 0.5) {
    stop("SKILL_INVALID_PARAMETER: valid_size must be between 0 and 0.5")
  }

  if (params$top_n < 1) {
    stop("SKILL_INVALID_PARAMETER: top_n must be at least 1")
  }

  numeric_positive_int <- c("nrounds", "num_leaves", "min_data_in_leaf", "bagging_freq", "early_stopping_rounds")
  for (field in numeric_positive_int) {
    if (!is.numeric(params[[field]]) || params[[field]] < 1) {
      stop("SKILL_INVALID_PARAMETER: ", field, " must be at least 1")
    }
  }

  numeric_nonnegative <- c("lambda_l1", "lambda_l2")
  for (field in numeric_nonnegative) {
    if (!is.numeric(params[[field]]) || params[[field]] < 0) {
      stop("SKILL_INVALID_PARAMETER: ", field, " must be non-negative")
    }
  }

  proportion_fields <- c("learning_rate", "feature_fraction", "bagging_fraction")
  for (field in proportion_fields) {
    if (!is.numeric(params[[field]]) || params[[field]] <= 0 || params[[field]] > 1) {
      stop("SKILL_INVALID_PARAMETER: ", field, " must be between 0 and 1")
    }
  }

  if (!is.numeric(params$max_depth) || params$max_depth < -1) {
    stop("SKILL_INVALID_PARAMETER: max_depth must be -1 or a non-negative integer")
  }

  params
}

read_delimited_data <- function(file_path, sep, file_label) {
  tryCatch(
    data.table::fread(file_path, header = TRUE, sep = sep, check.names = FALSE),
    error = function(e) {
      stop("SKILL_INVALID_DATA: Failed to parse ", file_label, " file '", file_path, "'. ", e$message)
    }
  )
}

read_data <- function(file_path) {
  check_pkg("data.table")

  if (!file.exists(file_path)) {
    stop("SKILL_FILE_NOT_FOUND: File not found: ", file_path)
  }

  file_ext <- tolower(tools::file_ext(file_path))
  log_info("Loading data from", file_path, sprintf("(%s format)", ifelse(nzchar(file_ext), file_ext, "txt")))

  data <- if (file_ext == "csv") {
    read_delimited_data(file_path, sep = ",", file_label = "csv")
  } else if (file_ext %in% c("txt", "tsv")) {
    read_delimited_data(file_path, sep = "\t", file_label = file_ext)
  } else if (file_ext == "") {
    read_delimited_data(file_path, sep = "\t", file_label = "tab-delimited")
  } else {
    stop(
      "SKILL_INVALID_PARAMETER: Unsupported file format: ", file_ext,
      ". Supported formats: .csv, .txt, .tsv"
    )
  }

  if (ncol(data) <= 1 && file_ext %in% c("txt", "tsv", "")) {
    stop(
      "SKILL_INVALID_DATA: Parsed text input as a single-column table. ",
      "This workflow expects tab-delimited text for .txt/.tsv files. ",
      "Re-export the file as tab-delimited text or convert it to CSV, then rerun the command."
    )
  }

  log_info("Data loaded:", nrow(data), "rows and", ncol(data), "columns")
  data
}

create_output_structure <- function(base_dir, fail_if_output_exists = FALSE) {
  if (dir.exists(base_dir)) {
    existing_files <- list.files(base_dir, recursive = TRUE, all.files = FALSE, no.. = TRUE)
    if (length(existing_files) > 0) {
      if (isTRUE(fail_if_output_exists)) {
        stop(
          "SKILL_OUTPUT_EXISTS: Output directory already contains files: ", base_dir,
          ". Choose a fresh --output_dir or rerun without --fail_if_output_exists."
        )
      }
      log_warn(
        "Output directory already contains files and rerunning here will overwrite prior artifacts:",
        base_dir,
        "Use a timestamped or per-run output directory when you need an audit trail."
      )
    }
  }

  if (!dir.exists(base_dir)) {
    dir.create(base_dir, recursive = TRUE, showWarnings = FALSE)
    log_info("Created output directory:", base_dir)
  }

  data_dir <- file.path(base_dir, "data")
  table_dir <- file.path(base_dir, "table")
  figure_dir <- file.path(base_dir, "figure")

  dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

  list(
    base_dir = base_dir,
    data_dir = data_dir,
    table_dir = table_dir,
    figure_dir = figure_dir
  )
}

write_table_file <- function(df, file_path, output_format) {
  if (output_format == "csv") {
    utils::write.csv(df, file_path, row.names = FALSE)
  } else {
    utils::write.table(df, file_path, row.names = FALSE, sep = "\t", quote = FALSE)
  }
}

save_session_info <- function(output_dir) {
  session_file <- file.path(output_dir, "session_info.txt")
  writeLines(capture.output(sessionInfo()), session_file)
  log_info("Session info saved to:", session_file)
}
