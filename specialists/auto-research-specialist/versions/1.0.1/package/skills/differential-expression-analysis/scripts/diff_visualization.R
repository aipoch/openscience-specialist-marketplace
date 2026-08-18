generate_volcano <- function(diff_file, output_dir, p_threshold = 0.05, logfc_threshold = 0.1) {
  check_pkg("ggplot2")
  check_pkg("ggrepel")

  if (!file.exists(diff_file))
    stop(paste("SKILL_FILE_NOT_FOUND:", diff_file))

  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  dif <- data.table::fread(diff_file, data.table = FALSE)
  gene_id_col <- ifelse("gene_id" %in% colnames(dif), "gene_id", colnames(dif)[1])

  dif_up <- dif[dif$logFC > logfc_threshold & dif$Padj < p_threshold, ]
  dif_down <- dif[dif$logFC < -logfc_threshold & dif$Padj < p_threshold, ]

  dif <- dif %>%
    dplyr::mutate(group = case_when(
      .data[[gene_id_col]] %in% dif_up[[gene_id_col]] ~ "Up",
      .data[[gene_id_col]] %in% dif_down[[gene_id_col]] ~ "Down",
      TRUE ~ "Not"
    ))

  dif$logP <- -log10(dif$Padj)
  dif$change <- factor(dif$group, levels = c("Down", "Not", "Up"))
  dif <- dif[order(abs(dif$logFC), decreasing = TRUE), ]
  x_lim <- max(abs(dif$logFC)) * 1.1

  p <- ggplot(dif, aes(.data[["logFC"]], .data[["logP"]], color = .data[["change"]])) +
    geom_point(alpha = 0.6) + theme_bw() +
    labs(x = "LogFC", y = "-Log10(Padj)", color = "Significance") +
    geom_hline(yintercept = -log10(p_threshold), linetype = 2) +
    geom_vline(xintercept = c(-logfc_threshold, logfc_threshold), linetype = 2) +
    scale_x_continuous(limits = c(-x_lim, x_lim)) +
    scale_color_manual(values = c("Down" = "#4DBBD5", "Not" = "grey", "Up" = "#E64B35")) +
    ggtitle("Volcano Plot") +
    theme(plot.title = element_text(hjust = 0.5, size = 16),
          axis.text = element_text(size = 12), panel.grid = element_blank())

  ggsave(file.path(output_dir, "volcano_plot.pdf"), p, width = 8, height = 5)
  write.csv(dif, file.path(output_dir, "volcano_data.csv"), row.names = FALSE)
  p
}

generate_heatmap <- function(input_file, group_file, rdegs_file, output_dir, top_n = 10) {
  check_pkg("pheatmap")

  for (f in c(input_file, group_file, rdegs_file))
    if (!file.exists(f)) stop(paste("SKILL_FILE_NOT_FOUND:", f))

  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  mat <- data.table::fread(input_file, data.table = FALSE)
  rownames(mat) <- mat[[1]]; mat <- mat[, -1]

  map <- data.table::fread(group_file, data.table = FALSE)
  dat_rdegs <- data.table::fread(rdegs_file, data.table = FALSE)

  if (nrow(dat_rdegs) > top_n * 2) {
    rdegs_sorted <- dat_rdegs[order(dat_rdegs$logFC), ]
    top_genes <- c(head(rdegs_sorted$gene_id, top_n), tail(rdegs_sorted$gene_id, top_n))
  } else {
    top_genes <- dat_rdegs$gene_id
  }

  dat_heatmap <- mat[top_genes, map[[1]]]
  map[[2]] <- factor(map[[2]], levels = unique(map[[2]]))
  annotation_col <- data.frame(Group = map[[2]], row.names = map[[1]])
  color <- c("#E64B35", "#4DBBD5"); names(color) <- unique(map[[2]])
  annotation_colors <- list(Group = color)

  p_heatmap <- pheatmap::pheatmap(
    dat_heatmap, scale = "row", annotation_col = annotation_col,
    annotation_colors = annotation_colors,
    color = colorRampPalette(c("#03a6ff", "white", "#f9320c"))(50),
    breaks = seq(-3, 3, length = 50),
    cluster_cols = FALSE, cluster_rows = TRUE,
    labels_col = "", border_color = NA,
    main = "Differential Gene Expression Heatmap"
  )

  ggsave(file.path(output_dir, "heatmap.pdf"), p_heatmap, width = 8, height = 8)
  write.csv(dat_heatmap, file.path(output_dir, "heatmap_data.csv"))
  p_heatmap
}
