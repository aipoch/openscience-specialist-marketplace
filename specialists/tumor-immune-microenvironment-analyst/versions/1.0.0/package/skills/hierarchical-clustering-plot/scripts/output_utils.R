write_output_csv <- function(data_object, output_file, description, row_names = FALSE) {
  tryCatch(
    utils::write.csv(data_object, output_file, row.names = row_names, quote = FALSE),
    error = function(e) {
      stop("SKILL_WRITE_ERROR: Failed to write ", description, ": ", conditionMessage(e), call. = FALSE)
    }
  )
}

save_distance_matrix <- function(distance_obj, output_file) {
  write_output_csv(as.matrix(distance_obj), output_file, "distance matrix", row_names = TRUE)
}

save_matched_samples <- function(group_df, output_file) {
  write_output_csv(group_df, output_file, "matched samples", row_names = FALSE)
}

save_clustering_order <- function(order_df, output_file) {
  write_output_csv(order_df, output_file, "clustering order", row_names = FALSE)
}

plot_clustering_pdf <- function(hc, labels, output_file, label_cex, distance_method, linkage_method) {
  tryCatch({
    grDevices::pdf(output_file, width = 11, height = 7)
    on.exit(grDevices::dev.off(), add = TRUE)
    plot(
      hc,
      labels = labels,
      hang = -1,
      cex = label_cex,
      main = "Hierarchical Clustering of Samples",
      xlab = "",
      sub = paste("distance =", distance_method, "| linkage =", linkage_method)
    )
  }, error = function(e) {
    stop("SKILL_PLOT_ERROR: ", conditionMessage(e), call. = FALSE)
  })
}
