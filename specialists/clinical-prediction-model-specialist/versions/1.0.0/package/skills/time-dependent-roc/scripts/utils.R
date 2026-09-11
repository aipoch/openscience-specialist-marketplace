log_msg <- function(level, ...) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  msg <- paste(..., sep = "", collapse = "")
  cat(paste0("[", timestamp, "] ", toupper(level), ": ", msg, "\n"))
}

log_info <- function(...) log_msg("info", ...)
log_warn <- function(...) log_msg("warn", ...)
log_error <- function(...) log_msg("error", ...)

check_pkg <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop("SKILL_DEPENDENCY_MISSING: ", pkg)
  }
  library(pkg, character.only = TRUE, warn.conflicts = FALSE)
}

parse_csv_numeric <- function(value, arg_name) {
  parts <- trimws(strsplit(value, ",", fixed = TRUE)[[1]])
  parts <- parts[nzchar(parts)]

  if (length(parts) == 0) {
    stop("SKILL_INVALID_PARAMETER: ", arg_name, " must contain at least one numeric value")
  }

  parsed <- suppressWarnings(as.numeric(parts))
  if (any(is.na(parsed))) {
    stop("SKILL_INVALID_PARAMETER: ", arg_name, " must be a comma-separated numeric list")
  }

  parsed
}

parse_csv_character <- function(value) {
  parts <- trimws(strsplit(value, ",", fixed = TRUE)[[1]])
  parts[nzchar(parts)]
}

read_data <- function(file_path) {
  if (!file.exists(file_path)) {
    stop("SKILL_FILE_NOT_FOUND: Data file not found: ", file_path)
  }

  file_ext <- tolower(tools::file_ext(file_path))
  log_info("Loading data from ", file_path, " (", ifelse(file_ext == "", "no extension", file_ext), ")")

  if (file_ext == "csv") {
    data <- read.csv(file_path, header = TRUE, check.names = FALSE, stringsAsFactors = FALSE)
  } else if (file_ext %in% c("txt", "tsv", "tab")) {
    data <- read.delim(file_path, header = TRUE, check.names = FALSE, stringsAsFactors = FALSE)
  } else if (file_ext %in% c("xls", "xlsx")) {
    check_pkg("openxlsx")
    data <- as.data.frame(openxlsx::read.xlsx(file_path), stringsAsFactors = FALSE)
  } else {
    stop(
      "SKILL_INVALID_PARAMETER: Unsupported file format: ",
      ifelse(file_ext == "", "<none>", file_ext),
      ". Supported formats: csv, txt, tsv, tab, xls, xlsx"
    )
  }

  log_info("Data loaded: ", nrow(data), " rows, ", ncol(data), " columns")
  data
}

create_output_structure <- function(base_dir) {
  if (!dir.exists(base_dir)) {
    dir.create(base_dir, recursive = TRUE, showWarnings = FALSE)
    log_info("Created output directory: ", base_dir)
  }

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

save_session_info <- function(output_dir) {
  session_file <- file.path(output_dir, "session_info.txt")
  writeLines(capture.output(sessionInfo()), session_file)
  log_info("Session info saved to: ", session_file)
}

validate_parameters_opt <- function(params) {
  if (!file.exists(params$data_file)) {
    stop("SKILL_FILE_NOT_FOUND: Data file not found: ", params$data_file)
  }

  if (length(params$times) == 0 || any(!is.finite(params$times)) || any(params$times <= 0)) {
    stop("SKILL_INVALID_PARAMETER: times must contain positive numeric values")
  }

  if (!(params$time_unit %in% c("year", "month", "day"))) {
    stop("SKILL_INVALID_PARAMETER: time_unit must be one of: year, month, day")
  }

  if (!(params$weighting %in% c("aalen", "marginal", "cox"))) {
    stop("SKILL_INVALID_PARAMETER: weighting must be one of: aalen, marginal, cox")
  }

  if (!(params$output_format %in% c("csv", "txt"))) {
    stop("SKILL_INVALID_PARAMETER: output_format must be one of: csv, txt")
  }

  if (!is.numeric(params$cause) || length(params$cause) != 1 || !is.finite(params$cause)) {
    stop("SKILL_INVALID_PARAMETER: cause must be a single numeric value")
  }

  if (!is.numeric(params$width) || params$width <= 0 || !is.numeric(params$height) || params$height <= 0) {
    stop("SKILL_INVALID_PARAMETER: width and height must be positive numbers")
  }

  if (!params$line_type %in% c("solid", "dashed", "dotted", "dotdash", "longdash", "twodash")) {
    stop("SKILL_INVALID_PARAMETER: line_type must be a valid ggplot line type")
  }

  if (!params$diagonal_type %in% c("solid", "dashed", "dotted", "dotdash", "longdash", "twodash")) {
    stop("SKILL_INVALID_PARAMETER: diagonal_type must be a valid ggplot line type")
  }

  if (!params$legend_position %in% c("none", "left", "right", "top", "bottom", "bottomright", "bottomleft", "topright", "topleft")) {
    stop("SKILL_INVALID_PARAMETER: legend_position must be one of: none, left, right, top, bottom, bottomright, bottomleft, topright, topleft")
  }

  if (is.null(params$marker_col) || !nzchar(params$marker_col)) {
    stop("SKILL_INVALID_PARAMETER: marker_col must not be empty")
  }

  if (length(params$line_colors) == 0) {
    stop("SKILL_INVALID_PARAMETER: line_colors must contain at least one color value")
  }

  params
}
