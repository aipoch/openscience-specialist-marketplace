build_output_paths <- function(output_dir) {
  root <- ensure_dir(output_dir)
  list(
    root = root,
    plots = ensure_dir(file.path(root, "plots")),
    tables = ensure_dir(file.path(root, "tables")),
    data = ensure_dir(file.path(root, "data"))
  )
}

save_table <- function(df, output_file, row_names = TRUE) {
  write.csv(df, output_file, row.names = row_names)
  log_info(sprintf("Saved table: %s", output_file))
}

save_rds_logged <- function(object, output_file) {
  saveRDS(object, output_file)
  log_info(sprintf("Saved RDS: %s", output_file))
}

load_group_data <- function(group_file, sample_column, group_column, sample_names) {
  group_file <- assert_file_exists(group_file, "Group file")
  group_df <- data.table::fread(group_file, data.table = FALSE)

  if (nrow(group_df) == 0 || ncol(group_df) < 2) {
    skill_stop("EMPTY_DATA", "Group file is empty or missing required columns")
  }

  sample_column <- resolve_column(group_df, sample_column, 1, "Sample")
  group_column <- resolve_column(group_df, group_column, 2, "Group")
  group_df <- group_df[, c(sample_column, group_column), drop = FALSE]
  colnames(group_df) <- c("sample", "group")
  group_df$sample <- as.character(group_df$sample)
  group_df$group <- as.character(group_df$group)

  if (anyNA(group_df$sample) || any(trimws(group_df$sample) == "")) {
    skill_stop("MISSING_COLUMNS", "Group file sample column contains empty values")
  }
  if (anyNA(group_df$group) || any(trimws(group_df$group) == "")) {
    skill_stop("MISSING_COLUMNS", "Group file group column contains empty values")
  }

  assert_unique_values(group_df$sample, "Group file sample names")
  assert_unique_values(sample_names, "Expression matrix sample names")

  missing_samples <- setdiff(group_df$sample, sample_names)
  if (length(missing_samples) > 0) {
    skill_stop(
      "SAMPLE_MISMATCH",
      sprintf("Samples in group file not found in expression matrix: %s", paste(head(missing_samples, 10), collapse = ", "))
    )
  }

  group_df <- group_df[match(sample_names, group_df$sample), , drop = FALSE]
  if (anyNA(group_df$sample)) {
    skill_stop("SAMPLE_MISMATCH", "Expression matrix contains samples missing from the group file")
  }

  group_df$group <- standardize_group_factor(group_df$group)
  if (nlevels(group_df$group) < 2) {
    skill_stop("INVALID_PARAMETER", "At least two groups are required for WGCNA trait comparison")
  }

  data.frame(
    gsm = group_df$sample,
    sample = group_df$sample,
    group = group_df$group,
    row.names = group_df$sample,
    stringsAsFactors = FALSE
  )
}
