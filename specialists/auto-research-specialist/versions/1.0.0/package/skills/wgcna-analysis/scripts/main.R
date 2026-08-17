#!/usr/bin/env Rscript

required_packages <- c("optparse", "WGCNA", "data.table")

get_script_dir <- function() {
  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", cmd_args, value = TRUE)
  if (length(file_arg) > 0) {
    return(dirname(normalizePath(sub("^--file=", "", file_arg[1]))))
  }
  "."
}

script_dir <- get_script_dir()
source(file.path(script_dir, "utils.R"))
source(file.path(script_dir, "functions.R"))
source(file.path(script_dir, "wgcna_core.R"))
source(file.path(script_dir, "wgcna_selection.R"))
source(file.path(script_dir, "io.R"))
source(file.path(script_dir, "chunk_io.R"))
source(file.path(script_dir, "plotting.R"))
source(file.path(script_dir, "run_analysis.R"))

check_pkgs(required_packages)

option_list <- list(
  optparse::make_option(c("-i", "--input_file"), type = "character", default = NULL, help = "Expression matrix file, genes as rows and samples as columns [required]", metavar = "file"),
  optparse::make_option(c("-g", "--group_file"), type = "character", default = NULL, help = "Sample-to-group mapping file [required]", metavar = "file"),
  optparse::make_option(c("-o", "--output_dir"), type = "character", default = "./output/", help = "Output directory [default %default]", metavar = "dir"),
  optparse::make_option(c("-a", "--sample_column"), type = "character", default = "sample", help = "Sample column in group file; falls back to first column if not found [default %default]"),
  optparse::make_option(c("-b", "--group_column"), type = "character", default = "group", help = "Group column in group file; falls back to second column if not found [default %default]"),
  optparse::make_option(c("-n", "--network_type"), type = "character", default = "unsigned", help = "Network type: unsigned or signed [default %default]"),
  optparse::make_option(c("-c", "--cor_type"), type = "character", default = "pearson", help = "Correlation type: pearson or bicor [default %default]"),
  optparse::make_option(c("-q", "--mad_quantile"), type = "double", default = 0.25, help = "MAD quantile used as the variability cutoff [default %default]"),
  optparse::make_option(c("-m", "--min_mad"), type = "double", default = 0.01, help = "Minimum MAD cutoff applied with the quantile filter [default %default]"),
  optparse::make_option(c("-k", "--max_genes"), type = "integer", default = 0, help = "Optional cap on retained variable genes; 0 keeps all filtered genes [default %default]"),
  optparse::make_option(c("-p", "--min_module_size"), type = "integer", default = 30, help = "Minimum module size for blockwiseModules [default %default]"),
  optparse::make_option(c("-r", "--merge_cut_height"), type = "double", default = 0.25, help = "Merge cut height for module merging [default %default]"),
  optparse::make_option(c("-u", "--soft_r2_cutoff"), type = "double", default = 0.85, help = "Target scale-free topology R^2 cutoff used for pickSoftThreshold [default %default]"),
  optparse::make_option(c("-t", "--trait_of_interest"), type = "character", default = NULL, help = "Trait column used for module-gene scatter plot; defaults to the first trait column"),
  optparse::make_option(c("-x", "--module_of_interest"), type = "character", default = "auto", help = "Module color or comma-separated module colors to export; use auto to rank by trait correlation [default %default]"),
  optparse::make_option(c("--top_modules"), type = "integer", default = 1, help = "When module_of_interest=auto, export the top N modules ranked by absolute module-trait correlation [default %default]"),
  optparse::make_option(c("-y", "--tom_sample_size"), type = "integer", default = 400, help = "Number of genes sampled for TOM heatmap [default %default]"),
  optparse::make_option(c("--chunk_size"), type = "integer", default = 0, help = "Optional row chunk size for large expression matrices; 0 disables chunked loading [default %default]"),
  optparse::make_option(c("-s", "--seed"), type = "integer", default = 42, help = "Random seed [default %default]"),
  optparse::make_option(c("-z", "--timeout_seconds"), type = "integer", default = 0, help = "Optional elapsed-time limit in seconds, 0 disables timeout [default %default]")
)

main <- function() {
  parser <- optparse::OptionParser(option_list = option_list, description = "WGCNA analysis")
  opt <- optparse::parse_args(parser)

  validate_main_options(opt)
  apply_time_limit(opt$timeout_seconds)
  set.seed(opt$seed)

  ensure_dir(opt$output_dir)
  on.exit(save_session_info(opt$output_dir), add = TRUE)

  log_header("WGCNA Analysis")
  log_option_summary(opt)

  run_wgcna_analysis(opt)

  log_info("WGCNA analysis completed successfully")
}

run_main(main)
