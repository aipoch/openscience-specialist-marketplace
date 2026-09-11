diff_limma <- function(df, map) {
  check_pkg("limma")
  check_pkg("dplyr")
  validate_non_empty(as.data.frame(df), "Expression matrix")

  design <- model.matrix(~ 0 + map[[2]])
  rownames(design) <- map[[1]]
  colnames(design) <- levels(map[[2]])

  treat_name <- levels(map[[2]])[2]
  con_name <- levels(map[[2]])[1]
  fit <- limma::lmFit(df, design)
  contrast <- limma::makeContrasts(contrasts = paste0(treat_name, "-", con_name), levels = design)
  fit2 <- limma::eBayes(limma::contrasts.fit(fit, contrast))

  dif <- limma::topTable(fit2, coef = 1, n = Inf) %>%
    as.data.frame() %>%
    dplyr::rename(Pvalue = "P.Value", Padj = "adj.P.Val") %>%
    stats::na.omit() %>%
    dplyr::arrange(Pvalue)

  if (nrow(dif) == 0) {
    skill_stop("SKILL_EMPTY_DATA", "No rows returned by limma")
  }

  dif$gene_id <- rownames(dif)
  dif[, c(ncol(dif), 1:(ncol(dif) - 1))]
}
