align_inputs <- function(exp_mat, group_map, case_group, control_group, verbose) {
  common_samples <- intersect(colnames(exp_mat), names(group_map))
  if (length(common_samples) == 0) {
    skill_stop("SKILL_SAMPLE_MISMATCH", "No overlapping samples were found between the expression matrix and the group file.")
  }
  exp_mat <- exp_mat[, common_samples, drop = FALSE]
  group_map <- group_map[common_samples]
  if (sum(group_map == case_group) < 1 || sum(group_map == control_group) < 1) {
    skill_stop("SKILL_SAMPLE_MISMATCH", "No samples remain for one of the target groups after alignment.")
  }
  if (sum(group_map == case_group) < 3 || sum(group_map == control_group) < 3) {
    log_warn("One or both groups have fewer than 3 samples; statistical summaries may be unstable.", verbose)
  }
  list(exp_mat = exp_mat, group_map = group_map)
}

filter_gene_sets <- function(genesets, exp_mat, min_sz) {
  summary_df <- data.frame(
    cell_type = names(genesets),
    geneset_size = vapply(genesets, length, numeric(1)),
    overlap_n = vapply(genesets, function(x) sum(x %in% rownames(exp_mat)), numeric(1)),
    stringsAsFactors = FALSE
  )
  summary_df$kept <- summary_df$overlap_n >= min_sz
  kept <- genesets[summary_df$cell_type[summary_df$kept]]
  if (length(kept) == 0) {
    skill_stop("SKILL_EMPTY_DATA", "No gene sets passed overlap filtering.")
  }
  list(genesets = kept, geneset_summary = summary_df)
}

run_ssgsea_core <- function(exp_mat, genesets, method, kcdf, min_sz, max_sz, parallel_sz, mx_diff, tau) {
  actual_parallel <- min(parallel_sz, max(1, parallel::detectCores(logical = FALSE)))
  res <- tryCatch(
    GSVA::gsva(
      expr = exp_mat, gset.idx.list = genesets, method = method, kcdf = kcdf,
      min.sz = min_sz, max.sz = max_sz, parallel.sz = actual_parallel,
      mx.diff = mx_diff, tau = tau
    ),
    error = function(e) skill_stop("SKILL_INVALID_PARAMETER", paste("GSVA failed:", conditionMessage(e)))
  )
  attr(res, "actual_parallel_sz") <- actual_parallel
  res
}

make_scores_long <- function(scores, group_map, cell_anno, case_group, control_group) {
  out <- tibble::rownames_to_column(as.data.frame(scores), "cell_type")
  out <- tidyr::pivot_longer(out, -cell_type, names_to = "sample", values_to = "ssgsea_score")
  out$group <- factor(unname(group_map[out$sample]), levels = c(control_group, case_group))
  dplyr::left_join(out, cell_anno, by = "cell_type")
}

calc_group_compare <- function(scores_long, case_group, control_group) {
  split_df <- split(scores_long, scores_long$cell_type)
  res <- lapply(split_df, function(df) {
    x_case <- df$ssgsea_score[df$group == case_group]
    x_ctrl <- df$ssgsea_score[df$group == control_group]
    p_val <- tryCatch(stats::wilcox.test(x_case, x_ctrl)$p.value, error = function(e) NA_real_)
    data.frame(
      cell_type = df$cell_type[1], case_n = length(x_case), control_n = length(x_ctrl),
      case_mean = mean(x_case), control_mean = mean(x_ctrl),
      delta_mean = mean(x_case) - mean(x_ctrl), p_value = p_val,
      stringsAsFactors = FALSE
    )
  })
  dplyr::mutate(dplyr::bind_rows(res), p_adj = p.adjust(.data$p_value, method = "BH"), test_method = "wilcox")
}

calc_correlation_tables <- function(scores) {
  cell_types <- rownames(scores)
  cor_mat <- stats::cor(t(scores), method = "spearman")
  p_mat <- matrix(NA_real_, nrow = nrow(scores), ncol = nrow(scores), dimnames = list(cell_types, cell_types))
  for (i in seq_len(nrow(scores))) {
    for (j in i:nrow(scores)) {
      tmp <- if (i == j) c(cor = 1, p = 0) else safe_cor_test(as.numeric(scores[i, ]), as.numeric(scores[j, ]))
      p_mat[i, j] <- tmp["p"]
      p_mat[j, i] <- tmp["p"]
    }
  }
  list(cor_mat = cor_mat, p_mat = p_mat)
}
