build_core_option_list <- function() {
  list(
    optparse::make_option(c("-i", "--input_file"), type = "character", default = NULL,
      help = paste(
        "Expression matrix file with samples in rows and features in columns",
        "[required unless --plot_only TRUE]"
      ),
      metavar = "file"
    ),
    optparse::make_option(c("-g", "--group_file"), type = "character", default = NULL,
      help = "Group file with sample IDs in the first column [required unless --plot_only TRUE]", metavar = "file"
    ),
    optparse::make_option(c("-c", "--case_group"), type = "character", default = NULL,
      help = "Case group label [required unless --plot_only TRUE]", metavar = "label"
    ),
    optparse::make_option(c("-r", "--control_group"), type = "character", default = NULL,
      help = "Control group label [required unless --plot_only TRUE]", metavar = "label"
    ),
    optparse::make_option(c("-o", "--output_dir"), type = "character", default = "output",
      help = "Output directory inside the skill root [default %default]", metavar = "dir"
    ),
    optparse::make_option(c("-p", "--plot_only"), type = "logical", default = FALSE,
      help = paste(
        "Reuse an existing model from output_dir/data/rf_result.rds and regenerate plots;",
        "in this mode the raw input-file and group-label arguments are not required [default %default]"
      )
    ),
    optparse::make_option(c("-s", "--seed"), type = "integer", default = 42,
      help = "Random seed [default %default]", metavar = "int"
    ),
    optparse::make_option(c("-t", "--timeout_seconds"), type = "integer", default = 600,
      help = "Elapsed time limit in seconds [default %default]", metavar = "int"
    )
  )
}

build_model_option_list <- function() {
  list(
    optparse::make_option("--rf_ntree", type = "integer", default = 500,
      help = "Number of trees in the random forest [default %default]", metavar = "int"
    ),
    optparse::make_option("--rf_mtry", type = "integer", default = NA,
      help = "Number of variables sampled at each split [default NA = randomForest default]",
      metavar = "int"
    ),
    optparse::make_option("--rf_nodesize", type = "integer", default = NA,
      help = "Minimum terminal node size [default NA = randomForest default]", metavar = "int"
    ),
    optparse::make_option("--rf_imp_type", type = "integer", default = 1,
      help = "Importance metric type passed to randomForest::importance (1 or 2) [default %default]",
      metavar = "int"
    ),
    optparse::make_option("--rf_imp_threshold", type = "double", default = 0,
      help = "Minimum importance score to keep a feature in the top-features table [default %default]",
      metavar = "num"
    ),
    optparse::make_option("--rf_top_n", type = "integer", default = 30,
      help = "Maximum number of rows in the top-features table [default %default]", metavar = "int"
    )
  )
}
