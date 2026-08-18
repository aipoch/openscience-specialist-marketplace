read_expression_matrix <- function(path, delimiter = "auto", verbose = TRUE) {
  if (is.null(path) || !nzchar(path)) {
    skill_stop("SKILL_INVALID_PARAMETER", "--input_file is required.")
  }
  if (!file.exists(path)) {
    skill_stop("SKILL_FILE_NOT_FOUND", sprintf("Input file not found: %s", path))
  }

  sep <- detect_delimiter(path, delimiter)
  if (isTRUE(verbose)) {
    log_info(sprintf("Reading expression matrix: %s", path))
  }

  df <- tryCatch(
    read.table(path, header = TRUE, sep = sep, quote = "\"", comment.char = "", check.names = FALSE, stringsAsFactors = FALSE),
    error = function(e) skill_stop("SKILL_INVALID_PARAMETER", paste("Failed to read input matrix:", e$message))
  )

  if (ncol(df) < 2) {
    skill_stop("SKILL_MISSING_COLUMNS", "Matrix must contain one feature column and at least one sample column.")
  }
  if (nrow(df) < 1) {
    skill_stop("SKILL_EMPTY_DATA", "Matrix contains no rows.")
  }

  feature_ids <- as.character(df[[1]])
  if (any(is.na(feature_ids) | trimws(feature_ids) == "")) {
    skill_stop("SKILL_INVALID_PARAMETER", "Feature identifiers in the first column must be non-empty.")
  }

  numeric_df <- df[-1]
  for (col_name in colnames(numeric_df)) {
    numeric_df[[col_name]] <- suppressWarnings(as.numeric(numeric_df[[col_name]]))
  }
  mat <- as.matrix(numeric_df)
  storage.mode(mat) <- "double"
  if (anyNA(mat)) {
    skill_stop("SKILL_INVALID_PARAMETER", "All expression values must be numeric and non-missing.")
  }
  if (any(!is.finite(mat))) {
    skill_stop("SKILL_INVALID_PARAMETER", "All expression values must be finite numeric values.")
  }
  rownames(mat) <- feature_ids
  if (nrow(mat) < 1 || ncol(mat) < 1) {
    skill_stop("SKILL_EMPTY_DATA", "Matrix contains no usable numeric values.")
  }

  list(
    feature_col = colnames(df)[1],
    matrix = mat
  )
}

write_normalized_outputs <- function(output_dir, feature_col, input_mat, normalized_mat, metadata) {
  data_dir <- file.path(output_dir, "data")
  table_dir <- file.path(output_dir, "table")
  ensure_dir(data_dir)
  ensure_dir(table_dir)

  normalized_df <- data.frame(feature = rownames(normalized_mat), normalized_mat, check.names = FALSE)
  colnames(normalized_df)[1] <- feature_col
  write.csv(normalized_df, file.path(table_dir, "normalized_matrix.csv"), row.names = FALSE, quote = TRUE)

  feature_summary <- summarize_axis(input_mat, normalized_mat, axis = "row")
  sample_summary <- summarize_axis(input_mat, normalized_mat, axis = "column")
  write.csv(feature_summary, file.path(table_dir, "feature_summary.csv"), row.names = FALSE, quote = TRUE)
  write.csv(sample_summary, file.path(table_dir, "sample_summary.csv"), row.names = FALSE, quote = TRUE)

  saveRDS(
    list(
      normalized_matrix = normalized_mat,
      metadata = metadata
    ),
    file.path(data_dir, "normalized_matrix.rds")
  )
}
