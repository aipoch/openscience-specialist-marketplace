write_session_info <- function(output_dir) {
  sink(file.path(output_dir, "session_info.txt"))
  on.exit(sink(), add = TRUE)
  print(utils::sessionInfo())
}

write_output_manifest <- function(output_dir, manifest) {
  lines <- c("# Output Manifest", "")
  for (entry in manifest) {
    lines <- c(lines, sprintf("- %s | %s", entry$file, entry$description))
  }
  writeLines(lines, file.path(output_dir, "output_manifest.txt"))
}

write_run_record <- function(output_dir, details) {
  lines <- c(
    "# Run Record",
    sprintf("- input_file: %s", details$input_file),
    sprintf("- method: %s", details$method),
    sprintf("- margin: %s", details$margin),
    sprintf("- delimiter: %s", details$delimiter),
    sprintf("- pseudo_count: %s", format_num(details$pseudo_count)),
    sprintf("- center: %s", tolower(as.character(details$center))),
    sprintf("- scale_values: %s", tolower(as.character(details$scale_values))),
    sprintf("- timeout_seconds: %s", details$timeout_seconds),
    sprintf("- seed: %d", details$seed),
    sprintf("- verbose: %s", tolower(as.character(details$verbose))),
    sprintf("- feature_count: %d", details$feature_count),
    sprintf("- sample_count: %d", details$sample_count),
    sprintf("- runtime_seconds: %s", format_num(details$runtime_seconds)),
    details$output_summary
  )
  writeLines(lines, file.path(output_dir, "run_record.txt"))
}
