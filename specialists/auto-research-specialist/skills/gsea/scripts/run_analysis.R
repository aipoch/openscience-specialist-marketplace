run_gsea_pipeline <- function(
  input,
  outdir = "GSEA_analysis",
  gene_col = "name",
  fc_col = "logFC",
  type = "KEGG",
  species = "human",
  method = "fgsea",
  pvalue_cutoff = 0.05,
  chunk_size = 1000,
  verbose = FALSE,
  rds_path = NULL,
  seed = 42,
  script_dir = ".",
  timeout_seconds = 300
) {
  # Set random seed
  set.seed(seed)
  if (!is.null(timeout_seconds) && is.finite(timeout_seconds) && timeout_seconds > 0) {
    setTimeLimit(elapsed = timeout_seconds, transient = TRUE)
    on.exit(setTimeLimit(cpu = Inf, elapsed = Inf, transient = FALSE), add = TRUE)
  }
  
  # Validate input file before loading heavy packages
  validate_existing_file(input, "Input file")
  if (!is.null(rds_path)) {
    validate_existing_file(rds_path, "rds_path")
  }
  
  # Create output directory
  if (!dir.exists(outdir)) {
    dir.create(outdir, recursive = TRUE)
  }
  outdir <- normalizePath(outdir, mustWork = FALSE)
  if (verbose) {
    log_info(paste("Created output directory:", outdir))
  }
  
  data_dir <- file.path(outdir, "data")
  table_dir <- file.path(outdir, "Table")
  plot_dir <- file.path(outdir, "plot")
  
  # Read input data
  if (verbose) {
    log_info(paste("Reading input data from:", input))
  }
  
  input_data <- read.csv(input)
  
  # Check required columns
  if (!gene_col %in% colnames(input_data)) {
    skill_stop("SKILL_MISSING_COLUMNS", paste("Gene column not found:", gene_col, 
               ". Available columns:", paste(colnames(input_data), collapse = ", ")))
  }
  
  if (!fc_col %in% colnames(input_data)) {
    skill_stop("SKILL_MISSING_COLUMNS", paste("Fold change column not found:", fc_col,
               ". Available columns:", paste(colnames(input_data), collapse = ", ")))
  }
  
  # Prepare gene list
  gene_list <- data.frame(
    gene = as.character(input_data[[gene_col]]),
    logFC = as.numeric(input_data[[fc_col]])
  )
  
  # Remove NA values
  gene_list <- gene_list[!is.na(gene_list$gene) & !is.na(gene_list$logFC), ]
  gene_list <- gene_list[gene_list$gene != "", ]
  
  if (nrow(gene_list) == 0) {
    skill_stop("SKILL_EMPTY_DATA", "No valid gene data found after filtering NA values")
  }
  
  if (verbose) {
    log_info(paste("Prepared gene list with", nrow(gene_list), "genes"))
  }
  
  # Load required packages only after cheap validation passes
  load_gsea_packages()
  
  # Load gene sets
  if (verbose) {
    log_info(paste("Loading gene sets for", species, "(", type, ")..."))
  }
  
  msigdbr_data <- NULL
  if (is.null(rds_path)) {
    default_rds_path <- file.path(dirname(script_dir), "assets", "ssGSEA.rds")
    if (file.exists(default_rds_path)) {
      rds_path <- default_rds_path
      if (verbose) {
        log_info(paste("Using default RDS file from assets directory:", default_rds_path))
      }
    }
  }
  if (!is.null(rds_path)) {
    msigdbr_data <- readRDS(rds_path)
  }
  
  term2gene <- load_msigdb_sets(species, type, msigdbr_data, chunk_size, verbose)
  
  if (nrow(term2gene) == 0) {
    skill_stop("SKILL_EMPTY_DATA", "No gene sets loaded. Check species and type parameters.")
  }
  
  # Run GSEA analysis
  if (verbose) {
    log_info("Starting GSEA analysis...")
    log_info(paste("  Method:", method))
    log_info(paste("  P-value cutoff:", pvalue_cutoff))
    log_info(paste("  Species:", species))
    log_info(paste("  Gene set type:", type))
  }
  
  gsea_result <- run_gsea_analysis(
    gene_list = gene_list,
    term2gene = term2gene,
    method = method,
    pvalueCutoff = pvalue_cutoff,
    verbose = verbose
  )
  
  # Convert to data frame
  gsea_df <- as.data.frame(gsea_result)
  
  # Create output directories
  dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(plot_dir, recursive = TRUE, showWarnings = FALSE)
  
  # Save results
  GSEA_list <- list(
    gsea_df = gsea_df,
    gsea_result = gsea_result,
    gene_list = gene_list,
    term2gene = term2gene,
    parameters = list(
      species = species,
      type = type,
      method = method,
      pvalue_cutoff = pvalue_cutoff,
      input_file = input,
      gene_col = gene_col,
      fc_col = fc_col,
      total_genes = nrow(gene_list)
    )
  )
  
  save(GSEA_list, file = file.path(data_dir, "GSEA_list.rda"))
  write.csv(gsea_df, file.path(table_dir, "enrichGSEA.csv"), row.names = FALSE)
  
  running_score_path <- file.path(table_dir, "gsea_running_scores.csv")

  # Generate and save running score table
  if (nrow(gsea_df) > 0) {
    if (verbose) {
      log_info("Generating running score table for all pathways...")
    }
    
    # Sort by p.adjust
    res_sorted <- gsea_result@result[order(gsea_result@result$p.adjust), ]
    
    if (nrow(res_sorted) > 6) {
      if (verbose) {
        log_info("Limiting running score table to top 6 pathways to reduce file size...")
      }
      all_ids <- res_sorted$ID[1:6]
    } else {
      all_ids <- res_sorted$ID
    }
    
    running_score_list <- lapply(all_ids, function(id) {
      extract_gsea_data(gsea_result, id)
    })
    running_score_df <- do.call(rbind, running_score_list)
    write.csv(
      running_score_df,
      running_score_path,
      row.names = FALSE,
      quote = FALSE
    )
  } else {
    empty_running_score_df <- data.frame(
      Description = character(),
      Symbol = character(),
      x = integer(),
      runningScore = numeric(),
      position = integer(),
      ymin = numeric(),
      ymax = numeric(),
      geneList = numeric(),
      stringsAsFactors = FALSE
    )
    write.csv(
      empty_running_score_df,
      running_score_path,
      row.names = FALSE,
      quote = FALSE
    )
    if (verbose) {
      log_info("No enrichment found; wrote empty gsea_running_scores.csv")
    }
  }
  
  # Save session info and emit summary
  save_session_info(outdir)
  
  # Create opt object for emit_run_summary
  opt_summary <- list(
    outdir = outdir,
    species = species,
    type = type,
    method = method
  )
  
  emit_run_summary(opt_summary)

  # Return results invisibly
  invisible(GSEA_list)
}

