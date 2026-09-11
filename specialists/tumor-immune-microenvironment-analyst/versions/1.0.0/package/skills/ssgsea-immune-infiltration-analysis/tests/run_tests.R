#!/usr/bin/env Rscript
cmd_args <- commandArgs(trailingOnly = FALSE)
file_arg_idx <- which(grepl("^--file=", cmd_args))
script_file <- if (length(file_arg_idx) > 0) sub("^--file=", "", cmd_args[file_arg_idx[1]]) else "tests/run_tests.R"
script_dir <- normalizePath(dirname(script_file), winslash = "/", mustWork = FALSE)
skill_root <- normalizePath(file.path(script_dir, ".."), winslash = "/", mustWork = FALSE)
output_dir <- file.path(skill_root, "tests", "output")
main_script <- file.path(skill_root, "scripts", "main.R")
group_file <- file.path(skill_root, "tests", "data", "group_info.csv")

trim_ws <- function(x) {
  gsub("^\\s+|\\s+$", "", as.character(x))
}

resolve_case_control_groups <- function(group_file) {
  group_df <- read.csv(group_file, stringsAsFactors = FALSE, check.names = FALSE)
  if (!all(c("sample", "group") %in% colnames(group_df))) {
    stop("tests/data/group_info.csv must contain sample and group columns.", call. = FALSE)
  }

  groups <- unique(trim_ws(group_df$group))
  groups <- groups[!is.na(groups) & groups != ""]
  if (length(groups) < 2) {
    stop("At least two non-empty groups are required in tests/data/group_info.csv.", call. = FALSE)
  }

  lower_groups <- tolower(groups)
  case_priority <- c("tumor", "treatment", "case", "disease", "patient")
  control_priority <- c("healthy", "normal", "control", "adjacent")

  case_idx <- match(TRUE, lower_groups %in% case_priority, nomatch = 0)
  control_idx <- match(TRUE, lower_groups %in% control_priority, nomatch = 0)

  if (case_idx > 0 && control_idx > 0 && case_idx != control_idx) {
    return(list(case_group = groups[case_idx], control_group = groups[control_idx]))
  }

  return(list(case_group = groups[1], control_group = groups[2]))
}

resolved_groups <- resolve_case_control_groups(group_file)

cmd <- c(
  main_script,
  "-i", file.path(skill_root, "tests", "data", "expression_matrix.csv"),
  "-g", group_file,
  "-e", file.path(skill_root, "tests", "data", "immune_gene_sets.csv"),
  "-a", resolved_groups$case_group,
  "-b", resolved_groups$control_group,
  "-o", output_dir
)
status <- system2("Rscript", cmd)
if (status != 0) quit(status = status)

source(file.path(skill_root, "scripts", "utils.R"))
source(file.path(skill_root, "scripts", "visualization.R"))
source(file.path(skill_root, "scripts", "io.R"))
source(file.path(skill_root, "scripts", "functions.R"))
scores_long <- read.csv(file.path(output_dir, "table", "ssgsea_scores_long.csv"), stringsAsFactors = FALSE, check.names = FALSE)
if (!all(c("cell_type", "sample", "ssgsea_score", "group") %in% colnames(scores_long))) {
  stop("ssgsea_scores_long.csv is missing required columns.", call. = FALSE)
}
group_compare <- read.csv(file.path(output_dir, "table", "ssgsea_group_compare.csv"), stringsAsFactors = FALSE, check.names = FALSE)
if (!all(c("cell_type", "p_value", "p_adj", "test_method") %in% colnames(group_compare))) {
  stop("ssgsea_group_compare.csv is missing required columns.", call. = FALSE)
}
ssgsea_list <- readRDS(file.path(output_dir, "data", "ssgsea_list.rds"))
if (!is.list(ssgsea_list) || is.null(ssgsea_list$scores) || is.null(ssgsea_list$group)) {
  stop("ssgsea_list.rds is missing required result entries.", call. = FALSE)
}
cor_check <- calc_correlation_tables(ssgsea_list$scores)
if (!identical(dim(cor_check$cor_mat), dim(cor_check$p_mat))) {
  stop("Correlation matrix and p-value matrix dimensions do not match.", call. = FALSE)
}
plot_correlation_heatmap(
  cor_mat = as.matrix(read.csv(file.path(output_dir, "table", "immune_cell_correlation_matrix.csv"), row.names = 1, check.names = FALSE)),
  p_mat = as.matrix(read.csv(file.path(output_dir, "table", "immune_cell_correlation_pvalue.csv"), row.names = 1, check.names = FALSE)),
  cell_anno = unique(scores_long[, c("cell_type", "cell_type_label")]),
  output_dir = output_dir,
  filename = "reused_heatmap.pdf"
)
quit(status = 0)
