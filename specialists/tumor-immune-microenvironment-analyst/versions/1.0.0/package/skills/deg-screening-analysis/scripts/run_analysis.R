write_outputs <- function(output_dir, diff_result, filtered, case_name, control_name, p_adjust, p_threshold, logfc_threshold) {
  data_dir <- file.path(output_dir, "data")
  table_dir <- file.path(output_dir, "table")
  ensure_dir(data_dir)
  ensure_dir(table_dir)

  diff_table <- data.frame(
    name = diff_result$gene_id,
    logFC = diff_result$logFC,
    P.value = diff_result$Pvalue,
    P.adj = diff_result$Padj,
    stringsAsFactors = FALSE
  )
  deg <- data.frame(
    name = filtered$data$name[filtered$data$group != "no"],
    logFC = filtered$data$logFC[filtered$data$group != "no"],
    P.value = filtered$data$Pvalue[filtered$data$group != "no"],
    P.adj = filtered$data$Padj[filtered$data$group != "no"],
    group = filtered$data$group[filtered$data$group != "no"],
    stringsAsFactors = FALSE
  )
  utils::write.csv(diff_table, file.path(table_dir, "Diffanalysis.csv"), row.names = FALSE)
  utils::write.csv(deg, file.path(table_dir, "DEG.csv"), row.names = FALSE)

  deg_list <- list(
    method = "limma",
    case = case_name,
    control = control_name,
    DEG = deg,
    diff_table = diff_table,
    p_type = ifelse(p_adjust, "p.adj", "p"),
    logfc_value = logfc_threshold,
    p_value = p_threshold
  )
  save(deg_list, file = file.path(data_dir, "DEG_list.rda"))
  list(diff_table = diff_table, deg = deg)
}

run_diff_analysis <- function(input_file, group_file, output_dir, case_name, control_name, method,
                              p_threshold, logfc_threshold, top_n, p_adjust, run_plots, timeout_seconds) {
  with_timeout({
    log_info("Step 1/4: Loading and validating data...")
    dat <- load_data(input_file, group_file, case_name, control_name)
    ensure_dir(output_dir)
    save_session_info(output_dir)
    log_info(paste("Groups:", dat$con_name, "vs", dat$treat_name))

    log_info(paste0("Step 2/4: Running differential expression (", method, ")..."))
    diff_result <- run_diff_method(dat, method)

    log_info("Step 3/4: Filtering differential results...")
    filtered <- filter_results(diff_result, p_threshold, logfc_threshold, p_adjust)
    if (filtered$significant == 0) {
      log_warn("No significant genes found with current thresholds; writing empty DEG table and skipping heatmap")
    }
    output_tables <- write_outputs(output_dir, diff_result, filtered, dat$treat_name, dat$con_name, p_adjust, p_threshold, logfc_threshold)

    heatmap_matrix <- build_xiantao_heatmap(dat$mat, dat$map, filtered$data, dat$treat_name, dat$con_name, top_n, p_adjust)
    if (is.null(heatmap_matrix)) {
      log_warn("Not enough significant genes found for heatmap export; skipping heatmap")
    }

    if (isTRUE(run_plots)) {
      log_info("Step 4/4: Generating plots...")
      generate_volcano(output_tables$diff_table, file.path(output_dir, "plot"), p_threshold, logfc_threshold, p_adjust = p_adjust)
      if (!is.null(heatmap_matrix)) {
        generate_heatmap(heatmap_matrix, file.path(output_dir, "plot"))
      }
    }
    log_info("Analysis complete!")
  }, timeout_seconds)
}
