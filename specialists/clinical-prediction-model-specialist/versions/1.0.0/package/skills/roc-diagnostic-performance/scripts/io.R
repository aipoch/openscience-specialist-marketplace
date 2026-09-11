read_tabular_file <- function(file_path, arg_name) {
  normalized_path <- validate_existing_file(file_path, arg_name, extensions = c("csv", "tsv", "txt"))
  ext <- tolower(tools::file_ext(normalized_path))
  reader <- if (ext %in% c("tsv", "txt")) utils::read.delim else utils::read.csv
  data <- tryCatch(
    reader(normalized_path, header = TRUE, check.names = FALSE, stringsAsFactors = FALSE),
    error = function(e) stop_skill("SKILL_INVALID_PARAMETER", paste("Failed to read", arg_name, ":", conditionMessage(e)))
  )
  if (nrow(data) == 0 || ncol(data) == 0)
    stop_skill("SKILL_EMPTY_DATA", paste(arg_name, "contains no usable rows or columns"))
  data
}

read_expression_matrix <- function(expression_file) {
  read_tabular_file(expression_file, "--expression_file")
}

read_group_file <- function(group_file) {
  read_tabular_file(group_file, "--group_file")
}

write_analysis_outputs <- function(bundle, output_paths) {
  saveRDS(bundle$data, file.path(output_paths$data, "analysis_data.rds"))
  saveRDS(bundle, file.path(output_paths$data, "roc_model.rds"))
  utils::write.csv(bundle$coefficients, file.path(output_paths$table, "model_coefficients.csv"), row.names = FALSE)
  utils::write.csv(bundle$auc_summary, file.path(output_paths$table, "roc_auc_summary.csv"), row.names = FALSE)
  invisible(output_paths)
}
