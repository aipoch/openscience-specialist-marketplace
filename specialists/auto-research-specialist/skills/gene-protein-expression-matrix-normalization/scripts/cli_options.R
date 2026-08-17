build_option_list <- function() {
  list(
    optparse::make_option(c("-i", "--input_file"), type = "character", default = NULL,
      help = "Expression matrix file [required]", metavar = "file"),
    optparse::make_option(c("-o", "--output_dir"), type = "character", default = "./output",
      help = "Output directory [default: %default]", metavar = "dir"),
    optparse::make_option(c("-m", "--method"), type = "character", default = "log2",
      help = "Normalization method: log2, zscore, minmax [default: %default]"),
    optparse::make_option(c("-r", "--margin"), type = "character", default = "column",
      help = "Apply by row or column [default: %default]"),
    optparse::make_option(c("-p", "--pseudo_count"), type = "double", default = 1,
      help = "Pseudo-count used for log2 [default: %default]"),
    optparse::make_option(c("-c", "--center"), type = "character", default = "true",
      help = "Center values for z-score (true/false) [default: %default]"),
    optparse::make_option(c("-s", "--scale_values"), type = "character", default = "true",
      help = "Scale values for z-score (true/false) [default: %default]"),
    optparse::make_option(c("-t", "--timeout_seconds"), type = "integer", default = 0,
      help = "Optional timeout in seconds; 0 disables it [default: %default]"),
    optparse::make_option(c("-d", "--delimiter"), type = "character", default = "auto",
      help = "Input delimiter: auto, csv, tsv [default: %default]"),
    optparse::make_option(c("--seed"), type = "integer", default = 42,
      help = "Random seed [default: %default]"),
    optparse::make_option(c("--verbose"), type = "character", default = "true",
      help = "Verbose logging (true/false) [default: %default]")
  )
}

parse_main_args <- function() {
  parser <- optparse::OptionParser(
    option_list = build_option_list(),
    description = "Gene or protein expression matrix normalization"
  )
  opt <- optparse::parse_args(parser)
  opt$center <- as_bool(opt$center, TRUE, "--center")
  opt$scale_values <- as_bool(opt$scale_values, TRUE, "--scale_values")
  opt$verbose <- as_bool(opt$verbose, TRUE, "--verbose")
  opt
}
