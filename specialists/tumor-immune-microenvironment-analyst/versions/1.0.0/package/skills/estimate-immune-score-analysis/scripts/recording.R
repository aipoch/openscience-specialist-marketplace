#!/usr/bin/env Rscript

append_report_block <- function(path, lines) {
  existing <- file.exists(path)
  con <- file(path, open = if (existing) "at" else "wt")
  on.exit(close(con), add = TRUE)
  if (existing) {
    writeLines(c("", strrep("=", 72), "", lines), con = con, sep = "\n", useBytes = TRUE)
  } else {
    writeLines(lines, con = con, sep = "\n", useBytes = TRUE)
  }
  path
}

write_output_manifest <- function(output_dir, output_items, opt, runtime_info, status = "success", error_message = NULL) {
  manifest_file <- file.path(output_dir, "output_manifest.txt")
  lines <- c("Output Files", "============", "")
  lines <- c(lines, sprintf("Generated At: %s", runtime_info$end_time %||% "N/A"))
  lines <- c(lines, sprintf("Run Status: %s", status))
  lines <- c(lines, sprintf("Input File: %s", opt$input_file))
  if (!is.null(error_message) && nzchar(error_message)) {
    lines <- c(lines, sprintf("Error: %s", error_message))
  }
  lines <- c(lines, "")
  if (length(output_items) == 0) {
    lines <- c(lines, "No output files were generated.", "")
  }
  for (item in output_items) {
    lines <- c(lines, sprintf("- %s", item$path))
    lines <- c(lines, sprintf("  Description: %s", item$description))
    lines <- c(lines, sprintf("  Content: %s", item$content))
    lines <- c(lines, "")
  }
  append_report_block(manifest_file, lines)
}

build_runtime_lines <- function(opt, runtime_info) {
  c(
    "Runtime And Resource Notes",
    "--------------------------",
    sprintf("- start_time: %s", runtime_info$start_time),
    sprintf("- end_time: %s", runtime_info$end_time),
    sprintf("- elapsed_seconds: %.3f", runtime_info$elapsed_seconds),
    sprintf("- user_cpu_seconds: %.3f", runtime_info$user_cpu_seconds),
    sprintf("- system_cpu_seconds: %.3f", runtime_info$system_cpu_seconds),
    sprintf("- timeout_seconds: %s", opt$timeout_seconds),
    "- gc_snapshot:",
    paste0("  ", runtime_info$gc_snapshot)
  )
}

build_run_record_lines <- function(opt, runtime_info, input_info, output_items, status = "success", error_message = NULL) {
  lines <- c(
    "Run Record",
    "==========",
    "",
    "Run Status",
    "----------",
    sprintf("- status: %s", status)
  )
  if (!is.null(error_message) && nzchar(error_message)) {
    lines <- c(lines, sprintf("- error: %s", error_message))
  }
  lines <- c(lines, "",
    "Input Parameters",
    "----------------",
    sprintf("- input_file: %s", opt$input_file),
    sprintf("- group_file: %s", opt$group_file %||% "N/A"),
    sprintf("- output_dir: %s", opt$output_dir),
    sprintf("- gene_id_type: %s", opt$gene_id_type),
    sprintf("- platform: %s", opt$platform),
    sprintf("- input_delimiter: %s", opt$input_delimiter),
    sprintf("- group_delimiter: %s", opt$group_delimiter),
    sprintf("- sample_column: %s", opt$sample_column),
    sprintf("- group_column: %s", opt$group_column),
    sprintf("- plot_file: %s", opt$plot_file),
    sprintf("- heatmap_file: %s", opt$heatmap_file),
    sprintf("- seed: %s", opt$seed),
    "",
    "Input Summary",
    "-------------",
    sprintf("- genes: %s", input_info$genes %||% "N/A"),
    sprintf("- samples: %s", input_info$samples %||% "N/A"),
    sprintf("- input_gene_column: %s", input_info$first_gene_column %||% "N/A"),
    sprintf("- matched_group_samples: %s", input_info$matched_group_samples %||% "N/A"),
    sprintf("- group_levels: %s", input_info$group_levels %||% "N/A")
  )
  lines <- c(lines, "", build_runtime_lines(opt, runtime_info), "", "Output Summary", "--------------")
  if (length(output_items) == 0) {
    lines <- c(lines, "- no output files generated")
  }
  for (item in output_items) {
    lines <- c(lines, sprintf("- %s", item$path))
    lines <- c(lines, sprintf("  Description: %s", item$description))
  }
  lines
}

write_run_record <- function(output_dir, opt, runtime_info, input_info, output_items, status = "success", error_message = NULL) {
  record_file <- file.path(output_dir, "run_record.txt")
  append_report_block(record_file, build_run_record_lines(opt, runtime_info, input_info, output_items, status = status, error_message = error_message))
}
