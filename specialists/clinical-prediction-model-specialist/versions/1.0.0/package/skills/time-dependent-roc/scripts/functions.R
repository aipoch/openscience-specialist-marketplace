resolve_marker_column <- function(data, marker_col = NULL) {
  if (is.null(marker_col) || !nzchar(marker_col)) {
    stop("SKILL_INVALID_PARAMETER: marker_col must not be empty")
  }

  if (!marker_col %in% colnames(data)) {
    stop("SKILL_MISSING_COLUMNS: Marker column not found in data: ", marker_col)
  }

  marker_col
}

prepare_analysis_data <- function(data, marker_col = NULL, cause = 1) {
  required_cols <- c("futime", "fustat")
  missing_cols <- setdiff(required_cols, colnames(data))
  if (length(missing_cols) > 0) {
    stop("SKILL_MISSING_COLUMNS: Missing required columns: ", paste(missing_cols, collapse = ", "))
  }

  marker_name <- resolve_marker_column(data, marker_col)

  futime <- suppressWarnings(as.numeric(data$futime))
  fustat <- suppressWarnings(as.numeric(data$fustat))
  marker <- suppressWarnings(as.numeric(data[[marker_name]]))

  if (all(is.na(futime))) {
    stop("SKILL_INVALID_DATA: futime could not be parsed as numeric")
  }

  if (all(is.na(fustat))) {
    stop("SKILL_INVALID_DATA: fustat could not be parsed as numeric")
  }

  if (all(is.na(marker))) {
    stop("SKILL_INVALID_DATA: Marker column '", marker_name, "' could not be parsed as numeric")
  }

  complete_idx <- complete.cases(futime, fustat, marker)
  prepared <- data.frame(
    futime = futime[complete_idx],
    fustat = fustat[complete_idx],
    marker = marker[complete_idx],
    stringsAsFactors = FALSE
  )

  if (nrow(prepared) < 5) {
    stop("SKILL_INSUFFICIENT_DATA: Need at least 5 complete rows, found: ", nrow(prepared))
  }

  n_events <- sum(prepared$fustat == cause, na.rm = TRUE)
  if (n_events < 1) {
    stop("SKILL_INSUFFICIENT_DATA: No events found for cause = ", cause)
  }

  if (length(unique(prepared$marker)) < 2) {
    stop("SKILL_INVALID_DATA: Marker column '", marker_name, "' must contain at least 2 distinct values")
  }

  list(
    data = prepared,
    marker_col = marker_name,
    n_complete = nrow(prepared),
    n_events = n_events
  )
}

convert_follow_up_time <- function(futime, time_unit = "year", auto_convert_days = TRUE) {
  converted <- futime
  conversion_note <- "No automatic time conversion applied"

  if (isTRUE(auto_convert_days) && length(futime) > 0) {
    max_time <- max(futime, na.rm = TRUE)

    if (time_unit == "year" && max_time > 365) {
      converted <- futime / 365
      conversion_note <- "Converted futime from days to years because max(futime) > 365"
    } else if (time_unit == "month" && max_time > 365) {
      converted <- futime / 30.4375
      conversion_note <- "Converted futime from days to months because max(futime) > 365"
    }
  }

  list(values = converted, note = conversion_note)
}

extract_time_column <- function(x, index) {
  if (is.null(dim(x))) {
    return(x)
  }
  x[, index]
}

run_time_dependent_roc <- function(prepared_data, params) {
  log_info("Running time-dependent ROC analysis")
  log_info("Marker column: ", prepared_data$marker_col)
  log_info("Complete rows: ", prepared_data$n_complete)
  log_info("Events for cause ", params$cause, ": ", prepared_data$n_events)

  converted_time <- convert_follow_up_time(
    prepared_data$data$futime,
    time_unit = params$time_unit,
    auto_convert_days = params$auto_convert_days
  )

  if (nzchar(converted_time$note)) {
    log_info(converted_time$note)
  }

  prepared_data$data$futime <- converted_time$values

  roc_result <- timeROC::timeROC(
    T = prepared_data$data$futime,
    delta = prepared_data$data$fustat,
    marker = prepared_data$data$marker,
    cause = params$cause,
    weighting = params$weighting,
    times = params$times,
    ROC = TRUE
  )

  list(
    roc_object = roc_result,
    analysis_data = prepared_data$data,
    marker_col = prepared_data$marker_col,
    n_complete = prepared_data$n_complete,
    n_events = prepared_data$n_events,
    conversion_note = converted_time$note
  )
}

extract_auc_table <- function(roc_run, params) {
  data.frame(
    time = params$times,
    time_unit = params$time_unit,
    auc = as.numeric(roc_run$roc_object$AUC[seq_along(params$times)]),
    marker_col = roc_run$marker_col,
    n_complete = roc_run$n_complete,
    n_events = roc_run$n_events,
    weighting = params$weighting,
    cause = params$cause,
    stringsAsFactors = FALSE
  )
}

validate_auc_table <- function(auc_table, params) {
  invalid_idx <- which(!is.finite(auc_table$auc))
  if (length(invalid_idx) == 0) {
    return(auc_table)
  }

  invalid_times <- paste(auc_table$time[invalid_idx], collapse = ",")
  stop(
    "SKILL_INVALID_DATA: Unusable AUC values were produced for time point(s): ",
    invalid_times,
    ". Try earlier time points within the observed follow-up range or check whether enough events remain informative at those times."
  )
}

