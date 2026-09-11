DEFAULT_LINE_COLORS <- c(
  "#4DBBD5", "#E64B35", "#00A087", "#3C5488",
  "#F39B7F", "#8491B4", "#91D1C2", "#DC0000"
)

SUPPORTED_LINE_TYPES <- c("solid", "dashed", "dotted", "dotdash", "longdash", "twodash")

log_msg <- function(level, ...) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  msg <- paste(..., sep = "", collapse = "")
  cat(paste0("[", timestamp, "] ", toupper(level), ": ", msg, "\n"))
}

log_info <- function(...) log_msg("info", ...)
log_warn <- function(...) log_msg("warn", ...)

check_pkg <- function(pkg, min_ver = NULL) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop(paste("SKILL_DEPENDENCY_MISSING:", pkg))
  }
  suppressPackageStartupMessages(
    library(pkg, character.only = TRUE, warn.conflicts = FALSE)
  )
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

parse_line_colors_opt <- function(value) {
  pieces <- trimws(unlist(strsplit(as.character(value), ",", fixed = TRUE)))
  pieces <- pieces[nzchar(pieces)]

  if (length(pieces) == 0) {
    return(DEFAULT_LINE_COLORS)
  }

  return(pieces)
}

validate_parameters_opt <- function(params) {
  if (!file.exists(params$input_file)) {
    stop("SKILL_FILE_NOT_FOUND: Input file not found: ", params$input_file)
  }

  params$legend_show <- parse_bool(params$legend_show, "legend_show")
  params$censor_show <- parse_bool(params$censor_show, "censor_show")
  params$confidence_show <- parse_bool(params$confidence_show, "confidence_show")
  params$risk_table_show <- parse_bool(params$risk_table_show, "risk_table_show")
  params$risk_table_border <- parse_bool(params$risk_table_border, "risk_table_border")
  params$risk_table_panel <- parse_bool(params$risk_table_panel, "risk_table_panel")
  params$auto_convert_days <- parse_bool(params$auto_convert_days, "auto_convert_days")
  params$line_colors <- parse_line_colors_opt(params$line_colors)

  if (!(params$time_unit %in% c("year", "month", "day"))) {
    stop("SKILL_INVALID_PARAMETER: time_unit must be one of: year, month, day")
  }

  if (!(params$statistics_method %in% c("logrank", "wald"))) {
    stop("SKILL_INVALID_PARAMETER: statistics_method must be one of: 'logrank', 'wald'")
  }

  if (!(params$line_type %in% SUPPORTED_LINE_TYPES)) {
    stop(
      "SKILL_INVALID_PARAMETER: line_type must be one of: ",
      paste(SUPPORTED_LINE_TYPES, collapse = ", ")
    )
  }

  numeric_params <- c(
    "figure_width", "figure_height", "line_size",
    "censor_size", "risk_table_size", "axis_title_size",
    "axis_text_size", "legend_text_size"
  )

  for (param_name in numeric_params) {
    if (!is.numeric(params[[param_name]]) || length(params[[param_name]]) != 1 || is.na(params[[param_name]]) || params[[param_name]] <= 0) {
      stop("SKILL_INVALID_PARAMETER: ", param_name, " must be greater than 0")
    }
  }

  if (params$confidence_alpha < 0 || params$confidence_alpha > 1) {
    stop("SKILL_INVALID_PARAMETER: confidence_alpha must be between 0 and 1")
  }

  if (!(params$legend_position %in% c("top", "bottom", "left", "right", "none"))) {
    stop("SKILL_INVALID_PARAMETER: legend_position must be one of: 'top', 'bottom', 'left', 'right', 'none'")
  }

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
    data <- fread(file_path, header = TRUE, sep = "\t", check.names = FALSE)
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

create_output_dir <- function(base_dir) {
  if (!dir.exists(base_dir)) {
    dir.create(base_dir, recursive = TRUE, showWarnings = FALSE)
    log_info("Created output directory: ", base_dir)
  }
  invisible(base_dir)
}

save_session_info <- function(output_dir) {
  session_file <- file.path(output_dir, "session_info.txt")
  writeLines(capture.output(sessionInfo()), session_file)
  log_info("Session info saved to: ", session_file)
}
