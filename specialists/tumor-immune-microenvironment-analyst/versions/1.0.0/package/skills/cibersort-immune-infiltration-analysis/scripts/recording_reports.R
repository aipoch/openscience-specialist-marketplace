write_output_manifest <- function(output_dir, output_items, opt, runtime_info) {
  path <- file.path(output_dir, "output_manifest.txt")
  lines <- c("Output Files", "============", "", sprintf("Run Mode: %s", "analysis"), sprintf("Generated At: %s", runtime_info$end_time), "")
  for (item in output_items) {
    lines <- c(lines, sprintf("- %s", item$path), sprintf("  Description: %s", item$description), sprintf("  Content: %s", item$content), "")
  }
  append_report_block(path, lines)
}

build_run_record_lines <- function(opt, runtime_info, input_info, output_items, rendering_metadata = NULL) {
  lines <- c(
    "Run Record", "==========", "", "Input Parameters", "----------------",
    sprintf("- input_file: %s", opt$input_file),
    sprintf("- group_file: %s", opt$group_file),
    sprintf("- signature_file: %s", or_default(opt$signature_file, "LM22")),
    sprintf("- case_group: %s", opt$case_group),
    sprintf("- control_group: %s", opt$control_group),
    sprintf("- gene_id_case: %s", opt$gene_id_case),
    sprintf("- auto_unlog: %s", opt$auto_unlog),
    sprintf("- min_mean_expression: %s", opt$min_mean_expression),
    sprintf("- perm: %s", opt$perm),
    sprintf("- qn: %s", opt$qn),
    sprintf("- svm_cores: %s", opt$svm_cores),
    sprintf("- make_plots: %s", opt$make_plots),
    sprintf("- timeout_seconds: %s", opt$timeout_seconds),
    sprintf("- seed: %s", opt$seed),
    "", "Input Summary", "-------------",
    sprintf("- genes: %s", input_info$genes),
    sprintf("- samples: %s", input_info$samples),
    sprintf("- case_samples: %s", input_info$case_samples),
    sprintf("- control_samples: %s", input_info$control_samples),
    sprintf("- signature_genes: %s", input_info$signature_genes),
    sprintf("- overlapping_genes: %s", input_info$overlapping_genes),
    sprintf("- cell_types: %s", input_info$cell_types),
    "", "Runtime And Resource Notes", "--------------------------",
    sprintf("- start_time: %s", runtime_info$start_time),
    sprintf("- end_time: %s", runtime_info$end_time),
    sprintf("- elapsed_seconds: %.3f", runtime_info$elapsed_seconds),
    sprintf("- user_cpu_seconds: %.3f", runtime_info$user_cpu_seconds),
    sprintf("- system_cpu_seconds: %.3f", runtime_info$system_cpu_seconds),
    "- gc_snapshot:"
  )
  lines <- c(lines, paste0("  ", runtime_info$gc_snapshot))
  if (length(runtime_info$notes) > 0) {
    lines <- c(lines, "", "Runtime Notes", "-------------", sprintf("- %s", runtime_info$notes))
  }
  lines <- c(lines, "", "Output Summary", "--------------")
  for (item in output_items) {
    lines <- c(lines, sprintf("- %s", item$path), sprintf("  Description: %s", item$description))
  }
  heatmap_meta <- rendering_metadata$correlation_heatmap
  if (!is.null(heatmap_meta)) {
    lines <- c(
      lines,
      "",
      "Rendering Metadata",
      "------------------",
      sprintf("- plot_enabled: %s", heatmap_meta$plot_enabled),
      sprintf("- correlation_heatmap_non_finite_values_replaced: %s", heatmap_meta$non_finite_values_replaced),
      sprintf("- correlation_heatmap_replacement_value: %s", heatmap_meta$replacement_value),
      sprintf("- correlation_heatmap_replacement_scope: %s", heatmap_meta$replacement_scope),
      sprintf("- correlation_heatmap_significant_marker_count: %s", heatmap_meta$significant_marker_count)
    )
  }
  lines
}

write_run_record <- function(output_dir, opt, runtime_info, input_info, output_items, rendering_metadata = NULL) {
  path <- file.path(output_dir, "run_record.txt")
  append_report_block(path, build_run_record_lines(opt, runtime_info, input_info, output_items, rendering_metadata))
}

write_failure_manifest <- function(output_dir, opt, runtime_info, error_message) {
  ensure_dir(output_dir)
  path <- file.path(output_dir, "output_manifest.txt")
  lines <- c(
    "Output Files",
    "============",
    "",
    sprintf("Run Mode: %s", "analysis_failed"),
    sprintf("Generated At: %s", runtime_info$end_time),
    sprintf("Output Directory: %s", opt$output_dir),
    sprintf("Error: %s", error_message),
    "",
    "No payload files were promoted because validation or execution failed before a successful run completed."
  )
  append_report_block(path, lines)
}

write_failure_run_record <- function(output_dir, opt, runtime_info, error_message) {
  ensure_dir(output_dir)
  path <- file.path(output_dir, "run_record.txt")
  lines <- c(
    "Run Record",
    "==========",
    "",
    "Run Status",
    "----------",
    "- status: failed",
    sprintf("- error: %s", error_message),
    "",
    "Input Parameters",
    "----------------",
    sprintf("- input_file: %s", opt$input_file),
    sprintf("- group_file: %s", opt$group_file),
    sprintf("- signature_file: %s", or_default(opt$signature_file, "LM22")),
    sprintf("- case_group: %s", opt$case_group),
    sprintf("- control_group: %s", opt$control_group),
    sprintf("- output_dir: %s", opt$output_dir),
    sprintf("- seed: %s", opt$seed),
    "",
    "Runtime And Resource Notes",
    "--------------------------",
    sprintf("- start_time: %s", runtime_info$start_time),
    sprintf("- end_time: %s", runtime_info$end_time),
    sprintf("- elapsed_seconds: %.3f", runtime_info$elapsed_seconds),
    sprintf("- user_cpu_seconds: %.3f", runtime_info$user_cpu_seconds),
    sprintf("- system_cpu_seconds: %.3f", runtime_info$system_cpu_seconds),
    "- gc_snapshot:"
  )
  lines <- c(lines, paste0("  ", runtime_info$gc_snapshot))
  if (length(runtime_info$notes) > 0) {
    lines <- c(lines, "", "Failure Notes", "-------------", sprintf("- %s", runtime_info$notes))
  }
  append_report_block(path, lines)
}
