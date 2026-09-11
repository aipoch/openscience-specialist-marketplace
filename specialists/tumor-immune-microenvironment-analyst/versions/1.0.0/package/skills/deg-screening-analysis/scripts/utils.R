log_msg <- function(level, msg, stream = stdout()) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  cat(sprintf("[%s] %s: %s\n", timestamp, toupper(level), msg), file = stream)
}

log_info <- function(msg) log_msg("INFO", msg, stdout())
log_warn <- function(msg) log_msg("WARN", msg, stderr())
log_error <- function(msg) log_msg("ERROR", msg, stderr())

skill_stop <- function(code, msg) stop(sprintf("%s: %s", code, msg), call. = FALSE)

check_pkg <- function(pkg, min_ver = NULL) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    skill_stop("SKILL_PACKAGE_NOT_FOUND", paste("Missing required package", pkg))
  }
  suppressPackageStartupMessages(library(pkg, character.only = TRUE, warn.conflicts = FALSE))
  if (!is.null(min_ver) && packageVersion(pkg) < min_ver) {
    skill_stop("SKILL_INVALID_PARAMETER", paste(pkg, "needs >=", min_ver))
  }
}

check_file_exists <- function(path, label = "file") {
  if (is.null(path) || !nzchar(path) || !file.exists(path)) {
    skill_stop("SKILL_FILE_NOT_FOUND", paste(label, "does not exist:", path))
  }
  invisible(TRUE)
}

ensure_dir <- function(path) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  invisible(path)
}

save_session_info <- function(output_dir) {
  ensure_dir(output_dir)
  session_file <- file.path(output_dir, "session_info.txt")
  writeLines(capture.output(sessionInfo()), session_file)
  log_info(paste("Session info saved to:", session_file))
}

validate_thresholds <- function(p_threshold, logfc_threshold, top_n, timeout_seconds) {
  if (!is.numeric(p_threshold) || length(p_threshold) != 1 || p_threshold <= 0 || p_threshold >= 1) {
    skill_stop("SKILL_INVALID_PARAMETER", "p_threshold must be a number between 0 and 1")
  }
  if (!is.numeric(logfc_threshold) || length(logfc_threshold) != 1 || logfc_threshold < 0) {
    skill_stop("SKILL_INVALID_PARAMETER", "logfc_threshold must be a non-negative number")
  }
  if (!is.numeric(top_n) || length(top_n) != 1 || top_n < 1) {
    skill_stop("SKILL_INVALID_PARAMETER", "top_n must be a positive integer")
  }
  if (!is.numeric(timeout_seconds) || length(timeout_seconds) != 1 || timeout_seconds <= 0) {
    skill_stop("SKILL_INVALID_PARAMETER", "timeout_seconds must be a positive integer")
  }
  invisible(TRUE)
}

match_group_name <- function(target, choices) {
  idx <- which(tolower(trimws(choices)) == tolower(trimws(target)))
  if (length(idx) == 0) return(NA_character_)
  choices[idx[1]]
}

validate_groups <- function(group_df, case_name, control_name, min_per_group = 2) {
  groups <- trimws(as.character(group_df[[2]]))
  group_counts <- table(groups)
  if (length(group_counts) < 2) {
    skill_stop("SKILL_INVALID_PARAMETER", "At least 2 groups are required")
  }
  case_matched <- match_group_name(case_name, names(group_counts))
  control_matched <- match_group_name(control_name, names(group_counts))
  if (is.na(case_matched) || is.na(control_matched)) {
    skill_stop("SKILL_INVALID_PARAMETER", paste0(
      "case/control groups do not match the group file; available groups: ",
      paste(names(group_counts), collapse = ", ")
    ))
  }
  if (tolower(case_matched) == tolower(control_matched)) {
    skill_stop("SKILL_INVALID_PARAMETER", "case and control cannot be the same")
  }
  selected_counts <- group_counts[c(control_matched, case_matched)]
  if (any(selected_counts < min_per_group)) {
    skill_stop("SKILL_INVALID_PARAMETER", paste("Each selected group must have at least", min_per_group, "samples"))
  }
  list(case = case_matched, control = control_matched)
}

