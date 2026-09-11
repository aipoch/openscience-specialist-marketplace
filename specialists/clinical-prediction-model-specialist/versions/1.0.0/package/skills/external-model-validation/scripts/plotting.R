compute_km_break <- function(risk_data, km_breaks) {
  if (km_breaks > 0)
    return(km_breaks)
  max(1, ceiling(max(risk_data$futime, na.rm = TRUE) / 6))
}

generate_survival_plot <- function(risk_data, output_paths, col_high, col_low, km_breaks) {
  colors <- c(low = col_low, high = col_high)
  fit <- survival::survfit(survival::Surv(futime, fustat) ~ risk, data = risk_data)
  out_file <- file.path(output_paths$plot, "out_varifySurv.pdf")
  grDevices::pdf(out_file, width = 5.5, height = 6, onefile = FALSE)
  on.exit(grDevices::dev.off(), add = TRUE)
  km_plot <- survminer::ggsurvplot(
    fit,
    data = risk_data,
    conf.int = TRUE,
    pval = TRUE,
    palette = unname(colors[c("low", "high")]),
    xlab = "Time (Years)",
    break.time.by = compute_km_break(risk_data, km_breaks),
    risk.table = TRUE,
    legend.labs = c("Low risk", "High risk"),
    ggtheme = ggplot2::theme_bw()
  )
  print(km_plot)
  out_file
}

generate_risk_score_plot <- function(risk_data, output_paths, col_high, col_low) {
  out_file <- file.path(output_paths$plot, "out_varify.riskScore.pdf")
  grDevices::pdf(out_file, width = 6, height = 4.5)
  on.exit(grDevices::dev.off(), add = TRUE)
  point_colors <- ifelse(risk_data$risk == "high", col_high, col_low)
  plot(risk_data$riskScore, pch = 20, xlab = "Patients (increasing risk)", ylab = "Risk score", col = point_colors)
  abline(h = stats::median(risk_data$riskScore), v = sum(risk_data$risk == "low"), lty = 2)
  legend("topleft", legend = c("High risk", "Low risk"), col = c(col_high, col_low), pch = 20, bty = "n", cex = 1.1)
  out_file
}

generate_survival_status_plot <- function(risk_data, output_paths, col_high, col_low) {
  out_file <- file.path(output_paths$plot, "out_varify.survStat.pdf")
  grDevices::pdf(out_file, width = 6, height = 4.5)
  on.exit(grDevices::dev.off(), add = TRUE)
  status_colors <- ifelse(risk_data$fustat == 1, col_high, col_low)
  plot(risk_data$futime, pch = 19, cex = 0.6, xlab = "Patients (increasing risk)", ylab = "Survival time (years)", col = status_colors)
  abline(v = sum(risk_data$risk == "low"), lty = 2)
  legend("topleft", legend = c("Dead", "Alive"), col = c(col_high, col_low), pch = 19, bty = "n", cex = 1.1)
  out_file
}

generate_heatmap_plot <- function(risk_data, output_paths, col_high, col_low) {
  gene_cols <- setdiff(colnames(risk_data), c("id", "futime", "fustat", "riskScore", "risk"))
  mat <- t(as.matrix(risk_data[, gene_cols, drop = FALSE]))
  keep_rows <- apply(mat, 1, stats::sd, na.rm = TRUE) > 0
  if (!any(keep_rows)) {
    log_warn("Skipped heatmap because all model genes have zero variance")
    return(NULL)
  }
  ann_col <- data.frame(Risk = risk_data$risk)
  rownames(ann_col) <- risk_data$id
  ann_colors <- list(Risk = c(low = col_low, high = col_high))
  out_file <- file.path(output_paths$plot, "out_varify.heatmap.pdf")
  grDevices::pdf(out_file, width = 8, height = 4.5)
  on.exit(grDevices::dev.off(), add = TRUE)
  pheatmap::pheatmap(
    mat[keep_rows, , drop = FALSE],
    annotation_col = ann_col,
    annotation_colors = ann_colors,
    cluster_cols = FALSE,
    scale = "row",
    show_colnames = FALSE,
    color = grDevices::colorRampPalette(c(col_low, "white", col_high))(100)
  )
  out_file
}

generate_roc_plot <- function(risk_data, output_paths, roc_times, roc_colors, roc_pos) {
  max_followup <- max(risk_data$futime, na.rm = TRUE)
  if (any(roc_times >= max_followup)) {
    stop_skill(
      "SKILL_INVALID_PARAMETER",
      sprintf("All --roc_times must be smaller than the maximum follow-up time of %.3f years", max_followup)
    )
  }
  roc_res <- timeROC::timeROC(
    T = risk_data$futime,
    delta = risk_data$fustat,
    marker = risk_data$riskScore,
    cause = 1,
    times = roc_times,
    iid = FALSE
  )
  out_file <- file.path(output_paths$plot, "out_varify.ROC.pdf")
  grDevices::pdf(out_file, width = 5, height = 5)
  on.exit(grDevices::dev.off(), add = TRUE)
  plot(roc_res, time = roc_times[1], col = roc_colors[1], lwd = 2, title = FALSE)
  if (length(roc_times) > 1) {
    for (idx in 2:length(roc_times))
      plot(roc_res, time = roc_times[idx], col = roc_colors[idx], add = TRUE, lwd = 2)
  }
  legend(
    roc_pos,
    legend = paste0(roc_times, "-year AUC: ", sprintf("%.03f", roc_res$AUC)),
    col = roc_colors[seq_along(roc_times)],
    lwd = 2,
    bty = "n",
    cex = 0.85
  )
  out_file
}

generate_all_plots <- function(risk_data, output_paths, col_high, col_low, roc_times, roc_colors, roc_pos, km_breaks) {
  risk_data <- risk_data[order(risk_data$riskScore), , drop = FALSE]
  list(
    km = generate_survival_plot(risk_data, output_paths, col_high, col_low, km_breaks),
    risk = generate_risk_score_plot(risk_data, output_paths, col_high, col_low),
    status = generate_survival_status_plot(risk_data, output_paths, col_high, col_low),
    heatmap = generate_heatmap_plot(risk_data, output_paths, col_high, col_low),
    roc = generate_roc_plot(risk_data, output_paths, roc_times, roc_colors, roc_pos)
  )
}
