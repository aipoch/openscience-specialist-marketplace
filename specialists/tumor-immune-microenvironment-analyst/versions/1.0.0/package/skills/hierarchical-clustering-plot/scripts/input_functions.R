read_csv_checked <- function(file_path, dataset_name) {
  log_info(paste("Reading", dataset_name, "CSV with data.table::fread"))
  tryCatch(
    data.table::fread(
      file_path,
      data.table = FALSE,
      check.names = FALSE,
      encoding = "UTF-8"
    ),
    error = function(e) {
      stop("SKILL_PARSE_ERROR: Failed to read ", dataset_name, " CSV: ", conditionMessage(e), call. = FALSE)
    }
  )
}

load_expression_matrix <- function(input_file) {
  expr_df <- read_csv_checked(input_file, "expression matrix")
  if (nrow(expr_df) == 0)
    stop("SKILL_EMPTY_DATA: Expression matrix contains no rows", call. = FALSE)
  if (ncol(expr_df) < 3)
    stop("SKILL_INVALID_DATA: Expression matrix must contain one feature column and at least two sample columns", call. = FALSE)

  sample_names <- trimws(colnames(expr_df)[-1])
  feature_ids <- trimws(as.character(expr_df[[1]]))
  expr_values_raw <- expr_df[-1]
  if (anyNA(sample_names) || any(sample_names == ""))
    stop("SKILL_MISSING_COLUMNS: Expression matrix sample columns must have non-empty names", call. = FALSE)
  if (anyDuplicated(sample_names))
    stop("SKILL_INVALID_DATA: Expression matrix sample column names must be unique", call. = FALSE)
  if (anyNA(feature_ids) || any(feature_ids == ""))
    stop("SKILL_INVALID_DATA: Feature IDs in the first column must be non-empty", call. = FALSE)
  if (anyDuplicated(feature_ids))
    stop("SKILL_INVALID_DATA: Feature IDs in the first column must be unique", call. = FALSE)
  if (!all(vapply(expr_values_raw, is.numeric, logical(1))))
    stop("SKILL_INVALID_TYPE: Expression values must be numeric", call. = FALSE)

  expr_mat <- as.matrix(data.frame(expr_values_raw, check.names = FALSE))
  rownames(expr_mat) <- feature_ids
  colnames(expr_mat) <- sample_names
  if (anyNA(expr_mat))
    stop("SKILL_INVALID_DATA: Expression matrix contains non-numeric or missing values", call. = FALSE)
  if (nrow(expr_mat) < 2)
    stop("SKILL_INVALID_DATA: Expression matrix must contain at least two features", call. = FALSE)
  expr_mat
}

load_group_data <- function(group_file, label_column) {
  group_df <- read_csv_checked(group_file, "group annotation")
  if (nrow(group_df) == 0)
    stop("SKILL_EMPTY_DATA: Group file contains no rows", call. = FALSE)
  if (ncol(group_df) < 2)
    stop("SKILL_INVALID_DATA: Group file must contain a sample column and at least one label column", call. = FALSE)

  validate_required_columns(group_df, colnames(group_df)[1:2], "group file")
  sample_ids <- trimws(as.character(group_df[[1]]))
  selected_label <- if (nzchar(label_column)) label_column else colnames(group_df)[2]
  if (!(selected_label %in% colnames(group_df)))
    stop("SKILL_INVALID_PARAMETER: label column not found in group file: ", selected_label, call. = FALSE)

  labels <- trimws(as.character(group_df[[selected_label]]))
  if (anyNA(sample_ids) || any(sample_ids == ""))
    stop("SKILL_INVALID_DATA: Sample IDs in group file must be non-empty", call. = FALSE)
  if (anyDuplicated(sample_ids))
    stop("SKILL_INVALID_DATA: Sample IDs in group file must be unique", call. = FALSE)
  if (anyNA(labels) || any(labels == ""))
    stop("SKILL_INVALID_DATA: Selected label column contains empty values", call. = FALSE)
  data.frame(sample_id = sample_ids, label = labels, stringsAsFactors = FALSE)
}

align_samples <- function(expr_mat, group_df) {
  if (!all(group_df$sample_id %in% colnames(expr_mat))) {
    missing_samples <- setdiff(group_df$sample_id, colnames(expr_mat))
    stop(
      "SKILL_SAMPLE_MISMATCH: Samples in group file not found in expression matrix: ",
      paste(head(missing_samples, 10), collapse = ", "),
      call. = FALSE
    )
  }

  extra_samples <- setdiff(colnames(expr_mat), group_df$sample_id)
  if (length(extra_samples) > 0)
    warning(
      paste("SKILL_WARNING: Ignoring matrix samples not listed in group file:", paste(head(extra_samples, 10), collapse = ", ")),
      call. = FALSE
    )

  aligned_expr <- expr_mat[, group_df$sample_id, drop = FALSE]
  if (ncol(aligned_expr) < 2)
    stop("SKILL_INVALID_DATA: At least two matched samples are required for clustering", call. = FALSE)
  list(expr = aligned_expr, groups = group_df)
}
