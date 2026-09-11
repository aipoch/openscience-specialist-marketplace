safe_sd <- function(x) {
  stats::sd(x)
}

safe_summary_sd <- function(x) {
  if (length(x) <= 1) {
    return(0)
  }
  stats::sd(x)
}

normalize_zscore_vector <- function(x, center = TRUE, scale_values = TRUE) {
  mu <- if (isTRUE(center)) mean(x) else 0
  centered <- x - mu
  if (!isTRUE(scale_values)) {
    return(centered)
  }
  sigma <- safe_sd(centered)
  if (is.na(sigma) || sigma == 0) {
    return(rep(0, length(x)))
  }
  centered / sigma
}

normalize_minmax_vector <- function(x) {
  x_min <- min(x)
  x_max <- max(x)
  if (isTRUE(all.equal(x_min, x_max))) {
    return(rep(0, length(x)))
  }
  (x - x_min) / (x_max - x_min)
}

apply_by_margin <- function(mat, margin = "column", fn) {
  if (margin == "column") {
    res <- apply(mat, 2, fn)
    if (is.null(dim(res))) {
      res <- matrix(res, ncol = ncol(mat))
    }
    rownames(res) <- rownames(mat)
    colnames(res) <- colnames(mat)
    return(res)
  }

  if (margin == "row") {
    res <- t(apply(mat, 1, fn))
    if (is.null(dim(res))) {
      res <- matrix(res, nrow = nrow(mat))
    }
    rownames(res) <- rownames(mat)
    colnames(res) <- colnames(mat)
    return(res)
  }

  skill_stop("SKILL_INVALID_PARAMETER", "Unsupported --margin.")
}

normalize_matrix <- function(mat, method = "log2", margin = "column", pseudo_count = 1, center = TRUE, scale_values = TRUE) {
  if (method == "log2") {
    if (any((mat + pseudo_count) <= 0)) {
      skill_stop("SKILL_INVALID_PARAMETER", "log2 requires all values plus --pseudo_count to be > 0.")
    }
    return(log2(mat + pseudo_count))
  }

  if (method == "zscore") {
    return(apply_by_margin(mat, margin, function(x) normalize_zscore_vector(x, center = center, scale_values = scale_values)))
  }

  if (method == "minmax") {
    return(apply_by_margin(mat, margin, normalize_minmax_vector))
  }

  skill_stop("SKILL_INVALID_PARAMETER", "Unsupported --method.")
}

summarize_axis <- function(input_mat, normalized_mat, axis = "row") {
  if (axis == "row") {
    ids <- rownames(input_mat)
    input_values <- split(input_mat, row(input_mat))
    output_values <- split(normalized_mat, row(normalized_mat))
    label <- "feature"
  } else {
    ids <- colnames(input_mat)
    input_values <- split(input_mat, col(input_mat))
    output_values <- split(normalized_mat, col(normalized_mat))
    label <- "sample"
  }

  stats_frame <- data.frame(
    id = ids,
    input_mean = vapply(input_values, mean, numeric(1)),
    input_sd = vapply(input_values, safe_summary_sd, numeric(1)),
    input_min = vapply(input_values, min, numeric(1)),
    input_max = vapply(input_values, max, numeric(1)),
    normalized_mean = vapply(output_values, mean, numeric(1)),
    normalized_sd = vapply(output_values, safe_summary_sd, numeric(1)),
    normalized_min = vapply(output_values, min, numeric(1)),
    normalized_max = vapply(output_values, max, numeric(1)),
    check.names = FALSE
  )
  colnames(stats_frame)[1] <- label
  stats_frame
}