parse_group_columns <- function(group_df) {
  validate_non_empty(group_df, "Group file")
  if (ncol(group_df) < 2) {
    skill_stop("SKILL_MISSING_COLUMNS", "Group file must contain at least two columns")
  }

  col_names <- tolower(trimws(colnames(group_df)))
  sample_aliases <- c("sample", "sample_id", "sampleid", "id", "sample_name")
  group_aliases <- c("group", "group_name", "condition", "class", "type")
  sample_col <- which(col_names %in% sample_aliases)
  group_col <- which(col_names %in% group_aliases)

  if (length(sample_col) > 0 && length(group_col) > 0) {
    return(list(sample = sample_col[1], group = group_col[1]))
  }

  log_warn("Group file header not matched to standard aliases; fallback to the first two columns as sample/group")
  list(sample = 1, group = 2)
}

validate_non_empty <- function(df, label) {
  if (is.null(df) || nrow(df) == 0 || ncol(df) == 0) {
    skill_stop("SKILL_EMPTY_DATA", paste(label, "is empty"))
  }
  invisible(TRUE)
}


detect_group_columns <- function(group_df, expr_sample_names, case_name, control_name) {
  validate_non_empty(group_df, "Group file")
  if (ncol(group_df) < 2) {
    skill_stop("SKILL_MISSING_COLUMNS", "Group file must contain at least two columns")
  }

  expr_sample_names <- trimws(as.character(expr_sample_names))
  case_name <- trimws(case_name)
  control_name <- trimws(control_name)
  col_names <- tolower(trimws(colnames(group_df)))
  sample_aliases <- c("sample", "sample_id", "sampleid", "id", "sample_name")
  group_aliases <- c("group", "group_name", "condition", "class", "type")

  sample_score <- vapply(seq_len(ncol(group_df)), function(i) {
    vals <- trimws(as.character(group_df[[i]]))
    alias_bonus <- ifelse(col_names[i] %in% sample_aliases, 1000, 0)
    alias_bonus + sum(vals %in% expr_sample_names, na.rm = TRUE)
  }, numeric(1))

  group_score <- vapply(seq_len(ncol(group_df)), function(i) {
    vals <- tolower(trimws(as.character(group_df[[i]])))
    alias_bonus <- ifelse(col_names[i] %in% group_aliases, 1000, 0)
    alias_bonus + sum(vals %in% tolower(c(case_name, control_name)), na.rm = TRUE)
  }, numeric(1))

  sample_col <- which.max(sample_score)
  group_candidates <- setdiff(seq_len(ncol(group_df)), sample_col)
  if (length(group_candidates) == 0) {
    skill_stop("SKILL_MISSING_COLUMNS", "Unable to identify both sample and group columns")
  }
  group_col <- group_candidates[which.max(group_score[group_candidates])]

  if (sample_score[sample_col] <= 0) {
    log_warn("Sample column not confidently matched by header; using best-overlap column")
  }
  if (group_score[group_col] <= 0) {
    log_warn("Group column not confidently matched by header/value; using best candidate column")
  }

  list(sample = sample_col, group = group_col)
}

with_timeout <- function(expr, timeout_seconds) {
  setTimeLimit(elapsed = timeout_seconds, transient = TRUE)
  on.exit(setTimeLimit(cpu = Inf, elapsed = Inf, transient = FALSE), add = TRUE)
  tryCatch(
    force(expr),
    error = function(e) {
      msg <- conditionMessage(e)
      if (grepl("reached elapsed time limit", msg, fixed = TRUE) || grepl("time limit", msg, ignore.case = TRUE)) {
        skill_stop("SKILL_TIMEOUT", paste("Computation exceeded", timeout_seconds, "seconds"))
      }
      stop(e)
    }
  )
}
