optimize_min_folds <- function(group_counts) {
  max(2L, min(as.integer(group_counts)))
}

create_stratified_folds <- function(labels, k, seed) {
  set.seed(seed)
  labels <- as.character(labels)
  k <- min(k, optimize_min_folds(table(labels)))
  fold_ids <- integer(length(labels))
  for (label in unique(labels)) {
    idx <- which(labels == label)
    idx <- sample(idx, length(idx))
    fold_ids[idx] <- rep(seq_len(k), length.out = length(idx))
  }
  lapply(seq_len(k), function(fold_id) which(fold_ids == fold_id))
}

scale_train_test <- function(train_x, test_x = NULL) {
  scaled_train <- scale(train_x)
  center <- attr(scaled_train, "scaled:center")
  scale_values <- attr(scaled_train, "scaled:scale")
  scale_values[scale_values == 0] <- 1
  attr(scaled_train, "scaled:scale") <- scale_values
  scaled_test <- if (is.null(test_x)) NULL else scale(test_x, center = center, scale = scale_values)
  list(train = scaled_train, test = scaled_test)
}

fit_linear_svm_weights <- function(train_x, train_y) {
  scaled <- scale_train_test(train_x)
  model <- e1071::svm(x = scaled$train, y = train_y, kernel = "linear", cost = 10, scale = FALSE, type = "C-classification")
  drop(t(model$coefs) %*% model$SV)
}

compute_feature_scores <- function(train_x, train_y, inner_k, seed) {
  if (ncol(train_x) == 1) return(1)
  if (inner_k > 1 && optimize_min_folds(table(train_y)) >= 2) {
    folds <- create_stratified_folds(train_y, inner_k, seed)
    weights <- lapply(seq_along(folds), function(index) {
      valid_idx <- folds[[index]]
      fit_linear_svm_weights(train_x[-valid_idx, , drop = FALSE], train_y[-valid_idx])
    })
    weight_matrix <- do.call(rbind, weights)
    normalized <- t(apply(weight_matrix, 1, function(row) row / sqrt(sum(row^2))))
    vbar <- colMeans(normalized^2)
    vsd <- apply(normalized^2, 2, stats::sd)
    vbar / pmax(vsd, .Machine$double.eps)
  } else {
    weights <- fit_linear_svm_weights(train_x, train_y)
    weights^2
  }
}

rank_features_once <- function(train_x, train_y, inner_k, halve_above, seed) {
  surviving <- seq_len(ncol(train_x))
  ranked <- integer(length(surviving))
  insert_at <- length(surviving)
  while (length(surviving) > 0) {
    scores <- compute_feature_scores(train_x[, surviving, drop = FALSE], train_y, inner_k, seed + length(surviving))
    ranking <- if (length(surviving) == 1) 1 else order(scores)
    ncut <- if (length(surviving) > halve_above) max(1L, round(length(surviving) / 2)) else 1L
    remove_ids <- surviving[ranking[seq_len(ncut)]]
    ranked[insert_at:(insert_at - ncut + 1)] <- remove_ids
    surviving <- surviving[-ranking[seq_len(ncut)]]
    insert_at <- insert_at - ncut
  }
  ranked
}

fit_linear_svm_prediction <- function(train_x, train_y, valid_x) {
  scaled <- scale_train_test(train_x, valid_x)
  model <- e1071::svm(x = scaled$train, y = train_y, kernel = "linear", cost = 10, scale = FALSE, type = "C-classification")
  stats::predict(model, scaled$test)
}
