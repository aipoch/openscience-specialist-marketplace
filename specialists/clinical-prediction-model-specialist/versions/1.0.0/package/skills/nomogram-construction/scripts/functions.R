prepare_nomogram_data <- function(sample_info, features, time_col, event_col, years) {
  required_cols <- unique(c(features, time_col, event_col))
  missing_cols <- setdiff(required_cols, colnames(sample_info))
  if (length(missing_cols) > 0)
    stop_skill("SKILL_MISSING_COLUMNS", paste("Clinical data is missing columns:", paste(missing_cols, collapse = ", ")))
  data <- sample_info[, required_cols, drop = FALSE]
  data[[time_col]] <- suppressWarnings(as.numeric(data[[time_col]]))
  data[[event_col]] <- suppressWarnings(as.numeric(data[[event_col]]))
  for (feature in features)
    if (is.character(data[[feature]])) data[[feature]] <- factor(data[[feature]])
  keep_rows <- stats::complete.cases(data)
  if (!all(keep_rows)) log_warn(sprintf("Removing %d incomplete samples before model fitting", sum(!keep_rows)))
  data <- data[keep_rows, , drop = FALSE]
  if (nrow(data) < 20)
    stop_skill("SKILL_INSUFFICIENT_DATA", "At least 20 complete samples are required for nomogram construction")
  if (any(!is.finite(data[[time_col]])) || any(data[[time_col]] <= 0))
    stop_skill("SKILL_INVALID_DATA", "Time column must contain finite values greater than 0")
  if (!all(data[[event_col]] %in% c(0, 1)))
    stop_skill("SKILL_INVALID_DATA", "Event column must use 0/1 encoding")
  if (sum(data[[event_col]] == 1) < 10)
    stop_skill("SKILL_INSUFFICIENT_DATA", "At least 10 events are required for nomogram construction")
  if (max(years) > max(data[[time_col]]))
    log_warn("Some prediction time points exceed the observed follow-up range")
  data
}

reduce_vector_uniformly <- function(vec, n) {
  if (length(vec) <= n) return(vec)
  vec[round(seq(1, length(vec), length.out = n))]
}

build_nomogram_bundle <- function(data, features, time_col, event_col, years) {
  y <- survival::Surv(time = data[[time_col]], event = data[[event_col]])
  formula_text <- paste0("y ~ `", paste(features, collapse = "` + `"), "`")
  old_datadist <- getOption("datadist")
  dd_name <- sprintf("skill_dd_%s", as.integer(Sys.time()))
  assign(dd_name, rms::datadist(data), envir = .GlobalEnv)
  on.exit({
    options(datadist = old_datadist)
    if (exists(dd_name, envir = .GlobalEnv, inherits = FALSE))
      rm(list = dd_name, envir = .GlobalEnv)
  }, add = TRUE)
  options(datadist = dd_name)
  fit <- tryCatch(rms::cph(stats::as.formula(formula_text), data = data, x = TRUE, y = TRUE, surv = TRUE), error = function(e) stop_skill("SKILL_ANALYSIS_ERROR", paste("Failed to fit cph model:", conditionMessage(e))))
  survival_fn <- rms::Survival(fit)
  survival_funs <- lapply(years, function(tp) { force(tp); function(lp) survival_fn(tp, lp) })
  nomo <- tryCatch(rms::nomogram(fit, fun = survival_funs, funlabel = paste0(years, " Year Survival")), error = function(e) stop_skill("SKILL_ANALYSIS_ERROR", paste("Failed to build nomogram object:", conditionMessage(e))))
  for (axis_name in names(nomo)[grepl("Survival", names(nomo))]) for (idx in seq_along(nomo[[axis_name]])) nomo[[axis_name]][[idx]] <- nomo[[axis_name]][[idx]][reduce_vector_uniformly(seq_along(nomo[[axis_name]][[idx]]), min(3, length(nomo[[axis_name]][[idx]])))]
  lp <- stats::predict(fit, type = "lp")
  c_index <- as.numeric(survival::concordance(y ~ lp, reverse = TRUE)$concordance)
  bundle <- list(nomogram = nomo, c_index = c_index, model = fit, data = data, features = features, time_points = years, time_col = time_col, event_col = event_col, linear_predictor = lp)
  bundle$c_index_table <- data.frame(metric = c("C-index", "Events", "Samples", "Features"), value = c(bundle$c_index, sum(data[[event_col]] == 1), nrow(data), length(features)), stringsAsFactors = FALSE, check.names = FALSE)
  bundle
}
