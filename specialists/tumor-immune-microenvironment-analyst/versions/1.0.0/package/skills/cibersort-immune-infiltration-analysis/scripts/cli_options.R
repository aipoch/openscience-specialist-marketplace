build_option_list <- function(script_dir) {
  default_signature <- file.path(script_dir, "..", "tests", "data", "LM22.txt")
  if (!file.exists(default_signature)) {
    default_signature <- NULL
  }
  list(
    optparse::make_option(c("-i", "--input_file"), type = "character", default = NULL,
      help = "Expression matrix file [required]", metavar = "file"),
    optparse::make_option(c("-g", "--group_file"), type = "character", default = NULL,
      help = "Group annotation file [required]", metavar = "file"),
    optparse::make_option(c("-a", "--case_group"), type = "character", default = NULL,
      help = "Case group label [required]"),
    optparse::make_option(c("-b", "--control_group"), type = "character", default = NULL,
      help = "Control group label [required]"),
    optparse::make_option(c("-o", "--output_dir"), type = "character", default = "./output",
      help = "Output directory [default: %default]", metavar = "dir"),
    optparse::make_option(c("--signature_file"), type = "character", default = default_signature,
      help = "Optional custom signature matrix file; defaults to packaged LM22 when present"),
    optparse::make_option(c("--sample_col"), type = "character", default = NULL,
      help = "Optional sample column name or 1-based index"),
    optparse::make_option(c("--group_col"), type = "character", default = NULL,
      help = "Optional group column name or 1-based index"),
    optparse::make_option(c("--gene_id_case"), type = "character", default = "upper",
      help = "Gene ID normalization: asis, upper, lower [default: %default]"),
    optparse::make_option(c("--auto_unlog"), type = "character", default = "true",
      help = "Apply 2^x only if the matrix passes a conservative log-scale heuristic (true/false) [default: %default]"),
    optparse::make_option(c("--min_mean_expression"), type = "double", default = 1,
      help = "Minimum mean expression filter [default: %default]"),
    optparse::make_option(c("--perm"), type = "integer", default = 1000,
      help = "Permutation count passed to cibersort when supported [default: %default]"),
    optparse::make_option(c("--qn"), type = "character", default = "true",
      help = "Quantile normalization flag when supported (true/false) [default: %default]"),
    optparse::make_option(c("--svm_cores"), type = "integer", default = 1,
      help = "Worker count used for the nu-SVR model selection step [default: %default]"),
    optparse::make_option(c("--make_plots"), type = "character", default = "true",
      help = "Generate PDF plots (true/false) [default: %default]"),
    optparse::make_option(c("--plot_width"), type = "double", default = 16,
      help = "Default plot width in inches [default: %default]"),
    optparse::make_option(c("--plot_height"), type = "double", default = 10,
      help = "Default plot height in inches [default: %default]"),
    optparse::make_option(c("-s", "--seed"), type = "integer", default = 42,
      help = "Random seed [default: %default]"),
    optparse::make_option(c("-t", "--timeout_seconds"), type = "integer", default = 0,
      help = "Optional timeout in seconds; 0 disables it [default: %default]"),
    optparse::make_option(c("--verbose"), type = "character", default = "true",
      help = "Verbose logging (true/false) [default: %default]")
  )
}

parse_main_args <- function(script_dir) {
  parser <- optparse::OptionParser(
    option_list = build_option_list(script_dir),
    description = "CIBERSORT immune infiltration analysis"
  )
  opt <- optparse::parse_args(parser)
  opt$auto_unlog <- as_bool(opt$auto_unlog, TRUE, "--auto_unlog")
  opt$qn <- as_bool(opt$qn, TRUE, "--qn")
  opt$make_plots <- as_bool(opt$make_plots, TRUE, "--make_plots")
  opt$verbose <- as_bool(opt$verbose, TRUE, "--verbose")
  if (!is.null(opt$sample_col) && grepl("^[0-9]+$", opt$sample_col)) {
    opt$sample_col <- as.integer(opt$sample_col)
  }
  if (!is.null(opt$group_col) && grepl("^[0-9]+$", opt$group_col)) {
    opt$group_col <- as.integer(opt$group_col)
  }
  opt
}
