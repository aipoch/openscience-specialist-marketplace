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

capture_runtime_info <- function(start_time, start_proc, notes = NULL, end_time = Sys.time(), end_proc = proc.time()) {
  list(
    start_time = format(start_time, "%Y-%m-%d %H:%M:%S"),
    end_time = format(end_time, "%Y-%m-%d %H:%M:%S"),
    elapsed_seconds = as.numeric(difftime(end_time, start_time, units = "secs")),
    user_cpu_seconds = unname((end_proc - start_proc)[["user.self"]]),
    system_cpu_seconds = unname((end_proc - start_proc)[["sys.self"]]),
    gc_snapshot = capture.output(gc()),
    notes = notes[!is.na(notes) & nzchar(notes)]
  )
}

make_staging_output_dir <- function(output_dir) {
  parent_dir <- dirname(output_dir)
  ensure_dir(parent_dir)
  staging_dir <- tempfile(
    pattern = paste0(".", or_default(sanitize_filename(basename(output_dir)), "output"), "_staging_"),
    tmpdir = parent_dir
  )
  ensure_dir(staging_dir)
  for (subdir in c("data", "table", "plot")) {
    ensure_dir(file.path(staging_dir, subdir))
  }
  for (filename in c("run_record.txt", "output_manifest.txt")) {
    source_path <- file.path(output_dir, filename)
    if (file.exists(source_path)) {
      file.copy(source_path, file.path(staging_dir, filename), overwrite = TRUE)
    }
  }
  staging_dir
}

promote_staged_output <- function(staging_dir, output_dir) {
  ensure_dir(output_dir)
  for (subdir in c("data", "table", "plot")) {
    target_path <- file.path(output_dir, subdir)
    if (dir.exists(target_path)) {
      unlink(target_path, recursive = TRUE, force = TRUE)
    }
    file.copy(file.path(staging_dir, subdir), output_dir, recursive = TRUE)
  }
  for (filename in c("session_info.txt", "run_record.txt", "output_manifest.txt")) {
    staged_path <- file.path(staging_dir, filename)
    if (file.exists(staged_path)) {
      file.copy(staged_path, file.path(output_dir, filename), overwrite = TRUE)
    }
  }
  invisible(output_dir)
}