run_gsea_plotting <- function(
  running_file,
  enrich_file,
  plot_output = "gsea_plot.pdf",
  plot_width = 8,
  plot_height = 6,
  plot_format = "pdf",
  top_n = 1,
  rank_by = "p.adjust",
  geneSetID = "",
  plot_title = "",
  colors = "#4DBBD5,#E64B35,#00A087,#F39B7F,#3C5488,#8491B4",
  base_size = 11,
  subplots = "1,2,3",
  rel_heights = "1.5,0.8,1",
  NES_table = TRUE,
  NES_label_size = 4,
  NES_label_x = 0.75,
  NES_label_y = 0.75,
  NES_label_color = "black",
  NES_label_hjust = 0,
  NES_label_vjust = 1,
  line_width = 1,
  dot_size = 1.2,
  legend_position = "auto",
  legend_x = 0.02,
  legend_y = 0.02,
  legend_just_x = 0,
  legend_just_y = 0,
  legend_text_size = 9,
  legend_key_size = 0.6,
  legend_bg_alpha = 0,
  grid_major_color = "grey92",
  grid_minor_color = "grey92",
  ylab_es = "Enrichment Score",
  ylab_rank = "Ranked List Metric",
  xlab_rank = "Rank in Ordered Dataset",
  hit_height = 1,
  hit_gap = 0,
  hit_linewidth = 0.5,
  rank_bar_alpha = 0.9,
  rank_bar_height_ratio = 0.3,
  rank_metric_segment_color = "grey",
  rank_metric_segment_width = 0.3,
  rank_metric_segment_alpha = 1,
  pvalue_table = FALSE,
  ES_geom = "line",
  verbose = FALSE,
  timeout_seconds = 300
) {
  if (!is.null(timeout_seconds) && is.finite(timeout_seconds) && timeout_seconds > 0) {
    setTimeLimit(elapsed = timeout_seconds, transient = TRUE)
    on.exit(setTimeLimit(cpu = Inf, elapsed = Inf, transient = FALSE), add = TRUE)
  }

  # Validate required files
  validate_existing_file(running_file, "running_file")
  validate_existing_file(enrich_file, "enrich_file")
  
  # Validate plot format
  if (!plot_format %in% c("pdf", "png")) {
    skill_stop("SKILL_INVALID_PARAMETER", "plot_format must be 'pdf' or 'png'")
  }
  if (!is.numeric(top_n) || top_n <= 0) {
    skill_stop("SKILL_INVALID_PARAMETER", "top_n must be greater than 0")
  }
  
  # Load enrichment data
  if (verbose) {
    log_info(paste("Loading enrichment data from:", enrich_file))
  }
  enrich <- data.table::fread(enrich_file)
  if (!"ID" %in% names(enrich)) {
    skill_stop("SKILL_MISSING_COLUMNS", "enrich_file must contain column 'ID'")
  }
  enrich <- as.data.frame(enrich)
  rownames(enrich) <- enrich$ID
  
  # Load running score data
  if (verbose) {
    log_info(paste("Loading running score data from:", running_file))
  }
  gsdata <- data.table::fread(running_file)
  attr(enrich, "gsdata") <- gsdata
  
  # Determine geneSetID
  if (!is.null(geneSetID) && geneSetID != "") {
    geneSetID <- trimws(strsplit(geneSetID, ",", fixed = TRUE)[[1]])
  } else {
    if (!rank_by %in% names(enrich)) {
      skill_stop("SKILL_INVALID_PARAMETER", paste("rank_by column not found in enrich file:", rank_by))
    }
    ord <- order(enrich[[rank_by]], na.last = TRUE)
    geneSetID <- enrich$ID[ord][seq_len(min(top_n, nrow(enrich)))]
  }
  
  # Generate title if not provided
  if (!is.null(plot_title) && plot_title != "") {
    title <- plot_title
  } else {
    if (length(geneSetID) == 1) {
      title <- format_pathway_label(enrich[geneSetID[1], "Description"])
    } else {
      title <- ""
    }
  }
  
  # Parse color palette
  pal <- trimws(strsplit(colors, ",", fixed = TRUE)[[1]])
  if (length(pal) < length(geneSetID)) pal <- rep(pal, length.out = length(geneSetID))
  
  # Parse numeric vectors
  subplots_vec <- parse_int_vec(subplots)
  if (is.null(subplots_vec)) subplots_vec <- 1:3
  rel_heights_vec <- parse_num_vec(rel_heights)
  if (is.null(rel_heights_vec)) rel_heights_vec <- c(1.5, 0.8, 1)
  
  # Create plot
  if (verbose) {
    log_info(paste("Generating GSEA plot for", length(geneSetID), "pathway(s)"))
  }
  gseaplot <- myGSEA(
    enrich,
    geneSetID = geneSetID,
    title = title,
    pvalue_table = isTRUE(pvalue_table),
    NES_table = isTRUE(NES_table),
    NES_label_size = NES_label_size,
    NES_label_x = NES_label_x,
    NES_label_y = NES_label_y,
    NES_label_color = NES_label_color,
    NES_label_hjust = NES_label_hjust,
    NES_label_vjust = NES_label_vjust,
    line_width = line_width,
    dot_size = dot_size,
    legend_position = legend_position,
    legend_x = legend_x,
    legend_y = legend_y,
    legend_just_x = legend_just_x,
    legend_just_y = legend_just_y,
    legend_text_size = legend_text_size,
    legend_key_size = legend_key_size,
    legend_bg_alpha = legend_bg_alpha,
    grid_major_color = grid_major_color,
    grid_minor_color = grid_minor_color,
    ylab_es = ylab_es,
    ylab_rank = ylab_rank,
    xlab_rank = xlab_rank,
    hit_height = hit_height,
    hit_gap = hit_gap,
    hit_linewidth = hit_linewidth,
    rank_bar_alpha = rank_bar_alpha,
    rank_bar_height_ratio = rank_bar_height_ratio,
    rank_metric_segment_color = rank_metric_segment_color,
    rank_metric_segment_width = rank_metric_segment_width,
    rank_metric_segment_alpha = rank_metric_segment_alpha,
    base_size = base_size,
    subplots = subplots_vec,
    rel_heights = rel_heights_vec,
    color = pal,
    ES_geom = ES_geom
  )
  
  # Ensure output directory exists
  outdir <- dirname(plot_output)
  if (!dir.exists(outdir)) dir.create(outdir, recursive = TRUE)
  
  # Save plot
  if (verbose) {
    log_info(paste("Saving plot to:", plot_output))
  }
  save_plot_file(plot_output, gseaplot, plot_format, plot_width, plot_height)
  
  log_info(paste("GSEA plot saved successfully:", plot_output))
  
  # Emit summary
  cat("\n========================================\n")
  cat("GSEA Plotting Complete\n")
  cat("========================================\n")
  cat("Plot file:", plot_output, "\n")
  cat("Pathways plotted:", length(geneSetID), "\n")
  if (length(geneSetID) <= 5) {
    cat("Pathways:", paste(geneSetID, collapse = ", "), "\n")
  }
  cat("Dimensions:", plot_width, "x", plot_height, "inches\n")
  cat("Format:", plot_format, "\n")
  cat("========================================\n")
  
  invisible(plot_output)
}