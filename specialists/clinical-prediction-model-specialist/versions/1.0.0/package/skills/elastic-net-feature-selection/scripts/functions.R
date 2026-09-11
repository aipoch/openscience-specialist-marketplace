align_inputs <- function(expr, groups, case_group, control_group) {
  unsupported_groups <- setdiff(unique(groups$group), c(case_group, control_group))
  if (length(unsupported_groups) > 0L) {
    stop(
      sprintf(
        paste0(
          "SKILL_INVALID_DATA: group file contains unsupported labels outside the requested binary comparison: %s. ",
          "This skill only supports binary case-vs-control analysis."
        ),
        paste(sort(unsupported_groups), collapse = ", ")
      ),
      call. = FALSE
    )
  }
  groups <- groups[groups$group %in% c(case_group, control_group), , drop = FALSE]
  if (!all(c(case_group, control_group) %in% groups$group)) {
    stop("SKILL_INVALID_DATA: both case and control groups must be present", call. = FALSE)
  }
  matched_samples <- intersect(groups$sample_id, colnames(expr))
  if (length(matched_samples) < 4L) {
    stop("SKILL_SAMPLE_MISMATCH: too few overlapping samples between matrix and group file", call. = FALSE)
  }
  groups <- groups[match(matched_samples, groups$sample_id), , drop = FALSE]
  expr <- expr[, matched_samples, drop = FALSE]
  if (any(table(groups$group) < 2L)) {
    stop("SKILL_INVALID_DATA: each group must contain at least 2 matched samples", call. = FALSE)
  }
  list(expr = expr, groups = groups)
}

filter_expression_features <- function(expr, feature_list = NULL) {
  if (is.null(feature_list)) {
    return(expr)
  }
  kept <- intersect(feature_list, rownames(expr))
  if (length(kept) < 2L) {
    stop("SKILL_INVALID_DATA: fewer than 2 requested features were found in the expression matrix", call. = FALSE)
  }
  if (length(kept) < length(unique(feature_list))) {
    log_warn(sprintf("Only %d of %d requested features were found in the expression matrix.", length(kept), length(unique(feature_list))))
  }
  expr[kept, , drop = FALSE]
}

build_design_matrix <- function(expr) {
  x <- t(expr)
  storage.mode(x) <- "double"
  if (ncol(x) < 2L) {
    stop("SKILL_INVALID_DATA: fewer than 2 usable features remain after filtering", call. = FALSE)
  }
  zero_var <- vapply(seq_len(ncol(x)), function(idx) stats::var(x[, idx]) == 0, logical(1))
  if (all(zero_var)) {
    stop("SKILL_INVALID_DATA: all features have zero variance", call. = FALSE)
  }
  if (any(zero_var)) {
    log_warn(sprintf("Dropping %d zero-variance feature(s) before model fitting.", sum(zero_var)))
    x <- x[, !zero_var, drop = FALSE]
  }
  x
}

encode_response <- function(groups, case_group, control_group) {
  as.integer(factor(groups$group, levels = c(control_group, case_group))) - 1L
}

build_cv_setup <- function(y, nfolds) {
  class_sizes <- table(y)
  actual_nfolds <- min(as.integer(nfolds), as.integer(min(class_sizes)))
  if (actual_nfolds < 2L) {
    stop("SKILL_INVALID_DATA: too few samples per class for cross-validation", call. = FALSE)
  }
  if (actual_nfolds != nfolds) {
    log_warn(sprintf("Reducing nfolds from %d to %d based on class sizes.", nfolds, actual_nfolds))
  }
  if (min(class_sizes) < 8L) {
    log_warn("Minority class has fewer than 8 samples; feature selection may be unstable.")
  }
  list(actual_nfolds = actual_nfolds, foldid = sample(rep(seq_len(actual_nfolds), length.out = length(y))))
}

suppress_glmnet_warnings <- function(expr) {
  withCallingHandlers(expr, warning = function(w) {
    warning_text <- conditionMessage(w)
    known_warning <- grepl("one multinomial or binomial class has fewer than 8  observations; dangerous ground", warning_text, fixed = TRUE) ||
      grepl("Option grouped=FALSE enforced in cv.glmnet, since < 3 observations per fold", warning_text, fixed = TRUE) ||
      grepl("from glmnet C++ code", warning_text, fixed = TRUE)
    if (known_warning) {
      log_warn(warning_text)
      invokeRestart("muffleWarning")
    }
  })
}
