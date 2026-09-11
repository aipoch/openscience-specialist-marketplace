detect_delimiter <- function(path) {
  ext <- tolower(tools::file_ext(path))
  if (ext == "csv")
    return(",")
  if (ext %in% c("tsv", "txt"))
    return("\t")
  stop_skill("SKILL_INVALID_PARAMETER", "--input_file and --group_file must be csv, tsv, or txt")
}

read_delimited_table <- function(path) {
  ensure_file_exists(path, "Input file")
  sep <- detect_delimiter(path)
  data.table::fread(path, sep = sep, data.table = FALSE, check.names = FALSE, encoding = "UTF-8")
}

load_expression_matrix <- function(path) {
  raw_table <- read_delimited_table(path)
  if (nrow(raw_table) == 0L || ncol(raw_table) < 2L) {
    stop_skill("SKILL_INVALID_DATA", "Expression matrix must contain genes and samples.")
  }
  gene_ids <- trimws(as.character(raw_table[[1]]))
  if (any(!nzchar(gene_ids)) || anyDuplicated(gene_ids)) {
    stop_skill("SKILL_INVALID_DATA", "Expression matrix gene identifiers must be non-empty and unique.")
  }
  expression_table <- raw_table[, -1, drop = FALSE]
  expression_matrix <- as.matrix(expression_table)
  suppressWarnings(storage.mode(expression_matrix) <- "numeric")
  if (anyNA(expression_matrix)) {
    stop_skill("SKILL_INVALID_DATA", "Expression matrix contains NA or non-numeric values.")
  }
  rownames(expression_matrix) <- gene_ids
  expression_matrix
}

load_group_table <- function(path) {
  group_table <- read_delimited_table(path)
  if (nrow(group_table) == 0L || ncol(group_table) < 2L) {
    stop_skill("SKILL_MISSING_COLUMNS", "Group file must contain sample and group columns.")
  }
  group_table
}

load_gene_list <- function(path) {
  ensure_file_exists(path, "Gene list file")
  gene_lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  gene_lines <- trimws(gene_lines)
  gene_lines <- gene_lines[nzchar(gene_lines)]
  gene_lines <- vapply(strsplit(gene_lines, ","), function(parts) {
    trimws(gsub('^"|"$', "", parts[1]))
  }, character(1))
  if (length(gene_lines) > 0L && tolower(gene_lines[1]) %in% c("gene", "genes", "symbol", "gene_id")) {
    gene_lines <- gene_lines[-1]
  }
  unique(gene_lines[nzchar(gene_lines)])
}
