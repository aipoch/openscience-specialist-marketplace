compute_mad_values <- function(expr_mat) {
  mad_values <- apply(expr_mat, 1, stats::mad, na.rm = TRUE)
  mad_values[!is.finite(mad_values)] <- NA_real_
  mad_values
}

select_genes_by_mad <- function(gene_ids, mad_values, mad_quantile, min_mad, max_genes) {
  finite_mad <- mad_values[is.finite(mad_values)]
  if (length(finite_mad) == 0) {
    skill_stop("EMPTY_DATA", "No genes have finite MAD values after handling missing data")
  }
  cutoff <- max(stats::quantile(finite_mad, probs = mad_quantile, names = FALSE, na.rm = TRUE), min_mad)
  keep_idx <- which(is.finite(mad_values) & mad_values >= cutoff)
  if (length(keep_idx) == 0) {
    skill_stop("EMPTY_DATA", "No genes passed the MAD filter")
  }
  kept_ids <- gene_ids[keep_idx]
  if (max_genes > 0 && length(kept_ids) > max_genes) {
    rank_idx <- order(mad_values[keep_idx], decreasing = TRUE)[seq_len(max_genes)]
    kept_ids <- kept_ids[rank_idx]
  }
  list(cutoff = cutoff, kept_gene_ids = kept_ids)
}

prepare_wgcna_matrix <- function(filtered_expr) {
  data_expr <- as.data.frame(t(filtered_expr), stringsAsFactors = FALSE)
  gsg <- WGCNA::goodSamplesGenes(data_expr, verbose = 3)
  if (!gsg$allOK) {
    if (sum(!gsg$goodGenes) > 0) {
      log_warn(sprintf("Removing genes flagged by goodSamplesGenes: %s", paste(names(data_expr)[!gsg$goodGenes], collapse = ", ")))
    }
    if (sum(!gsg$goodSamples) > 0) {
      log_warn(sprintf("Removing samples flagged by goodSamplesGenes: %s", paste(rownames(data_expr)[!gsg$goodSamples], collapse = ", ")))
    }
    data_expr <- data_expr[gsg$goodSamples, gsg$goodGenes, drop = FALSE]
  }
  if (nrow(data_expr) < 4 || ncol(data_expr) < 20) {
    skill_stop("EMPTY_DATA", "Filtered matrix is too small for WGCNA after quality control")
  }
  data_expr
}

choose_fallback_power <- function(n_samples, network_type) {
  if (n_samples < 20) return(if (network_type == "unsigned") 9 else 18)
  if (n_samples < 30) return(if (network_type == "unsigned") 8 else 16)
  if (n_samples < 40) return(if (network_type == "unsigned") 7 else 14)
  if (network_type == "unsigned") 6 else 12
}

select_soft_threshold <- function(data_expr, network_type, soft_r2_cutoff) {
  powers <- c(1:10, seq(from = 12, to = 30, by = 2))
  sft <- WGCNA::pickSoftThreshold(data_expr, powerVector = powers, networkType = network_type, RsquaredCut = soft_r2_cutoff, verbose = 5)
  power <- sft$powerEstimate
  if (is.na(power)) {
    power <- choose_fallback_power(nrow(data_expr), network_type)
    log_warn(sprintf("No power reached R^2 >= %s; using fallback power %s", soft_r2_cutoff, power))
  }
  list(sft = sft, powers = powers, power = power)
}

run_blockwise_modules <- function(data_expr, power, network_type, cor_type, min_module_size, merge_cut_height, tom_base) {
  max_p_outliers <- if (cor_type == "pearson") 1 else 0.05
  local({
    cor <- WGCNA::cor
    bicor <- WGCNA::bicor
    WGCNA::blockwiseModules(
      data_expr,
      power = power,
      maxBlockSize = ncol(data_expr),
      networkType = network_type,
      TOMType = network_type,
      minModuleSize = min_module_size,
      reassignThreshold = 0,
      mergeCutHeight = merge_cut_height,
      numericLabels = TRUE,
      pamRespectsDendro = FALSE,
      saveTOMs = TRUE,
      loadTOMs = FALSE,
      saveTOMFileBase = tom_base,
      corType = cor_type,
      maxPOutliers = max_p_outliers,
      verbose = 3
    )
  })
}

build_trait_matrix <- function(dat_traits) {
  trait_data <- stats::model.matrix(~0 + dat_traits$group)
  colnames(trait_data) <- levels(dat_traits$group)
  rownames(trait_data) <- rownames(dat_traits)
  trait_data
}
