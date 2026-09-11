draw_error_lines <- function(errors, line_color, best_point_color, label_cex, label_pos) {
  valid_idx <- which(!is.na(errors))
  lines(valid_idx, errors[valid_idx], col = line_color)
  best_idx <- which.min(replace(errors, is.na(errors), Inf))
  points(best_idx, errors[best_idx], col = best_point_color)
  text(best_idx, errors[best_idx], sprintf("%d - %.3f", best_idx, errors[best_idx]), pos = label_pos, col = best_point_color, cex = label_cex)
}

save_svm_error_plot <- function(error_rates, baseline_error, options, save_path) {
  grDevices::pdf(save_path, width = options$svm_error_width, height = options$svm_error_height)
  on.exit(grDevices::dev.off(), add = TRUE)
  plot(error_rates, type = "n", ylim = range(c(error_rates, baseline_error), na.rm = TRUE), xlab = options$svm_error_xlab, ylab = options$svm_error_ylab)
  draw_error_lines(error_rates, options$svm_error_main_line_color, options$svm_error_best_point_color, options$svm_error_label_cex, options$svm_error_label_pos)
  graphics::abline(h = baseline_error, lty = options$svm_error_noinfo_lty, col = options$svm_error_second_line_color)
}

save_svm_ranking_plot <- function(ranking_df, options, save_path) {
  if (nrow(ranking_df) == 0) fail("SKILL_EMPTY_DATA", "Ranking table is empty.")
  top_n <- min(options$svm_rank_top_n, nrow(ranking_df))
  plot_df <- ranking_df[seq_len(top_n), , drop = FALSE]
  plot_df$Feature <- factor(plot_df$Feature, levels = rev(plot_df$Feature))
  plot_obj <- ggplot2::ggplot(plot_df, ggplot2::aes(x = AvgRank, y = Feature)) +
    ggplot2::geom_col(fill = options$svm_rank_color) +
    ggplot2::labs(x = "Average Rank (smaller = more important)", y = NULL, title = options$svm_rank_title) +
    ggplot2::theme_bw(base_size = 11) +
    ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5), panel.grid.minor = ggplot2::element_blank())
  ggplot2::ggsave(filename = save_path, plot = plot_obj, width = options$svm_rank_width, height = options$svm_rank_height)
}
