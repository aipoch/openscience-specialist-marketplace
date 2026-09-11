#!/usr/bin/env Rscript

read_expression_matrix <- function(path) {
  validate_existing_file(path, "input_file")
  exp_df <- read_delimited_table(path, row_names = TRUE)
  if (nrow(exp_df) < 2 || ncol(exp_df) < 2) {
    stop_skill("SKILL_EMPTY_DATA", "Expression matrix must contain at least 2 genes and 2 samples.")
  }
  exp_mat <- as.matrix(exp_df)
  suppressWarnings(storage.mode(exp_mat) <- "double")
  if (any(is.na(exp_mat))) {
    stop_skill("SKILL_EMPTY_DATA", "Expression matrix contains NA or non-numeric values.")
  }
  exp_mat
}

read_group_file <- function(path) {
  validate_existing_file(path, "group_file")
  group_df <- read_delimited_table(path, row_names = FALSE)
  col_names <- tolower(trimws(colnames(group_df)))
  col_names <- gsub("[[:space:]]+", "_", col_names)

  sample_candidates <- c("sample", "sample_name", "sampleid", "sample_id")
  group_candidates <- c("group", "condition", "cluster", "class")

  sample_col <- match(TRUE, col_names %in% sample_candidates, nomatch = 0)
  group_col <- match(TRUE, col_names %in% group_candidates, nomatch = 0)

  if (sample_col == 0 || group_col == 0) {
    stop_skill(
      "SKILL_MISSING_COLUMNS",
      paste(
        "Group file must contain one sample column",
        "(sample, sample_name, sample_id) and one group column",
        "(group, condition, cluster, class)."
      )
    )
  }

  sample_names <- trimws(group_df[[sample_col]])
  groups <- trimws(group_df[[group_col]])

  if (any(is.na(sample_names) | sample_names == "")) {
    stop_skill("SKILL_INVALID_PARAMETER", "Group file contains empty sample names.")
  }
  if (any(is.na(groups) | groups == "")) {
    stop_skill("SKILL_INVALID_PARAMETER", "Group file contains empty group labels.")
  }
  if (anyDuplicated(sample_names) > 0) {
    dup_name <- unique(sample_names[duplicated(sample_names)])[1]
    stop_skill("SKILL_INVALID_PARAMETER", sprintf("Duplicated sample name detected: %s", dup_name))
  }

  setNames(groups, sample_names)
}

validate_analysis_inputs <- function(exp_mat, groups, case_group, control_group) {
  if (!(case_group %in% unname(groups) && control_group %in% unname(groups))) {
    stop_skill(
      "SKILL_INVALID_PARAMETER",
      sprintf("Both case_group (%s) and control_group (%s) must exist in group_file.", case_group, control_group)
    )
  }
  if (!all(colnames(exp_mat) %in% names(groups))) {
    missing_samples <- setdiff(colnames(exp_mat), names(groups))
    stop_skill(
      "SKILL_SAMPLE_MISMATCH",
      sprintf("Samples missing from group_file: %s", paste(head(missing_samples, 10), collapse = ", "))
    )
  }

  common_samples <- intersect(colnames(exp_mat), names(groups))
  groups <- groups[common_samples]
  exp_mat <- exp_mat[, common_samples, drop = FALSE]

  case_n <- sum(groups == case_group)
  control_n <- sum(groups == control_group)
  if (case_n < 2 || control_n < 2) {
    stop_skill(
      "SKILL_INVALID_PARAMETER",
      sprintf("At least 2 samples are required per group. case=%s, control=%s.", case_n, control_n)
    )
  }

  list(exp_mat = exp_mat, groups = groups)
}

load_gsva_result <- function(output_dir) {
  rda_path <- file.path(output_dir, "data", "GSVA_list.rda")
  validate_existing_file(rda_path, "GSVA result file")
  env <- new.env(parent = emptyenv())
  load(rda_path, envir = env)
  if (!exists("gsva_result", envir = env, inherits = FALSE)) {
    stop_skill("SKILL_EMPTY_DATA", "gsva_result object was not found in GSVA_list.rda.")
  }
  get("gsva_result", envir = env, inherits = FALSE)
}
