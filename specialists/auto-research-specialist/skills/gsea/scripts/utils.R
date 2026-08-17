log_msg <- function(level, msg) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  message(sprintf("[%s]  %s | %s", toupper(level), timestamp, msg))
}

log_info <- function(msg) log_msg("INFO", msg)
log_error <- function(msg) log_msg("ERROR", msg)
log_warn <- function(msg) log_msg("WARN", msg)

skill_stop <- function(code, msg) stop(sprintf("%s: %s", code, msg), call. = FALSE)
skill_warn <- function(code, msg) warning(sprintf("%s: %s", code, msg), call. = FALSE)

check_pkg <- function(pkg, min_ver = NULL) {
  if (!requireNamespace(pkg, quietly = TRUE)) skill_stop("SKILL_PACKAGE_NOT_FOUND", paste("Required package is not installed", pkg))
  library(pkg, character.only = TRUE, warn.conflicts = FALSE)
  if (!is.null(min_ver) && packageVersion(pkg) < min_ver) skill_stop("SKILL_INVALID_PARAMETER", paste("Package version is incompatible", pkg, "needs >=", min_ver))
}

check_pkgs <- function(pkgs) invisible(lapply(pkgs, check_pkg))

check_feature_input <- function(feature) {
  if (is.null(feature) || !nzchar(trimws(feature))) skill_stop("SKILL_INVALID_PARAMETER", "--feature is required")
  invisible(TRUE)
}

validate_existing_file <- function(path, label = "input file") {
  if (is.null(path) || !nzchar(trimws(path))) skill_stop("SKILL_INVALID_PARAMETER", paste(label, "path is empty"))
  if (!file.exists(path)) skill_stop("SKILL_FILE_NOT_FOUND", paste("File does not exist", path))
  invisible(normalizePath(path, mustWork = TRUE))
}

validate_choice <- function(value, choices, label) {
  if (!value %in% choices) skill_stop("SKILL_INVALID_PARAMETER", paste(label, "must be one of", paste(choices, collapse = ", ")))
}

validate_timeout_value <- function(timeout_seconds) {
  if (is.null(timeout_seconds) || is.na(timeout_seconds)) {
    skill_stop("SKILL_INVALID_PARAMETER", "timeout must not be NA")
  }
  if (!is.numeric(timeout_seconds)) {
    skill_stop("SKILL_INVALID_PARAMETER", "timeout must be numeric")
  }
  invisible(TRUE)
}

# GSEA-specific validation functions
validate_gsea_options <- function(opt) {
  # Validate species
  valid_species <- c("human", "mouse", "rat")
  validate_choice(opt$species, valid_species, "species")
  
  # Validate gene set type
  valid_types <- c("KEGG", "HALLMARKS", "GO_BP", "GO_MF", "GO_CC")
  validate_choice(opt$type, valid_types, "type")
  
  # Validate method
  valid_methods <- c("fgsea", "DOSE")
  validate_choice(opt$method, valid_methods, "method")
  
  # Validate p-value cutoff
  if (!is.numeric(opt$pvalue_cutoff) || opt$pvalue_cutoff <= 0 || opt$pvalue_cutoff > 1) {
    skill_stop("SKILL_INVALID_PARAMETER", "pvalue_cutoff must be between 0 and 1")
  }
  
  # Validate chunk size
  if (!is.numeric(opt$chunk_size) || opt$chunk_size <= 0) {
    skill_stop("SKILL_INVALID_PARAMETER", "chunk_size must be greater than 0")
  }
  
  invisible(TRUE)
}

# Function to load required packages for GSEA
load_gsea_packages <- function() {
  required_packages <- c(
    "clusterProfiler",
    "GSEABase",
    "msigdbr",
    "fgsea",
    "dplyr",
    "doParallel",
    "enrichplot",
    "DOSE",
    "foreach",
    "parallel"
  )
  
  log_info("Loading required packages for GSEA analysis...")
  
  for (pkg in required_packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      skill_stop("SKILL_PACKAGE_NOT_FOUND", paste("Required package not installed:", pkg))
    }
    suppressPackageStartupMessages(library(pkg, character.only = TRUE))
  }
  
  log_info("All required packages loaded successfully")
}

# Function to save session info
save_session_info <- function(output_dir) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  session_file <- file.path(output_dir, "session_info.txt")
  
  si <- sessionInfo()
  loaded_pkgs <- c(si$otherPkgs, si$loadedOnly)
  loaded_pkg_lines <- if (length(loaded_pkgs) > 0) {
    vapply(names(loaded_pkgs), function(pkg) {
      sprintf("- %s: %s", pkg, as.character(loaded_pkgs[[pkg]]$Version))
    }, character(1))
  } else {
    "- None"
  }
  
  lines <- c(
    sprintf("R version: %s", R.version.string),
    sprintf("Platform: %s", R.version$platform),
    sprintf("Date: %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
    "",
    "Loaded package versions:",
    loaded_pkg_lines,
    "",
    "Full sessionInfo():",
    capture.output(sessionInfo())
  )
  
  writeLines(lines, session_file)
  log_info(paste("Session info saved to:", session_file))
}

# Function to check if CSV has data rows
csv_has_data_rows <- function(path) {
  if (!file.exists(path)) {
    return(FALSE)
  }
  
  lines <- tryCatch(
    readLines(path, warn = FALSE, n = 2),
    error = function(e) character(0)
  )
  
  length(lines) > 1
}

# Function to summarize result status
summarize_result_status <- function(csv_path, rda_path) {
  if (!all(file.exists(c(csv_path, rda_path)))) {
    return("MISSING")
  }
  
  if (!csv_has_data_rows(csv_path)) {
    return("EMPTY")
  }
  
  "SUCCESS"
}

# Function to emit run summary
emit_run_summary <- function(opt) {
  temp_dir <- file.path(opt$outdir, "data")
  table_dir <- file.path(opt$outdir, "Table")
  
  gsea_status <- summarize_result_status(
    file.path(table_dir, "enrichGSEA.csv"),
    file.path(temp_dir, "GSEA_list.rda")
  )
  
  running_score_status <- summarize_result_status(
    file.path(table_dir, "gsea_running_scores.csv"),
    file.path(temp_dir, "GSEA_list.rda")
  )
  
  key_files <- c(
    file.path(temp_dir, "GSEA_list.rda"),
    file.path(table_dir, "enrichGSEA.csv"),
    file.path(table_dir, "gsea_running_scores.csv"),
    file.path(opt$outdir, "session_info.txt")
  )
  
  log_info("SUMMARY_BEGIN")
  log_info(paste0("summary.output_dir=", opt$outdir))
  log_info(paste0("summary.species=", opt$species))
  log_info(paste0("summary.gene_set_type=", opt$type))
  log_info(paste0("summary.method=", opt$method))
  log_info(paste0("summary.gsea_status=", gsea_status))
  log_info(paste0("summary.running_score_status=", running_score_status))
  log_info(paste0("summary.key_files=", paste(key_files[file.exists(key_files)], collapse = ";")))
  log_info("SUMMARY_END")
}

# Function to cleanup temporary files
cleanup_temp_files <- function(temp_files) {
  for (f in temp_files)
    if (file.exists(f)) file.remove(f)
}