#!/usr/bin/env Rscript

read_expression_matrix <- function(path) {
  validate_existing_file(path, "input_file")
  exp_df <- read_delimited_table(path, row_names = TRUE)
  if (nrow(exp_df) < 2 || ncol(exp_df) < 2) stop_skill("SKILL_EMPTY_DATA", "Expression matrix must contain at least 2 genes and 2 samples.")
  exp_mat <- as.matrix(exp_df)
  suppressWarnings(storage.mode(exp_mat) <- "double")
  if (any(is.na(exp_mat))) stop_skill("SKILL_EMPTY_DATA", "Expression matrix contains NA or non-numeric values.")
  exp_mat
}

read_group_file <- function(path) {
  validate_existing_file(path, "group_file")
  group_df <- read_delimited_table(path, row_names = FALSE)
  col_names <- tolower(gsub("[[:space:]]+", "_", trimws(colnames(group_df))))
  sample_col <- match(TRUE, col_names %in% c("sample", "sample_name", "sampleid", "sample_id"), nomatch = 0)
  group_col <- match(TRUE, col_names %in% c("group", "condition", "cluster", "class"), nomatch = 0)
  if (sample_col == 0 || group_col == 0) stop_skill("SKILL_MISSING_COLUMNS", "Group file must contain a sample column and a group column.")
  sample_names <- trimws(group_df[[sample_col]])
  groups <- trimws(group_df[[group_col]])
  if (any(is.na(sample_names) | sample_names == "")) stop_skill("SKILL_INVALID_PARAMETER", "Group file contains empty sample names.")
  if (any(is.na(groups) | groups == "")) stop_skill("SKILL_INVALID_PARAMETER", "Group file contains empty group labels.")
  if (anyDuplicated(sample_names) > 0) stop_skill("SKILL_INVALID_PARAMETER", sprintf("Duplicated sample name detected: %s", unique(sample_names[duplicated(sample_names)])[1]))
  setNames(groups, sample_names)
}

read_geneset_table <- function(path, geneset_column, gene_column) {
  validate_existing_file(path, "geneset_file")
  geneset_df <- read_delimited_table(path, row_names = FALSE)
  if (!(geneset_column %in% colnames(geneset_df)) || !(gene_column %in% colnames(geneset_df))) {
    stop_skill("SKILL_MISSING_COLUMNS", sprintf("Gene-set table must contain '%s' and '%s'.", geneset_column, gene_column))
  }
  geneset_df <- geneset_df[, c(geneset_column, gene_column), drop = FALSE]
  colnames(geneset_df) <- c("geneset", "gene")
  geneset_df$geneset <- trimws(as.character(geneset_df$geneset))
  geneset_df$gene <- trimws(as.character(geneset_df$gene))
  geneset_df <- unique(geneset_df[!is.na(geneset_df$geneset) & !is.na(geneset_df$gene) & geneset_df$geneset != "" & geneset_df$gene != "", , drop = FALSE])
  if (nrow(geneset_df) < 1) stop_skill("SKILL_EMPTY_DATA", "Gene-set table contains no valid pathway-gene rows.")
  geneset_df
}

validate_analysis_inputs <- function(exp_mat, groups, case_group, control_group) {
  resolve_group_label <- function(requested_label, available_groups, label_name) {
    if (requested_label %in% available_groups) return(requested_label)
    matched <- available_groups[tolower(available_groups) == tolower(requested_label)]
    if (length(matched) == 1) return(matched[[1]])
    stop_skill("SKILL_INVALID_PARAMETER", sprintf("Both case_group (%s) and control_group (%s) must exist in group_file.", case_group, control_group))
  }
  case_group <- resolve_group_label(case_group, unique(unname(groups)), "case_group")
  control_group <- resolve_group_label(control_group, unique(unname(groups)), "control_group")
  if (!all(colnames(exp_mat) %in% names(groups))) {
    stop_skill("SKILL_SAMPLE_MISMATCH", sprintf("Samples missing from group_file: %s", paste(setdiff(colnames(exp_mat), names(groups)), collapse = ", ")))
  }
  common_samples <- intersect(colnames(exp_mat), names(groups))
  groups <- groups[common_samples]
  exp_mat <- exp_mat[, common_samples, drop = FALSE]
  case_n <- sum(groups == case_group)
  control_n <- sum(groups == control_group)
  if (case_n < 2 || control_n < 2) {
    stop_skill("SKILL_INVALID_PARAMETER", sprintf("At least 2 samples are required per group. case=%s, control=%s.", case_n, control_n))
  }
  list(exp_mat = exp_mat, groups = groups, case_group = case_group, control_group = control_group)
}

load_gsva_result <- function(output_dir) {
  rds_path <- file.path(output_dir, "data", "immune_pathway_result.rds")
  validate_existing_file(rds_path, "saved result file")
  readRDS(rds_path)
}
