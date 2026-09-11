detect_task_type <- function(target, requested_task_type) {
  if (requested_task_type != "auto") {
    return(requested_task_type)
  }

  non_missing_target <- target[!is.na(target)]
  unique_count <- length(unique(non_missing_target))

  if (is.numeric(non_missing_target) && unique_count > 10) {
    "regression"
  } else {
    "classification"
  }
}

prepare_binary_levels <- function(values, positive_class = NULL) {
  level_values <- sort(unique(as.character(values[!is.na(values)])))
  if (length(level_values) != 2) {
    stop("SKILL_INVALID_DATA: Binary classification requires exactly 2 target classes")
  }

  if (!is.null(positive_class)) {
    positive_class <- as.character(positive_class)
    if (!(positive_class %in% level_values)) {
      stop("SKILL_INVALID_PARAMETER: positive_class must match one of the observed target classes")
    }
    negative_class <- setdiff(level_values, positive_class)
    return(c(negative_class, positive_class))
  }

  level_values
}

prepare_target <- function(target, task_type, positive_class = NULL) {
  if (task_type == "regression") {
    numeric_target <- suppressWarnings(as.numeric(target))
    if (any(is.na(numeric_target) & !is.na(target))) {
      stop("SKILL_INVALID_DATA: Regression target must be numeric")
    }
    return(list(
      label = numeric_target,
      task_type = "regression",
      nclass = NA_integer_,
      class_levels = character(0)
    ))
  }

  target_chr <- as.character(target)
  class_values <- sort(unique(target_chr[!is.na(target_chr)]))

  if (length(class_values) != 2) {
    stop("SKILL_INVALID_DATA: Binary classification requires exactly 2 target classes")
  }

  class_levels <- prepare_binary_levels(target_chr, positive_class)

  label <- match(target_chr, class_levels) - 1L

  list(
    label = as.numeric(label),
    task_type = "classification",
    nclass = length(class_levels),
    class_levels = class_levels
  )
}

sanitize_predictors <- function(predictors) {
  predictors_df <- as.data.frame(predictors, stringsAsFactors = FALSE)

  for (column_name in names(predictors_df)) {
    column_data <- predictors_df[[column_name]]
    if (is.logical(column_data)) {
      column_data <- ifelse(is.na(column_data), NA, ifelse(column_data, "TRUE", "FALSE"))
      predictors_df[[column_name]] <- factor(column_data)
    } else if (is.character(column_data) || is.factor(column_data)) {
      column_chr <- as.character(column_data)
      column_chr[is.na(column_chr)] <- "__MISSING__"
      predictors_df[[column_name]] <- factor(column_chr)
    }
  }

  predictors_df
}

build_feature_matrix <- function(predictors) {
  check_pkg("Matrix")

  predictors_df <- sanitize_predictors(predictors)
  original_names <- colnames(predictors_df)
  safe_names <- make.names(original_names, unique = TRUE)
  colnames(predictors_df) <- safe_names

  formula_obj <- stats::as.formula("~ . - 1")
  feature_matrix <- Matrix::sparse.model.matrix(formula_obj, data = predictors_df, na.action = stats::na.pass)
  term_labels <- attr(stats::terms(formula_obj, data = predictors_df), "term.labels")
  assign_idx <- attr(feature_matrix, "assign")
  original_term_labels <- original_names[match(term_labels, safe_names)]

  feature_map <- data.frame(
    encoded_feature = colnames(feature_matrix),
    original_feature = original_term_labels[assign_idx],
    stringsAsFactors = FALSE
  )

  list(feature_matrix = feature_matrix, feature_map = feature_map)
}

detect_auto_excluded_columns <- function(data, target_var, ignore_vars) {
  auto_excluded <- character(0)

  if (ncol(data) == 0) {
    return(auto_excluded)
  }

  first_name <- colnames(data)[1]
  first_col <- data[[1]]
  non_missing <- first_col[!is.na(first_col)]

  is_unnamed_id_col <- first_name %in% c("V1", "", "X") &&
    first_name != target_var &&
    !(first_name %in% ignore_vars) &&
    length(non_missing) > 0 &&
    length(unique(as.character(non_missing))) == length(non_missing) &&
    !is.numeric(first_col)

  if (is_unnamed_id_col) {
    auto_excluded <- c(auto_excluded, first_name)
  }

  auto_excluded
}

