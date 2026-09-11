default_cluster_palette <- function() {
  c("#A6CEE3", "#1F78B4", "#B2DF8A", "#33A02C", "#FB9A99",
    "#E31A1C", "#FDBF6F", "#FF7F00", "#CAB2D6", "#6A3D9A")
}

build_cluster_colors <- function(consensus_class, palette = default_cluster_palette()) {
  cluster_ids <- sort(unique(as.integer(consensus_class)))
  if (length(cluster_ids) > length(palette)) {
    stop_skill("SKILL_INVALID_DATA", "Too many clusters for the built-in plot palette.")
  }
  color_map <- stats::setNames(palette[seq_along(cluster_ids)], cluster_ids)
  list(side = unname(color_map[as.character(consensus_class)]),
       legend = unname(color_map))
}

lower_triangle_values <- function(matrix_data) {
  matrix_data[lower.tri(matrix_data)]
}

generate_consensus_matrix_plot <- function(result_object, best_k, plot_path) {
  matrix_data <- result_object[[best_k]]$consensusMatrix
  consensus_tree <- result_object[[best_k]]$consensusTree
  cluster_assignments <- result_object[[best_k]]$consensusClass
  color_list <- build_cluster_colors(cluster_assignments)

  grDevices::pdf(plot_path, width = 6, height = 5)
  on.exit(grDevices::dev.off(), add = TRUE)
  stats::heatmap(
    rbind(matrix_data[consensus_tree$order, ], 0),
    Colv = stats::as.dendrogram(consensus_tree),
    Rowv = NA,
    symm = FALSE,
    scale = "none",
    col = c("#FFFFFF", "#E5E5FF", "#CCCCFF", "#B2B2FF", "#9999FF",
            "#7F7FFF", "#6666FF", "#4C4CFF", "#3333FF", "#1919FF", "#0000FF"),
    na.rm = TRUE,
    labRow = FALSE,
    labCol = FALSE,
    margins = c(5, 5),
    main = paste0("consensus matrix k=", best_k),
    ColSideColors = color_list$side
  )
  graphics::legend("topright", legend = sort(unique(cluster_assignments)), fill = color_list$legend,
                   title = "Cluster", bty = "n")
}

generate_cdf_plot <- function(result_object, plot_path) {
  curve_colors <- c("#FF0000", "#FFAA00", "#AAFF00", "#00FF00", "#00FFAA",
                    "#00AAFF", "#0000FF", "#AA00FF", "#FF00AA", "#FF0099")
  ml_list <- lapply(2:length(result_object), function(i) result_object[[i]]$ml)
  max_k <- length(ml_list) + 1

  grDevices::pdf(plot_path, width = 6, height = 5)
  on.exit(grDevices::dev.off(), add = TRUE)
  graphics::plot(c(0), xlim = c(0, 1), ylim = c(0, 1), col = "white",
                 xlab = "consensus index", ylab = "CDF", main = "consensus CDF",
                 type = "n", las = 2, frame.plot = TRUE)

  for (i in seq_along(ml_list)) {
    v <- lower_triangle_values(ml_list[[i]])
    h <- graphics::hist(v, plot = FALSE, breaks = seq(0, 1, by = 0.01))
    h$counts <- cumsum(h$counts) / sum(h$counts)
    graphics::lines(h$mids, h$counts, col = curve_colors[i], lwd = 2, type = "l")
  }

  graphics::legend("bottomright", legend = as.character(2:max_k),
                   fill = curve_colors[seq_len(length(ml_list))], bty = "n")
}
