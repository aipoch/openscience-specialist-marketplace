log_msg <- function(level, ...) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  msg <- paste(..., sep = "", collapse = "")
  cat(paste0("[", timestamp, "] ", toupper(level), ": ", msg, "\n"))
}

log_info <- function(...) log_msg("info", ...)
log_error <- function(...) log_msg("error", ...)
log_warn <- function(...) log_msg("warn", ...)

check_pkg <- function(pkg, min_ver = NULL) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop(paste("SKILL_DEPENDENCY_MISSING:", pkg))
  }
  library(pkg, character.only = TRUE, warn.conflicts = FALSE)
  if (!is.null(min_ver) && packageVersion(pkg) < min_ver) {
    stop(paste("SKILL_PKG_VERSION:", pkg, "needs >=", min_ver))
  }
}

parse_bool <- function(value, name) {
  if (is.logical(value) && length(value) == 1 && !is.na(value)) {
    return(value)
  }

  normalized <- tolower(trimws(as.character(value)))
  if (normalized %in% c("true", "t", "1", "yes", "y")) {
    return(TRUE)
  }
  if (normalized %in% c("false", "f", "0", "no", "n")) {
    return(FALSE)
  }

  stop("SKILL_INVALID_PARAMETER: ", name, " must be one of true or false")
}

normalize_optional_column <- function(value) {
  if (is.null(value)) {
    return(NULL)
  }

  trimmed <- trimws(as.character(value))
  if (!nzchar(trimmed)) {
    return(NULL)
  }

  return(trimmed)
}

split_feature_columns <- function(value) {
  if (is.null(value)) {
    return(NULL)
  }

  pieces <- trimws(unlist(strsplit(as.character(value), ",", fixed = TRUE)))
  pieces <- pieces[nzchar(pieces)]

  if (length(pieces) == 0) {
    return(NULL)
  }

  duplicated_cols <- unique(pieces[duplicated(pieces)])
  if (length(duplicated_cols) > 0) {
    stop(
      "SKILL_INVALID_PARAMETER: feature_columns contains duplicates: ",
      paste(duplicated_cols, collapse = ", ")
    )
  }

  return(pieces)
}

validate_parameters_opt <- function(params) {
  if (!file.exists(params$data_file)) {
    stop("SKILL_FILE_NOT_FOUND: Data file not found: ", params$data_file)
  }

  params$sample_id_column <- normalize_optional_column(params$sample_id_column)
  params$group_column <- normalize_optional_column(params$group_column)
  params$feature_columns <- split_feature_columns(params$feature_columns)

  params$center_data <- parse_bool(params$center_data, "center_data")
  params$scale_data <- parse_bool(params$scale_data, "scale_data")

  if (!is.numeric(params$n_components) || length(params$n_components) != 1 || is.na(params$n_components) || params$n_components < 1) {
    stop("SKILL_INVALID_PARAMETER: n_components must be a positive integer")
  }
  params$n_components <- as.integer(params$n_components)

  if (!is.numeric(params$top_loadings) || length(params$top_loadings) != 1 || is.na(params$top_loadings) || params$top_loadings < 1) {
    stop("SKILL_INVALID_PARAMETER: top_loadings must be a positive integer")
  }
  params$top_loadings <- as.integer(params$top_loadings)

  if (!(params$output_format %in% c("csv", "txt"))) {
    stop("SKILL_INVALID_PARAMETER: output_format must be one of: 'csv', 'txt'")
  }

  if (is.null(params$output_prefix) || !nzchar(trimws(params$output_prefix))) {
    stop("SKILL_INVALID_PARAMETER: output_prefix must not be empty")
  }
  params$output_prefix <- trimws(params$output_prefix)

  return(params)
}

read_data <- function(file_path) {
  check_pkg("data.table")

  if (!file.exists(file_path)) {
    stop("SKILL_FILE_NOT_FOUND: File not found: ", file_path)
  }

  file_ext <- tolower(tools::file_ext(file_path))
  log_info("Loading data from ", file_path, " (", ifelse(nzchar(file_ext), file_ext, "no extension"), ")...")

  if (file_ext == "csv") {
    data <- fread(file_path, header = TRUE, check.names = FALSE)
  } else if (file_ext %in% c("txt", "tsv")) {
    sep_value <- ifelse(file_ext == "tsv", "\t", "")
    data <- fread(file_path, header = TRUE, sep = sep_value, check.names = FALSE)
  } else if (file_ext == "") {
    data <- fread(file_path, header = TRUE, sep = "\t", check.names = FALSE)
  } else {
    stop(
      "SKILL_INVALID_PARAMETER: Unsupported file format: ",
      file_ext,
      ". Supported formats: .csv, .txt, .tsv"
    )
  }

  if (nrow(data) == 0 || ncol(data) == 0) {
    stop("SKILL_INVALID_DATA: Input data file is empty")
  }

  log_info("Data loaded: ", nrow(data), " rows, ", ncol(data), " columns")
  return(data)
}

create_output_structure <- function(base_dir) {
  if (!dir.exists(base_dir)) {
    dir.create(base_dir, recursive = TRUE, showWarnings = FALSE)
    log_info("Created output directory: ", base_dir)
  }

  dir.create(file.path(base_dir, "data"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(base_dir, "table"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(base_dir, "figure"), recursive = TRUE, showWarnings = FALSE)

  return(list(
    base_dir = base_dir,
    data_dir = file.path(base_dir, "data"),
    table_dir = file.path(base_dir, "table"),
    figure_dir = file.path(base_dir, "figure")
  ))
}

write_output_table <- function(df, file_path, format) {
  if (format == "csv") {
    write.csv(df, file_path, row.names = FALSE)
  } else {
    write.table(df, file_path, row.names = FALSE, sep = "\t", quote = FALSE)
  }
  log_info("Saved results to: ", file_path)
}

save_session_info <- function(output_dir) {
  session_file <- file.path(output_dir, "session_info.txt")
  writeLines(capture.output(sessionInfo()), session_file)
  log_info("Session info saved to: ", session_file)
}
