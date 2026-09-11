read_expression_matrix <- function(path) {
  validate_file_exists(path)
  file_info <- file.info(path)
  if (is.na(file_info$size) || file_info$size <= 0)
    stop("SKILL_EMPTY_DATA: expression matrix file is empty", call. = FALSE)
  data <- tryCatch(
    read.csv(path, row.names = 1, check.names = FALSE, stringsAsFactors = FALSE),
    error = function(e) stop(sprintf("SKILL_INVALID_DATA: failed to read expression matrix: %s", conditionMessage(e)), call. = FALSE)
  )
  if (nrow(data) < 2L || ncol(data) < 4L)
    stop("SKILL_INVALID_DATA: expression matrix must contain at least 2 genes and 4 samples", call. = FALSE)
  if (anyDuplicated(rownames(data)) > 0L)
    stop("SKILL_INVALID_DATA: duplicate gene IDs found in expression matrix", call. = FALSE)
  if (anyDuplicated(colnames(data)) > 0L)
    stop("SKILL_INVALID_DATA: duplicate sample IDs found in expression matrix", call. = FALSE)
  matrix_data <- as.matrix(data)
  suppressWarnings(storage.mode(matrix_data) <- "double")
  if (anyNA(matrix_data))
    stop("SKILL_INVALID_DATA: expression matrix contains non-numeric or missing values", call. = FALSE)
  matrix_data
}

read_group_file <- function(path) {
  validate_file_exists(path)
  file_info <- file.info(path)
  if (is.na(file_info$size) || file_info$size <= 0)
    stop("SKILL_EMPTY_DATA: group file is empty", call. = FALSE)
  data <- tryCatch(
    read.csv(path, stringsAsFactors = FALSE, check.names = FALSE),
    error = function(e) stop(sprintf("SKILL_INVALID_DATA: failed to read group file: %s", conditionMessage(e)), call. = FALSE)
  )
  if (ncol(data) < 2L)
    stop("SKILL_MISSING_COLUMNS: group file must contain sample and group columns", call. = FALSE)
  names_lower <- tolower(names(data))
  sample_idx <- which(names_lower %in% c("sample", "sample_id", "id"))[1]
  group_idx <- which(names_lower %in% c("group", "class", "label"))[1]
  if (is.na(sample_idx) || is.na(group_idx))
    stop("SKILL_MISSING_COLUMNS: unable to detect sample/group columns", call. = FALSE)
  groups <- data.frame(
    sample_id = trimws(as.character(data[[sample_idx]])),
    group = trimws(as.character(data[[group_idx]])),
    stringsAsFactors = FALSE
  )
  groups <- groups[nzchar(groups$sample_id) & nzchar(groups$group), , drop = FALSE]
  if (nrow(groups) < 4L)
    stop("SKILL_INVALID_DATA: group file must contain at least 4 labeled samples", call. = FALSE)
  if (anyDuplicated(groups$sample_id) > 0L)
    stop("SKILL_INVALID_DATA: duplicate sample IDs found in group file", call. = FALSE)
  groups
}

read_feature_list <- function(path) {
  if (is.null(path) || !nzchar(path))
    return(NULL)
  validate_file_exists(path)
  file_info <- file.info(path)
  if (is.na(file_info$size) || file_info$size <= 0)
    stop("SKILL_EMPTY_DATA: feature file is empty", call. = FALSE)
  data <- tryCatch(
    read.csv(path, header = FALSE, stringsAsFactors = FALSE),
    error = function(e) stop(sprintf("SKILL_INVALID_DATA: failed to read feature file: %s", conditionMessage(e)), call. = FALSE)
  )
  features <- unique(trimws(as.character(data[[1]])))
  features <- features[nzchar(features)]
  if (length(features) == 0L)
    stop("SKILL_INVALID_DATA: feature file contains no usable feature names", call. = FALSE)
  features
}
