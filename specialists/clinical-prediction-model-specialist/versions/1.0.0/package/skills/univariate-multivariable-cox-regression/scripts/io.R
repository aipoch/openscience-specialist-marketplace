read_clinical_data <- function(data_file) {
  validate_existing_file(data_file, "--data_file", extensions = c("csv"))
  data <- tryCatch(
    read.csv(data_file, row.names = 1, check.names = FALSE, stringsAsFactors = FALSE),
    error = function(e) stop_skill("SKILL_INVALID_PARAMETER", paste("--data_file must be a readable clinical CSV:", conditionMessage(e)))
  )
  if (nrow(data) == 0 || ncol(data) == 0)
    stop_skill("SKILL_EMPTY_DATA", "Clinical data file is empty")
  data
}
