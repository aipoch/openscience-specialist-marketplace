load_data <- function(input_file, group_file, case_name, control_name) {
  check_pkg("data.table")
  exp_df <- data.table::fread(input_file, data.table = FALSE)
  validate_non_empty(exp_df, "Expression matrix")

  if (ncol(exp_df) < 2) {
    skill_stop("SKILL_MISSING_COLUMNS", "Expression matrix must contain a gene column and sample columns")
  }

  rownames(exp_df) <- exp_df[[1]]
  exp_mat <- as.matrix(exp_df[, -1, drop = FALSE])
  validate_non_empty(as.data.frame(exp_mat), "Expression matrix")

  if (anyNA(exp_mat)) {
    skill_stop("SKILL_INVALID_PARAMETER", "Expression matrix contains NA values")
  }

  group_df <- data.table::fread(group_file, data.table = FALSE)
  validate_non_empty(group_df, "Group file")
  cols <- detect_group_columns(group_df, colnames(exp_mat), case_name, control_name)
  map <- data.frame(
    sample = trimws(as.character(group_df[[cols$sample]])),
    group = trimws(as.character(group_df[[cols$group]])),
    stringsAsFactors = FALSE
  )

  matched_groups <- tryCatch(
    validate_groups(map, case_name, control_name),
    error = function(e) {
      log_warn("Retrying group file parsing as headerless input")
      group_df2 <- data.table::fread(group_file, data.table = FALSE, header = FALSE)
      validate_non_empty(group_df2, "Group file")
      cols2 <- detect_group_columns(group_df2, colnames(exp_mat), case_name, control_name)
      map <<- data.frame(
        sample = trimws(as.character(group_df2[[cols2$sample]])),
        group = trimws(as.character(group_df2[[cols2$group]])),
        stringsAsFactors = FALSE
      )
      validate_groups(map, case_name, control_name)
    }
  )

  if (!all(colnames(exp_mat) %in% map$sample)) {
    missing <- setdiff(colnames(exp_mat), map$sample)
    skill_stop("SKILL_SAMPLE_MISMATCH", paste("Samples not found in group file:", paste(head(missing, 5), collapse = ", ")))
  }

  ordered_samples <- intersect(map$sample, colnames(exp_mat))
  if (length(ordered_samples) == 0) {
    skill_stop("SKILL_EMPTY_DATA", "No overlapping samples between expression matrix and group file")
  }

  map <- map[match(ordered_samples, map$sample), , drop = FALSE]
  map$group <- factor(map$group, levels = c(matched_groups$control, matched_groups$case))

  list(
    mat = exp_mat[, ordered_samples, drop = FALSE],
    map = map,
    treat_name = matched_groups$case,
    con_name = matched_groups$control
  )
}

run_diff_method <- function(dat, method) {
  if (!identical(method, "limma")) {
    skill_stop("SKILL_INVALID_PARAMETER", paste("Unknown method:", method))
  }
  diff_limma(dat$mat, dat$map)
}

filter_results <- function(diff_data, p_threshold, logfc_threshold, p_adjust = TRUE) {
  check_pkg("dplyr")
  validate_non_empty(diff_data, "Differential result")
  p_name <- ifelse(p_adjust, "Padj", "Pvalue")
  gene_id_col <- ifelse("gene_id" %in% colnames(diff_data), "gene_id", colnames(diff_data)[1])

  diff_data <- diff_data %>%
    dplyr::mutate(group = dplyr::case_when(
      .data[["logFC"]] > logfc_threshold & .data[[p_name]] < p_threshold ~ "up",
      .data[["logFC"]] < -logfc_threshold & .data[[p_name]] < p_threshold ~ "down",
      TRUE ~ "no"
    ))
  diff_data$name <- diff_data[[gene_id_col]]

  sig_count <- sum(diff_data$group != "no", na.rm = TRUE)
  list(
    data = diff_data,
    significant = sig_count,
    up = sum(diff_data$group == "up", na.rm = TRUE),
    down = sum(diff_data$group == "down", na.rm = TRUE)
  )
}

build_xiantao_volcano <- function(filtered_data, p_adjust = TRUE) {
  p_col <- ifelse(p_adjust, "Padj", "Pvalue")
  data.frame(gene = filtered_data$name, logFC = filtered_data$logFC, p_value = filtered_data[[p_col]])
}

build_xiantao_heatmap <- function(exp_mat, group_map, deg_table, case_name, control_name, top_n, p_adjust = TRUE) {
  check_pkg("dplyr")
  deg_genes_all <- deg_table[deg_table$group != "no", , drop = FALSE]
  if (nrow(deg_genes_all) == 0) return(NULL)

  p_col <- if (p_adjust) {
    if ("Padj" %in% colnames(deg_genes_all)) "Padj" else "P.adj"
  } else {
    if ("Pvalue" %in% colnames(deg_genes_all)) "Pvalue" else "P.value"
  }

  top_up <- deg_genes_all[deg_genes_all$group == "up", , drop = FALSE] %>%
    dplyr::slice_min(order_by = .data[[p_col]], n = top_n, with_ties = FALSE)
  top_down <- deg_genes_all[deg_genes_all$group == "down", , drop = FALSE] %>%
    dplyr::slice_min(order_by = .data[[p_col]], n = top_n, with_ties = FALSE)

  top_genes <- unique(c(top_up$name, top_down$name))
  top_genes <- top_genes[top_genes %in% rownames(exp_mat)]
  if (length(top_genes) < 2) return(NULL)

  heatmap_data <- exp_mat[top_genes, , drop = FALSE]
  sample_groups <- setNames(as.character(group_map$group), group_map$sample)
  ordered_samples <- c(names(sample_groups)[sample_groups == case_name], names(sample_groups)[sample_groups == control_name])
  ordered_samples <- ordered_samples[ordered_samples %in% colnames(heatmap_data)]
  heatmap_data <- heatmap_data[, ordered_samples, drop = FALSE]
  sample_groups <- sample_groups[ordered_samples]

  rbind(c("#group", sample_groups), c("id", colnames(heatmap_data)), cbind(rownames(heatmap_data), heatmap_data))
}
