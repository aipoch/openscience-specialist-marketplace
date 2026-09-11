#!/usr/bin/env Rscript
REQUIRED_PACKAGES <- c("optparse", "data.table", "ConsensusClusterPlus")
missing_packages <- REQUIRED_PACKAGES[!vapply(REQUIRED_PACKAGES, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0L)
  stop(sprintf("SKILL_DEPENDENCY_MISSING: %s", paste(missing_packages, collapse = ", ")))
suppressPackageStartupMessages(library(optparse))

get_script_dir <- function() {
  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_arg_idx <- which(grepl("^--file=", cmd_args))
  if (length(file_arg_idx) > 0) {
    arg0 <- sub("^--file=", "", cmd_args[file_arg_idx])
    if (!is.na(arg0) && nzchar(arg0) && file.exists(arg0))
      return(dirname(normalizePath(arg0)))
  }
  "."
}

script_dir <- get_script_dir()
source(file.path(script_dir, "utils.R"))
source(file.path(script_dir, "io_utils.R"))
source(file.path(script_dir, "functions_analysis.R"))
source(file.path(script_dir, "visualization.R"))
source(file.path(script_dir, "run_analysis.R"))

option_list <- list(
  make_option(c("-i", "--input_file"), type = "character", default = NULL,
              help = "Expression matrix file (genes x samples) [required]", metavar = "file"),
  make_option(c("-g", "--group_file"), type = "character", default = NULL,
              help = "Group file with sample and group columns [required]", metavar = "file"),
  make_option(c("-d", "--disease_group"), type = "character", default = "case",
              help = "Group label retained for clustering [default %default]"),
  make_option(c("-k", "--max_k"), type = "integer", default = 4,
              help = "Maximum cluster count to evaluate [default %default]"),
  make_option(c("-o", "--output_dir"), type = "character", default = "./output/",
              help = "Output directory [default %default]", metavar = "dir"),
  make_option(c("-m", "--gene_selection"), type = "character", default = "highly_variable",
              help = "Gene selection mode: highly_variable or custom [default %default]"),
  make_option(c("-n", "--top_n"), type = "integer", default = 5000,
              help = "Top variable genes to keep [default %default]"),
  make_option(c("-l", "--gene_list"), type = "character", default = NULL,
              help = "Custom gene list file when gene_selection=custom"),
  make_option(c("-c", "--center_data"), type = "logical", default = TRUE,
              help = "Median-center genes before clustering [default %default]"),
  make_option(c("-r", "--reps"), type = "integer", default = 1000,
              help = "Consensus resampling repetitions [default %default]"),
  make_option(c("--p_item"), type = "double", default = 0.8,
              help = "Sample resampling proportion [default %default]"),
  make_option(c("--p_feature"), type = "double", default = 1.0,
              help = "Feature resampling proportion [default %default]"),
  make_option(c("-t", "--timeout_seconds"), type = "integer", default = 3600,
              help = "Elapsed timeout in seconds [default %default]"),
  make_option(c("-s", "--seed"), type = "integer", default = 42,
              help = "Random seed [default %default]")
)

parser <- OptionParser(option_list = option_list,
                       description = "Consensus clustering analysis with PAC-based model selection")

log_run_options <- function(opt) {
  log_info("==========================================")
  log_info("Consensus Clustering Analysis")
  log_info("==========================================")
  log_info(sprintf("Input file: %s", opt$input_file))
  log_info(sprintf("Group file: %s", opt$group_file))
  log_info(sprintf("Disease group: %s", opt$disease_group))
  log_info(sprintf("max_k: %d", opt$max_k))
  log_info(sprintf("Gene selection: %s", opt$gene_selection))
  log_info(sprintf("Output directory: %s", opt$output_dir))
  log_info(sprintf("Timeout (seconds): %d", opt$timeout_seconds))
  log_info(sprintf("Seed: %d", opt$seed))
}

prepare_runtime <- function(opt) {
  check_runtime_packages(REQUIRED_PACKAGES)
  ensure_dir(opt$output_dir)
  validate_cli_options(opt)
  warn_if_output_dir_nonempty(opt$output_dir)
  set.seed(opt$seed)
  apply_timeout(opt$timeout_seconds)
}

execute_analysis <- function(opt) {
  result <- run_consensus_analysis(opt)
  log_info("Analysis completed.")
  log_info(sprintf("Optimal model: %s %s K=%d PAC=%.4f",
                   result$optimal$dist, result$optimal$clusterAlg,
                   result$optimal$bestK, result$optimal$PAC))
  log_info(sprintf("Output directory: %s", normalizePath(opt$output_dir)))
  0L
}

run_cli <- function() {
  opt <- tryCatch({
    parse_args(parser)
  }, error = function(e) {
    log_error(sprintf("SKILL_INVALID_PARAMETER: %s", conditionMessage(e)))
    NULL
  })
  if (is.null(opt))
    return(1L)
  if (is.null(opt$input_file) || is.null(opt$group_file)) {
    log_error("SKILL_INVALID_PARAMETER: --input_file and --group_file are required.")
    print_help(parser)
    return(1L)
  }
  on.exit(save_session_info(opt$output_dir), add = TRUE)
  on.exit(release_timeout(), add = TRUE)

  tryCatch({
    prepare_runtime(opt)
    log_run_options(opt)
    execute_analysis(opt)
  }, error = function(e) {
    log_error(classify_runtime_error(e))
    1L
  })
}

quit(status = run_cli())
