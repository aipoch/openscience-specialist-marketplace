write_lines <- function(path, lines) {
  writeLines(lines, con = path, useBytes = TRUE)
}

write_output_manifest <- function(output_dir, manifest_entries) {
  path <- file.path(output_dir, "output_manifest.txt")
  header <- c(sprintf("Run recorded at: %s", timestamp_now()), "Output files:")
  body <- vapply(manifest_entries, function(x) sprintf("- %s | %s", x$file, x$description), character(1))
  write_lines(path, c(header, body, ""))
}

write_run_record <- function(output_dir, run_meta) {
  path <- file.path(output_dir, "run_record.txt")
  lines <- c(
    sprintf("Run recorded at: %s", timestamp_now()),
    sprintf("Input parameters: %s", jsonlite::toJSON(run_meta$args, auto_unbox = TRUE)),
    sprintf("Input summary: %s", run_meta$input_summary),
    sprintf("Runtime seconds: %.3f", run_meta$runtime_seconds),
    sprintf("CPU summary: %s", run_meta$cpu_summary),
    sprintf("GC note: %s", run_meta$gc_note),
    sprintf("Output summary: %s", run_meta$output_summary),
    ""
  )
  write_lines(path, lines)
}
