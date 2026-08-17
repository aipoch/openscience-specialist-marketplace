read_delimited <- function(file_path, row_names = FALSE) {
  check_file_exists(file_path, basename(file_path))
  is_csv <- grepl("\\.csv$", file_path, ignore.case = TRUE)
  reader <- if (is_csv) utils::read.csv else utils::read.table
  args <- list(file = file_path, header = TRUE, stringsAsFactors = FALSE,
               check.names = FALSE, fileEncoding = "UTF-8-BOM")
  if (row_names)
    args$row.names <- 1
  if (!is_csv)
    args$sep <- "\t"
  tryCatch(
    do.call(reader, args),
    error = function(e) {
      stop(paste("SKILL_PARSE_ERROR: Failed to parse input file:", file_path, "-", conditionMessage(e)))
    }
  )
}

load_expression_matrix <- function(file_path) {
  expr_df <- read_delimited(file_path, row_names = TRUE)
  if (nrow(expr_df) == 0 || ncol(expr_df) == 0)
    stop("SKILL_EMPTY_DATA: Expression matrix is empty")
  if (nrow(expr_df) < 2 || ncol(expr_df) < 2)
    stop("SKILL_INVALID_DATA: Expression matrix must contain at least 2 features and 2 samples")
  if (any(!nzchar(trimws(rownames(expr_df)))))
    stop("SKILL_INVALID_DATA: Expression matrix contains empty feature IDs")
  if (anyDuplicated(rownames(expr_df)) > 0)
    stop("SKILL_INVALID_DATA: Duplicate feature IDs detected in expression matrix")
  if (anyDuplicated(colnames(expr_df)) > 0)
    stop("SKILL_INVALID_DATA: Duplicate sample IDs detected in expression matrix")
  if (!all(vapply(expr_df, is.numeric, logical(1))))
    stop("SKILL_INVALID_TYPE: Expression values must be numeric")
  expr_mat <- as.matrix(data.frame(lapply(expr_df, as.numeric), check.names = FALSE,
                                   row.names = rownames(expr_df)))
  dimnames(expr_mat) <- dimnames(as.matrix(expr_df))
  if (anyNA(expr_mat))
    stop("SKILL_INVALID_DATA: Expression matrix contains non-numeric or missing values")
  expr_mat
}

load_group_data <- function(file_path) {
  group_df <- read_delimited(file_path, row_names = FALSE)
  if (nrow(group_df) == 0)
    stop("SKILL_EMPTY_DATA: Group file is empty")
  if (ncol(group_df) < 2)
    stop("SKILL_MISSING_COLUMNS: Group file must have at least sample and group columns")
  col_names <- tolower(trimws(colnames(group_df)))
  sample_idx <- which(col_names %in% c("sample", "sample_name", "samplename", "id"))
  group_idx <- which(col_names %in% c("group", "group_name", "groupname", "class"))
  if (length(sample_idx) == 0 || length(group_idx) == 0) {
    sample_idx <- 1
    group_idx <- 2
  }
  clean_df <- data.frame(
    sample = trimws(group_df[[sample_idx[1]]]),
    group = trimws(group_df[[group_idx[1]]]),
    stringsAsFactors = FALSE
  )
  if (any(clean_df$sample == "") || any(clean_df$group == ""))
    stop("SKILL_INVALID_DATA: Group file contains empty sample or group values")
  if (anyDuplicated(clean_df$sample) > 0)
    stop("SKILL_INVALID_DATA: Duplicate sample IDs detected in group file")
  clean_df
}

parse_feature_input <- function(feature) {
  if (is.null(feature) || trimws(feature) == "")
    return(NULL)
  feature <- trimws(gsub("^['\"]|['\"]$", "", feature))
  if (file.exists(feature)) {
    check_file_exists(feature, basename(feature))
    values <- trimws(readLines(feature, warn = FALSE, encoding = "UTF-8"))
  } else {
    values <- trimws(unlist(strsplit(feature, ",")))
  }
  values <- unique(values[nzchar(values)])
  if (length(values) == 0)
    stop("SKILL_INVALID_PARAMETER: --feature did not contain any valid feature names")
  values
}
