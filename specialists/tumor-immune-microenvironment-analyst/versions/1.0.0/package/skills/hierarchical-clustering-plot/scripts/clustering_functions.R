build_distance_matrix <- function(expr_mat, distance_method) {
  allowed_methods <- c("euclidean", "maximum", "manhattan", "canberra", "binary", "minkowski")
  if (!(distance_method %in% allowed_methods))
    stop("SKILL_INVALID_PARAMETER: Unsupported distance_method: ", distance_method, call. = FALSE)
  if (!is.matrix(expr_mat) || !is.numeric(expr_mat))
    stop("SKILL_INVALID_TYPE: expr_mat must be a numeric matrix", call. = FALSE)

  stats::dist(t(expr_mat), method = distance_method)
}

build_clustering <- function(distance_obj, linkage_method) {
  allowed_methods <- c("complete", "single", "average", "mcquitty", "median", "centroid", "ward.D", "ward.D2")
  if (!(linkage_method %in% allowed_methods))
    stop("SKILL_INVALID_PARAMETER: Unsupported linkage_method: ", linkage_method, call. = FALSE)

  stats::hclust(distance_obj, method = linkage_method)
}

build_clustering_order <- function(hc, group_df) {
  ordered_samples <- hc$labels[hc$order]
  ordered_groups <- group_df[match(ordered_samples, group_df$sample_id), , drop = FALSE]
  data.frame(
    plot_order = seq_along(ordered_samples),
    sample_id = ordered_groups$sample_id,
    label = ordered_groups$label,
    stringsAsFactors = FALSE
  )
}
