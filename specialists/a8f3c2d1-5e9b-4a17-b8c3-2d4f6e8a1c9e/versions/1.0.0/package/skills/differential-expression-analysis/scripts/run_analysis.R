run_diff_analysis <- function(input_file, group_file, output_dir, method, norm_method,
                             p_threshold, logfc_threshold, p_adjust) {
  check_pkg("data.table")
  log_info("Step 1/4: Loading and validating data...")
  dat <- load_data(input_file, group_file)

  log_info(paste("Groups:", dat$con_name, "vs", dat$treat_name))
  log_info(paste("Samples per group:", paste(table(dat$map[[2]]), collapse = ", ")))

  log_info(paste("Step 2/4: Running differential expression (", method, ")..."))
  diff_result <- run_diff_method(dat, method, norm_method)

  temp_dir <- file.path(output_dir, "temp")
  dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)
  diff_path <- file.path(temp_dir, "Diffanalysis.csv")
  write.csv(diff_result, diff_path, row.names = FALSE)
  log_info(paste("DE results saved:", diff_path))

  log_info(paste("Step 3/4: Filtering results (p<", p_threshold, ", |logFC|>=", logfc_threshold, ")..."))
  filtered <- filter_results(diff_result, p_threshold, logfc_threshold, p_adjust)
  log_info(paste("Significant:", filtered$significant, "(Up:", filtered$up, ", Down:", filtered$down, ")"))

  rdegs <- filtered$data[filtered$data$group != "Not", ]
  write.csv(rdegs, file.path(temp_dir, "rdegs.csv"), row.names = FALSE)
  write.csv(filtered$data, file.path(temp_dir, "Diffanalysis_filtered.csv"), row.names = FALSE)

  log_info("Step 4/4: Generating visualizations...")
  generate_outputs(input_file, group_file, temp_dir, output_dir)

  log_info("Analysis complete!")
  invisible(filtered)
}

generate_outputs <- function(input_file, group_file, temp_dir, output_dir) {
  check_pkg("data.table")
  rdegs_file <- file.path(temp_dir, "rdegs.csv")

  if (file.exists(rdegs_file) && nrow(data.table::fread(rdegs_file, data.table = FALSE)) > 0) {
    log_info("Generating volcano plot...")
    generate_volcano(file.path(temp_dir, "Diffanalysis.csv"), output_dir)

    log_info("Generating heatmap...")
    generate_heatmap(input_file, group_file, rdegs_file, output_dir)
  } else {
    log_warn("No significant genes found - skipping visualizations")
  }
}
