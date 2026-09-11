validate_cli_options <- function(opt) {
  ensure_file_exists(opt$input_file, "Input file")
  ensure_file_exists(opt$group_file, "Group file")
  if (!opt$gene_selection %in% c("highly_variable", "custom")) {
    stop_skill("SKILL_INVALID_PARAMETER", "--gene_selection must be 'highly_variable' or 'custom'.")
  }
  if (opt$gene_selection == "custom" && is.null(opt$gene_list)) {
    stop_skill("SKILL_INVALID_PARAMETER", "--gene_list is required when --gene_selection=custom.")
  }
  if (!is.null(opt$gene_list))
    ensure_file_exists(opt$gene_list, "Gene list file")
  if (opt$max_k < 3L || opt$top_n < 1L || opt$reps < 2L) {
    stop_skill("SKILL_INVALID_PARAMETER", "--max_k >= 3, --top_n >= 1, and --reps >= 2 are required.")
  }
  if (opt$p_item <= 0 || opt$p_item > 1 || opt$p_feature <= 0 || opt$p_feature > 1) {
    stop_skill("SKILL_INVALID_PARAMETER", "--p_item and --p_feature must be within (0, 1].")
  }
  if (opt$timeout_seconds < 1L) {
    stop_skill("SKILL_INVALID_PARAMETER", "--timeout_seconds must be >= 1.")
  }
}

detect_column_name <- function(column_names, candidates, label) {
  hit <- which(tolower(column_names) %in% candidates)
  if (length(hit) == 0L)
    stop_skill("SKILL_MISSING_COLUMNS", sprintf("Could not detect the %s column.", label))
  column_names[hit[1]]
}

standardize_group_table <- function(group_table) {
  sample_col <- detect_column_name(colnames(group_table),
                                   c("sample", "sampleid", "sample_id", "samplename", "sample_name", "id"),
                                   "sample")
  group_col <- detect_column_name(colnames(group_table),
                                  c("group", "condition", "class", "type", "treatment"),
                                  "group")
  standardized <- data.frame(sample = trimws(group_table[[sample_col]]),
                             group = trimws(group_table[[group_col]]),
                             stringsAsFactors = FALSE)
  if (any(!nzchar(standardized$sample)) || any(!nzchar(standardized$group)) || anyDuplicated(standardized$sample)) {
    stop_skill("SKILL_INVALID_DATA", "Group table sample and group values must be non-empty and sample IDs must be unique.")
  }
  standardized
}

filter_disease_matrix <- function(expression_matrix, group_table, disease_group, max_k) {
  group_hit <- unique(group_table$group[tolower(group_table$group) == tolower(disease_group)])
  if (length(group_hit) == 0L) {
    stop_skill("SKILL_INVALID_PARAMETER", sprintf("Disease group '%s' was not found.", disease_group))
  }
  if (!all(colnames(expression_matrix) %in% group_table$sample)) {
    stop_skill("SKILL_SAMPLE_MISMATCH", "Expression matrix samples are missing from the group file.")
  }
  disease_samples <- group_table$sample[group_table$group == group_hit[1]]
  disease_samples <- disease_samples[disease_samples %in% colnames(expression_matrix)]
  if (length(disease_samples) < 3L || length(disease_samples) < max_k) {
    stop_skill("SKILL_INVALID_DATA", "Disease-group sample count must be at least 3 and not smaller than max_k.")
  }
  list(matrix = expression_matrix[, disease_samples, drop = FALSE],
       disease_group = group_hit[1],
       disease_samples = disease_samples)
}

select_gene_matrix <- function(expression_matrix, gene_selection, top_n, gene_list) {
  if (gene_selection == "highly_variable") {
    gene_scores <- apply(expression_matrix, 1, stats::mad)
    keep_n <- min(top_n, nrow(expression_matrix))
    keep_ids <- order(gene_scores, decreasing = TRUE)[seq_len(keep_n)]
    selected <- expression_matrix[keep_ids, , drop = FALSE]
    return(list(matrix = selected,
                metadata = data.frame(gene = rownames(selected), mode = "highly_variable", stringsAsFactors = FALSE)))
  }
  hit_genes <- intersect(gene_list, rownames(expression_matrix))
  if (length(hit_genes) < 2L)
    stop_skill("SKILL_INVALID_DATA", "Custom gene list retained fewer than two genes.")
  selected <- expression_matrix[hit_genes, , drop = FALSE]
  list(matrix = selected,
       metadata = data.frame(gene = rownames(selected), mode = "custom", stringsAsFactors = FALSE))
}

center_expression_matrix <- function(expression_matrix, center_data) {
  if (!isTRUE(center_data))
    return(expression_matrix)
  sweep(expression_matrix, 1, apply(expression_matrix, 1, stats::median, na.rm = TRUE), FUN = "-")
}

build_method_grid <- function() {
  method_grid <- expand.grid(dist = c("pearson", "spearman", "euclidean", "maximum", "canberra", "minkowski"),
                             clusterAlg = c("hc", "pam", "km"), stringsAsFactors = FALSE)
  method_grid <- method_grid[!(method_grid$clusterAlg == "km" & method_grid$dist != "euclidean"), , drop = FALSE]
  method_grid <- method_grid[!(method_grid$clusterAlg == "hc" & method_grid$dist %in% c("maximum", "minkowski")), , drop = FALSE]
  rownames(method_grid) <- NULL
  method_grid
}

compute_pac_table <- function(result_object, max_k) {
  k_values <- 2:max_k
  pac_values <- vapply(k_values, function(k_value) {
    consensus_values <- result_object[[k_value]]$consensusMatrix
    consensus_values <- consensus_values[lower.tri(consensus_values)]
    if (length(consensus_values) == 0L || all(is.na(consensus_values)))
      return(NA_real_)
    cdf_function <- stats::ecdf(consensus_values)
    cdf_function(0.9) - cdf_function(0.1)
  }, numeric(1))
  data.frame(k = k_values, PAC = pac_values, stringsAsFactors = FALSE)
}

select_best_result <- function(cluster_results) {
  valid_rows <- cluster_results[!is.na(cluster_results$PAC), , drop = FALSE]
  if (nrow(valid_rows) == 0L)
    stop_skill("SKILL_INVALID_DATA", "No valid clustering result was produced.")
  valid_rows[which.min(valid_rows$PAC), , drop = FALSE]
}
