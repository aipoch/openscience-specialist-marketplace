write_session_info <- function(output_dir) {
  file_path <- file.path(output_dir, "session_info.txt")
  writeLines(capture.output(sessionInfo()), file_path)
  invisible(file_path)
}
