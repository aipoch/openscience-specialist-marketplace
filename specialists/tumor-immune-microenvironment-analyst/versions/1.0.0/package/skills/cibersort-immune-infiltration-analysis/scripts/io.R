detect_delimiter <- function(path) {
  if (grepl("\\.tsv$|\\.txt$", path, ignore.case = TRUE)) {
    return("\t")
  }
  ","
}

detect_log_scaled_matrix <- function(mat) {
  vals <- as.numeric(mat)
  vals <- vals[is.finite(vals)]
  if (length(vals) == 0) {
    return(list(should_unlog = FALSE, reason = "no finite values"))
  }
  q <- stats::quantile(vals, probs = c(0, 0.5, 0.75, 0.95, 0.99, 1), na.rm = TRUE, names = FALSE)
  non_negative <- q[1] >= 0
  compact_upper_tail <- q[5] <= 20 && q[6] <= 50
  low_center <- q[2] <= 8 && q[3] <= 10 && q[4] <= 15
  should_unlog <- isTRUE(non_negative && compact_upper_tail && low_center)
  reason <- sprintf(
    "min=%.3f median=%.3f q75=%.3f q95=%.3f q99=%.3f max=%.3f",
    q[1], q[2], q[3], q[4], q[5], q[6]
  )
  list(should_unlog = should_unlog, reason = reason)
}

read_table_any <- function(path) {
  utils::read.table(
    path,
    sep = detect_delimiter(path),
    header = TRUE,
    check.names = FALSE,
    stringsAsFactors = FALSE,
    quote = "\"",
    comment.char = "",
    fill = TRUE
  )
}

collapse_expression_by_gene <- function(df) {
  split_rows <- split(df[, -1, drop = FALSE], df[[1]])
  merged <- lapply(split_rows, function(x) {
    apply(as.matrix(x), 2, max, na.rm = TRUE)
  })
  out <- as.data.frame(do.call(rbind, merged), check.names = FALSE, stringsAsFactors = FALSE)
  out$gene <- rownames(out)
  out[, c("gene", setdiff(colnames(out), "gene")), drop = FALSE]
}

read_expression_matrix <- function(path, gene_id_case, min_mean_expression, auto_unlog = TRUE, verbose = TRUE) {
  if (!file.exists(path)) {
    skill_stop("SKILL_FILE_NOT_FOUND", sprintf("Expression matrix was not found: %s", path))
  }
  log_info(sprintf("Reading expression matrix: %s", path), verbose)
  df <- read_table_any(path)
  if (ncol(df) < 3) {
    skill_stop("SKILL_MISSING_COLUMNS", "Expression matrix must contain one gene column and at least two sample columns.")
  }
  colnames(df)[1] <- "gene"
  df$gene <- normalize_gene_id(df$gene, gene_id_case)
  df <- df[!is.na(df$gene) & trim_ws(df$gene) != "", , drop = FALSE]
  df[, -1] <- lapply(df[, -1, drop = FALSE], function(x) suppressWarnings(as.numeric(x)))
  if (anyNA(as.matrix(df[, -1, drop = FALSE]))) {
    skill_stop("SKILL_INVALID_PARAMETER", "Expression matrix contains non-numeric values after the gene column.")
  }
  df <- collapse_expression_by_gene(df)
  rownames(df) <- df$gene
  mat <- as.matrix(df[, -1, drop = FALSE])
  if (isTRUE(auto_unlog)) {
    log_scale_check <- detect_log_scaled_matrix(mat)
    if (isTRUE(log_scale_check$should_unlog)) {
      log_info(sprintf("Expression values passed the conservative log-scale heuristic (%s); applying 2^x back-transformation.", log_scale_check$reason), verbose)
      mat <- 2^mat
    } else {
      log_info(sprintf("Skipped automatic 2^x back-transformation because the matrix did not pass the conservative log-scale heuristic (%s).", log_scale_check$reason), verbose)
    }
  }
  mean_keep <- rowMeans(mat, na.rm = TRUE) >= min_mean_expression
  mat <- mat[mean_keep, , drop = FALSE]
  if (nrow(mat) == 0 || ncol(mat) == 0) {
    skill_stop("SKILL_EMPTY_DATA", "No expression rows remained after filtering.")
  }
  log_info(sprintf("Expression matrix kept %d genes and %d samples.", nrow(mat), ncol(mat)), verbose)
  mat
}

read_group_info <- function(path, case_group, control_group, sample_col = NULL, group_col = NULL, verbose = TRUE) {
  if (!file.exists(path)) {
    skill_stop("SKILL_FILE_NOT_FOUND", sprintf("Group file was not found: %s", path))
  }
  log_info(sprintf("Reading group file: %s", path), verbose)
  df <- read_table_any(path)
  sample_name <- resolve_name_or_index(df, sample_col, c("sample", "sample_name", "sample_id", "id"), "sample")
  group_name <- resolve_name_or_index(df, group_col, c("group", "condition", "class", "cluster"), "group")
  out <- data.frame(
    sample = trim_ws(df[[sample_name]]),
    group = trim_ws(df[[group_name]]),
    stringsAsFactors = FALSE
  )
  out <- out[!is.na(out$sample) & out$sample != "" & !is.na(out$group) & out$group != "", , drop = FALSE]
  if (nrow(out) == 0) {
    skill_stop("SKILL_EMPTY_DATA", "Group file contained no usable sample annotations.")
  }
  if (anyDuplicated(out$sample) > 0) {
    skill_stop("SKILL_INVALID_PARAMETER", "Group file contains duplicated sample identifiers.")
  }
  if (!(case_group %in% out$group) || !(control_group %in% out$group)) {
    skill_stop("SKILL_INVALID_PARAMETER", "Both case and control groups must exist in the group file.")
  }
  out
}

read_signature_matrix <- function(signature_file = NULL, gene_id_case = "upper", verbose = TRUE) {
  if (is.null(signature_file) || !nzchar(signature_file) || !file.exists(signature_file)) {
    skill_stop("SKILL_FILE_NOT_FOUND", "A signature matrix file is required for this workflow.")
  }
  log_info(sprintf("Reading signature matrix: %s", signature_file), verbose)
  sig <- read_table_any(signature_file)
  if (ncol(sig) < 2) {
    skill_stop("SKILL_MISSING_COLUMNS", "Signature matrix must contain one gene column and at least one immune-cell signature column.")
  }
  colnames(sig)[1] <- "gene"
  sig$gene <- normalize_gene_id(sig$gene, gene_id_case)
  sig <- sig[!is.na(sig$gene) & sig$gene != "", , drop = FALSE]
  value_cols <- setdiff(colnames(sig), "gene")
  sig[, value_cols] <- lapply(sig[, value_cols, drop = FALSE], function(x) suppressWarnings(as.numeric(x)))
  sig_values <- as.matrix(sig[, value_cols, drop = FALSE])
  invalid_n <- sum(!is.finite(sig_values))
  if (invalid_n > 0) {
    skill_stop(
      "SKILL_INVALID_PARAMETER",
      sprintf("Signature matrix contains %d non-numeric, NA, NaN, or Inf values in immune-cell columns.", invalid_n)
    )
  }
  sig <- collapse_expression_by_gene(sig[, c("gene", value_cols), drop = FALSE])
  rownames(sig) <- sig$gene
  if (any(!is.finite(as.matrix(sig[, -1, drop = FALSE])))) {
    skill_stop("SKILL_INVALID_PARAMETER", "Signature matrix contains non-finite values after duplicate-gene consolidation.")
  }
  as.matrix(sig[order(rownames(sig)), -1, drop = FALSE])
}
