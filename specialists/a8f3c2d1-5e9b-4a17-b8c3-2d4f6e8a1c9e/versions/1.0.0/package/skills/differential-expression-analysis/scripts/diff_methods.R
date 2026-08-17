diff_limma <- function(df, map) {
  check_pkg("limma")
  check_pkg("dplyr")
  treat_name <- levels(map[[2]])[2]
  con_name <- levels(map[[2]])[1]

  design <- model.matrix(~ 0 + map[[2]])
  rownames(design) <- map[[1]]
  colnames(design) <- levels(map[[2]])

  fit <- lmFit(df, design)
  cont_matrix <- makeContrasts(contrasts = paste0(treat_name, "-", con_name), levels = design)
  fit2 <- contrasts.fit(fit, cont_matrix)
  fit2 <- eBayes(fit2)

  dif <- topTable(fit2, coef = 1, n = Inf) %>%
    as.data.frame() %>%
    dplyr::rename(Pvalue = "P.Value", Padj = "adj.P.Val") %>%
    na.omit() %>%
    dplyr::arrange(Pvalue)

  dif$gene_id <- rownames(dif)
  dif[, c(ncol(dif), 1:(ncol(dif)-1))]
}

diff_deseq2 <- function(df, map) {
  check_pkg("DESeq2")
  check_pkg("dplyr")

  col_data <- data.frame(row.names = colnames(df), group_list = map[[2]])
  dds <- DESeqDataSetFromMatrix(countData = round(df), colData = col_data, design = ~group_list)
  dds2 <- DESeq(dds)
  res <- results(dds2)

  dif <- res %>%
    as.data.frame() %>%
    dplyr::rename(logFC = "log2FoldChange", Pvalue = "pvalue", Padj = "padj") %>%
    na.omit() %>%
    dplyr::arrange(Pvalue)

  dif$gene_id <- rownames(dif)
  dif[, c(ncol(dif), 1:(ncol(dif)-1))]
}

diff_edger <- function(df, map, norm = "TMM") {
  check_pkg("edgeR")
  check_pkg("statmod")
  check_pkg("dplyr")

  dgelist <- DGEList(counts = df, group = map[[2]])
  keep <- rowSums(cpm(dgelist) > 1) >= 2
  dgelist <- dgelist[keep, , keep.lib.sizes = FALSE]
  dgelist_norm <- calcNormFactors(dgelist, method = norm)

  design <- model.matrix(~ map[[2]])
  dge <- estimateDisp(dgelist_norm, design, robust = TRUE)
  fit <- glmFit(dge, design, robust = TRUE)
  lrt <- topTags(glmLRT(fit), n = nrow(dgelist$counts))

  dif <- lrt %>%
    as.data.frame() %>%
    dplyr::rename(Pvalue = "PValue", Padj = "FDR") %>%
    na.omit() %>%
    dplyr::arrange(Pvalue)

  dif$gene_id <- rownames(dif)
  dif[, c(ncol(dif), 1:(ncol(dif)-1))]
}

diff_stat <- function(df, map, stat = "t") {
  check_pkg("dplyr")
  treat_name <- levels(map[[2]])[2]
  con_name <- levels(map[[2]])[1]
  treat <- map[map[[2]] == treat_name, ][[1]]
  control <- map[map[[2]] == con_name, ][[1]]

  res <- data.frame(logFC = apply(df, 1, function(row) {
    log2(mean(row[treat]) / mean(row[control]))
  }))

  if (stat == "t") {
    df_test <- apply(df, 1, function(row) {
      tryCatch({
        result <- t.test(row ~ map[[2]])
        c(result$p.value, result$statistic)
      }, error = function(e) c(1, 0))
    })
  } else {
    df_test <- apply(df, 1, function(row) {
      tryCatch({
        result <- wilcox.test(row ~ map[[2]])
        c(result$p.value, result$statistic)
      }, error = function(e) c(1, 0))
    })
  }

  df_test <- t(df_test)
  colnames(df_test) <- c("Pvalue", "stat")
  res <- cbind(res, df_test)
  res$Padj <- p.adjust(res$Pvalue, method = "BH")
  res <- res %>% na.omit() %>% dplyr::arrange(Pvalue)

  res$gene_id <- rownames(res)
  res[, c(ncol(res), 1:(ncol(res)-1))]
}
