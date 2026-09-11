build_error_plot_option_list <- function() {
  list(
    optparse::make_option("--rf_error_xlab", type = "character", default = "Number of Trees",
      help = "X-axis label for the RF error plot [default %default]"
    ),
    optparse::make_option("--rf_error_ylab", type = "character", default = "Error",
      help = "Y-axis label for the RF error plot [default %default]"
    ),
    optparse::make_option("--rf_error_line_size", type = "double", default = 0.6,
      help = "Line width for the RF error plot [default %default]", metavar = "num"
    ),
    optparse::make_option("--rf_error_line_alpha", type = "double", default = 1,
      help = "Line alpha for the RF error plot [default %default]", metavar = "num"
    ),
    optparse::make_option("--rf_error_line_color", type = "character",
      default = "#6C85F9,#D9503D,#939DE4,#DEA441,#A2C6D6,#E9B9E1,#BDD69F,#EBC98A",
      help = "Comma-separated non-OOB line colors for the RF error plot"
    ),
    optparse::make_option("--rf_error_line_type", type = "character", default = "dashed",
      help = "Line type for class-specific RF error curves [default %default]"
    ),
    optparse::make_option("--rf_error_line_oob_type", type = "character", default = "solid",
      help = "Line type for the OOB RF error curve [default %default]"
    ),
    optparse::make_option("--rf_error_legend_position", type = "character", default = "none",
      help = "Legend position for the RF error plot [default %default]"
    ),
    optparse::make_option("--rf_error_border_color", type = "character", default = "black",
      help = "Panel border color for the RF error plot [default %default]"
    ),
    optparse::make_option("--rf_error_border_fill", type = "character", default = "NA",
      help = "Panel border fill for the RF error plot; use NA or NULL as text [default %default]"
    ),
    optparse::make_option("--rf_error_border_size", type = "double", default = 0.8,
      help = "Panel border line width for the RF error plot [default %default]", metavar = "num"
    ),
    optparse::make_option("--rf_error_base_size", type = "double", default = 14,
      help = "Base font size for the RF error plot [default %default]", metavar = "num"
    ),
    optparse::make_option("--rf_error_width", type = "double", default = 6,
      help = "RF error plot width in inches [default %default]", metavar = "num"
    ),
    optparse::make_option("--rf_error_height", type = "double", default = 5,
      help = "RF error plot height in inches [default %default]", metavar = "num"
    )
  )
}

build_importance_plot_option_list <- function() {
  list(
    optparse::make_option("--rf_importance_sort", type = "logical", default = TRUE,
      help = "Sort variables in the RF importance plot [default %default]"
    ),
    optparse::make_option("--rf_importance_top_n", type = "integer", default = 10,
      help = "Maximum number of variables in the RF importance plot [default %default]",
      metavar = "int"
    ),
    optparse::make_option("--rf_importance_label_x_ann", type = "logical", default = TRUE,
      help = "Show x-axis tick labels in the RF importance plot [default %default]"
    ),
    optparse::make_option("--rf_importance_label_color", type = "character", default = "black",
      help = "Text and point outline color in the RF importance plot [default %default]"
    ),
    optparse::make_option("--rf_importance_label_cex", type = "double", default = 0.9,
      help = "Label size in the RF importance plot [default %default]", metavar = "num"
    ),
    optparse::make_option("--rf_importance_point_cex", type = "double", default = 0.9,
      help = "Point size in the RF importance plot [default %default]", metavar = "num"
    ),
    optparse::make_option("--rf_importance_point_shape", type = "integer", default = 23,
      help = "Point shape in the RF importance plot [default %default]", metavar = "int"
    ),
    optparse::make_option("--rf_importance_point_fill", type = "character", default = "red",
      help = "Point fill color in the RF importance plot [default %default]"
    ),
    optparse::make_option("--rf_importance_line_color", type = "character", default = "gray",
      help = "Segment color in the RF importance plot [default %default]"
    ),
    optparse::make_option("--rf_importance_theme_border", type = "logical", default = TRUE,
      help = "Draw a border around RF importance panels [default %default]"
    ),
    optparse::make_option("--rf_importance_theme_offset", type = "double", default = 0.2,
      help = "Axis expansion factor for the RF importance plot [default %default]", metavar = "num"
    ),
    optparse::make_option("--rf_importance_title", type = "character", default = "Variable Importance",
      help = "Main title for the RF importance plot [default %default]"
    ),
    optparse::make_option("--rf_importance_title_x_ann", type = "logical", default = TRUE,
      help = "Show the RF importance plot title and axis annotations [default %default]"
    ),
    optparse::make_option("--rf_importance_width", type = "double", default = 6,
      help = "RF importance plot width in inches [default %default]", metavar = "num"
    ),
    optparse::make_option("--rf_importance_height", type = "double", default = 5,
      help = "RF importance plot height in inches [default %default]", metavar = "num"
    )
  )
}
