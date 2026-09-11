prepare_decision_data <- function(data, outcome_col, predictor_col) {
  required_cols <- c(outcome_col, predictor_col)
  missing_cols <- setdiff(required_cols, colnames(data))
  if (length(missing_cols) > 0)
    stop_skill("SKILL_MISSING_COLUMNS", paste("Missing required columns:", paste(missing_cols, collapse = ", ")))

  analysis_data <- data[, required_cols, drop = FALSE]
  analysis_data[[outcome_col]] <- suppressWarnings(as.numeric(analysis_data[[outcome_col]]))
  analysis_data[[predictor_col]] <- suppressWarnings(as.numeric(analysis_data[[predictor_col]]))
  if (any(!analysis_data[[outcome_col]] %in% c(0, 1)))
    stop_skill("SKILL_INVALID_PARAMETER", paste(outcome_col, "must use 0/1 encoding"))
  if (any(!is.finite(analysis_data[[predictor_col]])))
    stop_skill("SKILL_INVALID_PARAMETER", paste(predictor_col, "must contain finite numeric values"))
  if (nrow(analysis_data) < 20)
    stop_skill("SKILL_INVALID_PARAMETER", "At least 20 rows are required for decision curve analysis")
  if (sum(analysis_data[[outcome_col]] == 1) < 5 || sum(analysis_data[[outcome_col]] == 0) < 5)
    stop_skill("SKILL_INVALID_PARAMETER", "At least 5 positive and 5 negative outcomes are required")
  analysis_data
}

build_thresholds <- function(threshold_by) {
  validate_positive_number(threshold_by, "--threshold_by")
  if (threshold_by >= 1)
    stop_skill("SKILL_INVALID_PARAMETER", "--threshold_by must be smaller than 1")
  thresholds <- seq(0, 1, by = threshold_by)
  if (tail(thresholds, 1) < 1)
    thresholds <- c(thresholds, 1)
  unique(thresholds)
}

fit_decision_curve_model <- function(analysis_data, options) {
  validate_probability(options$confidence_level, "--confidence_level")
  if (identical(options$study_design, "case-control"))
    validate_probability(options$population_prevalence, "--population_prevalence")

  formula <- stats::as.formula(sprintf("`%s` ~ `%s`", options$outcome_col, options$predictor_col))
  dca_args <- list(
    formula = formula,
    data = analysis_data,
    family = stats::binomial(link = "logit"),
    thresholds = build_thresholds(options$threshold_by),
    confidence.intervals = options$confidence_level,
    study.design = options$study_design
  )
  if (identical(options$study_design, "case-control"))
    dca_args$population.prevalence <- options$population_prevalence

  model <- NULL
  package_messages <- character(0)
  model <- tryCatch(
    {
      package_output <- capture.output({
        model <- withCallingHandlers(
          do.call(rmda::decision_curve, dca_args),
          message = function(m) {
            package_messages <<- c(package_messages, conditionMessage(m))
            invokeRestart("muffleMessage")
          }
        )
      }, type = "output")
      package_output <- trimws(c(package_output, package_messages))
      package_output <- package_output[nzchar(package_output)]
      if (length(package_output) > 0) {
        for (line in package_output)
          log_info(line)
      }
      model
    },
    error = function(e) stop_skill("SKILL_INVALID_PARAMETER", paste("Decision curve modeling failed:", conditionMessage(e)))
  )
  list(
    model = model,
    formula_text = Reduce(paste, deparse(formula)),
    sample_size = nrow(analysis_data),
    event_count = sum(analysis_data[[options$outcome_col]] == 1),
    non_event_count = sum(analysis_data[[options$outcome_col]] == 0),
    threshold_count = length(dca_args$thresholds)
  )
}

build_summary_lines <- function(model, standardize_net_benefit) {
  measure_name <- if (isTRUE(standardize_net_benefit)) "sNB" else "NB"
  capture.output(summary(model, measure = measure_name))
}

plot_decision_curve_to_device <- function(model, options) {
  rmda::plot_decision_curve(
    model,
    curve.names = "Predictive Model",
    cost.benefit.axis = FALSE,
    col = options$decision_curve_color,
    confidence.intervals = isTRUE(options$show_confidence_intervals),
    standardize = isTRUE(options$standardize_net_benefit)
  )
  graphics::title(main = options$plot_title)
}

plot_clinical_impact_to_device <- function(model, options, impact_colors) {
  rmda::plot_clinical_impact(
    model,
    population.size = options$population_size,
    cost.benefit.axis = TRUE,
    n.cost.benefits = options$n_cost_benefits,
    col = impact_colors,
    confidence.intervals = isTRUE(options$show_confidence_intervals)
  )
}
