timestamp_now <- function() {
  format(Sys.time(), "%Y-%m-%d %H:%M:%S")
}

or_default <- function(x, y) {
  if (is.null(x) || length(x) == 0 || all(is.na(x))) y else x
}

trim_ws <- function(x) {
  gsub("^\\s+|\\s+$", "", as.character(x))
}

log_message <- function(level, message, verbose = TRUE) {
  line <- sprintf("[%s] %s | %s", level, timestamp_now(), message)
  if (isTRUE(verbose) || identical(level, "ERROR")) {
    cat(line, "\n", sep = "")
  }
  invisible(line)
}

log_info <- function(message, verbose = TRUE) {
  log_message("INFO", message, verbose = verbose)
}

log_warn <- function(message, verbose = TRUE) {
  log_message("WARN", message, verbose = verbose)
}

skill_stop <- function(code, message) {
  stop(sprintf("%s: %s", code, message), call. = FALSE)
}

as_bool <- function(x, default = FALSE, arg_name = "boolean argument") {
  if (is.null(x) || length(x) == 0 || anyNA(x)) {
    return(default)
  }
  if (is.logical(x)) {
    return(x)
  }
  value <- tolower(trim_ws(x))
  if (value %in% c("true", "t", "1", "yes", "y")) {
    return(TRUE)
  }
  if (value %in% c("false", "f", "0", "no", "n")) {
    return(FALSE)
  }
  skill_stop(
    "SKILL_INVALID_PARAMETER",
    sprintf("%s must be a boolean value such as true/false.", arg_name)
  )
}

ensure_dir <- function(path) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
}

check_required_packages <- function(packages) {
  missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing) > 0) {
    skill_stop(
      "SKILL_PACKAGE_NOT_FOUND",
      sprintf("Missing required packages: %s", paste(missing, collapse = ", "))
    )
  }
}

normalize_gene_id <- function(x, mode = "upper") {
  x <- trim_ws(x)
  if (mode == "upper") {
    return(toupper(x))
  }
  if (mode == "lower") {
    return(tolower(x))
  }
  x
}

sanitize_filename <- function(x) {
  x <- trim_ws(x)
  x <- gsub("[[:space:]]+", "_", x)
  x <- gsub("[^A-Za-z0-9_\\-]", "_", x)
  x <- gsub("_+", "_", x)
  gsub("^_|_$", "", x)
}

resolve_name_or_index <- function(df, value, candidates, label) {
  if (!is.null(value)) {
    if (is.numeric(value)) {
      idx <- as.integer(value)
      if (idx < 1 || idx > ncol(df)) {
        skill_stop("SKILL_INVALID_PARAMETER", sprintf("Invalid %s column index.", label))
      }
      return(colnames(df)[idx])
    }
    if (!(value %in% colnames(df))) {
      skill_stop("SKILL_MISSING_COLUMNS", sprintf("%s column '%s' was not found.", label, value))
    }
    return(value)
  }
  hit <- candidates[candidates %in% colnames(df)]
  if (length(hit) == 0) {
    skill_stop("SKILL_MISSING_COLUMNS", sprintf("No supported %s column was found.", label))
  }
  hit[[1]]
}

safe_cor_test <- function(x, y, method = "spearman") {
  ok <- is.finite(x) & is.finite(y)
  x <- x[ok]
  y <- y[ok]
  if (length(x) < 3 || length(unique(x)) < 2 || length(unique(y)) < 2) {
    return(c(cor = NA_real_, p = NA_real_))
  }
  res <- suppressWarnings(stats::cor.test(x, y, method = method, exact = FALSE))
  c(cor = unname(res$estimate), p = res$p.value)
}

write_session_info <- function(output_dir) {
  capture.output(sessionInfo(), file = file.path(output_dir, "session_info.txt"))
}
