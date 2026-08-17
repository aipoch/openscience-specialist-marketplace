prepare_inputs <- function(opt) {
  log_info("Step 1/6: Loading expression matrix and group file")
  filtered_expr <- load_expression_matrix(
    opt$input_file,
    opt$mad_quantile,
    opt$min_mad,
    opt$max_genes,
    opt$chunk_size
  )
  dat_traits <- load_group_data(
    opt$group_file,
    opt$sample_column,
    opt$group_column,
    colnames(filtered_expr)
  )
  list(filtered_expr = filtered_expr, dat_traits = dat_traits)
}

prepare_analysis_objects <- function(filtered_expr, dat_traits) {
  log_info("Step 2/6: Preparing WGCNA matrix")
  data_expr <- prepare_wgcna_matrix(filtered_expr)
  dat_traits <- dat_traits[rownames(data_expr), , drop = FALSE]
  trait_data <- build_trait_matrix(dat_traits)
  list(data_expr = data_expr, dat_traits = dat_traits, trait_data = trait_data)
}

run_network_construction <- function(opt, paths, data_expr) {
  log_info("Step 3/6: Selecting soft-threshold power")
  soft_out <- select_soft_threshold(data_expr, opt$network_type, opt$soft_r2_cutoff)
  plot_soft_threshold(
    soft_out$sft,
    soft_out$powers,
    opt$soft_r2_cutoff,
    file.path(paths$plots, "soft_threshold.pdf")
  )
  save_table(
    as.data.frame(soft_out$sft$fitIndices),
    file.path(paths$tables, "sft_fit_indices.csv"),
    row_names = FALSE
  )

  log_info("Step 4/6: Building weighted gene co-expression network")
  net <- run_blockwise_modules(
    data_expr,
    soft_out$power,
    opt$network_type,
    opt$cor_type,
    opt$min_module_size,
    opt$merge_cut_height,
    file.path(paths$data, "wgcna_tom")
  )
  save_rds_logged(net, file.path(paths$data, "net.rds"))
  list(soft_out = soft_out, net = net)
}

save_primary_outputs <- function(paths, analysis, network_out, stats_out, opt) {
  save_table(as.data.frame(stats_out$mod_trait_cor), file.path(paths$tables, "module_trait_cor.csv"))
  save_table(as.data.frame(stats_out$mod_trait_p), file.path(paths$tables, "module_trait_p.csv"))
  save_table(
    data.frame(gene_id = names(stats_out$module_colors), module = stats_out$module_colors, row.names = NULL),
    file.path(paths$tables, "module_assignments.csv"),
    row_names = FALSE
  )

  plot_sample_clustering(analysis$data_expr, analysis$dat_traits, file.path(paths$plots, "sample_clustering.pdf"))
  plot_gene_clusters(network_out$net, stats_out, file.path(paths$plots, "gene_cluster_modules.pdf"))
  plot_eigengene_network(stats_out, file.path(paths$plots, "module_eigengene_heatmap.pdf"))
  plot_tom_heatmap(network_out$net, stats_out, opt$tom_sample_size, opt$seed, file.path(paths$plots, "tom_heatmap.pdf"))
  plot_module_trait_heatmap(stats_out, analysis$trait_data, file.path(paths$plots, "module_trait_relationships.pdf"))
}

save_selection_outputs <- function(paths, stats_out, analysis, network_out, opt) {
  selected_trait <- resolve_trait_of_interest(analysis$trait_data, opt$trait_of_interest)
  selected_modules <- resolve_modules_of_interest(
    stats_out,
    selected_trait,
    opt$module_of_interest,
    opt$top_modules
  )

  selection_summary <- build_module_selection_summary(stats_out, selected_trait, selected_modules)
  save_table(selection_summary, file.path(paths$tables, "selected_modules.csv"), row_names = FALSE)

  for (selected_module in selected_modules) {
    plot_module_membership_scatter(
      stats_out,
      selected_module,
      selected_trait,
      file.path(paths$plots, sprintf("module_membership_vs_trait_%s_%s.pdf", selected_module, selected_trait))
    )
    export_df <- build_module_export(stats_out, selected_module, selected_trait)
    save_table(
      export_df,
      file.path(paths$tables, sprintf("module_genes_%s.csv", selected_module)),
      row_names = FALSE
    )
  }

  save_rds_logged(
    list(
      power = network_out$soft_out$power,
      data_expr = analysis$data_expr,
      dat_traits = analysis$dat_traits,
      trait_data = analysis$trait_data,
      stats = stats_out,
      selected_modules = selected_modules
    ),
    file.path(paths$data, "analysis_objects.rds")
  )

  save_table(
    data.frame(
      samples = nrow(analysis$data_expr),
      genes = ncol(analysis$data_expr),
      soft_power = network_out$soft_out$power,
      selected_trait = selected_trait,
      selected_modules = paste(selected_modules, collapse = ","),
      n_selected_modules = length(selected_modules),
      stringsAsFactors = FALSE
    ),
    file.path(paths$tables, "analysis_summary.csv"),
    row_names = FALSE
  )

  list(selected_trait = selected_trait, selected_modules = selected_modules)
}

run_wgcna_analysis <- function(opt) {
  paths <- build_output_paths(opt$output_dir)
  inputs <- prepare_inputs(opt)
  analysis <- prepare_analysis_objects(inputs$filtered_expr, inputs$dat_traits)

  network_out <- run_network_construction(opt, paths, analysis$data_expr)

  log_info("Step 5/6: Calculating module-trait and gene-trait statistics")
  stats_out <- compute_wgcna_statistics(
    analysis$data_expr,
    analysis$trait_data,
    network_out$net,
    opt$cor_type
  )
  save_primary_outputs(paths, analysis, network_out, stats_out, opt)

  log_info("Step 6/6: Selecting module(s) of interest and exporting genes")
  selection <- save_selection_outputs(paths, stats_out, analysis, network_out, opt)

  invisible(list(
    paths = paths,
    power = network_out$soft_out$power,
    selected_trait = selection$selected_trait,
    selected_modules = selection$selected_modules
  ))
}
