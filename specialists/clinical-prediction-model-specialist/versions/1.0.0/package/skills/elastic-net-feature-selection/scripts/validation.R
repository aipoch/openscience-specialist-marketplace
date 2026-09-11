parse_alpha_spec <- function(alpha_value) {
  alpha_text <- trimws(as.character(alpha_value))
  if (!nzchar(alpha_text)) {
    stop("SKILL_INVALID_PARAMETER: alpha must be a number between 0 and 1, or 'auto'", call. = FALSE)
  }
  if (tolower(alpha_text) == "auto") {
    return(list(mode = "auto", value = NA_real_))
  }
  alpha_numeric <- suppressWarnings(as.numeric(alpha_text))
  if (is.na(alpha_numeric) || alpha_numeric < 0 || alpha_numeric > 1) {
    stop("SKILL_INVALID_PARAMETER: alpha must be a number between 0 and 1, or 'auto'", call. = FALSE)
  }
  list(mode = "fixed", value = alpha_numeric)
}

parse_alpha_grid <- function(alpha_grid) {
  grid_parts <- trimws(strsplit(as.character(alpha_grid), ",", fixed = TRUE)[[1]])
  grid_parts <- grid_parts[nzchar(grid_parts)]
  grid_values <- suppressWarnings(as.numeric(grid_parts))
  if (length(grid_values) == 0L || anyNA(grid_values) || any(grid_values < 0 | grid_values > 1)) {
    stop("SKILL_INVALID_PARAMETER: alpha_grid must be a comma-separated list of numbers between 0 and 1", call. = FALSE)
  }
  unique(grid_values)
}

validate_cli_options <- function(opt) {
  if (is.null(opt$input_file) || !nzchar(opt$input_file) || is.null(opt$group_file) || !nzchar(opt$group_file)) {
    stop("SKILL_INVALID_PARAMETER: --input_file and --group_file are required", call. = FALSE)
  }
  if (is.null(opt$output_dir) || !nzchar(opt$output_dir)) {
    stop("SKILL_INVALID_PARAMETER: --output_dir must not be empty", call. = FALSE)
  }
  if (opt$case_group == opt$control_group) {
    stop("SKILL_INVALID_PARAMETER: case_group and control_group must differ", call. = FALSE)
  }
  if (!is.numeric(opt$nfolds) || is.na(opt$nfolds) || opt$nfolds < 2) {
    stop("SKILL_INVALID_PARAMETER: nfolds must be at least 2", call. = FALSE)
  }
  if (!opt$lambda_choice %in% c("lambda.min", "lambda.1se")) {
    stop("SKILL_INVALID_PARAMETER: lambda_choice must be lambda.min or lambda.1se", call. = FALSE)
  }
  if (!is.logical(opt$standardize) || is.na(opt$standardize)) {
    stop("SKILL_INVALID_PARAMETER: standardize must be TRUE or FALSE", call. = FALSE)
  }
  if (!is.numeric(opt$timeout_seconds) || is.na(opt$timeout_seconds) || opt$timeout_seconds <= 0) {
    stop("SKILL_INVALID_PARAMETER: timeout_seconds must be greater than 0", call. = FALSE)
  }
  parse_alpha_spec(opt$alpha)
  parse_alpha_grid(opt$alpha_grid)
  invisible(opt)
}
