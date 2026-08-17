pdf_device <- function(output_file, width, height) {
  grDevices::pdf(output_file, width = width, height = height)
  invisible(TRUE)
}

scale_plot_size <- function(n, base, per_item, min_value, max_value) {
  value <- base + n * per_item
  min(max(value, min_value), max_value)
}

format_number <- function(x, digits = 2) {
  if (!is.finite(x)) return("NA")
  format(signif(x, digits = digits), trim = TRUE)
}

plot_sample_clustering <- function(data_expr, dat_traits, output_file) {
  n_samples <- nrow(data_expr)
  width <- scale_plot_size(n_samples, base = 8, per_item = 0.12, min_value = 10, max_value = 24)
  height <- scale_plot_size(n_samples, base = 4, per_item = 0.05, min_value = 6, max_value = 14)

  sample_tree <- stats::hclust(stats::dist(data_expr), method = "average")
  sample_colors <- WGCNA::numbers2colors(as.numeric(dat_traits$group), signed = FALSE)
  pdf_device(output_file, width, height)
  on.exit(grDevices::dev.off(), add = TRUE)
  graphics::par(mar = c(1, 4, 3, 1), cex = 0.8)
  WGCNA::plotDendroAndColors(
    sample_tree,
    sample_colors,
    groupLabels = "Group",
    cex.dendroLabels = 0.8,
    marAll = c(1, 4, 3, 1),
    cex.rowText = 0.01,
    main = "Sample dendrogram and trait heatmap"
  )
}

plot_soft_threshold <- function(sft, powers, soft_r2_cutoff, output_file) {
  pdf_device(output_file, 8, 5.5)
  on.exit(grDevices::dev.off(), add = TRUE)
  graphics::par(mfrow = c(1, 2))
  cex1 <- 0.9

  graphics::plot(
    sft$fitIndices[, 1],
    -sign(sft$fitIndices[, 3]) * sft$fitIndices[, 2],
    xlab = "Soft Threshold (power)",
    ylab = "Scale Free Topology Model Fit, signed R^2",
    type = "n",
    main = "Scale independence"
  )
  graphics::text(
    sft$fitIndices[, 1],
    -sign(sft$fitIndices[, 3]) * sft$fitIndices[, 2],
    labels = powers,
    cex = cex1,
    col = "red"
  )
  graphics::abline(h = soft_r2_cutoff, col = "red")

  graphics::plot(
    sft$fitIndices[, 1],
    sft$fitIndices[, 5],
    xlab = "Soft Threshold (power)",
    ylab = "Mean Connectivity",
    type = "n",
    main = "Mean connectivity"
  )
  graphics::text(
    sft$fitIndices[, 1],
    sft$fitIndices[, 5],
    labels = powers,
    cex = cex1,
    col = "red"
  )
}

plot_gene_clusters <- function(net, stats_out, output_file) {
  pdf_device(output_file, 10, 6)
  on.exit(grDevices::dev.off(), add = TRUE)
  WGCNA::plotDendroAndColors(
    net$dendrograms[[1]],
    stats_out$module_colors[net$blockGenes[[1]]],
    "Module colors",
    dendroLabels = FALSE,
    hang = 0.03,
    addGuide = TRUE,
    guideHang = 0.05
  )
}

plot_eigengene_network <- function(stats_out, output_file) {
  n_modules <- ncol(stats_out$mes_colored)
  size <- scale_plot_size(n_modules, base = 4.5, per_item = 0.12, min_value = 6, max_value = 20)

  pdf_device(output_file, size, size)
  on.exit(grDevices::dev.off(), add = TRUE)
  WGCNA::plotEigengeneNetworks(
    stats_out$mes_colored,
    "Eigengene adjacency heatmap",
    marDendro = c(1, 3, 2, 4),
    marHeatmap = c(3, 3, 1, 2),
    plotDendrograms = TRUE,
    xLabelsAngle = 90
  )
}

load_tom_matrix <- function(tom_file) {
  tom_env <- new.env(parent = emptyenv())
  load(tom_file, envir = tom_env)
  if (!exists("TOM", envir = tom_env, inherits = FALSE)) {
    skill_stop("FILE_NOT_FOUND", sprintf("TOM object not found in saved TOM file: %s", tom_file))
  }
  as.matrix(get("TOM", envir = tom_env))
}

plot_tom_heatmap <- function(net, stats_out, sample_size, seed, output_file) {
  diss_tom <- 1 - load_tom_matrix(net$TOMFiles[1])
  n_select <- min(sample_size, ncol(diss_tom))
  set.seed(seed)
  selected <- sample(seq_len(ncol(diss_tom)), size = n_select)
  selected_tom <- diss_tom[selected, selected]
  selected_tree <- stats::hclust(stats::as.dist(selected_tom), method = "average")
  selected_colors <- stats_out$module_colors[selected]
  plot_diss <- selected_tom^7
  diag(plot_diss) <- NA_real_

  pdf_device(output_file, 8, 8)
  on.exit(grDevices::dev.off(), add = TRUE)
  WGCNA::TOMplot(1 - plot_diss, selected_tree, selected_colors, main = "Network heatmap plot, selected genes")
}

