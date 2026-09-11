create_analyze_parser <- function() {
  OptionParser(
    description = "Run univariate and multivariable Cox regression analysis",
    option_list = list(
      make_option(c("-d", "--data_file"), type = "character", default = NULL,
                  help = "Clinical CSV file with sample IDs as row names [required]"),
      make_option(c("-f", "--features"), type = "character", default = "age,gender,stage,Tstage,Nstage,Mstage,risk",
                  help = "Comma-separated clinical features [default: %default]"),
      make_option(c("-t", "--time_col"), type = "character", default = "futime",
                  help = "Survival time column [default: %default]"),
      make_option(c("-e", "--event_col"), type = "character", default = "fustat",
                  help = "Survival event column (1=event, 0=censored) [default: %default]"),
      make_option(c("-u", "--skip_univariate"), type = "character", default = "false",
                  help = "Skip univariate analysis: true or false [default: %default]"),
      make_option(c("-o", "--output_dir"), type = "character", default = "./output/",
                  help = "Output directory [default: %default]"),
      make_option(c("--overwrite"), action = "store_true", default = FALSE,
                  help = "Allow writing into a non-empty output directory [default: %default]"),
      make_option(c("-s", "--seed"), type = "integer", default = 42,
                  help = "Random seed [default: %default]"),
      make_option(c("-T", "--timeout_seconds"), type = "integer", default = 0,
                  help = "Elapsed time limit in seconds; 0 disables timeout [default: %default]")
    )
  )
}

create_plot_parser <- function(description) {
  OptionParser(
    description = description,
    option_list = list(
      make_option(c("-d", "--data_file"), type = "character", default = NULL,
                  help = "Cox results file in XLSX, XLS, or CSV format [required]"),
      make_option(c("-p", "--plot_save"), type = "character", default = NULL,
                  help = "Output PDF file path [required]"),
      make_option(c("-w", "--width"), type = "double", default = 8,
                  help = "Plot width in inches [default: %default]"),
      make_option(c("-H", "--height"), type = "double", default = 6,
                  help = "Plot height in inches [default: %default]"),
      make_option(c("-F", "--font_size"), type = "double", default = 11,
                  help = "Font size for plot labels [default: %default]"),
      make_option(c("-s", "--seed"), type = "integer", default = 42,
                  help = "Random seed [default: %default]"),
      make_option(c("-T", "--timeout_seconds"), type = "integer", default = 0,
                  help = "Elapsed time limit in seconds; 0 disables timeout [default: %default]")
    )
  )
}

print_main_help <- function() {
  cat("Univariate and Multivariable Cox Regression Analysis\n")
  cat("Usage: Rscript scripts/main.R <command> [options]\n\n")
  cat("Commands:\n")
  cat("  analyze           Run univariate and multivariable Cox regression\n")
  cat("  forest-plot       Generate a forest plot from univariate Cox results\n")
  cat("  multi-forest-plot Generate a forest plot from multivariable Cox results\n\n")
  cat("Examples:\n")
  cat("  Rscript scripts/main.R analyze --data_file tests/data/sample_clinical_survival_data.csv --output_dir tests/expected_output --overwrite\n")
  cat("  Rscript scripts/main.R forest-plot --data_file tests/expected_output/table/prognosis_uni_cox_results.xlsx --plot_save tests/expected_output/plot/uni_forest_plot.pdf\n")
  cat("  Rscript scripts/main.R analyze --help\n")
}
