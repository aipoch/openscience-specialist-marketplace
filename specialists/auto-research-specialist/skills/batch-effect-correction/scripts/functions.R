should_log_transform <- function(expr_mat, mode) {
  if (mode == "yes")
    return(TRUE)
  if (mode == "no")
    return(FALSE)

  finite_values <- expr_mat[is.finite(expr_mat)]
  if (length(finite_values) == 0)
    stop("SKILL_INVALID_DATA: Expression matrix contains no finite values", call. = FALSE)

  max_value <- max(finite_values)
  q99 <- as.numeric(stats::quantile(finite_values, probs = 0.99, na.rm = TRUE, names = FALSE))
  max_value > 50 || q99 > 16
}

prepare_expression_matrix <- function(expr_mat, apply_log_transform) {
  if (!apply_log_transform)
    return(expr_mat)
  if (any(expr_mat < 0))
    stop("SKILL_INVALID_DATA: Negative values cannot be log-transformed", call. = FALSE)
  log2(expr_mat + 1)
}

build_combat_design <- function(metadata) {
  stats::model.matrix(~group, data = metadata)
}

run_combat_correction <- function(expr_mat, metadata) {
  corrected <- NULL
  utils::capture.output(
    corrected <- suppressMessages(sva::ComBat(
      dat = expr_mat,
      batch = metadata$batch,
      mod = build_combat_design(metadata),
      par.prior = TRUE,
      prior.plots = FALSE
    ))
    ,
    file = NULL
  )
  limma::normalizeBetweenArrays(corrected)
}
