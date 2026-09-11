build_option_list <- function() {
  list(
    optparse::make_option(c("-i", "--input_file"), type = "character", default = NULL,
                          help = "Expression matrix file (features as rows, samples as columns) [required]", metavar = "file"),
    optparse::make_option(c("-g", "--group_file"), type = "character", default = NULL,
                          help = "Group file with sample and group columns [required]", metavar = "file"),
    optparse::make_option(c("-c", "--case_group"), type = "character", default = NULL,
                          help = "Case group label encoded as 1 [required]", metavar = "label"),
    optparse::make_option(c("-t", "--control_group"), type = "character", default = NULL,
                          help = "Control group label encoded as 0 [required]", metavar = "label"),
    optparse::make_option(c("-f", "--feature"), type = "character", default = NULL,
                          help = "Optional feature file or comma-separated feature names", metavar = "value"),
    optparse::make_option(c("-n", "--nfolds"), type = "integer", default = 10,
                          help = "Cross-validation folds: 3, 5, 7, or 10 [default %default]", metavar = "int"),
    optparse::make_option(c("--cv_title"), type = "character", default = "",
                          help = "Optional title for the cross-validation plot [default %default]", metavar = "text"),
    optparse::make_option(c("--path_title"), type = "character", default = "",
                          help = "Optional title for the coefficient path plot [default %default]", metavar = "text"),
    optparse::make_option(c("--timeout_seconds"), type = "integer", default = 1800,
                          help = "Maximum elapsed runtime in seconds [default %default]", metavar = "int"),
    optparse::make_option(c("-o", "--output_dir"), type = "character", default = "./output/",
                          help = "Output directory [default %default]", metavar = "dir"),
    optparse::make_option(c("-s", "--seed"), type = "integer", default = 42,
                          help = "Random seed for reproducibility [default %default]", metavar = "int")
  )
}

check_single_string <- function(value, name, allow_empty = FALSE) {
  if (!is.character(value) || length(value) != 1L || is.na(value))
    stop(sprintf("SKILL_INVALID_TYPE: %s must be a single character value", name))
  if (!allow_empty && !nzchar(trimws(value)))
    stop(sprintf("SKILL_INVALID_PARAMETER: %s cannot be empty", name))
  invisible(TRUE)
}

check_single_integer <- function(value, name, min_value) {
  if (!is.numeric(value) || length(value) != 1L || is.na(value) || !is.finite(value))
    stop(sprintf("SKILL_INVALID_TYPE: %s must be a single finite numeric value", name))
  if (value < min_value)
    stop(sprintf("SKILL_INVALID_PARAMETER: %s must be >= %s", name, min_value))
  invisible(TRUE)
}

validate_cli_options <- function(opt) {
  check_single_string(opt$input_file, "--input_file")
  check_single_string(opt$group_file, "--group_file")
  check_single_string(opt$case_group, "--case_group")
  check_single_string(opt$control_group, "--control_group")
  check_single_string(opt$output_dir, "--output_dir")
  check_single_string(opt$cv_title, "--cv_title", allow_empty = TRUE)
  check_single_string(opt$path_title, "--path_title", allow_empty = TRUE)
  check_single_integer(opt$nfolds, "--nfolds", 1)
  check_single_integer(opt$seed, "--seed", 0)
  check_single_integer(opt$timeout_seconds, "--timeout_seconds", 1)
  if (!(opt$nfolds %in% c(3L, 5L, 7L, 10L)))
    stop("SKILL_INVALID_PARAMETER: --nfolds must be one of 3, 5, 7, or 10")
  if (!is.null(opt$feature))
    check_single_string(opt$feature, "--feature")
  if (file.exists(opt$output_dir) && !dir.exists(opt$output_dir))
    stop("SKILL_INVALID_PARAMETER: --output_dir points to an existing file, not a directory")
  invisible(TRUE)
}

parse_cli_options <- function() {
  parser <- optparse::OptionParser(
    option_list = build_option_list(),
    description = "LASSO Logistic Regression Analysis"
  )
  opt <- optparse::parse_args(parser)
  required_values <- c(opt$input_file, opt$group_file, opt$case_group, opt$control_group)
  if (any(vapply(required_values, is.null, logical(1)))) {
    print_help(parser)
    stop("SKILL_INVALID_PARAMETER: --input_file, --group_file, --case_group, and --control_group are required")
  }
  validate_cli_options(opt)
  opt
}
