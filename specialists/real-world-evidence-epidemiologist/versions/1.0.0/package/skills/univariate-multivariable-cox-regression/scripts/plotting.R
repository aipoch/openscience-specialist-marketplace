read_results_table <- function(data_file) {
  ext <- tolower(tools::file_ext(validate_existing_file(data_file, "--data_file", c("xlsx", "xls", "csv"))))
  if (ext == "csv")
    return(read.csv(data_file, stringsAsFactors = FALSE, check.names = FALSE))
  check_required_packages(c("readxl"))
  readxl::read_excel(data_file)
}

parse_hr_ci_column <- function(values) {
  hr_values <- rep(NA_real_, length(values))
  low_values <- rep(NA_real_, length(values))
  high_values <- rep(NA_real_, length(values))
  pattern <- "^([0-9]+\\.?[0-9]*) \\(([0-9]+\\.?[0-9]*)-([0-9]+\\.?[0-9]*)\\)$"

  for (idx in seq_along(values)) {
    value <- values[[idx]]
    if (is.na(value) || !grepl(pattern, value))
      next
    matches <- regmatches(value, regexec(pattern, value))[[1]]
    hr_values[idx] <- as.numeric(matches[2])
    low_values[idx] <- as.numeric(matches[3])
    high_values[idx] <- as.numeric(matches[4])
  }

  data.frame(hr = hr_values, low = low_values, high = high_values)
}

generate_forest_plot <- function(data_file, plot_save, width, height, font_size, title) {
  check_required_packages(c("forestplot"))
  validate_positive_number(width, "--width")
  validate_positive_number(height, "--height")
  validate_positive_number(font_size, "--font_size")
  dir.create(dirname(plot_save), recursive = TRUE, showWarnings = FALSE)

  plot_data <- as.data.frame(read_results_table(data_file), stringsAsFactors = FALSE)
  if (nrow(plot_data) == 0)
    stop_skill("SKILL_EMPTY_DATA", "Plot input file contains no result rows")
  required_cols <- c("Characteristics", "Total(N)", "HR (95% CI)", "P value")
  missing_cols <- setdiff(required_cols, colnames(plot_data))
  if (length(missing_cols) > 0)
    stop_skill("SKILL_MISSING_COLUMNS", paste("Plot input is missing columns:", paste(missing_cols, collapse = ", ")))

  hr_ci <- parse_hr_ci_column(plot_data[["HR (95% CI)"]])
  tabletext <- rbind(
    c("Characteristic", "Total(N)", "HR (95% CI)", "P value"),
    as.matrix(plot_data[, required_cols])
  )

  grDevices::pdf(plot_save, width = width, height = height)
  on.exit(grDevices::dev.off(), add = TRUE)
  # forestplot objects are not auto-printed inside functions; keep rendering on the
  # current device page so the PDF does not start with a blank page.
  plot_obj <- forestplot::forestplot(
    labeltext = tabletext,
    mean = c(NA, hr_ci$hr),
    lower = c(NA, hr_ci$low),
    upper = c(NA, hr_ci$high),
    zero = 1,
    boxsize = 0.2,
    xlab = "Hazard ratio",
    new_page = FALSE,
    txt_gp = forestplot::fpTxtGp(label = grid::gpar(cex = font_size / 12), ticks = grid::gpar(cex = font_size / 12), xlab = grid::gpar(cex = font_size / 12)),
    col = forestplot::fpColors(box = "#4DBBD5", line = "#4DBBD5", zero = "black"),
    title = title
  )
  print(plot_obj)
  invisible(plot_save)
}
