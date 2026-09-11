#!/usr/bin/env Rscript

detect_input_delimiter <- function(path, hint = "auto") {
  if (hint == "csv") {
    return(",")
  }
  if (hint == "tsv") {
    return("\t")
  }
  if (grepl("\\.csv$", path, ignore.case = TRUE)) {
    return(",")
  }
  "\t"
}

load_expression_matrix <- function(input_file, input_delimiter = "auto") {
  delimiter <- detect_input_delimiter(input_file, input_delimiter)
  if (delimiter == ",") {
    expr <- read.csv(input_file, header = TRUE, stringsAsFactors = FALSE, check.names = FALSE)
  } else {
    expr <- read.table(
      input_file,
      header = TRUE,
      sep = "\t",
      stringsAsFactors = FALSE,
      check.names = FALSE,
      quote = ""
    )
  }

  if (nrow(expr) == 0 || ncol(expr) < 2) {
    stop_skill("SKILL_EMPTY_DATA", "The input expression matrix is empty or has no sample columns.")
  }

  expr
}

write_estimate_input_tsv <- function(expr_df, output_file, gene_id_type) {
  prepared <- expr_df
  colnames(prepared)[1] <- gene_id_type
  write.table(
    prepared,
    file = output_file,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    col.names = TRUE
  )
  output_file
}

read_estimate_score_gct <- function(score_gct_file) {
  scores <- read.table(
    score_gct_file,
    skip = 2,
    header = TRUE,
    sep = "\t",
    stringsAsFactors = FALSE,
    check.names = FALSE,
    quote = ""
  )

  if (nrow(scores) == 0 || ncol(scores) < 3) {
    stop_skill("SKILL_EMPTY_DATA", "estimate_score.gct did not contain any score rows.")
  }

  rownames(scores) <- scores[[1]]
  result <- as.data.frame(t(scores[, 3:ncol(scores), drop = FALSE]), stringsAsFactors = FALSE)
  result$sample <- rownames(result)
  rownames(result) <- NULL
  result <- result[, c("sample", setdiff(colnames(result), "sample")), drop = FALSE]
  result
}

write_score_table <- function(score_df, output_file) {
  write.table(
    score_df,
    file = output_file,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    col.names = TRUE
  )
  output_file
}

load_group_file <- function(group_file, group_delimiter = "auto") {
  delimiter <- detect_input_delimiter(group_file, group_delimiter)
  if (delimiter == ",") {
    read.csv(group_file, header = TRUE, stringsAsFactors = FALSE, check.names = FALSE)
  } else {
    read.table(
      group_file,
      header = TRUE,
      sep = "\t",
      stringsAsFactors = FALSE,
      check.names = FALSE,
      quote = ""
    )
  }
}
