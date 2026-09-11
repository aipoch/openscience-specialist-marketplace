log_msg <- function(level, msg) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  message(sprintf("[%s] %s | %s", toupper(level), timestamp, msg))
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

parse_feature_genes <- function(feature) {
  check_feature_input(feature)
  tokens <- strsplit(trimws(feature), "[,，；;\\t\\r\\n]+", perl = TRUE)[[1]]
  genes <- trimws(tokens)
  genes <- genes[nzchar(genes)]
  if (length(genes) == 0) skill_stop("SKILL_EMPTY_DATA", "feature contains no valid genes")
  unique(genes)
}

validate_existing_file <- function(path, label = "input file") {
  if (is.null(path) || !nzchar(trimws(path))) skill_stop("SKILL_INVALID_PARAMETER", paste(label, "path is empty"))
  if (!file.exists(path)) skill_stop("SKILL_FILE_NOT_FOUND", paste("File does not exist", path))
  invisible(normalizePath(path, mustWork = TRUE))
}

validate_choice <- function(value, choices, label) {
  if (!value %in% choices) skill_stop("SKILL_INVALID_PARAMETER", paste(label, "must be one of", paste(choices, collapse = ", ")))
}

validate_main_options <- function(opt) {
  validate_choice(opt$gene_type, c("SYMBOL", "ENSEMBL", "ENTREZID"), "gene_type")
  validate_choice(opt$pAdjustMethod, c("BH", "BY", "fdr", "holm", "hochberg", "hommel", "bonferroni", "none"), "pAdjustMethod")
  validate_choice(opt$format, c("pdf", "png", "svg"), "format")
  validate_choice(opt$sorting, c("ascending", "descending"), "sorting")
}

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

csv_has_data_rows <- function(path) {
  if (!file.exists(path)) {
    return(FALSE)
  }

  lines <- tryCatch(
    readLines(path, warn = FALSE),
    error = function(e) character(0)
  )

  length(lines) > 1
}

summarize_result_status <- function(csv_path, rda_path) {
  if (!all(file.exists(c(csv_path, rda_path)))) {
    return("MISSING")
  }

  if (!csv_has_data_rows(csv_path)) {
    return("EMPTY")
  }

  "SUCCESS"
}

emit_run_summary <- function(feature, output_dir, plot_format = "pdf") {
  parsed_genes <- parse_feature_genes(feature)
  temp_dir <- file.path(output_dir, "temp")
  plot_dir <- file.path(output_dir, "plot")
  plot_file <- file.path(plot_dir, paste0("gokegg_dot_chart.", plot_format))
  go_status <- summarize_result_status(
    file.path(temp_dir, "GO_df.csv"),
    file.path(temp_dir, "GO_list.rda")
  )
  kegg_status <- summarize_result_status(
    file.path(temp_dir, "KEGG_df.csv"),
    file.path(temp_dir, "KEGG_list.rda")
  )
  plot_status <- summarize_result_status(
    file.path(plot_dir, "gokegg_dot_chart_data.csv"),
    file.path(plot_dir, "gokegg_dot_chart_data.rda")
  )

  if (!file.exists(plot_file) && plot_status == "SUCCESS") {
    plot_status <- "MISSING"
  }

  key_files <- c(
    file.path(temp_dir, "GO_df.csv"), file.path(temp_dir, "GO_list.rda"),
    file.path(temp_dir, "KEGG_df.csv"), file.path(temp_dir, "KEGG_list.rda"),
    plot_file, file.path(plot_dir, "gokegg_dot_chart_data.csv"),
    file.path(plot_dir, "gokegg_dot_chart_data.rda"),
    file.path(output_dir, "session_info.txt")
  )
  log_info("SUMMARY_BEGIN")
  log_info(paste0("summary.parsed_gene_count=", length(parsed_genes)))
  log_info(paste0("summary.go_status=", go_status))
  log_info(paste0("summary.kegg_status=", kegg_status))
  log_info(paste0("summary.plot_status=", plot_status))
  log_info(paste0("summary.output_dir=", output_dir))
  log_info(paste0("summary.key_files=", paste(key_files[file.exists(key_files)], collapse = ";")))
  log_info("SUMMARY_END")
}

cleanup_temp_files <- function(temp_files) {
  for (f in temp_files)
    if (file.exists(f)) file.remove(f)
}

load_species_db <- function(sp) {
  species_map <- list(
    "org.Hs.eg.db" = list(pkg = "org.Hs.eg.db", obj = "org.Hs.eg.db", kegg_org = "hsa"),
    "org.Mm.eg.db" = list(pkg = "org.Mm.eg.db", obj = "org.Mm.eg.db", kegg_org = "mmu"),
    "org.Rn.eg.db" = list(pkg = "org.Rn.eg.db", obj = "org.Rn.eg.db", kegg_org = "rno")
  )
  info <- species_map[[sp]]
  if (is.null(info)) skill_stop("SKILL_INVALID_PARAMETER", paste("Unsupported species database", sp))
  if (!require(info$pkg, character.only = TRUE, quietly = TRUE)) skill_stop("SKILL_PACKAGE_NOT_FOUND", paste("Please install", info$pkg))
  library(info$pkg, character.only = TRUE, quietly = TRUE)
  info$db <- get(info$obj, envir = asNamespace(info$pkg))
  info
}

save_analysis_outputs <- function(obj, csv_df, prefix, output_dir,
                                  csv_suffix = "_df.csv",
                                  rda_suffix = "_list.rda",
                                  object_name = prefix) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  csv_path <- file.path(output_dir, paste0(prefix, csv_suffix))
  rda_path <- file.path(output_dir, paste0(prefix, rda_suffix))

  e <- new.env()
  assign(object_name, obj, envir = e)

  write.csv(csv_df, csv_path, row.names = FALSE)
  save(list = object_name, envir = e, file = rda_path)

  log_info(paste(prefix, "results saved to:", csv_path))
  log_info(paste(prefix, "results saved to:", rda_path))
  invisible(list(csv = csv_path, rda = rda_path))
}
