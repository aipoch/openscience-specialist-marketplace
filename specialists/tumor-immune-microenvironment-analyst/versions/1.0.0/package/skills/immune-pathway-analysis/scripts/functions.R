#!/usr/bin/env Rscript

build_gene_sets <- function(geneset_df, exp_mat, min_sz = 2L, max_sz = 5000L) {
  geneset_df <- geneset_df[geneset_df$gene %in% rownames(exp_mat), , drop = FALSE]
  gene_sets <- split(geneset_df$gene, geneset_df$geneset)
  gene_sets <- lapply(gene_sets, unique)
  gene_sets <- gene_sets[vapply(gene_sets, function(x) length(x) >= min_sz && length(x) <= max_sz, logical(1))]
  if (length(gene_sets) == 0) stop_skill("SKILL_EMPTY_DATA", "No immune gene sets remained after matching to the expression matrix.")
  gene_sets
}

build_geneset_summary <- function(gene_sets) {
  data.frame(geneset = names(gene_sets), gene_count = unname(vapply(gene_sets, length, integer(1))), stringsAsFactors = FALSE)
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
  old_option <- getOption("matrixStats.useNames")
  options(matrixStats.useNames = FALSE)
  on.exit(options(matrixStats.useNames = old_option), add = TRUE)
  tryCatch(
    do.call(GSVA::gsva, gsva_args),
    error = function(e) {
      if (grepl("useNames", conditionMessage(e), fixed = TRUE)) {
        log_warn("Retrying GSVA with matrixStats.useNames=FALSE for compatibility.")
        options(matrixStats.useNames = FALSE)
        return(do.call(GSVA::gsva, gsva_args))
      }
      stop(e)
    }
  )
}

run_limma_diff <- function(gsva_scores, groups, case_group, control_group) {
  group_factor <- factor(groups, levels = c(control_group, case_group))
  design <- stats::model.matrix(~ 0 + group_factor)
  colnames(design) <- levels(group_factor)
  fit <- limma::lmFit(gsva_scores, design)
  contrast <- limma::makeContrasts(contrasts = paste0(case_group, "-", control_group), levels = design)
  diff_df <- limma::topTable(limma::eBayes(limma::contrasts.fit(fit, contrast)), coef = 1, n = Inf, sort.by = "P")
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

save_analysis_outputs <- function(output_dir, gsva_scores, top_scores, diff_df, geneset_summary, result_object) {
  write.csv(diff_df, file.path(output_dir, "table", "immune_pathway_diff.csv"), row.names = FALSE, quote = FALSE)
  write.csv(data.frame(geneset = rownames(gsva_scores), gsva_scores, check.names = FALSE), file.path(output_dir, "table", "immune_pathway_scores.csv"), row.names = FALSE, quote = FALSE)
  write.csv(data.frame(geneset = rownames(top_scores), top_scores, check.names = FALSE), file.path(output_dir, "table", "immune_pathway_scores_top.csv"), row.names = FALSE, quote = FALSE)
  write.csv(geneset_summary, file.path(output_dir, "table", "immune_gene_set_summary.csv"), row.names = FALSE, quote = FALSE)
  saveRDS(result_object, file.path(output_dir, "data", "immune_pathway_result.rds"))
}

parse_focus_genesets <- function(focus_genesets) {
  if (is.null(focus_genesets) || !nzchar(trimws(focus_genesets))) return(character())
  unique(trimws(strsplit(focus_genesets, ",", fixed = TRUE)[[1]]))
}

rank_diff_genesets <- function(diff_df, sort_by) {
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
  list(diff_df = diff_df, diff_up = diff_up, diff_down = diff_down)
}

select_heatmap_genesets <- function(mat, diff_df, top_mode, top_up, top_down, sort_by, focus_genesets = NULL) {
  ranked <- rank_diff_genesets(diff_df, sort_by)
  top_up <- top_up %||% 0L
  top_down <- top_down %||% 0L
  auto_keep <- switch(
    top_mode,
    both = unique(c(head(ranked$diff_up$geneset, top_up), head(ranked$diff_down$geneset, top_down))),
    up = unique(head(ranked$diff_up$geneset, max(top_up, top_down))),
    down = unique(head(ranked$diff_down$geneset, max(top_up, top_down))),
    total = unique(head(ranked$diff_df[order(ranked$diff_df$adj.P.Val, -abs(ranked$diff_df$logFC)), "geneset"], max(top_up, top_down)))
  )
  focus_keep <- intersect(parse_focus_genesets(focus_genesets), rownames(mat))
  keep <- unique(c(focus_keep, auto_keep))
  keep <- intersect(keep, rownames(mat))
  keep
}

subset_heatmap_matrix <- function(mat, diff_df, top_mode, top_up, top_down, sort_by, focus_genesets = NULL) {
  if (is.null(top_up) && is.null(top_down) && length(parse_focus_genesets(focus_genesets)) == 0) return(mat)
  keep <- select_heatmap_genesets(mat, diff_df, top_mode, top_up, top_down, sort_by, focus_genesets)
  if (length(keep) < 2) {
    log_warn("Heatmap subset returned fewer than 2 pathways. The full matrix will be used.")
    return(mat)
  }
  mat[keep, , drop = FALSE]
}