extract_roc_points <- function(roc_run, params) {
  roc_points <- list()

  for (i in seq_along(params$times)) {
    fp <- extract_time_column(roc_run$roc_object$FP, i)
    tp <- extract_time_column(roc_run$roc_object$TP, i)

    point_df <- data.frame(
      false_positive_rate = as.numeric(fp),
      sensitivity = as.numeric(tp),
      time = params$times[i],
      time_unit = params$time_unit,
      auc = as.numeric(roc_run$roc_object$AUC[i]),
      curve_label = paste0(params$times[i], " ", params$time_unit, " (AUC = ", sprintf("%.3f", roc_run$roc_object$AUC[i]), ")"),
      stringsAsFactors = FALSE
    )

    point_df <- point_df[is.finite(point_df$false_positive_rate) & is.finite(point_df$sensitivity), , drop = FALSE]
    roc_points[[length(roc_points) + 1]] <- point_df
  }

  if (length(roc_points) == 0) {
    stop("SKILL_INVALID_DATA: No ROC curve points were produced for the requested time points")
  }

  do.call(rbind, roc_points)
}

apply_legend_position <- function(plot_obj, legend_position) {
  if (legend_position == "bottomright") {
    plot_obj + ggplot2::theme(legend.position = c(0.98, 0.02), legend.justification = c(1, 0))
  } else if (legend_position == "bottomleft") {
    plot_obj + ggplot2::theme(legend.position = c(0.02, 0.02), legend.justification = c(0, 0))
  } else if (legend_position == "topright") {
    plot_obj + ggplot2::theme(legend.position = c(0.98, 0.98), legend.justification = c(1, 1))
  } else if (legend_position == "topleft") {
    plot_obj + ggplot2::theme(legend.position = c(0.02, 0.98), legend.justification = c(0, 1))
  } else {
    plot_obj + ggplot2::theme(legend.position = legend_position)
  }
}

build_time_roc_plot <- function(roc_points, params) {
  roc_points$curve_label <- factor(roc_points$curve_label, levels = unique(roc_points$curve_label))

  plot_obj <- ggplot2::ggplot(
    roc_points,
    ggplot2::aes(x = false_positive_rate, y = sensitivity, color = curve_label, group = curve_label)
  ) +
    ggplot2::geom_line(linewidth = params$line_size, alpha = params$line_alpha, linetype = params$line_type) +
    ggplot2::labs(
      title = params$plot_title,
      x = params$x_label,
      y = params$y_label,
      color = params$legend_title
    ) +
    ggplot2::coord_cartesian(xlim = c(0, 1), ylim = c(0, 1), expand = FALSE) +
    ggplot2::theme_bw(base_size = params$theme_size) +
    ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5))

  if (length(levels(roc_points$curve_label)) <= length(params$line_colors)) {
    use_colors <- params$line_colors[seq_len(length(levels(roc_points$curve_label)))]
    plot_obj <- plot_obj + ggplot2::scale_color_manual(values = use_colors)
    if (isTRUE(params$area_show)) {
      plot_obj <- plot_obj + ggplot2::scale_fill_manual(values = use_colors)
    }
  }

  if (isTRUE(params$area_show)) {
    area_layers <- lapply(split(roc_points, roc_points$curve_label), function(df) {
      df <- df[order(df$false_positive_rate, df$sensitivity), , drop = FALSE]
      data.frame(
        false_positive_rate = c(0, df$false_positive_rate, 1),
        sensitivity = c(0, df$sensitivity, 0),
        curve_label = df$curve_label[1],
        stringsAsFactors = FALSE
      )
    })
    area_data <- do.call(rbind, area_layers)
    area_data$curve_label <- factor(area_data$curve_label, levels = levels(roc_points$curve_label))

    plot_obj <- plot_obj +
      ggplot2::geom_polygon(
        data = area_data,
        ggplot2::aes(x = false_positive_rate, y = sensitivity, fill = curve_label),
        color = NA,
        alpha = params$area_alpha,
        inherit.aes = FALSE,
        show.legend = FALSE
      )
  }

  if (isTRUE(params$diagonal_show)) {
    plot_obj <- plot_obj +
      ggplot2::geom_abline(
        intercept = 0,
        slope = 1,
        color = params$diagonal_color,
        linetype = params$diagonal_type,
        linewidth = params$diagonal_size,
        alpha = 0.6
      )
  }

  if (!isTRUE(params$legend_show)) {
    plot_obj <- plot_obj + ggplot2::theme(legend.position = "none")
  } else {
    plot_obj <- apply_legend_position(plot_obj, params$legend_position)
  }

  if (!isTRUE(params$theme_border)) {
    plot_obj <- plot_obj + ggplot2::theme(panel.border = ggplot2::element_blank(), axis.line = ggplot2::element_line(colour = "black"))
  }

  if (!isTRUE(params$theme_panel)) {
    plot_obj <- plot_obj + ggplot2::theme(panel.grid = ggplot2::element_blank())
  }

  plot_obj
}
