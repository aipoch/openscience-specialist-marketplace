create_output_dirs <- function(output_dir, overwrite = FALSE) {
  validate_required_value(output_dir, "--output_dir")
  if (dir.exists(output_dir)) {
    existing_entries <- list.files(output_dir, all.files = TRUE, no.. = TRUE)
    if (length(existing_entries) > 0 && !isTRUE(overwrite)) {
      stop_skill(
        "SKILL_INVALID_PARAMETER",
        paste("--output_dir already exists and is not empty:", normalizePath(output_dir, winslash = "/", mustWork = TRUE),
              "Use --overwrite to replace previous results")
      )
    }
    if (length(existing_entries) > 0)
      unlink(file.path(output_dir, existing_entries), recursive = TRUE, force = TRUE)
  }
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  for (subdir in c("data", "table", "plot"))
    dir.create(file.path(output_dir, subdir), recursive = TRUE, showWarnings = FALSE)
  list(
    root = normalizePath(output_dir, winslash = "/", mustWork = TRUE),
    data = file.path(output_dir, "data"),
    table = file.path(output_dir, "table"),
    plot = file.path(output_dir, "plot")
  )
}

read_clinical_data <- function(data_file) {
  file_path <- validate_existing_file(data_file, "--data_file", c("csv"))
  data <- tryCatch(
    read.csv(file_path, row.names = 1, check.names = FALSE, stringsAsFactors = FALSE),
    error = function(e) stop_skill("SKILL_INVALID_DATA", paste("Failed to read clinical data:", conditionMessage(e)))
  )
  if (nrow(data) == 0 || ncol(data) == 0)
    stop_skill("SKILL_EMPTY_DATA", "Clinical data file contains no usable rows or columns")
  data
}

save_nomogram_bundle <- function(bundle, output_paths) {
  tryCatch({
    qs::qsave(bundle, file.path(output_paths$data, "Nomogram_list.qs"))
    saveRDS(bundle$data, file.path(output_paths$data, "analysis_data.rds"))
    openxlsx::write.xlsx(bundle$c_index_table, file.path(output_paths$table, "nomogram_c_index.xlsx"))
  }, error = function(e) stop_skill("SKILL_ANALYSIS_ERROR", paste("Failed to save nomogram outputs:", conditionMessage(e))))
  invisible(output_paths)
}

read_nomogram_bundle <- function(nomo_data_file) {
  file_path <- validate_existing_file(nomo_data_file, "--nomo_data_file", c("qs"))
  bundle <- tryCatch(qs::qread(file_path), error = function(e) stop_skill("SKILL_INVALID_DATA", paste("Failed to read nomogram bundle:", conditionMessage(e))))
  required_names <- c("nomogram", "c_index", "model", "data", "features", "time_points")
  missing_names <- setdiff(required_names, names(bundle))
  if (length(missing_names) > 0)
    stop_skill("SKILL_INVALID_DATA", paste("Nomogram bundle is missing required objects:", paste(missing_names, collapse = ", ")))
  bundle
}

save_nomogram_plot <- function(bundle, plot_save, width, height, font_size, line_width, font_family) {
  validate_pdf_output(plot_save, "--plot_save")
  validate_positive_number(width, "--plot_width")
  validate_positive_number(height, "--plot_height")
  validate_positive_number(font_size, "--font_size")
  validate_positive_number(line_width, "--line_width")
  if (file.exists(plot_save)) log_warn(paste("Overwriting existing plot file:", plot_save))
  dir.create(dirname(plot_save), recursive = TRUE, showWarnings = FALSE)
  grDevices::pdf(plot_save, width = width, height = height, family = font_family)
  on.exit(grDevices::dev.off(), add = TRUE)
  graphics::par(family = font_family, ps = font_size)
  graphics::plot(bundle$nomogram, lplabel = "Linear Predictor", xfrac = 0.25, label.every = 1, col.grid = gray(c(0.8, 0.95)), cex.var = 1.2, cex.axis = 1, cex.lab = 1.2, lty = 1, lwd = line_width)
  invisible(plot_save)
}

save_session_info <- function(output_dir, metadata = list(), title = "Nomogram Construction Session Information") {
  session_file <- file.path(output_dir, "session_info.txt")
  lines <- c(title, paste(rep("=", nchar(title)), collapse = ""), paste("Generated:", format(Sys.time(), "%Y-%m-%d %H:%M:%S")), "")
  if (length(metadata) > 0) {
    lines <- c(lines, "Parameters:")
    for (name in names(metadata))
      lines <- c(lines, paste("-", name, ":", paste(metadata[[name]], collapse = ",")))
    lines <- c(lines, "")
  }
  writeLines(c(lines, capture.output(sessionInfo())), session_file)
  invisible(session_file)
}
