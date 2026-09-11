#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(optparse))

get_script_dir <- function() {
  cmd_args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", cmd_args, value = TRUE)
  if (length(file_arg) > 0) return(dirname(normalizePath(sub("^--file=", "", file_arg), winslash = "/", mustWork = FALSE)))
  "."
}

script_dir <- get_script_dir()
source(file.path(script_dir, "utils.R"))
source(file.path(script_dir, "recording.R"))
source(file.path(script_dir, "io.R"))
source(file.path(script_dir, "functions.R"))
source(file.path(script_dir, "plot_helpers.R"))
source(file.path(script_dir, "visualization.R"))
source(file.path(script_dir, "cli_options.R"))
source(file.path(script_dir, "run_analysis.R"))
opt <- parse_args(build_option_parser())

required_packages <- c("optparse", "GSVA", "limma", "pheatmap", "grid")

main <- function(opt) {
  opt <- validate_cli_options(opt)
  check_required_packages(required_packages)
  validate_dependency_versions()
  skill_root <- normalizePath(file.path(script_dir, ".."), winslash = "/", mustWork = FALSE)
  opt$output_dir <- resolve_output_dir(opt$output_dir, skill_root)
  start_time <- Sys.time()
  start_proc <- proc.time()
  ensure_dir(opt$output_dir)
  ensure_dir(file.path(opt$output_dir, "data"))
  ensure_dir(file.path(opt$output_dir, "table"))
  ensure_dir(file.path(opt$output_dir, "plot"))
  set.seed(opt$seed)
  enable_timeout(opt$timeout_seconds)
  log_info(sprintf("Mode: %s", opt$mode))
  log_info(sprintf("Output directory: %s", opt$output_dir))
  log_info(sprintf("Seed: %s", opt$seed))
  input_info <- list()
  result_summary <- list(significant_pathways = "N/A", reported_top_pathways = "N/A", fdr_threshold = opt$fdr_threshold, method = opt$method)
  output_items <- list()
  if (opt$mode %in% c("analyze", "full")) {
    required_fields <- c("input_file", "group_file", "geneset_file", "case_group", "control_group")
    for (field_name in required_fields) if (is.null(opt[[field_name]]) || !nzchar(opt[[field_name]])) stop_skill("SKILL_INVALID_PARAMETER", sprintf("--%s is required in %s mode.", field_name, opt$mode))
    analysis_outputs <- run_analysis_mode(opt)
    input_info <- analysis_outputs$input_info
    result_summary <- analysis_outputs$result_summary
    output_items <- c(output_items, list(list(path = analysis_outputs$diff_file, description = "Pathway-level differential results", content = "Columns include geneset, logFC, P.Value, adj.P.Val, t, and B."), list(path = analysis_outputs$scores_file, description = "Full immune pathway score matrix", content = "Rows are pathways and columns are samples."), list(path = analysis_outputs$top_scores_file, description = "Top-pathway score matrix", content = "Subset of pathways selected by top_n and fdr_threshold."), list(path = analysis_outputs$geneset_summary_file, description = "Immune gene-set summary table", content = "One row per retained pathway with unique gene counts."), list(path = analysis_outputs$rds_file, description = "Serialized analysis result object", content = "Saved object used for visualization-only mode.")))
  }
  if (opt$mode %in% c("visualize", "full")) {
    visualization_outputs <- run_visualization_mode(opt)
    if (opt$mode == "visualize") result_summary <- visualization_outputs$result_summary
    output_items <- c(output_items, list(list(path = visualization_outputs$plot_file, description = "Immune pathway heatmap PDF", content = "Heatmap comparing pathway scores between the selected sample groups.")))
  }
  end_time <- Sys.time()
  end_proc <- proc.time()
  runtime_info <- list(start_time = format(start_time, "%Y-%m-%d %H:%M:%S"), end_time = format(end_time, "%Y-%m-%d %H:%M:%S"), elapsed_seconds = as.numeric(difftime(end_time, start_time, units = "secs")), user_cpu_seconds = unname((end_proc - start_proc)[["user.self"]]), system_cpu_seconds = unname((end_proc - start_proc)[["sys.self"]]), gc_snapshot = capture.output(gc()))
  save_session_info(opt$output_dir)
  output_items <- c(output_items, list(list(path = file.path(opt$output_dir, "session_info.txt"), description = "R session and package version record", content = "sessionInfo() output captured at the end of the run.")))
  log_info(sprintf("Output manifest: %s", write_output_manifest(opt$output_dir, output_items, opt, runtime_info)))
  log_info(sprintf("Run record: %s", write_run_record(opt$output_dir, opt, runtime_info, input_info, output_items, result_summary)))
}

tryCatch({ main(opt); log_info("Immune pathway analysis completed successfully.") }, error = function(e) { message(sprintf("[ERROR] %s | %s", timestamp_now(), conditionMessage(e))); quit(status = 1) })
