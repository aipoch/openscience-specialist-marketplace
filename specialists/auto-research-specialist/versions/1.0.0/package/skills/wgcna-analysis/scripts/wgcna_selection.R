compute_wgcna_statistics <- function(data_expr, trait_data, net, cor_type) {
  robust_y <- cor_type != "pearson"
  module_colors <- WGCNA::labels2colors(net$colors)
  names(module_colors) <- colnames(data_expr)

  mes_colored <- net$MEs
  colnames(mes_colored) <- paste0("ME", WGCNA::labels2colors(as.numeric(sub("^ME", "", colnames(mes_colored)))))
  mes_colored <- WGCNA::orderMEs(mes_colored)
  n_samples <- nrow(data_expr)

  if (cor_type == "pearson") {
    mod_trait_cor <- stats::cor(mes_colored, trait_data, use = "p")
    mod_trait_p <- WGCNA::corPvalueStudent(mod_trait_cor, n_samples)
    gene_module_membership <- as.data.frame(stats::cor(data_expr, mes_colored, use = "p"))
    gene_trait_cor <- as.data.frame(stats::cor(data_expr, trait_data, use = "p"))
    mm_pvalue <- as.data.frame(WGCNA::corPvalueStudent(as.matrix(gene_module_membership), n_samples))
    gene_trait_p <- as.data.frame(WGCNA::corPvalueStudent(as.matrix(gene_trait_cor), n_samples))
  } else {
    mod_trait <- WGCNA::bicorAndPvalue(mes_colored, trait_data, robustY = robust_y)
    gene_mm <- WGCNA::bicorAndPvalue(data_expr, mes_colored, robustY = robust_y)
    gene_trait <- WGCNA::bicorAndPvalue(data_expr, trait_data, robustY = robust_y)
    mod_trait_cor <- mod_trait$bicor
    mod_trait_p <- mod_trait$p
    gene_module_membership <- as.data.frame(gene_mm$bicor)
    gene_trait_cor <- as.data.frame(gene_trait$bicor)
    mm_pvalue <- as.data.frame(gene_mm$p)
    gene_trait_p <- as.data.frame(gene_trait$p)
  }

  list(
    module_colors = module_colors,
    mes_colored = mes_colored,
    mod_trait_cor = mod_trait_cor,
    mod_trait_p = mod_trait_p,
    gene_module_membership = gene_module_membership,
    mm_pvalue = mm_pvalue,
    gene_trait_cor = gene_trait_cor,
    gene_trait_p = gene_trait_p
  )
}

resolve_trait_of_interest <- function(trait_data, trait_of_interest) {
  if (!is.null(trait_of_interest) && !identical(trait_of_interest, "")) {
    if (!(trait_of_interest %in% colnames(trait_data))) {
      skill_stop("INVALID_PARAMETER", sprintf("trait_of_interest must be one of: %s", paste(colnames(trait_data), collapse = ", ")))
    }
    return(trait_of_interest)
  }
  selected_trait <- colnames(trait_data)[1]
  log_warn(sprintf("trait_of_interest was not provided; using the first trait column '%s'", selected_trait))
  selected_trait
}

parse_requested_modules <- function(module_of_interest) {
  if (is.null(module_of_interest) || identical(module_of_interest, "") || identical(module_of_interest, "auto")) {
    return(NULL)
  }
  unique(trimws(strsplit(module_of_interest, ",", fixed = TRUE)[[1]]))
}

rank_modules_for_trait <- function(stats_out, selected_trait) {
  available_modules <- sub("^ME", "", rownames(stats_out$mod_trait_cor))
  cor_values <- as.numeric(stats_out$mod_trait_cor[, selected_trait])
  p_values <- as.numeric(stats_out$mod_trait_p[, selected_trait])

  rank_df <- data.frame(
    module = available_modules,
    module_trait_cor = cor_values,
    module_trait_abs_cor = abs(cor_values),
    module_trait_p = p_values,
    stringsAsFactors = FALSE
  )
  rank_df <- rank_df[rank_df$module != "grey", , drop = FALSE]
  rank_df <- rank_df[order(rank_df$module_trait_abs_cor, decreasing = TRUE), , drop = FALSE]
  rank_df$rank <- seq_len(nrow(rank_df))
  rank_df
}

resolve_modules_of_interest <- function(stats_out, selected_trait, module_of_interest, top_modules) {
  rank_df <- rank_modules_for_trait(stats_out, selected_trait)
  requested <- parse_requested_modules(module_of_interest)

  if (!is.null(requested)) {
    missing_modules <- setdiff(requested, rank_df$module)
    if (length(missing_modules) > 0) {
      skill_stop("INVALID_PARAMETER", sprintf("module_of_interest must be one of: %s", paste(rank_df$module, collapse = ", ")))
    }
    return(requested)
  }

  n_keep <- min(top_modules, nrow(rank_df))
  rank_df$module[seq_len(n_keep)]
}

build_module_selection_summary <- function(stats_out, selected_trait, selected_modules) {
  rank_df <- rank_modules_for_trait(stats_out, selected_trait)
  out <- rank_df[rank_df$module %in% selected_modules, c("rank", "module", "module_trait_cor", "module_trait_abs_cor", "module_trait_p"), drop = FALSE]
  out[order(out$rank), , drop = FALSE]
}

validate_export_targets <- function(stats_out, selected_module, selected_trait) {
  module_colname <- paste0("ME", selected_module)
  if (!(module_colname %in% colnames(stats_out$gene_module_membership))) {
    skill_stop("INVALID_PARAMETER", sprintf("Module membership column '%s' is not available for export", module_colname))
  }
  if (!(selected_trait %in% colnames(stats_out$gene_trait_cor))) {
    skill_stop("INVALID_PARAMETER", sprintf("Selected trait '%s' is not available in gene-trait correlations", selected_trait))
  }
  invisible(module_colname)
}
