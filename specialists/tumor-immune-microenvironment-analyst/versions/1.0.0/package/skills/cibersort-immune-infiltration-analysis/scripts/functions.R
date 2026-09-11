align_inputs <- function(exp_mat, group_df, case_group, control_group, verbose = TRUE) {
  keep_group <- group_df[group_df$group %in% c(case_group, control_group), , drop = FALSE]
  common_samples <- intersect(colnames(exp_mat), keep_group$sample)
  if (length(common_samples) < 2) {
    skill_stop("SKILL_SAMPLE_MISMATCH", "Fewer than two overlapping samples were found between the matrix and group file.")
  }
  keep_group <- keep_group[match(common_samples, keep_group$sample), , drop = FALSE]
  case_n <- sum(keep_group$group == case_group)
  control_n <- sum(keep_group$group == control_group)
  if (case_n < 1 || control_n < 1) {
    skill_stop("SKILL_SAMPLE_MISMATCH", "Both case and control groups must retain at least one matched sample.")
  }
  aligned <- exp_mat[, keep_group$sample, drop = FALSE]
  log_info(sprintf("Aligned %d samples: %d case and %d control.", ncol(aligned), case_n, control_n), verbose)
  list(exp_mat = aligned, group_map = setNames(keep_group$group, keep_group$sample))
}

scale_vector <- function(x) {
  sd_x <- stats::sd(x)
  if (!is.finite(sd_x) || sd_x == 0) {
    skill_stop("SKILL_EMPTY_DATA", "Encountered a zero-variance vector during CIBERSORT preprocessing.")
  }
  (x - mean(x)) / sd_x
}

prepare_cibersort_inputs <- function(exp_mat, signature_mat, qn = TRUE, verbose = TRUE) {
  X <- signature_mat[order(rownames(signature_mat)), , drop = FALSE]
  Y <- exp_mat[order(rownames(exp_mat)), , drop = FALSE]
  if (isTRUE(qn)) {
    log_info("Applying quantile normalization to the mixture matrix.", verbose)
    tmpc <- colnames(Y)
    tmpr <- rownames(Y)
    Y <- preprocessCore::normalize.quantiles(Y)
    colnames(Y) <- tmpc
    rownames(Y) <- tmpr
  }
  overlap_genes <- intersect(rownames(X), rownames(Y))
  if (length(overlap_genes) == 0) {
    skill_stop("SKILL_EMPTY_DATA", "No overlapping genes were found between the expression matrix and the signature matrix.")
  }
  if (length(overlap_genes) < 10) {
    log_warn(sprintf("Only %d genes overlapped with the signature matrix.", length(overlap_genes)), verbose)
  }
  X <- X[overlap_genes, , drop = FALSE]
  Y <- Y[overlap_genes, , drop = FALSE]
  X <- (X - mean(X)) / stats::sd(as.vector(X))
  if (!all(is.finite(X))) {
    skill_stop("SKILL_EMPTY_DATA", "The standardized signature matrix contains non-finite values.")
  }
  list(X = X, Y = Y, overlap_genes = overlap_genes, cell_types = colnames(X))
}

split_cibersort_output <- function(result_df, cell_types) {
  metric_cols <- c("P-value", "Correlation", "RMSE")
  fractions <- result_df[, cell_types, drop = FALSE]
  fractions[] <- lapply(fractions, as.numeric)
  quality <- result_df[, metric_cols, drop = FALSE]
  list(fractions = fractions, quality = quality)
}

make_fraction_long <- function(fractions, group_map) {
  expanded <- lapply(colnames(fractions), function(cell_type) {
    data.frame(
      sample = rownames(fractions),
      group = unname(group_map[rownames(fractions)]),
      cell_type = cell_type,
      fraction = as.numeric(fractions[[cell_type]]),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, expanded)
}

calc_group_compare <- function(long_df, case_group, control_group) {
  cell_types <- unique(long_df$cell_type)
  rows <- lapply(cell_types, function(cell_type) {
    sub_df <- long_df[long_df$cell_type == cell_type, , drop = FALSE]
    case_vals <- sub_df$fraction[sub_df$group == case_group]
    control_vals <- sub_df$fraction[sub_df$group == control_group]
    p_val <- tryCatch(stats::wilcox.test(case_vals, control_vals, exact = FALSE)$p.value, error = function(e) NA_real_)
    data.frame(
      cell_type = cell_type,
      case_n = length(case_vals),
      control_n = length(control_vals),
      case_mean = mean(case_vals, na.rm = TRUE),
      control_mean = mean(control_vals, na.rm = TRUE),
      delta_mean = mean(case_vals, na.rm = TRUE) - mean(control_vals, na.rm = TRUE),
      p_value = p_val,
      test_method = "wilcox",
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  out$p_adj <- stats::p.adjust(out$p_value, method = "BH")
  out[, c("cell_type", "case_n", "control_n", "case_mean", "control_mean", "delta_mean", "p_value", "p_adj", "test_method")]
}

calc_correlation_tables <- function(fractions) {
  cell_types <- colnames(fractions)
  cor_mat <- matrix(NA_real_, nrow = length(cell_types), ncol = length(cell_types), dimnames = list(cell_types, cell_types))
  p_mat <- cor_mat
  for (i in seq_along(cell_types)) {
    for (j in seq_along(cell_types)) {
      stat <- safe_cor_test(fractions[[cell_types[i]]], fractions[[cell_types[j]]], method = "spearman")
      cor_mat[i, j] <- stat[["cor"]]
      p_mat[i, j] <- stat[["p"]]
    }
  }
  list(cor_mat = cor_mat, p_mat = p_mat)
}
