read_expression_data <- function(exp_file) {
  exp_data <- tryCatch(
    read.csv(exp_file, row.names = 1, check.names = FALSE),
    error = function(e) stop_skill("SKILL_INVALID_DATA", paste("Failed to read expression matrix:", conditionMessage(e)))
  )
  if (nrow(exp_data) == 0 || ncol(exp_data) == 0)
    stop_skill("SKILL_EMPTY_DATA", "Expression matrix is empty")
  if (anyDuplicated(rownames(exp_data)))
    stop_skill("SKILL_INVALID_DATA", "Expression matrix contains duplicate gene identifiers")
  exp_data
}

read_clinical_data <- function(cli_file) {
  cli_data <- tryCatch(
    read.csv(cli_file, row.names = 1, check.names = FALSE),
    error = function(e) stop_skill("SKILL_INVALID_DATA", paste("Failed to read clinical file:", conditionMessage(e)))
  )
  required_cols <- c("OS", "OS.time")
  missing_cols <- setdiff(required_cols, colnames(cli_data))
  if (length(missing_cols) > 0)
    stop_skill("SKILL_MISSING_COLUMNS", paste("Clinical data is missing columns:", paste(missing_cols, collapse = ", ")))
  if (nrow(cli_data) == 0)
    stop_skill("SKILL_EMPTY_DATA", "Clinical data is empty")
  cli_data
}

read_model_data <- function(model_file) {
  model_data <- tryCatch(
    read.csv(model_file, check.names = FALSE),
    error = function(e) stop_skill("SKILL_INVALID_DATA", paste("Failed to read model file:", conditionMessage(e)))
  )
  required_cols <- c("Gene", "Coef")
  missing_cols <- setdiff(required_cols, colnames(model_data))
  if (length(missing_cols) > 0)
    stop_skill("SKILL_MISSING_COLUMNS", paste("Model file is missing columns:", paste(missing_cols, collapse = ", ")))
  if (nrow(model_data) == 0)
    stop_skill("SKILL_EMPTY_DATA", "Model file is empty")
  if (anyDuplicated(model_data$Gene))
    stop_skill("SKILL_INVALID_DATA", "Model file contains duplicate gene identifiers")
  model_data$Coef <- suppressWarnings(as.numeric(model_data$Coef))
  if (anyNA(model_data$Coef))
    stop_skill("SKILL_INVALID_DATA", "Model coefficients must be numeric")
  model_data
}

convert_followup_to_years <- function(followup_time, time_unit) {
  switch(
    time_unit,
    day = followup_time / 365,
    month = followup_time / 12,
    year = followup_time,
    stop_skill("SKILL_INVALID_PARAMETER", paste("Unsupported time unit:", time_unit))
  )
}

validate_analysis_dataset <- function(risk_data) {
  if (nrow(risk_data) < 4)
    stop_skill("SKILL_INVALID_DATA", "At least 4 matched samples are required")
  if (any(!is.finite(risk_data$futime)) || any(risk_data$futime <= 0))
    stop_skill("SKILL_INVALID_DATA", "Survival time must be finite and greater than 0")
  if (!all(stats::na.omit(risk_data$fustat) %in% c(0, 1)))
    stop_skill("SKILL_INVALID_DATA", "Clinical OS status must use 0/1 encoding")
  if (length(unique(as.character(risk_data$risk))) < 2)
    stop_skill("SKILL_ANALYSIS_ERROR", "Risk groups collapsed into a single class; check model coefficients and input data")
  if (sum(risk_data$fustat == 1, na.rm = TRUE) < 2)
    stop_skill("SKILL_ANALYSIS_ERROR", "At least 2 events are required for survival and ROC analysis")
  invisible(TRUE)
}

prepare_analysis_dataset <- function(exp_data, cli_data, model_data, time_unit) {
  matched_samples <- intersect(colnames(exp_data), rownames(cli_data))
  if (length(matched_samples) == 0)
    stop_skill("SKILL_SAMPLE_MISMATCH", "No overlapping samples were found between expression and clinical data")
  missing_genes <- setdiff(model_data$Gene, rownames(exp_data))
  if (length(missing_genes) > 0) {
    stop_skill("SKILL_INVALID_DATA",
               paste("Model genes not found in expression matrix:", paste(head(missing_genes, 10), collapse = ", ")))
  }

  cli_subset <- cli_data[matched_samples, , drop = FALSE]
  exp_subset <- t(exp_data[model_data$Gene, matched_samples, drop = FALSE])
  colnames(exp_subset) <- model_data$Gene

  futime_raw <- suppressWarnings(as.numeric(cli_subset$OS.time))
  fustat <- suppressWarnings(as.numeric(cli_subset$OS))
  risk_score <- as.numeric(exp_subset %*% model_data$Coef)
  complete_idx <- complete.cases(exp_subset, futime_raw, fustat, risk_score)
  if (!all(complete_idx)) {
    removed <- sum(!complete_idx)
    log_warn(sprintf("Removed %d samples with incomplete values before analysis", removed))
    exp_subset <- exp_subset[complete_idx, , drop = FALSE]
    cli_subset <- cli_subset[complete_idx, , drop = FALSE]
    futime_raw <- futime_raw[complete_idx]
    fustat <- fustat[complete_idx]
    risk_score <- risk_score[complete_idx]
  }

  risk_data <- data.frame(
    id = rownames(exp_subset),
    futime = convert_followup_to_years(futime_raw, time_unit),
    fustat = fustat,
    exp_subset,
    riskScore = risk_score,
    risk = factor(ifelse(risk_score > stats::median(risk_score), "high", "low"), levels = c("low", "high")),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  validate_analysis_dataset(risk_data)
  risk_data
}
