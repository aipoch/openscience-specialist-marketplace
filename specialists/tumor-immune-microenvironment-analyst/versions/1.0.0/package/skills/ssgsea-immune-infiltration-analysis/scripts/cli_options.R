build_option_list <- function(script_dir) {
  list(
    optparse::make_option(c("-i", "--input_file"), type = "character", default = NULL,
      help = "Expression matrix file [required]", metavar = "file"),
    optparse::make_option(c("-g", "--group_file"), type = "character", default = NULL,
      help = "Group annotation file [required]", metavar = "file"),
    optparse::make_option(c("-o", "--output_dir"), type = "character", default = "./output",
      help = "Output directory [default: %default]", metavar = "dir"),
    optparse::make_option(c("-s", "--seed"), type = "integer", default = 42,
      help = "Random seed [default: %default]"),
    optparse::make_option(c("-t", "--timeout_seconds"), type = "integer", default = 0,
      help = "Optional CPU timeout in seconds; 0 disables timeout [default: %default]"),
    optparse::make_option(c("-m", "--method"), type = "character", default = "ssgsea",
      help = "GSVA method: ssgsea, gsva [default: %default]"),
    optparse::make_option(c("-k", "--kcdf"), type = "character", default = "Gaussian",
      help = "Kernel mode: Gaussian, Poisson [default: %default]"),
    optparse::make_option(c("-n", "--min_sz"), type = "integer", default = 2,
      help = "Minimum genes per gene set [default: %default]"),
    optparse::make_option(c("-x", "--max_sz"), type = "integer", default = 10000,
      help = "Maximum genes per gene set [default: %default]"),
    optparse::make_option(c("-p", "--parallel_sz"), type = "integer", default = 2,
      help = "Requested parallel CPU size [default: %default]"),
    optparse::make_option(c("-u", "--tau"), type = "double", default = 0.25,
      help = "Tau parameter for ssGSEA [default: %default]"),
    optparse::make_option(c("-d", "--mx_diff"), type = "character", default = "true",
      help = "mx.diff for GSVA (true/false) [default: %default]"),
    optparse::make_option(c("-c", "--gene_id_case"), type = "character", default = "upper",
      help = "Gene ID normalization: asis, upper, lower [default: %default]"),
    optparse::make_option(c("-e", "--gene_set"), type = "character",
      default = file.path(script_dir, "..", "tests", "data", "immune_gene_sets.csv"),
      help = "Gene set CSV file [default: %default]", metavar = "file"),
    optparse::make_option(c("-a", "--case_group"), type = "character", default = NULL,
      help = "Case group name [required]"),
    optparse::make_option(c("-b", "--control_group"), type = "character", default = NULL,
      help = "Control group name [required]"),
    optparse::make_option(c("--sample_col"), type = "character", default = NULL,
      help = "Optional sample column name or 1-based index"),
    optparse::make_option(c("--group_col"), type = "character", default = NULL,
      help = "Optional group column name or 1-based index"),
    optparse::make_option(c("--make_plots"), type = "character", default = "true",
      help = "Generate PDF plots (true/false) [default: %default]"),
    optparse::make_option(c("--verbose"), type = "character", default = "true",
      help = "Verbose logging (true/false) [default: %default]")
  )
}

parse_main_args <- function(script_dir) {
  parser <- optparse::OptionParser(
    option_list = build_option_list(script_dir),
    description = "ssGSEA immune infiltration analysis"
  )
  opt <- optparse::parse_args(parser)
  opt$mx_diff <- as_bool(opt$mx_diff, TRUE, "--mx_diff")
  opt$make_plots <- as_bool(opt$make_plots, TRUE, "--make_plots")
  opt$verbose <- as_bool(opt$verbose, TRUE, "--verbose")
  opt$sample_col <- if (!is.null(opt$sample_col) && grepl("^[0-9]+$", opt$sample_col)) as.integer(opt$sample_col) else opt$sample_col
  opt$group_col <- if (!is.null(opt$group_col) && grepl("^[0-9]+$", opt$group_col)) as.integer(opt$group_col) else opt$group_col
  opt
}
