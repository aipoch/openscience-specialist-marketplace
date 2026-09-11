#!/usr/bin/env Rscript

load_gene_sets <- function(species, category, subcategory) {
  msig <- msigdbr::msigdbr(
    species = species,
    category = category,
    subcategory = subcategory
  )
  gene_sets <- split(msig$gene_symbol, msig$gs_name)
  if (length(gene_sets) == 0) {
    stop_skill(
      "SKILL_EMPTY_DATA",
      sprintf(
        "No gene sets found for species=%s, category=%s, subcategory=%s.",
        species, category, subcategory
      )
    )
  }
  gene_sets
}

run_gsva_scores <- function(exp_mat, gene_sets, opt) {
  gsva_args <- list(
    expr = exp_mat,
    gset.idx.list = gene_sets,
    method = opt$method,
    kcdf = opt$kcdf,
    min.sz = opt$min_sz,
    max.sz = opt$max_sz,
    parallel.sz = opt$parallel_sz,
    mx.diff = opt$mx_diff,
    tau = opt$tau
  )
  do.call(GSVA::gsva, gsva_args)
}

run_limma_diff <- function(gsva_scores, groups, case_group, control_group) {
  group_factor <- factor(groups, levels = c(control_group, case_group))
  design <- stats::model.matrix(~ 0 + group_factor)
  colnames(design) <- levels(group_factor)
  fit <- limma::lmFit(gsva_scores, design)
  contrast <- limma::makeContrasts(
    contrasts = paste0(case_group, "-", control_group),
    levels = design
  )
  fit2 <- limma::eBayes(limma::contrasts.fit(fit, contrast))
  diff_df <- limma::topTable(fit2, coef = 1, n = Inf, sort.by = "P")
  diff_df$geneset <- rownames(diff_df)
  diff_df
}

select_top_pathways <- function(diff_df, top_n, fdr_threshold) {
  sig_df <- diff_df[diff_df$adj.P.Val <= fdr_threshold, , drop = FALSE]
  if (nrow(sig_df) > 0) {
    sig_df <- sig_df[order(sig_df$adj.P.Val, -abs(sig_df$logFC)), , drop = FALSE]
    return(sig_df$geneset[seq_len(min(top_n, nrow(sig_df)))])
  }
  log_warn(sprintf("No pathways passed FDR <= %s. Falling back to top pathways by |t|.", fdr_threshold))
  diff_df <- diff_df[order(-abs(diff_df$t)), , drop = FALSE]
  diff_df$geneset[seq_len(min(top_n, nrow(diff_df)))]
}

save_analysis_outputs <- function(output_dir, gsva_scores, top_scores, diff_df, result_object) {
  write.csv(
    diff_df,
    file.path(output_dir, "table", "GSVA_diff.csv"),
    row.names = FALSE,
    quote = FALSE
  )

  gsva_scores_df <- data.frame(geneset = rownames(gsva_scores), gsva_scores, check.names = FALSE)
  write.csv(
    gsva_scores_df,
    file.path(output_dir, "table", "GSVA_enrichment_results.csv"),
    row.names = FALSE,
    quote = FALSE
  )

  top_scores_df <- data.frame(geneset = rownames(top_scores), top_scores, check.names = FALSE)
  write.csv(
    top_scores_df,
    file.path(output_dir, "table", "GSVA_enrichment_results_topN.csv"),
    row.names = FALSE,
    quote = FALSE
  )

  gsva_result <- result_object
  save(gsva_result, file = file.path(output_dir, "data", "GSVA_list.rda"))
}

subset_heatmap_matrix <- function(mat, diff_df, top_mode, top_up, top_down, sort_by) {
  if (is.null(top_up) && is.null(top_down)) {
    return(mat)
  }

  diff_df <- diff_df[!is.na(diff_df$adj.P.Val) & !is.na(diff_df$logFC), , drop = FALSE]
  diff_up <- diff_df[diff_df$logFC > 0, , drop = FALSE]
  diff_down <- diff_df[diff_df$logFC < 0, , drop = FALSE]

  if (sort_by == "FDR") {
    diff_up <- diff_up[order(diff_up$adj.P.Val, -diff_up$logFC), , drop = FALSE]
    diff_down <- diff_down[order(diff_down$adj.P.Val, diff_down$logFC), , drop = FALSE]
  } else if (sort_by == "absLFC") {
    diff_up <- diff_up[order(-abs(diff_up$logFC), diff_up$adj.P.Val), , drop = FALSE]
    diff_down <- diff_down[order(-abs(diff_down$logFC), diff_down$adj.P.Val), , drop = FALSE]
  } else {
    diff_up <- diff_up[order(-diff_up$logFC, diff_up$adj.P.Val), , drop = FALSE]
    diff_down <- diff_down[order(diff_down$logFC, diff_down$adj.P.Val), , drop = FALSE]
  }

  top_up <- top_up %||% 0L
  top_down <- top_down %||% 0L
  keep <- character()

  if (top_mode == "both") {
    keep <- unique(c(head(diff_up$geneset, top_up), head(diff_down$geneset, top_down)))
  } else if (top_mode == "up") {
    keep <- unique(head(diff_up$geneset, max(top_up, top_down)))
  } else if (top_mode == "down") {
    keep <- unique(head(diff_down$geneset, max(top_up, top_down)))
  } else {
    diff_all <- diff_df[order(diff_df$adj.P.Val, -abs(diff_df$logFC)), , drop = FALSE]
    keep <- unique(head(diff_all$geneset, max(top_up, top_down)))
  }

  keep <- intersect(keep, rownames(mat))
  if (length(keep) < 2) {
    log_warn("Heatmap subset returned fewer than 2 pathways. The full matrix will be used.")
    return(mat)
  }
  mat[keep, , drop = FALSE]
}
