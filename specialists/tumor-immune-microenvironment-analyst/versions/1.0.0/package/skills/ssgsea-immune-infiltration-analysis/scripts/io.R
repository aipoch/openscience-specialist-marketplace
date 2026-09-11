read_delim_auto <- function(file, header = TRUE, check.names = FALSE) {
  if (!file.exists(file)) {
    skill_stop("SKILL_FILE_NOT_FOUND", paste("File does not exist:", file))
  }
  if (grepl("\\.csv$", file, ignore.case = TRUE)) {
    return(read.csv(file, header = header, stringsAsFactors = FALSE, check.names = check.names))
  }
  read.table(
    file, header = header, sep = "\t", stringsAsFactors = FALSE,
    check.names = check.names, quote = "", comment.char = ""
  )
}

read_expression_matrix <- function(input_file, gene_id_case, verbose) {
  log_info("Reading expression matrix.", verbose)
  exp_df <- read_delim_auto(input_file, header = TRUE, check.names = FALSE)
  if (ncol(exp_df) < 2) {
    skill_stop("SKILL_INVALID_PARAMETER", "Expression matrix must contain one gene column and at least one sample column.")
  }
  gene_names <- normalize_gene_id(exp_df[[1]], gene_id_case)
  if (any(is.na(gene_names)) || any(gene_names == "")) {
    skill_stop("SKILL_EMPTY_DATA", "Expression matrix contains empty gene identifiers.")
  }
  if (anyDuplicated(gene_names) > 0) {
    skill_stop("SKILL_INVALID_PARAMETER", "Expression matrix contains duplicated gene identifiers after normalization.")
  }
  exp_df <- exp_df[, -1, drop = FALSE]
  colnames(exp_df) <- trim_ws(colnames(exp_df))
  if (any(colnames(exp_df) == "")) {
    skill_stop("SKILL_INVALID_PARAMETER", "Expression matrix contains empty sample names.")
  }
  mat <- as.matrix(exp_df)
  suppressWarnings(storage.mode(mat) <- "numeric")
  if (anyNA(mat)) {
    skill_stop("SKILL_INVALID_PARAMETER", "Expression matrix contains NA or non-numeric values.")
  }
  rownames(mat) <- gene_names
  mat
}

read_group_info <- function(group_file, case_group, control_group, sample_col, group_col, verbose) {
  log_info("Reading group annotation.", verbose)
  group_df <- tryCatch(read_delim_auto(group_file, header = TRUE, check.names = FALSE), error = function(e) NULL)
  if (is.null(group_df) || ncol(group_df) < 2) {
    group_df <- read_delim_auto(group_file, header = FALSE, check.names = FALSE)
  }
  if (ncol(group_df) < 2) {
    skill_stop("SKILL_MISSING_COLUMNS", "Group file must contain sample and group columns.")
  }
  lower_names <- tolower(trim_ws(colnames(group_df)))
  resolve_col_index <- function(col_spec, default_names, default_idx, arg_name) {
    if (is.null(col_spec)) {
      matched <- which(lower_names %in% default_names)[1]
      if (is.na(matched) || length(matched) == 0) {
        return(default_idx)
      }
      return(matched)
    }
    if (is.character(col_spec)) {
      matched <- which(lower_names == tolower(trim_ws(col_spec)))[1]
      if (is.na(matched) || length(matched) == 0) {
        skill_stop("SKILL_INVALID_PARAMETER", sprintf("%s column '%s' was not found in the group file.", arg_name, col_spec))
      }
      return(matched)
    }
    if (is.numeric(col_spec)) {
      if (is.na(col_spec) || col_spec < 1 || col_spec > ncol(group_df)) {
        skill_stop("SKILL_INVALID_PARAMETER", sprintf("%s index must be between 1 and %d.", arg_name, ncol(group_df)))
      }
      return(as.integer(col_spec))
    }
    skill_stop("SKILL_INVALID_PARAMETER", sprintf("%s must be a column name or 1-based index.", arg_name))
  }
  sample_idx <- resolve_col_index(sample_col, c("sample", "sample_name", "sampleid", "id"), 1L, "--sample_col")
  group_idx <- resolve_col_index(group_col, c("group", "condition", "class"), 2L, "--group_col")
  if (is.na(sample_idx) || length(sample_idx) == 0) sample_idx <- 1
  if (is.na(group_idx) || length(group_idx) == 0) group_idx <- 2
  sample_vec <- trim_ws(group_df[[sample_idx]])
  group_vec <- trim_ws(group_df[[group_idx]])
  keep <- !is.na(sample_vec) & sample_vec != "" & !is.na(group_vec) & group_vec != ""
  out <- stats::setNames(group_vec[keep], sample_vec[keep])
  if (length(out) == 0) {
    skill_stop("SKILL_EMPTY_DATA", "No valid sample-group pairs were found in the group file.")
  }
  if (!(case_group %in% unname(out)) || !(control_group %in% unname(out))) {
    skill_stop("SKILL_INVALID_PARAMETER", "case_group or control_group is missing from the group file.")
  }
  out[out %in% c(case_group, control_group)]
}

read_gene_sets <- function(gene_set_file, gene_id_case, verbose) {
  log_info("Reading immune gene sets.", verbose)
  gs <- read_delim_auto(gene_set_file, header = TRUE, check.names = FALSE)
  required_cols <- c("gene", "cell_type")
  if (!all(required_cols %in% colnames(gs))) {
    skill_stop("SKILL_MISSING_COLUMNS", "Gene set file must contain gene and cell_type columns.")
  }
  gs <- dplyr::transmute(
    gs,
    gene = normalize_gene_id(.data$gene, gene_id_case),
    cell_type_label = trim_ws(.data$cell_type),
    immunity_class = if ("immunity_class" %in% colnames(gs)) trim_ws(.data$immunity_class) else NA_character_
  )
  gs <- dplyr::filter(gs, !is.na(.data$gene), .data$gene != "", !is.na(.data$cell_type_label), .data$cell_type_label != "")
  gs <- dplyr::mutate(gs, cell_type = gsub("\\s+", "_", .data$cell_type_label))
  gs <- dplyr::distinct(gs, .data$gene, .data$cell_type, .keep_all = TRUE)
  genesets <- split(gs$gene, gs$cell_type)
  cell_anno <- dplyr::arrange(dplyr::distinct(gs, .data$cell_type, .data$cell_type_label, .data$immunity_class), .data$cell_type)
  list(genesets = genesets, cell_anno = cell_anno)
}
