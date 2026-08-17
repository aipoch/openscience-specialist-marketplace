read_table_header <- function(file_path) {
  data.table::fread(file_path, nrows = 0, data.table = FALSE)
}

empty_chunk_df <- function(col_names) {
  out <- as.data.frame(setNames(replicate(length(col_names), character(0), simplify = FALSE), col_names), stringsAsFactors = FALSE)
  out
}

read_table_chunk <- function(file_path, chunk_size, skip_rows = 0, col_names = NULL) {
  if (skip_rows == 0) {
    return(data.table::fread(file_path, nrows = chunk_size, data.table = FALSE))
  }

  tryCatch(
    data.table::fread(
      file_path,
      skip = skip_rows + 1,
      nrows = chunk_size,
      header = FALSE,
      col.names = col_names,
      data.table = FALSE
    ),
    error = function(e) {
      msg <- conditionMessage(e)
      if (grepl("skip=.*input only has", msg)) {
        return(empty_chunk_df(col_names))
      }
      stop(e)
    }
  )
}

validate_expression_header <- function(header_df) {
  if (ncol(header_df) < 2) {
    skill_stop("EMPTY_DATA", "Expression matrix is empty or missing sample columns")
  }
  sample_names <- colnames(header_df)[-1]
  if (length(sample_names) == 0 || anyNA(sample_names) || any(trimws(sample_names) == "")) {
    skill_stop("MISSING_COLUMNS", "Expression matrix sample columns must have non-empty names")
  }
  assert_unique_values(sample_names, "Expression matrix sample names")
  sample_names
}

coerce_expression_chunk <- function(expr_chunk) {
  gene_ids <- as.character(expr_chunk[[1]])
  if (anyNA(gene_ids) || any(trimws(gene_ids) == "")) {
    skill_stop("MISSING_COLUMNS", "First column of the expression matrix must contain non-empty gene identifiers")
  }
  assert_unique_values(gene_ids, "Gene identifiers within expression chunk")

  expr_chr <- as.matrix(expr_chunk[, -1, drop = FALSE])
  expr_num <- suppressWarnings(matrix(as.numeric(expr_chr), nrow = nrow(expr_chr), ncol = ncol(expr_chr), dimnames = list(gene_ids, colnames(expr_chunk)[-1])))
  invalid_non_missing <- is.na(expr_num) & !is.na(expr_chr) & trimws(as.character(expr_chr)) != ""
  if (any(invalid_non_missing)) {
    bad_idx <- which(invalid_non_missing, arr.ind = TRUE)
    preview <- apply(head(bad_idx, 10), 1, function(idx) {
      sprintf("%s/%s='%s'", rownames(expr_num)[idx[1]], colnames(expr_num)[idx[2]], expr_chr[idx[1], idx[2]])
    })
    skill_stop("INVALID_PARAMETER", sprintf("Expression matrix contains non-numeric values: %s", paste(preview, collapse = ", ")))
  }
  if (anyNA(expr_num)) {
    log_warn("Expression matrix chunk contains NA values; downstream QC may remove affected genes or samples")
  }
  expr_num
}

load_expression_matrix_full <- function(input_file, mad_quantile, min_mad, max_genes) {
  expr_df <- data.table::fread(input_file, data.table = FALSE)
  if (nrow(expr_df) == 0 || ncol(expr_df) < 2) {
    skill_stop("EMPTY_DATA", "Expression matrix is empty or missing sample columns")
  }
  expr_mat <- coerce_expression_chunk(expr_df)
  assert_unique_values(rownames(expr_mat), "Gene identifiers in expression matrix")
  mad_info <- select_genes_by_mad(rownames(expr_mat), compute_mad_values(expr_mat), mad_quantile, min_mad, max_genes)
  expr_mat[mad_info$kept_gene_ids, , drop = FALSE]
}

first_pass_chunk_mad <- function(input_file, chunk_size) {
  header_df <- read_table_header(input_file)
  validate_expression_header(header_df)
  processed <- 0L
  all_gene_ids <- character()
  all_mad <- numeric()

  repeat {
    chunk_df <- read_table_chunk(input_file, chunk_size, skip_rows = processed, col_names = names(header_df))
    if (nrow(chunk_df) == 0) break
    chunk_mat <- coerce_expression_chunk(chunk_df)
    all_gene_ids <- c(all_gene_ids, rownames(chunk_mat))
    all_mad <- c(all_mad, compute_mad_values(chunk_mat))
    processed <- processed + nrow(chunk_df)
    log_info(sprintf("MAD first pass processed %s rows", processed))
    if (nrow(chunk_df) < chunk_size) break
  }

  assert_unique_values(all_gene_ids, "Gene identifiers in expression matrix")
  list(gene_ids = all_gene_ids, mad_values = all_mad, header_names = names(header_df))
}

second_pass_subset_matrix <- function(input_file, chunk_size, header_names, kept_gene_ids) {
  processed <- 0L
  kept_chunks <- list()

  repeat {
    chunk_df <- read_table_chunk(input_file, chunk_size, skip_rows = processed, col_names = header_names)
    if (nrow(chunk_df) == 0) break
    chunk_mat <- coerce_expression_chunk(chunk_df)
    keep_here <- rownames(chunk_mat) %in% kept_gene_ids
    if (any(keep_here)) {
      kept_chunks[[length(kept_chunks) + 1]] <- chunk_mat[keep_here, , drop = FALSE]
    }
    processed <- processed + nrow(chunk_df)
    log_info(sprintf("Subset second pass processed %s rows", processed))
    if (nrow(chunk_df) < chunk_size) break
  }

  if (length(kept_chunks) == 0) {
    skill_stop("EMPTY_DATA", "No genes remained after chunked MAD filtering")
  }
  filtered_mat <- do.call(rbind, kept_chunks)
  filtered_mat[match(kept_gene_ids, rownames(filtered_mat)), , drop = FALSE]
}

load_expression_matrix <- function(input_file, mad_quantile, min_mad, max_genes, chunk_size) {
  input_file <- assert_file_exists(input_file, "Input file")
  if (chunk_size <= 0) {
    return(load_expression_matrix_full(input_file, mad_quantile, min_mad, max_genes))
  }

  log_info(sprintf("Chunked loading enabled with chunk_size=%s", chunk_size))
  first_pass <- first_pass_chunk_mad(input_file, chunk_size)
  mad_info <- select_genes_by_mad(first_pass$gene_ids, first_pass$mad_values, mad_quantile, min_mad, max_genes)
  second_pass_subset_matrix(input_file, chunk_size, first_pass$header_names, mad_info$kept_gene_ids)
}
