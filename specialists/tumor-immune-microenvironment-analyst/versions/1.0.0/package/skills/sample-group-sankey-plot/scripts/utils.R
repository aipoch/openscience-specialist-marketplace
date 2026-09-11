log_message <- function(level, message_text) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  line <- sprintf("[%s] %s: %s\n", timestamp, toupper(level), message_text)

  if (toupper(level) %in% c("WARN", "ERROR")) {
    cat(line, file = stderr())
  } else {
    cat(line)
  }
}

log_info <- function(message_text) {
  log_message("info", message_text)
}

log_warn <- function(message_text) {
  log_message("warn", message_text)
}

log_error <- function(message_text) {
  log_message("error", message_text)
}

stop_skill <- function(code, message_text) {
  stop(sprintf("%s: %s", code, message_text), call. = FALSE)
}

validate_output_prefix <- function(output_prefix) {
  if (is.null(output_prefix) || !nzchar(trimws(output_prefix))) {
    stop_skill("SKILL_INVALID_PARAMETER", "--output_prefix must not be empty")
  }

  if (!grepl("^[A-Za-z0-9._-]+$", output_prefix)) {
    stop_skill(
      "SKILL_INVALID_PARAMETER",
      "--output_prefix may only contain letters, numbers, dot, underscore, and hyphen"
    )
  }
}

check_required_packages <- function(required_packages = c("ggplot2", "ggalluvial")) {
  missing_packages <- required_packages[
    !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
  ]

  if (length(missing_packages) > 0) {
    stop_skill(
      "SKILL_DEPENDENCY_MISSING",
      sprintf(
        "Missing required packages: %s. Run Rscript scripts/install_dependencies.R",
        paste(missing_packages, collapse = ", ")
      )
    )
  }
}

infer_separator <- function(input_file) {
  lower_name <- tolower(input_file)
  if (grepl("\\.(tsv|txt)$", lower_name)) {
    return("\t")
  }
  ","
}

read_annotation_table <- function(input_file) {
  if (!file.exists(input_file)) {
    stop_skill("SKILL_FILE_NOT_FOUND", input_file)
  }

  file_info <- file.info(input_file)
  if (is.na(file_info$size) || file_info$size <= 0) {
    stop_skill("SKILL_EMPTY_DATA", "Input file is empty")
  }

  separator <- infer_separator(input_file)
  tryCatch(
    {
      utils::read.table(
        input_file,
        header = TRUE,
        sep = separator,
        check.names = FALSE,
        stringsAsFactors = FALSE,
        quote = '"',
        comment.char = "",
        na.strings = c("", "NA")
      )
    },
    error = function(e) {
      stop_skill("SKILL_INVALID_DATA", conditionMessage(e))
    }
  )
}

ensure_output_dirs <- function(output_dir) {
  dirs <- list(
    root = output_dir,
    table = file.path(output_dir, "table"),
    plot = file.path(output_dir, "plot"),
    data = file.path(output_dir, "data")
  )

  for (dir_path in unname(unlist(dirs))) {
    ok <- dir.create(dir_path, recursive = TRUE, showWarnings = FALSE)
    if (!dir.exists(dir_path) && !ok) {
      stop_skill("SKILL_IO_ERROR", sprintf("Failed to create output directory: %s", dir_path))
    }
    if (file.access(dir_path, mode = 2) != 0) {
      stop_skill("SKILL_IO_ERROR", sprintf("Output directory is not writable: %s", dir_path))
    }
  }

  dirs
}

write_session_info <- function(output_file, parameters) {
  parameter_lines <- c(
    "# Runtime Parameters",
    paste(names(parameters), unlist(parameters), sep = ": "),
    "",
    "# Session Info",
    capture.output(sessionInfo())
  )

  tryCatch(
    {
      writeLines(parameter_lines, output_file)
    },
    error = function(e) {
      stop_skill("SKILL_IO_ERROR", conditionMessage(e))
    }
  )
}
