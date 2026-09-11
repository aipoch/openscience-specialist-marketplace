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

write_output_manifest <- function(output_dir, output_items, opt = NULL, runtime_info = NULL) {
  manifest_file <- file.path(output_dir, "output_manifest.txt")
  lines <- c("Output Files", "============", "")
  if (!is.null(opt)) {
    lines <- c(lines, sprintf("Run Mode: %s", opt$mode))
    lines <- c(lines, sprintf("Generated At: %s", runtime_info$end_time %||% "N/A"))
    lines <- c(lines, "")
  }
  for (item in output_items) {
    lines <- c(lines, sprintf("- %s", item$path))
    lines <- c(lines, sprintf("  Description: %s", item$description))
    if (!is.null(item$content)) {
      lines <- c(lines, sprintf("  Content: %s", item$content))
    }
    lines <- c(lines, "")
  }
  append_report_block(manifest_file, lines)
}

build_run_record_lines <- function(opt, runtime_info, input_info, output_items) {
  lines <- c(
    "Run Record",
    "==========",
    "",
    "Input Parameters",
    "----------------",
    sprintf("- mode: %s", opt$mode),
    sprintf("- input_file: %s", opt$input_file %||% "N/A"),
    sprintf("- group_file: %s", opt$group_file %||% "N/A"),
    sprintf("- case_group: %s", opt$case_group %||% "N/A"),
    sprintf("- control_group: %s", opt$control_group %||% "N/A"),
    sprintf("- species: %s", opt$species),
    sprintf("- category: %s", opt$category),
    sprintf("- subcategory: %s", opt$subcategory),
    sprintf("- method: %s", opt$method),
    sprintf("- kcdf: %s", opt$kcdf),
    sprintf("- fdr_threshold: %s", opt$fdr_threshold),
    sprintf("- top_n: %s", opt$top_n),
    sprintf("- seed: %s", opt$seed),
    sprintf("- output_dir: %s", opt$output_dir),
    "",
    "Input Summary",
    "-------------",
    sprintf("- genes: %s", input_info$genes %||% "N/A"),
    sprintf("- samples: %s", input_info$samples %||% "N/A"),
    sprintf("- case_samples: %s", input_info$case_samples %||% "N/A"),
    sprintf("- control_samples: %s", input_info$control_samples %||% "N/A")
  )
  lines <- c(lines, "", build_runtime_lines(opt, runtime_info), "", "Output Summary", "--------------")
  for (item in output_items) {
    lines <- c(lines, sprintf("- %s", item$path))
    lines <- c(lines, sprintf("  Description: %s", item$description))
  }
  lines
}

build_runtime_lines <- function(opt, runtime_info) {
  lines <- c(
    "Runtime And Resource Notes",
    "--------------------------",
    sprintf("- start_time: %s", runtime_info$start_time),
    sprintf("- end_time: %s", runtime_info$end_time),
    sprintf("- elapsed_seconds: %.3f", runtime_info$elapsed_seconds),
    sprintf("- user_cpu_seconds: %.3f", runtime_info$user_cpu_seconds),
    sprintf("- system_cpu_seconds: %.3f", runtime_info$system_cpu_seconds),
    sprintf("- timeout_seconds: %s", opt$timeout_seconds),
    "- gc_snapshot:"
  )
  c(lines, paste0("  ", runtime_info$gc_snapshot))
}

write_run_record <- function(output_dir, opt, runtime_info, input_info, output_items) {
  record_file <- file.path(output_dir, "run_record.txt")
  append_report_block(record_file, build_run_record_lines(opt, runtime_info, input_info, output_items))
}
