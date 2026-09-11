build_survival_formula <- function(features, time_col, event_col) {
  formula_text <- sprintf(
    "survival::Surv(`%s`, `%s`) ~ %s",
    time_col,
    event_col,
    paste(sprintf("`%s`", features), collapse = " + ")
  )
  stats::as.formula(formula_text)
}

prepare_model_data <- function(data, features, time_col, event_col) {
  required_cols <- c(features, time_col, event_col)
  missing_cols <- setdiff(required_cols, colnames(data))
  if (length(missing_cols) > 0)
    stop_skill("SKILL_MISSING_COLUMNS", paste("Missing required columns:", paste(missing_cols, collapse = ", ")))

  model_data <- data[, required_cols, drop = FALSE]
  complete_idx <- complete.cases(model_data)
  if (!all(complete_idx)) {
    removed_count <- sum(!complete_idx)
    log_warn(sprintf("Removed %d rows with missing values before calibration", removed_count))
    model_data <- model_data[complete_idx, , drop = FALSE]
  }
  if (nrow(model_data) == 0)
    stop_skill("SKILL_EMPTY_DATA", "No complete rows remained after filtering required columns")

  model_data[[time_col]] <- suppressWarnings(as.numeric(model_data[[time_col]]))
  model_data[[event_col]] <- suppressWarnings(as.numeric(model_data[[event_col]]))
  if (any(!is.finite(model_data[[time_col]])) || any(model_data[[time_col]] <= 0))
    stop_skill("SKILL_INVALID_PARAMETER", "Survival time values must be finite numbers greater than 0")
  if (!all(model_data[[event_col]] %in% c(0, 1)))
    stop_skill("SKILL_INVALID_PARAMETER", "Event indicator values must use 0/1 encoding")

  for (feature in features) {
    if (is.character(model_data[[feature]]))
      model_data[[feature]] <- factor(model_data[[feature]])
  }
  if (nrow(model_data) < 30)
    stop_skill("SKILL_INVALID_PARAMETER", "At least 30 complete samples are required for bootstrap calibration")
  if (sum(model_data[[event_col]] == 1) < 10)
    stop_skill("SKILL_INVALID_PARAMETER", "At least 10 events are required for stable calibration")
  model_data
}

build_calibration_list <- function(model_data, formula, years, bootstrap_reps) {
  calibrations <- vector("list", length(years))
  for (idx in seq_along(years)) {
    year_value <- years[[idx]]
    fit <- rms::cph(formula, data = model_data, x = TRUE, y = TRUE, surv = TRUE, time.inc = year_value)
    group_size <- min(50, max(10, floor(nrow(model_data) * 0.7)))
    calibrations[[idx]] <- rms::calibrate(
      fit,
      cmethod = "KM",
      method = "boot",
      u = year_value,
      m = group_size,
      B = bootstrap_reps
    )
  }
  names(calibrations) <- paste0(years, "-year")
  calibrations
}

calculate_c_index <- function(model_data, formula, time_col, event_col) {
  fit <- rms::cph(formula, data = model_data, x = TRUE, y = TRUE, surv = TRUE)
  linear_predictor <- stats::predict(fit, type = "lp")
  stats::setNames(
    list(
      c_index = as.numeric(
        survival::concordance(survival::Surv(model_data[[time_col]], model_data[[event_col]]) ~ linear_predictor)$concordance
      ),
      fit = fit
    ),
    c("c_index", "fit")
  )
}

build_calibration_result <- function(model_data, features, time_col, event_col, years, bootstrap_reps) {
  dd_name <- "dd_calibration_curve_skill"
  assign(dd_name, rms::datadist(model_data), envir = .GlobalEnv)
  old_datadist <- getOption("datadist")
  options(datadist = dd_name)
  on.exit({
    options(datadist = old_datadist)
    if (exists(dd_name, envir = .GlobalEnv, inherits = FALSE))
      rm(list = dd_name, envir = .GlobalEnv)
  }, add = TRUE)

  formula <- build_survival_formula(features, time_col, event_col)
  model_fit <- calculate_c_index(model_data, formula, time_col, event_col)
  calibrations <- build_calibration_list(model_data, formula, years, bootstrap_reps)
  list(
    calibration_data = calibrations,
    c_index = model_fit$c_index,
    time_points = years,
    features = features,
    formula_text = Reduce(paste, deparse(formula)),
    sample_size = nrow(model_data),
    event_count = sum(model_data[[event_col]] == 1),
    model_data = model_data
  )
}

extract_single_calibration_stat <- function(calibration_object, year_value, sample_size) {
  pred_mean <- NA_real_
  obs_mean <- NA_real_
  corrected_mean <- NA_real_
  if (is.matrix(calibration_object) && ncol(calibration_object) >= 3) {
    pred_mean <- mean(calibration_object[, 1], na.rm = TRUE)
    obs_mean <- mean(calibration_object[, 2], na.rm = TRUE)
    corrected_mean <- mean(calibration_object[, 3], na.rm = TRUE)
  }
  data.frame(
    time_point = year_value,
    predicted_mean = round(pred_mean, 3),
    observed_mean = round(obs_mean, 3),
    bias_corrected_mean = round(corrected_mean, 3),
    sample_size = sample_size,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

build_statistics_bundle <- function(calibration_result) {
  per_time_tables <- lapply(
    seq_along(calibration_result$calibration_data),
    function(idx) extract_single_calibration_stat(
      calibration_result$calibration_data[[idx]],
      calibration_result$time_points[[idx]],
      calibration_result$sample_size
    )
  )
  list(
    time_point_stats = do.call(rbind, per_time_tables),
    model_summary = data.frame(
      c_index = round(calibration_result$c_index, 3),
      sample_size = calibration_result$sample_size,
      event_count = calibration_result$event_count,
      features = paste(calibration_result$features, collapse = ", "),
      formula = calibration_result$formula_text,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  )
}
