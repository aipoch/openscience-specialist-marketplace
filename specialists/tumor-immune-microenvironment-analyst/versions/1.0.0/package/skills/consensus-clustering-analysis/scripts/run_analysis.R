build_output_dirs <- function(output_dir) {
  ensure_dir(output_dir)
  normalizePath(output_dir)
}

run_consensus_once <- function(matrix_data, method_row, opt, output_dirs) {
  result_name <- paste("result", method_row$dist, method_row$clusterAlg, sep = "_")
  result_dir <- file.path(output_dirs, result_name)
  ensure_dir(result_dir)
  log_info(sprintf("Running consensus clustering: %s + %s", method_row$dist, method_row$clusterAlg))

  old_dir <- getwd()
  on.exit(setwd(old_dir), add = TRUE)
  setwd(output_dirs)

  result_object <- suppress_package_output(function() {
    ConsensusClusterPlus::ConsensusClusterPlus(
      matrix_data, maxK = opt$max_k, reps = opt$reps, pItem = opt$p_item,
      pFeature = opt$p_feature, distance = method_row$dist, clusterAlg = method_row$clusterAlg,
      innerLinkage = "average", title = result_name, corUse = "complete.obs",
      seed = opt$seed, plot = "pdf", writeTable = TRUE
    )
  })
  remove_generated_logs(result_dir)

  pac_table <- compute_pac_table(result_object, opt$max_k)
  best_idx <- which.min(ifelse(is.na(pac_table$PAC), Inf, pac_table$PAC))
  write_csv_output(pac_table, file.path(result_dir, "PAC_scores.csv"))
  list(
    summary = data.frame(dist = method_row$dist, clusterAlg = method_row$clusterAlg,
                         bestK = pac_table$k[best_idx], PAC = pac_table$PAC[best_idx],
                         stringsAsFactors = FALSE),
    result_object = result_object,
    result_name = result_name
  )
}

run_method_grid <- function(matrix_data, opt, output_dirs) {
  method_grid <- build_method_grid()
  run_results <- lapply(seq_len(nrow(method_grid)), function(row_id) {
    method_row <- method_grid[row_id, , drop = FALSE]
    method_try <- try(withCallingHandlers({
      run_consensus_once(matrix_data, method_row, opt, output_dirs)
    }, warning = function(w) {
      if (!is_known_benign_warning(conditionMessage(w)))
        log_warn(conditionMessage(w))
      invokeRestart("muffleWarning")
    }), silent = TRUE)
    if (!inherits(method_try, "try-error"))
      return(method_try)
    log_warn(sprintf("Method %s + %s failed and was skipped.", method_row$dist, method_row$clusterAlg))
    list(
      summary = data.frame(dist = method_row$dist, clusterAlg = method_row$clusterAlg,
                           bestK = NA_integer_, PAC = NA_real_, stringsAsFactors = FALSE),
      result_object = NULL,
      result_name = paste("result", method_row$dist, method_row$clusterAlg, sep = "_")
    )
  })
  list(
    cluster_results = do.call(rbind, lapply(run_results, `[[`, "summary")),
    result_objects = stats::setNames(lapply(run_results, `[[`, "result_object"),
                                     vapply(run_results, `[[`, character(1), "result_name"))
  )
}

write_primary_outputs <- function(selection, filtered_data, cluster_results, optimal_row, output_dirs) {
  cluster_results$is_best <- with(cluster_results,
                                  !is.na(PAC) & dist == optimal_row$dist &
                                  clusterAlg == optimal_row$clusterAlg & bestK == optimal_row$bestK)
  write_csv_output(data.frame(sample = filtered_data$disease_samples, group = filtered_data$disease_group,
                              stringsAsFactors = FALSE),
                   file.path(output_dirs, "samples_for_clustering.csv"))
  write_csv_output(selection$metadata, file.path(output_dirs, "genes_for_clustering.csv"))
  write_csv_output(cluster_results, file.path(output_dirs, "Cluster_res.csv"))
  invisible(cluster_results)
}

draw_primary_plots <- function(optimal_row, output_dirs, result_objects) {
  result_name <- paste("result", optimal_row$dist, optimal_row$clusterAlg, sep = "_")
  result_object <- result_objects[[result_name]]
  if (is.null(result_object)) {
    stop_skill("SKILL_INVALID_DATA", sprintf("ConsensusClusterPlus object missing for %s", result_name))
  }
  generate_consensus_matrix_plot(result_object, optimal_row$bestK,
                                 file.path(output_dirs, "Consensus Matrix Plot.pdf"))
  generate_cdf_plot(result_object, file.path(output_dirs, "CDF curve Plot.pdf"))
}

run_consensus_analysis <- function(opt) {
  output_dirs <- build_output_dirs(opt$output_dir)
  log_info("Step 1/4: Reading input files.")
  expression_matrix <- load_expression_matrix(opt$input_file)
  group_table <- standardize_group_table(load_group_table(opt$group_file))
  filtered_data <- filter_disease_matrix(expression_matrix, group_table, opt$disease_group, opt$max_k)
  log_memory_usage("After input loading")

  log_info("Step 2/4: Building the clustering matrix.")
  gene_list <- if (opt$gene_selection == "custom") load_gene_list(opt$gene_list) else character(0)
  selection <- select_gene_matrix(filtered_data$matrix, opt$gene_selection, opt$top_n, gene_list)
  selection$matrix <- center_expression_matrix(selection$matrix, opt$center_data)
  log_info(sprintf("Selected %d genes across %d samples.", nrow(selection$matrix), ncol(selection$matrix)))
  log_memory_usage("After gene selection")

  clustering_run <- with_suppressed_benign_warnings({
    log_info("Step 3/4: Evaluating clustering methods.")
    method_results <- run_method_grid(selection$matrix, opt, output_dirs)
    cluster_results <- method_results$cluster_results
    optimal_row <- select_best_result(cluster_results)
    optimal_row$disease_group <- filtered_data$disease_group
    cluster_results <- write_primary_outputs(selection, filtered_data, cluster_results, optimal_row, output_dirs)

    log_info("Step 4/4: Rendering output plots.")
    draw_primary_plots(optimal_row, output_dirs, method_results$result_objects)
    list(cluster_results = cluster_results, optimal_row = optimal_row)
  })
  cluster_results <- clustering_run$cluster_results
  optimal_row <- clustering_run$optimal_row
  log_memory_usage("Final")
  invisible(list(optimal = optimal_row, cluster_results = cluster_results))
}
