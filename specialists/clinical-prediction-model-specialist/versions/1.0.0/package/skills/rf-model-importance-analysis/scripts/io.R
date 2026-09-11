read_delimited_table <- function(file_path) {
  if (grepl("\\.csv$", file_path, ignore.case = TRUE)) {
    utils::read.csv(file_path, header = TRUE, stringsAsFactors = FALSE, check.names = FALSE)
  } else {
    utils::read.table(
      file_path,
      header = TRUE,
      sep = "\t",
      stringsAsFactors = FALSE,
      check.names = FALSE,
      quote = "\"",
      comment.char = ""
    )
  }
}

detect_group_column <- function(group_df, case_group, control_group) {
  candidate_names <- colnames(group_df)[-1]

  for (column_name in candidate_names) {
    values <- as.character(group_df[[column_name]])
    if (case_group %in% values && control_group %in% values) {
      return(column_name)
    }
  }

  named_index <- grep("group", candidate_names, ignore.case = TRUE)
  if (length(named_index) > 0) {
    candidate_names[named_index[1]]
  } else {
    candidate_names[1]
  }
}

read_group_data <- function(group_file, case_group, control_group) {
  group_df <- read_delimited_table(group_file)
  if (nrow(group_df) == 0) {
    fail("SKILL_EMPTY_DATA", sprintf("Group file is empty: %s", group_file))
  }
  if (ncol(group_df) < 2) {
    fail("SKILL_MISSING_COLUMNS", "Group file must contain at least two columns.")
  }

  colnames(group_df)[1] <- "sample"
  target_column <- detect_group_column(group_df, case_group, control_group)
  group_df <- group_df[, c("sample", target_column), drop = FALSE]
  colnames(group_df) <- c("sample", "group")

  if (anyDuplicated(group_df$sample) > 0) {
    fail("SKILL_INVALID_PARAMETER", "Group file contains duplicated sample IDs.")
  }
  if (any(!nzchar(trimws(group_df$sample)))) {
    fail("SKILL_INVALID_PARAMETER", "Group file contains blank sample IDs.")
  }

  group_df
}

read_expression_data <- function(input_file) {
  expression_df <- read_delimited_table(input_file)
  if (nrow(expression_df) == 0) {
    fail("SKILL_EMPTY_DATA", sprintf("Expression matrix is empty: %s", input_file))
  }
  if (ncol(expression_df) < 3) {
    fail(
      "SKILL_MISSING_COLUMNS",
      "Expression matrix must contain a sample column and at least two feature columns."
    )
  }

  colnames(expression_df)[1] <- "sample"
  if (anyDuplicated(expression_df$sample) > 0) {
    fail("SKILL_INVALID_PARAMETER", "Expression matrix contains duplicated sample IDs.")
  }
  if (any(!nzchar(trimws(expression_df$sample)))) {
    fail("SKILL_INVALID_PARAMETER", "Expression matrix contains blank sample IDs.")
  }

  numeric_matrix <- lapply(expression_df[-1], function(column) suppressWarnings(as.numeric(column)))
  numeric_df <- as.data.frame(numeric_matrix, check.names = FALSE)
  colnames(numeric_df) <- colnames(expression_df)[-1]

  if (anyNA(numeric_df)) {
    fail("SKILL_INVALID_PARAMETER", "Expression matrix contains non-numeric feature values.")
  }

  rownames(numeric_df) <- expression_df$sample
  numeric_df
}

align_input_data <- function(expression_df, group_df, case_group, control_group) {
  available_groups <- unique(as.character(group_df$group))
  if (!(case_group %in% available_groups && control_group %in% available_groups)) {
    fail(
      "SKILL_INVALID_PARAMETER",
      sprintf(
        "Case/control labels were not found in the group file. Available groups: %s",
        paste(sort(available_groups), collapse = ", ")
      )
    )
  }

  expression_samples <- rownames(expression_df)
  group_samples <- as.character(group_df$sample)
  if (!setequal(expression_samples, group_samples)) {
    fail(
      "SKILL_SAMPLE_MISMATCH",
      sprintf(
        "Expression matrix and group file must contain the same sample IDs. Expression samples: %d; group samples: %d.",
        length(expression_samples),
        length(group_samples)
      )
    )
  }

  group_named <- stats::setNames(as.character(group_df$group), group_df$sample)
  aligned_group <- factor(group_named[expression_samples], levels = c(control_group, case_group))
  group_counts <- table(aligned_group)
  if (length(group_counts) != 2) {
    fail("SKILL_INVALID_PARAMETER", "Exactly two groups are required for this analysis.")
  }
  if (min(group_counts) < 2) {
    fail("SKILL_INVALID_PARAMETER", "Each group must contain at least two samples.")
  }

  list(
    expression = expression_df[expression_samples, , drop = FALSE],
    group = aligned_group,
    input_summary = c(
      sprintf("Samples: %d", nrow(expression_df)),
      sprintf("Features: %d", ncol(expression_df)),
      sprintf("Case group (%s): %d", case_group, unname(group_counts[case_group])),
      sprintf("Control group (%s): %d", control_group, unname(group_counts[control_group]))
    )
  )
}

save_table <- function(data_frame, output_path) {
  utils::write.csv(data_frame, output_path, row.names = FALSE)
  invisible(output_path)
}
