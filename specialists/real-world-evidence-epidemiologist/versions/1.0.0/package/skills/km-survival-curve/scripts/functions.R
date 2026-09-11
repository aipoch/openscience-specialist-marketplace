resolve_group_levels <- function(group_values) {
  unique_groups <- unique(as.character(group_values))
  unique_lower <- tolower(unique_groups)

  if (all(c("low", "high") %in% unique_lower) && length(unique_groups) == 2) {
    return(unique_groups[match(c("low", "high"), unique_lower)])
  }

  return(sort(unique_groups))
}

append_remediation <- function(message, remediation) {
  paste0(message, " Fix: ", remediation)
}

validate_risk_group_semantics <- function(group_values, column_name) {
  values <- trimws(as.character(group_values))
  values <- values[nzchar(values)]

  if (length(values) == 0) {
    stop(append_remediation(
      paste0("SKILL_INVALID_DATA: Risk group column '", column_name, "' has no non-empty values"),
      "Use a precomputed categorical grouping column with at least two non-empty groups."
    ))
  }

  unique_values <- unique(values)
  unique_count <- length(unique_values)
  unique_ratio <- unique_count / length(values)
  numeric_values <- suppressWarnings(as.numeric(values))
  numeric_like <- all(!is.na(numeric_values))

  if (unique_ratio > 0.5 || (numeric_like && unique_count > 5)) {
    stop(append_remediation(
      paste0(
        "SKILL_INVALID_DATA: Risk group column '", column_name,
        "' looks continuous or near-unique, but this tool requires a precomputed categorical group"
      ),
      "Use a precomputed grouping column such as low/high, or bin the score before running Kaplan-Meier analysis."
    ))
  }

  invisible(NULL)
}

convert_follow_up_time <- function(time_values, time_unit = "year", auto_convert_days = TRUE) {
  converted <- time_values
  conversion_note <- "No automatic time conversion applied"
  conversion_applied <- FALSE

  if (isTRUE(auto_convert_days) && length(time_values) > 0) {
    max_time <- max(time_values, na.rm = TRUE)

    if (time_unit == "year" && max_time > 365) {
      converted <- time_values / 365
      conversion_note <- paste(
        "Automatically converted survival time from days to years because max(time) > 365.",
        "Use this only when the source time column is known to be in days. Disable --auto_convert_days if your data are already in years."
      )
      conversion_applied <- TRUE
    } else if (time_unit == "month" && max_time > 365) {
      converted <- time_values / 30.4375
      conversion_note <- paste(
        "Automatically converted survival time from days to months because max(time) > 365.",
        "Use this only when the source time column is known to be in days. Disable --auto_convert_days if your data are already in months."
      )
      conversion_applied <- TRUE
    }
  }

  list(values = converted, note = conversion_note, applied = conversion_applied)
}