plot_module_trait_heatmap <- function(stats_out, trait_data, output_file) {
  n_modules <- nrow(stats_out$mod_trait_cor)
  n_traits <- ncol(trait_data)
  max_label_chars <- max(nchar(rownames(stats_out$mod_trait_cor)))
  width <- scale_plot_size(n_traits, base = 5.5, per_item = 1.2, min_value = 8, max_value = 18) + min(max_label_chars * 0.08, 2.5)
  height <- scale_plot_size(n_modules, base = 4, per_item = 0.18, min_value = 8, max_value = 22)
  cex_text <- if (n_modules > 60) 0.45 else if (n_modules > 40) 0.6 else 0.8
  left_margin <- max(8, min(16, 5 + max_label_chars * 0.45))

  text_matrix <- matrix(
    paste(signif(stats_out$mod_trait_cor, 2), "\n(", signif(stats_out$mod_trait_p, 1), ")", sep = ""),
    nrow = nrow(stats_out$mod_trait_cor)
  )

  pdf_device(output_file, width, height)
  on.exit(grDevices::dev.off(), add = TRUE)
  graphics::par(mar = c(3, left_margin, 4, 3), xpd = NA)
  WGCNA::labeledHeatmap(
    Matrix = stats_out$mod_trait_cor,
    xLabels = colnames(trait_data),
    xLabelsAngle = 0,
    yLabels = rownames(stats_out$mod_trait_cor),
    ySymbols = rownames(stats_out$mod_trait_cor),
    colorLabels = FALSE,
    colors = WGCNA::blueWhiteRed(50),
    textMatrix = text_matrix,
    setStdMargins = FALSE,
    cex.lab = 0.8,
    cex.text = cex_text,
    textAdj = c(0.5, 0.5),
    zlim = c(-1, 1),
    main = "Module-trait relationships"
  )
}

plot_module_membership_scatter <- function(stats_out, selected_module, selected_trait, output_file) {
  module_names <- sub("^ME", "", colnames(stats_out$mes_colored))
  module_column <- match(selected_module, module_names)
  trait_column <- match(selected_trait, colnames(stats_out$gene_trait_cor))
  module_genes <- stats_out$module_colors == selected_module

  if (is.na(module_column) || is.na(trait_column)) {
    skill_stop("INVALID_PARAMETER", "Selected module or trait cannot be found for membership scatter plot")
  }
  if (!any(module_genes)) {
    skill_stop("EMPTY_DATA", sprintf("No genes found in selected module '%s'", selected_module))
  }

  mm_values <- abs(stats_out$gene_module_membership[module_genes, module_column])
  gs_values <- abs(stats_out$gene_trait_cor[module_genes, trait_column])
  cc_idx <- stats::complete.cases(mm_values, gs_values)

  cor_val <- NA_real_
  p_val <- NA_real_
  if (sum(cc_idx) >= 3) {
    cor_val <- stats::cor(mm_values[cc_idx], gs_values[cc_idx], use = "p")
    p_val <- WGCNA::corPvalueStudent(cor_val, sum(cc_idx))
  }

  main_text <- sprintf(
    "Module membership vs. gene significance
cor=%s, p=%s",
    format_number(cor_val, 2),
    format_number(p_val, 3)
  )

  pdf_device(output_file, 7, 7)
  on.exit(grDevices::dev.off(), add = TRUE)
  graphics::par(mar = c(5, 5, 5.5, 2))
  graphics::plot(
    mm_values,
    gs_values,
    xlab = sprintf("Module Membership in %s module", selected_module),
    ylab = sprintf("Gene significance for %s", selected_trait),
    main = "",
    pch = 1,
    col = selected_module,
    cex.lab = 1.2,
    cex.axis = 1.1
  )
  graphics::title(main = main_text, cex.main = 1.2)
}

build_module_export <- function(stats_out, selected_module, selected_trait) {
  module_colname <- validate_export_targets(stats_out, selected_module, selected_trait)
  module_genes <- stats_out$module_colors == selected_module

  data.frame(
    gene_id = rownames(stats_out$gene_trait_cor)[module_genes],
    module = selected_module,
    gene_trait_cor = stats_out$gene_trait_cor[module_genes, selected_trait],
    gene_trait_p = stats_out$gene_trait_p[module_genes, selected_trait],
    module_membership = stats_out$gene_module_membership[module_genes, module_colname],
    module_membership_p = stats_out$mm_pvalue[module_genes, module_colname],
    row.names = NULL
  )
}
