#!/usr/bin/env Rscript

append_report_block <- function(path, lines) {
  existing <- file.exists(path)
  con <- file(path, open = if (existing) "at" else "wt")
  on.exit(close(con), add = TRUE)
  if (existing) writeLines(c("", strrep("=", 72), "", lines), con = con, sep = "\n", useBytes = TRUE) else writeLines(lines, con = con, sep = "\n", useBytes = TRUE)
  path
}

write_output_manifest <- function(output_dir, output_items, opt, runtime_info) {
  lines <- c("Output Files", "============", "", sprintf("Run Mode: %s", opt$mode), sprintf("Generated At: %s", runtime_info$end_time), "")
  for (item in output_items) {
    lines <- c(lines, sprintf("- %s", item$path), sprintf("  Description: %s", item$description), sprintf("  Content: %s", item$content), "")
  }
  append_report_block(file.path(output_dir, "output_manifest.txt"), lines)
}

build_runtime_lines <- function(opt, runtime_info) {
  c("Runtime And Resource Notes", "--------------------------", sprintf("- start_time: %s", runtime_info$start_time), sprintf("- end_time: %s", runtime_info$end_time), sprintf("- elapsed_seconds: %.3f", runtime_info$elapsed_seconds), sprintf("- user_cpu_seconds: %.3f", runtime_info$user_cpu_seconds), sprintf("- system_cpu_seconds: %.3f", runtime_info$system_cpu_seconds), sprintf("- timeout_seconds: %s", opt$timeout_seconds), "- gc_snapshot:", paste0("  ", runtime_info$gc_snapshot))
}

build_run_record_lines <- function(opt, runtime_info, input_info, output_items, result_summary) {
  lines <- c("Run Record", "==========", "", "Input Parameters", "----------------", sprintf("- mode: %s", opt$mode), sprintf("- input_file: %s", opt$input_file %||% "N/A"), sprintf("- group_file: %s", opt$group_file %||% "N/A"), sprintf("- geneset_file: %s", opt$geneset_file %||% "N/A"), sprintf("- geneset_column: %s", opt$geneset_column %||% "N/A"), sprintf("- gene_column: %s", opt$gene_column %||% "N/A"), sprintf("- focus_genesets: %s", opt$focus_genesets %||% "N/A"), sprintf("- case_group: %s", opt$case_group %||% "N/A"), sprintf("- control_group: %s", opt$control_group %||% "N/A"), sprintf("- method: %s", opt$method), sprintf("- kcdf: %s", opt$kcdf), sprintf("- fdr_threshold: %s", opt$fdr_threshold), sprintf("- top_n: %s", opt$top_n), sprintf("- seed: %s", opt$seed), sprintf("- output_dir: %s", opt$output_dir), "", "Input Summary", "-------------", sprintf("- genes: %s", input_info$genes %||% "N/A"), sprintf("- samples: %s", input_info$samples %||% "N/A"), sprintf("- case_samples: %s", input_info$case_samples %||% "N/A"), sprintf("- control_samples: %s", input_info$control_samples %||% "N/A"), sprintf("- genesets_retained: %s", input_info$genesets_retained %||% "N/A"), sprintf("- matched_genes: %s", input_info$matched_genes %||% "N/A"), "", build_runtime_lines(opt, runtime_info), "", "Recorded Result Summary", "-----------------------", sprintf("- significant_pathways_fdr_le_%s: %s", result_summary$fdr_threshold, result_summary$significant_pathways), sprintf("- reported_top_pathways: %s", result_summary$reported_top_pathways), sprintf("- method: %s", result_summary$method), "", "Output Summary", "--------------")
  for (item in output_items) lines <- c(lines, sprintf("- %s", item$path), sprintf("  Description: %s", item$description), sprintf("  Content: %s", item$content))
  lines
}

write_run_record <- function(output_dir, opt, runtime_info, input_info, output_items, result_summary) {
  append_report_block(file.path(output_dir, "run_record.txt"), build_run_record_lines(opt, runtime_info, input_info, output_items, result_summary))
}
