resolve_sample_ids <- function(data, sample_id_column) {
  if (!is.null(sample_id_column)) {
    if (!sample_id_column %in% colnames(data)) {
      stop("SKILL_MISSING_COLUMNS: Sample ID column '", sample_id_column, "' not found in data")
    }

    sample_ids <- as.character(data[[sample_id_column]])
    if (any(is.na(sample_ids)) || any(!nzchar(trimws(sample_ids)))) {
      stop("SKILL_INVALID_DATA: Sample ID column '", sample_id_column, "' contains missing or empty values")
    }
    if (anyDuplicated(sample_ids)) {
      stop("SKILL_INVALID_DATA: Sample ID column '", sample_id_column, "' must contain unique values")
    }

    return(list(values = sample_ids, column = sample_id_column, source = "explicit"))
  }

  first_column_name <- colnames(data)[1]
  first_column <- data[[1]]
  if (!is.numeric(first_column)) {
    sample_ids <- as.character(first_column)
    if (!any(is.na(sample_ids)) && all(nzchar(trimws(sample_ids))) && !anyDuplicated(sample_ids)) {
      return(list(values = sample_ids, column = first_column_name, source = "auto_first_non_numeric"))
    }
  }

  return(list(
    values = paste0("Sample_", seq_len(nrow(data))),
    column = NULL,
    source = "generated"
  ))
}

resolve_group_values <- function(data, group_column) {
  if (is.null(group_column)) {
    return(NULL)
  }

  if (!group_column %in% colnames(data)) {
    stop("SKILL_MISSING_COLUMNS: Group column '", group_column, "' not found in data")
  }

  return(as.character(data[[group_column]]))
}

resolve_feature_columns <- function(data, params, sample_id_info) {
  excluded_columns <- c(sample_id_info$column, params$group_column)
  excluded_columns <- excluded_columns[!is.null(excluded_columns)]

  if (!is.null(params$feature_columns)) {
    missing_columns <- setdiff(params$feature_columns, colnames(data))
    if (length(missing_columns) > 0) {
      stop(
        "SKILL_MISSING_COLUMNS: Requested feature columns not found: ",
        paste(missing_columns, collapse = ", ")
      )
    }
    feature_columns <- params$feature_columns
  } else {
    numeric_columns <- colnames(data)[vapply(data, is.numeric, logical(1))]
    feature_columns <- setdiff(numeric_columns, excluded_columns)
  }

  if (length(feature_columns) < 2) {
    stop("SKILL_INSUFFICIENT_DATA: At least 2 numeric feature columns are required for PCA")
  }

  non_numeric_columns <- feature_columns[!vapply(data[, ..feature_columns], is.numeric, logical(1))]
  if (length(non_numeric_columns) > 0) {
    stop(
      "SKILL_INVALID_DATA: Selected feature columns must be numeric. Non-numeric columns: ",
      paste(non_numeric_columns, collapse = ", ")
    )
  }

  return(feature_columns)
}

prepare_pca_input <- function(data, params) {
  sample_id_info <- resolve_sample_ids(data, params$sample_id_column)
  group_values <- resolve_group_values(data, params$group_column)
  feature_columns <- resolve_feature_columns(data, params, sample_id_info)

  feature_frame <- as.data.frame(data[, ..feature_columns])
  feature_matrix <- as.matrix(feature_frame)

  finite_mask <- apply(feature_matrix, 1, function(row) all(is.finite(row)))
  complete_mask <- complete.cases(feature_frame) & finite_mask
  removed_rows <- which(!complete_mask)

  filtered_features <- feature_matrix[complete_mask, , drop = FALSE]
  filtered_sample_ids <- sample_id_info$values[complete_mask]
  filtered_groups <- if (is.null(group_values)) NULL else group_values[complete_mask]

  if (nrow(filtered_features) < 2) {
    stop(
      "SKILL_INSUFFICIENT_DATA: Need at least 2 complete samples after filtering, found: ",
      nrow(filtered_features)
    )
  }

  feature_sds <- apply(filtered_features, 2, sd)
  zero_variance_columns <- names(feature_sds)[is.na(feature_sds) | feature_sds == 0]
  if (length(zero_variance_columns) > 0) {
    stop(
      "SKILL_INVALID_DATA: PCA cannot be performed with zero-variance feature columns: ",
      paste(zero_variance_columns, collapse = ", ")
    )
  }

  effective_components <- min(params$n_components, nrow(filtered_features), ncol(filtered_features))
  if (effective_components < params$n_components) {
    log_warn(
      "Requested ", params$n_components,
      " components but only ", effective_components,
      " can be computed from the filtered data"
    )
  }

  filtered_input <- data.frame(sample_id = filtered_sample_ids, stringsAsFactors = FALSE)
  if (!is.null(filtered_groups)) {
    filtered_input$group <- filtered_groups
  }
  filtered_input <- cbind(filtered_input, as.data.frame(filtered_features, check.names = FALSE))

  return(list(
    feature_matrix = filtered_features,
    feature_columns = feature_columns,
    sample_ids = filtered_sample_ids,
    sample_id_column = sample_id_info$column,
    sample_id_source = sample_id_info$source,
    group_values = filtered_groups,
    removed_row_indices = removed_rows,
    removed_row_count = length(removed_rows),
    effective_components = effective_components,
    filtered_input = filtered_input
  ))
}

