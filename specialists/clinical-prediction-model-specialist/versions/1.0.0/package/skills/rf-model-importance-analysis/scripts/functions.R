build_model_frame <- function(expression_df, group_factor) {
  data.frame(Group = group_factor, expression_df, check.names = FALSE)
}

run_random_forest_model <- function(model_frame, options) {
  rf_args <- list(
    formula = Group ~ .,
    data = model_frame,
    ntree = options$rf_ntree,
    importance = TRUE,
    na.action = stats::na.fail
  )
  if (!is.na(options$rf_mtry)) rf_args$mtry <- options$rf_mtry
  if (!is.na(options$rf_nodesize)) rf_args$nodesize <- options$rf_nodesize

  set.seed(options$seed)
  do.call(randomForest::randomForest, rf_args)
}

pick_selection_metric <- function(importance_matrix) {
  metric_candidates <- c("MeanDecreaseAccuracy", "MeanDecreaseGini")
  available <- intersect(metric_candidates, colnames(importance_matrix))
  if (length(available) > 0) available[1] else colnames(importance_matrix)[1]
}

extract_importance_results <- function(rf_model, options) {
  importance_matrix <- randomForest::importance(rf_model, type = options$rf_imp_type)
  if (is.null(dim(importance_matrix))) {
    importance_matrix <- matrix(importance_matrix, ncol = 1)
    rownames(importance_matrix) <- names(randomForest::importance(rf_model, type = options$rf_imp_type))
    colnames(importance_matrix) <- sprintf("Importance_Type_%d", options$rf_imp_type)
  }

  importance_df <- data.frame(Feature = rownames(importance_matrix), importance_matrix, check.names = FALSE)
  metric_column <- pick_selection_metric(importance_matrix)
  ranked_table <- data.frame(
    Feature = importance_df$Feature,
    Importance = as.numeric(importance_df[[metric_column]]),
    Metric = metric_column,
    stringsAsFactors = FALSE
  )
  ranked_table <- ranked_table[order(-ranked_table$Importance), , drop = FALSE]

  selected <- ranked_table[ranked_table$Importance > options$rf_imp_threshold, , drop = FALSE]
  top_features <- utils::head(selected, options$rf_top_n)

  list(
    plot_table = importance_df,
    ranked_table = ranked_table,
    top_features = top_features,
    metric_column = metric_column
  )
}

extract_oob_error <- function(rf_model) {
  if (is.null(rf_model$err.rate) || nrow(rf_model$err.rate) == 0) {
    return(NA_real_)
  }

  oob_column <- grep("OOB", colnames(rf_model$err.rate), ignore.case = TRUE)
  if (length(oob_column) == 0) {
    as.numeric(rf_model$err.rate[nrow(rf_model$err.rate), 1])
  } else {
    as.numeric(rf_model$err.rate[nrow(rf_model$err.rate), oob_column[1]])
  }
}

build_result_summary <- function(importance_results, rf_model) {
  top_name <- if (nrow(importance_results$ranked_table) > 0) {
    importance_results$ranked_table$Feature[1]
  } else {
    "None"
  }

  c(
    sprintf("Selection metric: %s", importance_results$metric_column),
    sprintf("Features ranked: %d", nrow(importance_results$ranked_table)),
    sprintf("Features above threshold: %d", nrow(importance_results$top_features)),
    sprintf("Top-ranked feature: %s", top_name),
    sprintf("Final OOB error: %s", format(extract_oob_error(rf_model), digits = 4, nsmall = 4))
  )
}
