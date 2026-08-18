read_expression_matrix <- function(input_file) {
  expr_df <- tryCatch(
    data.table::fread(input_file, data.table = FALSE),
    error = function(e) {
      stop(sprintf("SKILL_RUNTIME_ERROR: Failed to read expression matrix: %s", conditionMessage(e)), call. = FALSE)
    }
  )
  validate_expression_frame(expr_df)

  expr_mat <- as.matrix(expr_df[, -1, drop = FALSE])
  rownames(expr_mat) <- expr_df[[1]]
  expr_mat
}

validate_expression_frame <- function(expr_df) {
  if (nrow(expr_df) == 0 || ncol(expr_df) < 2)
    stop("SKILL_INVALID_DATA: Expression matrix must contain gene IDs and at least one sample column", call. = FALSE)

  gene_ids <- expr_df[[1]]
  sample_ids <- colnames(expr_df)[-1]
  expr_cols <- expr_df[, -1, drop = FALSE]

  if (any(is.na(gene_ids) | trimws(gene_ids) == ""))
    stop("SKILL_INVALID_DATA: Gene identifiers must be non-empty", call. = FALSE)
  if (anyDuplicated(gene_ids))
    stop("SKILL_INVALID_DATA: Gene identifiers must be unique", call. = FALSE)
  if (any(is.na(sample_ids) | trimws(sample_ids) == ""))
    stop("SKILL_INVALID_DATA: Sample column names must be non-empty", call. = FALSE)
  if (anyDuplicated(sample_ids))
    stop("SKILL_INVALID_DATA: Sample column names must be unique", call. = FALSE)
  if (!all(vapply(expr_cols, is.numeric, logical(1))))
    stop("SKILL_INVALID_TYPE: Expression values must be numeric", call. = FALSE)

  expr_mat <- as.matrix(expr_cols)
  if (anyNA(expr_mat) || any(!is.finite(expr_mat)))
    stop("SKILL_INVALID_TYPE: Expression values must be numeric and finite", call. = FALSE)

  invisible(TRUE)
}

read_sample_metadata <- function(group_file, sample_column, group_column, batch_column) {
  metadata <- tryCatch(
    data.table::fread(group_file, data.table = FALSE),
    error = function(e) {
      stop(sprintf("SKILL_RUNTIME_ERROR: Failed to read sample metadata: %s", conditionMessage(e)), call. = FALSE)
    }
  )
  validate_metadata_columns(metadata, sample_column, group_column, batch_column)

  metadata <- metadata[, c(sample_column, group_column, batch_column), drop = FALSE]
  colnames(metadata) <- c("sample_id", "group", "batch")
  validate_metadata_values(metadata)
  metadata
}

validate_metadata_columns <- function(metadata, sample_column, group_column, batch_column) {
  if (nrow(metadata) == 0)
    stop("SKILL_INVALID_DATA: Sample metadata must contain at least one row", call. = FALSE)

  required_columns <- c(sample_column, group_column, batch_column)
  missing_columns <- setdiff(required_columns, colnames(metadata))
  if (length(missing_columns) > 0)
    stop(sprintf("SKILL_MISSING_COLUMNS: Metadata is missing column(s): %s", paste(missing_columns, collapse = ", ")), call. = FALSE)

  invisible(TRUE)
}

validate_metadata_values <- function(metadata) {
  if (any(is.na(metadata$sample_id) | trimws(metadata$sample_id) == ""))
    stop("SKILL_INVALID_DATA: Metadata sample IDs must be non-empty", call. = FALSE)
  if (anyDuplicated(metadata$sample_id))
    stop("SKILL_INVALID_DATA: Metadata sample IDs must be unique", call. = FALSE)
  if (any(is.na(metadata$group) | trimws(metadata$group) == ""))
    stop("SKILL_INVALID_DATA: Metadata group values must be non-empty", call. = FALSE)
  if (any(is.na(metadata$batch) | trimws(metadata$batch) == ""))
    stop("SKILL_INVALID_DATA: Metadata batch values must be non-empty", call. = FALSE)

  invisible(TRUE)
}

align_inputs <- function(expr_mat, metadata) {
  missing_samples <- setdiff(metadata$sample_id, colnames(expr_mat))
  if (length(missing_samples) > 0)
    stop(sprintf("SKILL_SAMPLE_MISMATCH: Metadata samples not found in expression matrix: %s", paste(head(missing_samples, 5), collapse = ", ")), call. = FALSE)

  extra_samples <- setdiff(colnames(expr_mat), metadata$sample_id)
  if (length(extra_samples) > 0)
    log_warn(sprintf("Ignoring %d expression columns absent from metadata", length(extra_samples)))

  metadata$group <- as.factor(metadata$group)
  metadata$batch <- as.factor(metadata$batch)
  list(expr = expr_mat[, metadata$sample_id, drop = FALSE], metadata = metadata)
}

validate_design <- function(metadata) {
  if (nrow(metadata) < 4)
    stop("SKILL_INVALID_DATA: At least 4 samples are required", call. = FALSE)

  batch_counts <- table(metadata$batch)
  group_counts <- table(metadata$group)
  if (length(batch_counts) < 2)
    stop("SKILL_INVALID_DATA: At least 2 batches are required", call. = FALSE)
  if (min(batch_counts) < 2)
    stop("SKILL_INVALID_DATA: Each batch must contain at least 2 samples", call. = FALSE)
  if (length(group_counts) < 2)
    stop("SKILL_INVALID_DATA: At least 2 biological groups are required", call. = FALSE)
  if (min(group_counts) < 2)
    stop("SKILL_INVALID_DATA: Each biological group must contain at least 2 samples", call. = FALSE)

  invisible(TRUE)
}
