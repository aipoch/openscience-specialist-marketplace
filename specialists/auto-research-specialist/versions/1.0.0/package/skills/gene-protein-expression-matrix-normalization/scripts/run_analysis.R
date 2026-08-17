validate_main_args <- function(opt) {
  if (is.null(opt$input_file) || !nzchar(opt$input_file)) {
    skill_stop("SKILL_INVALID_PARAMETER", "--input_file is required.")
  }
  if (!(opt$method %in% c("log2", "zscore", "minmax"))) {
    skill_stop("SKILL_INVALID_PARAMETER", "Unsupported --method.")
  }
  if (!(opt$margin %in% c("row", "column"))) {
    skill_stop("SKILL_INVALID_PARAMETER", "Unsupported --margin.")
  }
  if (!(opt$delimiter %in% c("auto", "csv", "tsv"))) {
    skill_stop("SKILL_INVALID_PARAMETER", "Unsupported --delimiter.")
  }
  if (is.na(opt$pseudo_count)) {
    skill_stop("SKILL_INVALID_PARAMETER", "--pseudo_count must be numeric.")
  }
  if (is.na(opt$seed)) {
    skill_stop("SKILL_INVALID_PARAMETER", "--seed must be an integer.")
  }
  if (is.na(opt$timeout_seconds) || opt$timeout_seconds < 0) {
    skill_stop("SKILL_INVALID_PARAMETER", "--timeout_seconds must be >= 0.")
  }
}

run_analysis <- function(opt) {
  validate_main_args(opt)

  if (opt$timeout_seconds > 0) {
    setTimeLimit(cpu = opt$timeout_seconds, elapsed = opt$timeout_seconds, transient = TRUE)
    on.exit(setTimeLimit(), add = TRUE)
  }

  tryCatch({
    set.seed(opt$seed)
    start_time <- Sys.time()

    if (dir_has_contents(opt$output_dir) && isTRUE(opt$verbose)) {
      log_warn(sprintf("Output directory already contains files and will be overwritten: %s", opt$output_dir))
    }
    ensure_dir(opt$output_dir)

    if (isTRUE(opt$verbose)) {
      log_info(sprintf("Starting normalization with method=%s, margin=%s", opt$method, opt$margin))
    }

    input_res <- read_expression_matrix(opt$input_file, delimiter = opt$delimiter, verbose = opt$verbose)
    normalized_mat <- normalize_matrix(
      input_res$matrix,
      method = opt$method,
      margin = opt$margin,
      pseudo_count = opt$pseudo_count,
      center = opt$center,
      scale_values = opt$scale_values
    )

    input_file_record <- make_relative_path(opt$input_file)
    output_dir_record <- make_relative_path(opt$output_dir)

    metadata <- list(
      input_file = input_file_record,
      method = opt$method,
      margin = opt$margin,
      delimiter = opt$delimiter,
      pseudo_count = opt$pseudo_count,
      center = opt$center,
      scale_values = opt$scale_values,
      timeout_seconds = opt$timeout_seconds,
      seed = opt$seed,
      verbose = opt$verbose
    )

    write_normalized_outputs(opt$output_dir, input_res$feature_col, input_res$matrix, normalized_mat, metadata)
    write_session_info(opt$output_dir)
    write_output_manifest(opt$output_dir, list(
      list(file = "table/normalized_matrix.csv", description = "Normalized expression matrix."),
      list(file = "table/feature_summary.csv", description = "Per-feature summary statistics before and after normalization."),
      list(file = "table/sample_summary.csv", description = "Per-sample summary statistics before and after normalization."),
      list(file = "data/normalized_matrix.rds", description = "Serialized normalized matrix and metadata."),
      list(file = "run_record.txt", description = "Structured execution record."),
      list(file = "output_manifest.txt", description = "Output manifest."),
      list(file = "session_info.txt", description = "R session information.")
    ))

    runtime <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
    write_run_record(opt$output_dir, list(
      input_file = input_file_record,
      method = opt$method,
      margin = opt$margin,
      delimiter = opt$delimiter,
      pseudo_count = opt$pseudo_count,
      center = opt$center,
      scale_values = opt$scale_values,
      timeout_seconds = opt$timeout_seconds,
      seed = opt$seed,
      verbose = opt$verbose,
      feature_count = nrow(input_res$matrix),
      sample_count = ncol(input_res$matrix),
      runtime_seconds = runtime,
      output_summary = sprintf("- output_summary: Wrote normalized matrix, summaries, manifest, and session metadata under %s", output_dir_record)
    ))

    if (isTRUE(opt$verbose)) {
      log_info(sprintf("Finished normalization; outputs written to %s", opt$output_dir))
    }

    invisible(normalized_mat)
  }, error = function(e) {
    rethrow_with_timeout_code(e, timeout_seconds = opt$timeout_seconds, context = "Normalization")
  })
}
