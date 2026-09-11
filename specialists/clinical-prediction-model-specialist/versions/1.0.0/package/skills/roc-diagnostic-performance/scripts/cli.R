create_core_option_list <- function() {
  list(
    make_option(c("-e", "--expression_file"), type = "character", default = NULL,
                help = "Expression matrix file in CSV/TSV format [required]"),
    make_option(c("-g", "--group_file"), type = "character", default = NULL,
                help = "Sample group file in CSV/TSV format [required]"),
    make_option(c("-m", "--marker_genes"), type = "character", default = NULL,
                help = "Comma-separated marker genes [required]"),
    make_option(c("-c", "--case_group"), type = "character", default = NULL,
                help = "Case group label in the group file [required]"),
    make_option(c("--group_col"), type = "character", default = NULL,
                help = "Optional group column name; auto-detected if omitted [default: %default]"),
    make_option(c("-o", "--output_dir"), type = "character", default = "./output/",
                help = "Output directory [default: %default]"),
    make_option(c("--overwrite"), action = "store_true", default = FALSE,
                help = "Allow writing into a non-empty output directory [default: %default]"),
    make_option(c("-s", "--seed"), type = "integer", default = 42,
                help = "Random seed [default: %default]"),
    make_option(c("-T", "--timeout_seconds"), type = "integer", default = 0,
                help = "Elapsed time limit in seconds; 0 disables timeout [default: %default]")
  )
}

create_plot_option_list <- function() {
  list(
    make_option(c("--plot_width"), type = "double", default = 6,
                help = "ROC plot width in inches [default: %default]"),
    make_option(c("--plot_height"), type = "double", default = 6,
                help = "ROC plot height in inches [default: %default]"),
    make_option(c("--font_family"), type = "character", default = "sans",
                help = "Font family for PDF output [default: %default]"),
    make_option(c("--line_colors"), type = "character", default = "#E64B35,#4DBBD5,#00A087,#3C5488,#F39B7F",
                help = "Comma-separated colors for ROC curves [default: %default]"),
    make_option(c("--line_width"), type = "double", default = 1.2,
                help = "ROC curve line width [default: %default]"),
    make_option(c("--show_diagonal"), type = "character", default = "true",
                help = "Show diagonal reference line: true or false [default: %default]"),
    make_option(c("--diagonal_color"), type = "character", default = "#7F7F7F",
                help = "Color of the diagonal reference line [default: %default]"),
    make_option(c("--diagonal_lty"), type = "integer", default = 2,
                help = "Line type for the diagonal reference line [default: %default]"),
    make_option(c("--plot_title"), type = "character", default = "ROC Diagnostic Performance",
                help = "Plot title [default: %default]"),
    make_option(c("--x_label"), type = "character", default = "1 - Specificity",
                help = "X-axis label [default: %default]"),
    make_option(c("--y_label"), type = "character", default = "Sensitivity",
                help = "Y-axis label [default: %default]"),
    make_option(c("--base_cex"), type = "double", default = 0.9,
                help = "Base text size multiplier for the plot [default: %default]"),
    make_option(c("--legend_position"), type = "character", default = "bottomright",
                help = "Legend position [default: %default]"),
    make_option(c("--legend_cex"), type = "double", default = 0.8,
                help = "Legend text size [default: %default]")
  )
}

create_parser <- function() {
  OptionParser(
    description = "Diagnostic ROC analysis using logistic regression",
    option_list = c(create_core_option_list(), create_plot_option_list())
  )
}