prepare_survival_input <- function(data, params) {
  required_cols <- c(params$time_col, params$status_col, params$risk_col)
  missing_cols <- setdiff(required_cols, colnames(data))

  if (length(missing_cols) > 0) {
    stop(append_remediation(
      paste0("SKILL_MISSING_COLUMNS: Missing required columns: ", paste(missing_cols, collapse = ", ")),
      "Check the header row and pass explicit names with --time_col, --status_col, and --risk_col. Ensure TXT input is tab-delimited."
    ))
  }

  selected_df <- as.data.frame(data[, required_cols, with = FALSE], check.names = FALSE)
  colnames(selected_df) <- c("time", "status", "risk_group")

  selected_df$time <- suppressWarnings(as.numeric(selected_df$time))
  selected_df$status <- suppressWarnings(as.numeric(selected_df$status))
  selected_df$risk_group <- trimws(as.character(selected_df$risk_group))

  if (all(is.na(selected_df$time))) {
    stop(append_remediation(
      paste0("SKILL_INVALID_DATA: Time column '", params$time_col, "' must be numeric"),
      "Check the selected time column and ensure it contains numeric follow-up values."
    ))
  }

  if (all(is.na(selected_df$status))) {
    stop(append_remediation(
      paste0("SKILL_INVALID_DATA: Status column '", params$status_col, "' must be numeric"),
      "Check the selected status column and ensure it is coded as 0 for censored and 1 for event."
    ))
  }

  complete_mask <- complete.cases(selected_df[, c("time", "status")]) & nzchar(selected_df$risk_group)
  removed_rows <- which(!complete_mask)

  surv_data <- selected_df[complete_mask, , drop = FALSE]
  if (nrow(surv_data) < 2) {
    stop(append_remediation(
      "SKILL_INSUFFICIENT_DATA: Need at least 2 complete observations for survival analysis",
      "Inspect missing values in the selected time, status, and risk columns, or use a dataset with more retained rows."
    ))
  }

  if (any(!is.finite(surv_data$time)) || any(surv_data$time < 0)) {
    stop(append_remediation(
      paste0("SKILL_INVALID_DATA: Time column '", params$time_col, "' must contain finite non-negative values"),
      "Remove missing, infinite, or negative follow-up values from the selected time column."
    ))
  }

  if (any(!surv_data$status %in% c(0, 1))) {
    stop(append_remediation(
      paste0("SKILL_INVALID_DATA: Status column '", params$status_col, "' must be coded as 0 or 1"),
      "Recode the selected status column so 0 means censored and 1 means event."
    ))
  }

  validate_risk_group_semantics(surv_data$risk_group, params$risk_col)

  group_levels <- resolve_group_levels(surv_data$risk_group)
  if (length(group_levels) < 2) {
    stop(append_remediation(
      "SKILL_INVALID_DATA: Risk group column must contain at least 2 groups",
      "Check whether filtering removed one group and confirm the selected --risk_col contains at least two non-empty groups."
    ))
  }

  converted_time <- convert_follow_up_time(
    surv_data$time,
    time_unit = params$time_unit,
    auto_convert_days = params$auto_convert_days
  )
  surv_data$time <- converted_time$values

  if (isTRUE(converted_time$applied)) {
    log_warn(converted_time$note)
  } else if (nzchar(converted_time$note)) {
    log_info(converted_time$note)
  }

  surv_data$risk_group <- factor(surv_data$risk_group, levels = group_levels)

  group_counts <- as.data.frame(table(surv_data$risk_group), stringsAsFactors = FALSE)
  colnames(group_counts) <- c("group", "sample_size")

  if (any(group_counts$sample_size < 3)) {
    warning_text <- paste(group_counts$group, group_counts$sample_size, sep = ": ", collapse = ", ")
    log_warn("Too few samples in some groups (", warning_text, ")")
  }

  return(list(
    surv_data = surv_data,
    removed_row_count = length(removed_rows),
    group_levels = group_levels,
    time_unit = params$time_unit,
    conversion_note = converted_time$note
  ))
}

calculate_p_value <- function(surv_data, statistics_method) {
  if (statistics_method == "logrank") {
    diff_result <- survival::survdiff(survival::Surv(time, status) ~ risk_group, data = surv_data)
    return(1 - stats::pchisq(diff_result$chisq, df = length(diff_result$n) - 1))
  }

  if (nlevels(surv_data$risk_group) != 2) {
    stop(append_remediation(
      "SKILL_INVALID_PARAMETER: statistics_method 'wald' only supports exactly 2 retained groups",
      "Use --statistics_method logrank for multi-group comparisons, or reduce the input to two groups."
    ))
  }

  cox_fit <- survival::coxph(survival::Surv(time, status) ~ risk_group, data = surv_data)
  summary(cox_fit)$coefficients[1, 5]
}

format_p_value <- function(p_value) {
  if (is.na(p_value)) {
    return("p = NA")
  }

  if (p_value < 0.001) {
    return("p < 0.001")
  }

  return(paste0("p = ", sprintf("%.3f", p_value)))
}

