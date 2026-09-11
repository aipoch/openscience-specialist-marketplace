get_skill_root <- function(script_dir) {
  normalizePath(file.path(script_dir, ".."), winslash = "/", mustWork = TRUE)
}

ensure_dir <- function(path) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  invisible(path)
}

canonicalize_path <- function(path) {
  normalized <- gsub("\\\\", "/", path)
  prefix <- ""
  if (grepl("^[A-Za-z]:/", normalized)) {
    prefix <- substr(normalized, 1, 2)
    normalized <- substr(normalized, 4, nchar(normalized))
  } else if (startsWith(normalized, "/")) {
    prefix <- "/"
    normalized <- substring(normalized, 2)
  }

  parts <- strsplit(normalized, "/", fixed = TRUE)[[1]]
  stack <- character(0)
  for (part in parts) {
    if (!nzchar(part) || identical(part, ".")) next
    if (identical(part, "..")) {
      if (length(stack) > 0 && tail(stack, 1) != "..") {
        stack <- head(stack, -1)
      } else if (!identical(prefix, "/")) {
        stack <- c(stack, part)
      }
    } else {
      stack <- c(stack, part)
    }
  }

  suffix <- paste(stack, collapse = "/")
  if (identical(prefix, "/")) return(if (nzchar(suffix)) paste0("/", suffix) else "/")
  if (nzchar(prefix)) return(if (nzchar(suffix)) paste0(prefix, "/", suffix) else paste0(prefix, "/"))
  if (nzchar(suffix)) suffix else "."
}

starts_with_path <- function(path, root_path) {
  normalized_path <- canonicalize_path(path)
  normalized_root <- canonicalize_path(root_path)
  identical(normalized_path, normalized_root) ||
    startsWith(normalized_path, paste0(normalized_root, "/"))
}

resolve_existing_input <- function(path, label) {
  if (is.null(path) || !nzchar(trimws(path))) {
    fail("SKILL_INVALID_PARAMETER", sprintf("%s is required.", label))
  }
  normalized <- normalizePath(trimws(path), winslash = "/", mustWork = FALSE)
  if (!file.exists(normalized)) {
    fail("SKILL_FILE_NOT_FOUND", sprintf("%s does not exist: %s", label, path))
  }
  normalizePath(normalized, winslash = "/", mustWork = TRUE)
}

resolve_output_dir <- function(output_dir, skill_root) {
  if (is.null(output_dir) || !nzchar(trimws(output_dir))) {
    fail("SKILL_INVALID_PARAMETER", "--output_dir must not be empty.")
  }
  candidate <- if (grepl("^([A-Za-z]:)?[/\\]", output_dir)) output_dir else file.path(skill_root, output_dir)
  normalized <- canonicalize_path(candidate)
  if (!starts_with_path(normalized, skill_root)) {
    fail("SKILL_INVALID_PARAMETER", sprintf("Output directory must stay inside the skill root: %s", skill_root))
  }
  normalized
}
