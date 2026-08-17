load_data <- function(input_file, group_file) {
  check_pkg("data.table")
  df <- data.table::fread(input_file, data.table = FALSE)
  rownames(df) <- df[[1]]
  df <- df[, -1]

  group <- data.table::fread(group_file, data.table = FALSE, header = TRUE)
  rownames(group) <- group[[1]]
  group[[2]] <- factor(group[[2]], levels = unique(group[[2]]))

  sample_cols <- group[[1]]
  if (!all(sample_cols %in% colnames(df))) {
    missing <- setdiff(sample_cols, colnames(df))
    stop("SKILL_SAMPLE_MISMATCH: Samples in group file not found in expression matrix: ",
         paste(head(missing, 5), collapse = ", "))
  }

  validate_groups(group)

  list(mat = df[, sample_cols], map = group,
       treat_name = levels(group[[2]])[2],
       con_name = levels(group[[2]])[1])
}

run_diff_method <- function(dat, method, norm_method) {
  switch(method,
    limma = diff_limma(dat$mat, dat$map),
    deseq2 = diff_deseq2(dat$mat, dat$map),
    edger = diff_edger(dat$mat, dat$map, norm = norm_method),
    t = diff_stat(dat$mat, dat$map, stat = "t"),
    wilcox = diff_stat(dat$mat, dat$map, stat = "wilcox"),
    stop("SKILL_INVALID_PARAMETER: Unknown method: ", method)
  )
}

filter_results <- function(diff_data, p_threshold, logfc_threshold, p_adjust) {
  check_pkg("dplyr")
  p_name <- ifelse(p_adjust, "Padj", "Pvalue")
  gene_id_col <- ifelse("gene_id" %in% colnames(diff_data), "gene_id", colnames(diff_data)[1])

  num_sig <- sum((abs(diff_data[["logFC"]]) > logfc_threshold) &
                 (diff_data[[p_name]] < p_threshold))

  if (num_sig == 0)
    stop("SKILL_FILTER_ERROR: No significant genes found with current thresholds")

  diff_data <- diff_data %>%
    dplyr::mutate(group = case_when(
      .data[[gene_id_col]] %in% rownames(.[.$logFC > logfc_threshold & .[[p_name]] < p_threshold,]) ~ "Up",
      .data[[gene_id_col]] %in% rownames(.[.$logFC < -logfc_threshold & .[[p_name]] < p_threshold,]) ~ "Down",
      TRUE ~ "Not"
    ))

  list(data = diff_data, significant = num_sig,
       up = sum(diff_data$group == "Up"),
       down = sum(diff_data$group == "Down"))
}
