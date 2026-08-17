save_cv_plot <- function(cv_fit, output_file, title_text = "") {
  grDevices::pdf(output_file, width = 7, height = 6)
  on.exit(grDevices::dev.off(), add = TRUE)
  plot(cv_fit)
  if (nzchar(title_text))
    title(main = title_text)
}

save_coefficient_path_plot <- function(fit, cv_fit, output_file, title_text = "") {
  grDevices::pdf(output_file, width = 7, height = 6)
  on.exit(grDevices::dev.off(), add = TRUE)
  plot(fit, xvar = "lambda", label = FALSE)
  graphics::abline(v = log(cv_fit$lambda.min), col = "red", lty = 2)
  if (nzchar(title_text))
    title(main = title_text)
}