prepare_model_data <- function(data, params) {
  if (!(params$target_var %in% colnames(data))) {
    stop("SKILL_MISSING_COLUMNS: Target variable '", params$target_var, "' not found in data")
  }

  auto_excluded <- detect_auto_excluded_columns(data, params$target_var, params$ignore_vars)
  ignore_vars <- unique(c(params$ignore_vars, auto_excluded, params$target_var))
  predictor_names <- setdiff(colnames(data), ignore_vars)

  if (length(predictor_names) == 0) {
    stop("SKILL_INVALID_DATA: No usable predictor columns remain after excluding target and ignored columns")
  }

  target <- data[[params$target_var]]
  keep_rows <- !is.na(target)
  filtered_data <- as.data.frame(data[keep_rows, , drop = FALSE], stringsAsFactors = FALSE)

  if (nrow(filtered_data) < 5) {
    stop("SKILL_INVALID_DATA: At least 5 rows with non-missing target values are required")
  }

  resolved_task_type <- detect_task_type(filtered_data[[params$target_var]], params$task_type)
  target_info <- prepare_target(filtered_data[[params$target_var]], resolved_task_type, params$positive_class)

  if (target_info$task_type == "classification") {
    class_counts <- table(target_info$label)
    if (any(class_counts < 2)) {
      stop("SKILL_INVALID_DATA: Each class must contain at least 2 rows for train-test splitting")
    }
  }

  predictors <- filtered_data[, predictor_names, drop = FALSE]
  matrix_info <- build_feature_matrix(predictors)

  if (ncol(matrix_info$feature_matrix) == 0) {
    stop("SKILL_INVALID_DATA: Predictor encoding produced zero usable model features")
  }

  list(
    feature_matrix = matrix_info$feature_matrix,
    feature_map = matrix_info$feature_map,
    label = target_info$label,
    task_type = target_info$task_type,
    nclass = target_info$nclass,
    class_levels = target_info$class_levels,
    auto_excluded = auto_excluded,
    predictor_names = predictor_names,
    filtered_data = filtered_data
  )
}

create_split_indices <- function(labels, task_type, test_size, seed) {
  n_rows <- length(labels)
  all_idx <- seq_len(n_rows)
  set.seed(seed)

  if (task_type == "classification") {
    test_idx <- integer(0)
    for (class_value in sort(unique(labels))) {
      class_idx <- which(labels == class_value)
      class_test_n <- max(1, floor(length(class_idx) * test_size))
      class_test_n <- min(class_test_n, length(class_idx) - 1)
      test_idx <- c(test_idx, sample(class_idx, class_test_n))
    }
    test_idx <- sort(unique(test_idx))
  } else {
    test_n <- max(1, floor(n_rows * test_size))
    test_n <- min(test_n, n_rows - 1)
    test_idx <- sort(sample(all_idx, test_n))
  }

  train_idx <- setdiff(all_idx, test_idx)
  if (length(train_idx) == 0 || length(test_idx) == 0) {
    stop("SKILL_INVALID_DATA: Train-test split produced an empty training or test set")
  }

  list(train_idx = train_idx, test_idx = test_idx)
}

build_xgb_params <- function(params, task_type, nclass) {
  base_params <- list(
    max_depth = params$max_depth,
    eta = params$eta,
    subsample = params$subsample,
    colsample_bytree = params$colsample_bytree,
    min_child_weight = params$min_child_weight,
    gamma = params$gamma,
    lambda = params$lambda,
    alpha = params$alpha,
    verbosity = 0
  )

  if (task_type == "regression") {
    return(c(base_params, list(objective = "reg:squarederror", eval_metric = "rmse")))
  }

  if (nclass == 2) {
    return(c(base_params, list(objective = "binary:logistic", eval_metric = "logloss")))
  }

  stop("SKILL_INVALID_DATA: Binary classification requires exactly 2 target classes")
}

safe_log_loss <- function(actual, predicted_prob) {
  eps <- 1e-15
  predicted_prob <- pmin(pmax(predicted_prob, eps), 1 - eps)
  -mean(actual * log(predicted_prob) + (1 - actual) * log(1 - predicted_prob))
}

