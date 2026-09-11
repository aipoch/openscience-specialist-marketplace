build_option_list <- function() {
  c(
    build_core_option_list(),
    build_model_option_list(),
    build_error_plot_option_list(),
    build_importance_plot_option_list()
  )
}
