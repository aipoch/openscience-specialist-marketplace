normalize_nonnegative_weights <- function(weights) {
  weights <- as.numeric(weights)
  weights[!is.finite(weights) | weights < 0] <- 0
  total <- sum(weights)
  if (!is.finite(total) || total <= 0) {
    return(rep(1 / length(weights), length(weights)))
  }
  weights / total
}

run_core_alg <- function(X, y, svm_cores = 1) {
  nu_values <- c(0.25, 0.5, 0.75)
  fit_once <- function(nus) {
    e1071::svm(X, y, type = "nu-regression", kernel = "linear", nu = nus, scale = FALSE)
  }
  if (!identical(Sys.info()[["sysname"]], "Windows") && svm_cores > 1) {
    out <- parallel::mclapply(nu_values, fit_once, mc.cores = min(svm_cores, length(nu_values)))
  } else {
    out <- lapply(nu_values, fit_once)
  }
  rmses <- rep(NA_real_, length(out))
  corrv <- rep(NA_real_, length(out))
  for (i in seq_along(out)) {
    weights <- as.numeric(t(out[[i]]$coefs) %*% out[[i]]$SV)
    w <- normalize_nonnegative_weights(weights)
    k <- rowSums(sweep(X, MARGIN = 2, w, "*"))
    rmses[i] <- sqrt(mean((k - y)^2))
    corrv[i] <- suppressWarnings(stats::cor(k, y))
  }
  best_idx <- which.min(rmses)
  q <- as.numeric(t(out[[best_idx]]$coefs) %*% out[[best_idx]]$SV)
  list(
    w = normalize_nonnegative_weights(q),
    mix_rmse = rmses[[best_idx]],
    mix_r = corrv[[best_idx]]
  )
}

run_null_distribution <- function(X, Y, perm = 1000, svm_cores = 1, verbose = TRUE) {
  values <- as.numeric(Y)
  gene_n <- nrow(X)
  dist <- numeric(perm)
  for (i in seq_len(perm)) {
    if (isTRUE(verbose) && (i == 1 || i == perm || i %% max(1, floor(perm / 10)) == 0)) {
      log_info(sprintf("Permutation %d/%d", i, perm), verbose)
    }
    yr <- sample(values, gene_n, replace = FALSE)
    yr <- scale_vector(yr)
    dist[[i]] <- run_core_alg(X, yr, svm_cores)$mix_r
  }
  sort(dist)
}

estimate_empirical_p <- function(mix_r, nulldist) {
  if (length(nulldist) == 0 || !is.finite(mix_r)) {
    return(NA_real_)
  }
  1 - (which.min(abs(nulldist - mix_r)) / length(nulldist))
}

run_cibersort_like <- function(X, Y, nulldist, svm_cores = 1, verbose = TRUE) {
  output <- matrix(NA_real_, nrow = ncol(Y), ncol = ncol(X) + 3)
  colnames(output) <- c(colnames(X), "P-value", "Correlation", "RMSE")
  rownames(output) <- colnames(Y)
  for (i in seq_len(ncol(Y))) {
    if (isTRUE(verbose) && (i == 1 || i == ncol(Y) || i %% max(1, floor(ncol(Y) / 5)) == 0)) {
      log_info(sprintf("Deconvolving sample %d/%d", i, ncol(Y)), verbose)
    }
    y <- scale_vector(Y[, i])
    result <- run_core_alg(X, y, svm_cores)
    output[i, colnames(X)] <- result$w
    output[i, "P-value"] <- estimate_empirical_p(result$mix_r, nulldist)
    output[i, "Correlation"] <- result$mix_r
    output[i, "RMSE"] <- result$mix_rmse
  }
  as.data.frame(output, check.names = FALSE, stringsAsFactors = FALSE)
}