safe_auc <- function(actual, score) {
  pos_n <- sum(actual == 1)
  neg_n <- sum(actual == 0)
  if (pos_n == 0 || neg_n == 0) {
    return(NA_real_)
  }
  ranks <- rank(score, ties.method = "average")
  (sum(ranks[actual == 1]) - pos_n * (pos_n + 1) / 2) / (pos_n * neg_n)
}

compute_metrics <- function(actual, prediction, task_type, nclass) {
  if (task_type == "regression") {
    residuals <- prediction - actual
    rmse <- sqrt(mean(residuals^2))
    mae <- mean(abs(residuals))
    denom <- sum((actual - mean(actual))^2)
    rsquared <- if (denom == 0) NA_real_ else 1 - sum(residuals^2) / denom
    return(data.frame(
      Metric = c("rmse", "mae", "rsquared"),
      Value = c(rmse, mae, rsquared),
      stringsAsFactors = FALSE
    ))
  }

  if (nclass == 2) {
    predicted_class <- ifelse(prediction >= 0.5, 1, 0)
    accuracy <- mean(predicted_class == actual)
    logloss <- safe_log_loss(actual, prediction)
    auc <- safe_auc(actual, prediction)
    return(data.frame(
      Metric = c("accuracy", "logloss", "auc"),
      Value = c(accuracy, logloss, auc),
      stringsAsFactors = FALSE
    ))
  }

  stop("SKILL_INVALID_DATA: Binary classification requires exactly 2 target classes")
}

predict_xgb <- function(model, dmatrix, task_type, nclass) {
  raw_prediction <- predict(model, dmatrix)
  if (task_type == "regression") {
    return(raw_prediction)
  }
  if (nclass != 2) {
    stop("SKILL_INVALID_DATA: Binary classification requires exactly 2 target classes")
  }
  raw_prediction
}

aggregate_importance <- function(importance_df, feature_map, selected_metric) {
  if (nrow(importance_df) == 0) {
    stop("SKILL_INVALID_DATA: XGBoost returned an empty feature importance table")
  }

  merged_df <- merge(
    importance_df,
    feature_map,
    by.x = "Feature",
    by.y = "encoded_feature",
    all.x = TRUE,
    sort = FALSE
  )
  merged_df$original_feature[is.na(merged_df$original_feature)] <- merged_df$Feature[is.na(merged_df$original_feature)]

  aggregated_df <- stats::aggregate(
    cbind(Gain, Cover, Frequency) ~ original_feature,
    data = merged_df,
    FUN = sum
  )

  metric_col <- importance_metric_column(selected_metric)
  aggregated_df <- aggregated_df[order(-aggregated_df[[metric_col]], -aggregated_df$Gain, -aggregated_df$Frequency), ]
  rownames(aggregated_df) <- NULL

  aggregated_df$Rank <- seq_len(nrow(aggregated_df))
  aggregated_df$SelectedMetric <- selected_metric
  aggregated_df$SelectedValue <- aggregated_df[[metric_col]]

  aggregated_df <- aggregated_df[, c("Rank", "original_feature", "Gain", "Cover", "Frequency", "SelectedMetric", "SelectedValue")]
  colnames(aggregated_df)[2] <- "Feature"
  aggregated_df
}

create_importance_plot <- function(importance_df, figure_file, selected_metric, top_n) {
  metric_col <- importance_metric_column(selected_metric)
  top_df <- utils::head(importance_df, top_n)

  if (nrow(top_df) == 0) {
    stop("SKILL_INVALID_DATA: No feature importance rows are available for plotting")
  }

  label_chars <- max(nchar(as.character(top_df$Feature)))
  grDevices::png(filename = figure_file, width = 1400, height = 900, res = 150)
  old_par <- graphics::par(no.readonly = TRUE)
  on.exit({
    graphics::par(old_par)
    grDevices::dev.off()
  }, add = TRUE)

  graphics::par(mar = c(5, max(10, min(24, ceiling(label_chars * 0.45))), 4, 2))
  ordered_idx <- rev(seq_len(nrow(top_df)))

  graphics::barplot(
    top_df[[metric_col]][ordered_idx],
    names.arg = top_df$Feature[ordered_idx],
    horiz = TRUE,
    las = 1,
    col = "#2C7FB8",
    border = NA,
    main = sprintf("Top %d Feature Importance (%s)", min(top_n, nrow(top_df)), toupper(selected_metric)),
    xlab = metric_col,
    cex.names = 0.9
  )
}
