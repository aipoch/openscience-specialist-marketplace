build_error_plot_option_list <- function() {
  list(
    optparse::make_option("--svm_error_height", type = "double", default = 5,
      help = "SVM error plot height in inches [default %default]", metavar = "num"),
    optparse::make_option("--svm_error_width", type = "double", default = 6,
      help = "SVM error plot width in inches [default %default]", metavar = "num"),
    optparse::make_option("--svm_error_xlab", type = "character", default = "Number of Features",
      help = "X-axis label for the SVM error plot [default %default]"),
    optparse::make_option("--svm_error_ylab", type = "character", default = "Classification Error Rate",
      help = "Y-axis label for the SVM error plot [default %default]"),
    optparse::make_option("--svm_error_main_line_color", type = "character", default = "black",
      help = "Main line color for the SVM error plot [default %default]"),
    optparse::make_option("--svm_error_second_line_color", type = "character", default = "#2BA2DE",
      help = "Secondary line color for the SVM error plot [default %default]"),
    optparse::make_option("--svm_error_best_point_color", type = "character", default = "red",
      help = "Color for the highlighted best point [default %default]"),
    optparse::make_option("--svm_error_noinfo_lty", type = "integer", default = 3,
      help = "Line type for the no-information baseline [default %default]", metavar = "int"),
    optparse::make_option("--svm_error_label_cex", type = "double", default = 0.75,
      help = "Label size for the best-point annotation [default %default]", metavar = "num"),
    optparse::make_option("--svm_error_label_pos", type = "integer", default = 4,
      help = "Label position for the best-point annotation [default %default]", metavar = "int")
  )
}

build_ranking_plot_option_list <- function() {
  list(
    optparse::make_option("--svm_rank_top_n", type = "integer", default = 20,
      help = "Maximum number of ranked features shown in the ranking plot [default %default]", metavar = "int"),
    optparse::make_option("--svm_rank_width", type = "double", default = 7,
      help = "Ranking plot width in inches [default %default]", metavar = "num"),
    optparse::make_option("--svm_rank_height", type = "double", default = 6,
      help = "Ranking plot height in inches [default %default]", metavar = "num"),
    optparse::make_option("--svm_rank_color", type = "character", default = "#2BA2DE",
      help = "Bar color for the ranking plot [default %default]"),
    optparse::make_option("--svm_rank_title", type = "character", default = "SVM-RFE Feature Ranking",
      help = "Title for the ranking plot [default %default]")
  )
}