validate_plot_inputs <- function(prepared_data, params) {
  retained_group_count <- length(prepared_data$group_levels)

  if (params$statistics_method == "wald" && retained_group_count != 2) {
    stop(append_remediation(
      "SKILL_INVALID_PARAMETER: statistics_method 'wald' only supports exactly 2 retained groups",
      "Use --statistics_method logrank for multi-group comparisons, or reduce the input to two groups."
    ))
  }

  if (length(params$line_colors) < retained_group_count) {
    stop(append_remediation(
      paste0(
        "SKILL_INVALID_PARAMETER: line_colors provides ", length(params$line_colors),
        " color(s), but ", retained_group_count, " retained group(s) will be plotted"
      ),
      "Provide at least one comma-separated color per retained group, or omit --line_colors to use the default multi-group palette."
    ))
  }

  invisible(NULL)
}

safe_ggsurvplot <- function(plot_args) {
  tryCatch(
    do.call(survminer::ggsurvplot, plot_args),
    error = function(e) {
      stop(append_remediation(
        paste0(
          "SKILL_INVALID_PARAMETER: Plot rendering failed for the provided plotting options. Underlying error: ",
          conditionMessage(e)
        ),
        "Review plotting arguments such as --line_type and --line_colors, then rerun with values compatible with the retained group count."
      ))
    }
  )
}

build_custom_theme <- function(params) {
  ggplot2::theme(
    axis.title = ggplot2::element_text(size = params$axis_title_size),
    axis.text = ggplot2::element_text(size = params$axis_text_size, colour = "black"),
    panel.background = ggplot2::element_blank(),
    axis.line = ggplot2::element_line(linewidth = 0.5),
    legend.key.size = grid::unit(0.5, "cm"),
    legend.text = ggplot2::element_text(size = params$legend_text_size)
  )
}

resolve_x_axis_title <- function(title_x, time_unit) {
  normalized_title <- trimws(as.character(title_x))

  if (!nzchar(normalized_title) || identical(normalized_title, "Time")) {
    return(paste0("Time (", time_unit, ")"))
  }

  normalized_title
}

apply_plot_linewidth <- function(plot_obj, line_size) {
  for (idx in seq_along(plot_obj$plot$layers)) {
    layer <- plot_obj$plot$layers[[idx]]
    if (inherits(layer$geom, "GeomStep") || inherits(layer$geom, "GeomLine")) {
      layer$aes_params$linewidth <- line_size
      layer$aes_params$size <- NULL
      plot_obj$plot$layers[[idx]] <- layer
    }
  }
  plot_obj
}

create_km_plot <- function(prepared_data, params) {
  surv_data <- prepared_data$surv_data
  validate_plot_inputs(prepared_data, params)
  fit <- survival::survfit(survival::Surv(time, status) ~ risk_group, data = surv_data)
  p_value <- calculate_p_value(surv_data, params$statistics_method)

  plot_args <- list(
    fit = fit,
    data = surv_data,
    pval = format_p_value(p_value),
    pval.coord = c(0.1, 0.1),
    conf.int = params$confidence_show,
    conf.int.alpha = params$confidence_alpha,
    risk.table = params$risk_table_show,
    risk.table.height = 0.25,
    risk.table.title = "",
    risk.table.fontsize = params$risk_table_size,
    risk.table.y.text = FALSE,
    censor = params$censor_show,
    censor.size = params$censor_size,
    palette = params$line_colors,
    legend = if (params$legend_show) params$legend_position else "none",
    xlab = resolve_x_axis_title(params$title_x, prepared_data$time_unit),
    ylab = params$title_y,
    title = params$title_main,
    ggtheme = build_custom_theme(params),
    font.family = params$figure_family,
    linetype = params$line_type
  )

  if (params$legend_show) {
    plot_args$legend.labs <- prepared_data$group_levels
  }

  if (nzchar(trimws(params$legend_title))) {
    plot_args$legend.title <- params$legend_title
  }

  plot_obj <- safe_ggsurvplot(plot_args)

  plot_obj <- apply_plot_linewidth(plot_obj, params$line_size)

  if (params$risk_table_show) {
    if (!params$risk_table_border) {
      plot_obj$table <- plot_obj$table + ggplot2::theme(panel.border = ggplot2::element_blank())
    }
    if (params$risk_table_panel) {
      plot_obj$table <- plot_obj$table + ggplot2::theme(
        panel.background = ggplot2::element_rect(fill = "white")
      )
    }
  }

  return(list(
    plot = plot_obj
  ))
}
