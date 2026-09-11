build_core_option_list <- function() {
  list(
    optparse::make_option(c("-i", "--input_file"), type = "character", default = NULL,
      help = "Expression matrix file with samples in rows and features in columns [required unless --plot_only TRUE]", metavar = "file"),
    optparse::make_option(c("-g", "--group_file"), type = "character", default = NULL,
      help = "Group file with sample IDs in the first column [required unless --plot_only TRUE]", metavar = "file"),
    optparse::make_option(c("-c", "--case_group"), type = "character", default = NULL,
      help = "Case group label [required unless --plot_only TRUE]", metavar = "label"),
    optparse::make_option(c("-r", "--control_group"), type = "character", default = NULL,
      help = "Control group label [required unless --plot_only TRUE]", metavar = "label"),
    optparse::make_option(c("-o", "--output_dir"), type = "character", default = "output",
      help = "Output directory inside the skill root [default %default]", metavar = "dir"),
    optparse::make_option(c("-p", "--plot_only"), type = "logical", default = FALSE,
      help = "Reuse an existing model from output_dir/data/svm_result.rds and regenerate plots; in this mode the raw input-file and group-label arguments are not required [default %default]"),
    optparse::make_option(c("-s", "--seed"), type = "integer", default = 42,
      help = "Random seed [default %default]", metavar = "int"),
    optparse::make_option(c("-t", "--timeout_seconds"), type = "integer", default = 600,
      help = "Elapsed time limit in seconds [default %default]", metavar = "int")
  )
}

build_model_option_list <- function() {
  list(
    optparse::make_option("--svm_k", type = "integer", default = 10,
      help = "Number of stratified folds for outer cross-validation [default %default]", metavar = "int"),
    optparse::make_option("--svm_halve_above", type = "integer", default = 50,
      help = "If surviving features exceed this count, remove half per iteration [default %default]", metavar = "int"),
    optparse::make_option("--svm_max_features_cap", type = "integer", default = 30,
      help = "Maximum feature count evaluated on the error curve [default %default]", metavar = "int"),
    optparse::make_option("--svm_select_rule", type = "character", default = "min",
      help = "Feature-count rule: min or tolerance [default %default]"),
    optparse::make_option("--svm_tol", type = "double", default = 0.01,
      help = "Tolerance used when --svm_select_rule tolerance is selected [default %default]", metavar = "num")
  )
}