run_pca <- function(prepared_data, params) {
  log_info("Running PCA with center=", params$center_data, ", scale=", params$scale_data)

  pca_result <- prcomp(
    prepared_data$feature_matrix,
    center = params$center_data,
    scale. = params$scale_data
  )

  component_indices <- seq_len(prepared_data$effective_components)
  total_variance <- sum(pca_result$sdev ^ 2)
  variance_values <- pca_result$sdev[component_indices] ^ 2

  summary_df <- data.frame(
    component = paste0("PC", component_indices),
    standard_deviation = pca_result$sdev[component_indices],
    variance = variance_values,
    proportion_variance = variance_values / total_variance,
    cumulative_variance = cumsum(variance_values / total_variance),
    stringsAsFactors = FALSE
  )

  scores_df <- data.frame(sample_id = prepared_data$sample_ids, stringsAsFactors = FALSE)
  if (!is.null(prepared_data$group_values)) {
    scores_df$group <- prepared_data$group_values
  }
  scores_df <- cbind(
    scores_df,
    as.data.frame(pca_result$x[, component_indices, drop = FALSE], check.names = FALSE)
  )

  loadings_matrix <- pca_result$rotation[, component_indices, drop = FALSE]
  loadings_df <- data.frame(feature = rownames(loadings_matrix), stringsAsFactors = FALSE)
  loadings_df <- cbind(loadings_df, as.data.frame(loadings_matrix, check.names = FALSE))

  top_loading_tables <- lapply(component_indices, function(idx) {
    component_name <- paste0("PC", idx)
    component_values <- loadings_matrix[, idx]
    ordered_index <- order(abs(component_values), decreasing = TRUE)
    selected_index <- ordered_index[seq_len(min(params$top_loadings, length(ordered_index)))]

    data.frame(
      component = component_name,
      rank = seq_along(selected_index),
      feature = rownames(loadings_matrix)[selected_index],
      loading = component_values[selected_index],
      abs_loading = abs(component_values[selected_index]),
      stringsAsFactors = FALSE
    )
  })
  top_loadings_df <- do.call(rbind, top_loading_tables)

  metadata_df <- data.frame(
    metric = c(
      "samples_used",
      "features_used",
      "rows_removed_for_missing_or_infinite_values",
      "sample_id_source",
      "sample_id_column",
      "group_column",
      "center_data",
      "scale_data",
      "components_exported"
    ),
    value = c(
      nrow(prepared_data$feature_matrix),
      ncol(prepared_data$feature_matrix),
      prepared_data$removed_row_count,
      prepared_data$sample_id_source,
      ifelse(is.null(prepared_data$sample_id_column), "generated", prepared_data$sample_id_column),
      ifelse(is.null(params$group_column), "none", params$group_column),
      params$center_data,
      params$scale_data,
      prepared_data$effective_components
    ),
    stringsAsFactors = FALSE
  )

  return(list(
    pca_object = pca_result,
    summary = summary_df,
    scores = scores_df,
    loadings = loadings_df,
    top_loadings = top_loadings_df,
    metadata = metadata_df
  ))
}
