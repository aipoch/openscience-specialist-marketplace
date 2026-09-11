#!/usr/bin/env Rscript

build_option_parser <- function() {
  option_list <- list(
    optparse::make_option(
      c("-i", "--input_file"),
      type = "character",
      default = NULL,
      help = "Input expression matrix file in CSV or TSV format [required].",
      metavar = "file"
    ),
    optparse::make_option(
      c("-o", "--output_dir"),
      type = "character",
      default = "./output",
      help = "Output directory [default %default].",
      metavar = "dir"
    ),
    optparse::make_option(
      c("--group_file"),
      type = "character",
      default = NULL,
      help = "Optional sample group file for ESTIMATE score boxplots and group-wise statistics.",
      metavar = "file"
    ),
    optparse::make_option(
      c("-g", "--gene_id_type"),
      type = "character",
      default = "GeneSymbol",
      help = "Gene identifier type passed to estimate::filterCommonGenes: GeneSymbol or EntrezID [default %default]."
    ),
    optparse::make_option(
      c("-p", "--platform"),
      type = "character",
      default = "affymetrix",
      help = "Platform passed to estimate::estimateScore: affymetrix, agilent, or illumina [default %default]."
    ),
    optparse::make_option(
      c("-s", "--seed"),
      type = "integer",
      default = 42,
      help = "Random seed [default %default]."
    ),
    optparse::make_option(
      c("-t", "--timeout_seconds"),
      type = "integer",
      default = 0,
      help = "Optional timeout in seconds; 0 disables timeout [default %default]."
    ),
    optparse::make_option(
      c("--input_delimiter"),
      type = "character",
      default = "auto",
      help = "Input delimiter hint: auto, csv, or tsv [default %default]."
    ),
    optparse::make_option(
      c("--group_delimiter"),
      type = "character",
      default = "auto",
      help = "Group file delimiter hint: auto, csv, or tsv [default %default]."
    ),
    optparse::make_option(
      c("--sample_column"),
      type = "character",
      default = "sample",
      help = "Sample column in the group file [default %default]."
    ),
    optparse::make_option(
      c("--group_column"),
      type = "character",
      default = "group",
      help = "Group column in the group file [default %default]."
    ),
    optparse::make_option(
      c("--plot_file"),
      type = "character",
      default = "estimate_scores_boxplot.pdf",
      help = "Plot file name under plot/ when group_file is provided [default %default]."
    ),
    optparse::make_option(
      c("--heatmap_file"),
      type = "character",
      default = "estimate_scores_heatmap.pdf",
      help = "Heatmap file name under plot/ [default %default]."
    )
  )

  optparse::OptionParser(
    option_list = option_list,
    description = "Run ESTIMATE immune score analysis from a bulk expression matrix."
  )
}

validate_cli_options <- function(opt) {
  validate_existing_file(opt$input_file, "input_file")
  if (!is.null(opt$group_file) && nzchar(opt$group_file)) {
    validate_existing_file(opt$group_file, "group_file")
  }
  validate_choice(opt$gene_id_type, c("GeneSymbol", "EntrezID"), "gene_id_type")
  validate_choice(opt$platform, c("affymetrix", "agilent", "illumina"), "platform")
  validate_choice(opt$input_delimiter, c("auto", "csv", "tsv"), "input_delimiter")
  validate_choice(opt$group_delimiter, c("auto", "csv", "tsv"), "group_delimiter")
  validate_positive_integer(opt$seed, "seed", allow_zero = TRUE)
  validate_positive_integer(opt$timeout_seconds, "timeout_seconds", allow_zero = TRUE)
  validate_safe_filename(opt$plot_file, "plot_file")
  validate_safe_filename(opt$heatmap_file, "heatmap_file")
  opt
}
