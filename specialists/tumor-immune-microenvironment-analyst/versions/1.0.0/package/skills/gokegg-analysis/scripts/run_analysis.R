run_gokegg_analysis <- function(feature, output_dir, sp, pAdjustMethod,
                                gene_type, pvalue_cutoff, qvalue_cutoff) {
  check_feature_input(feature)
  check_pkgs(c("clusterProfiler", "dplyr", "stringr"))
  species_info <- load_species_db(sp)
  org_db <- species_info$db
  kegg_org <- species_info$kegg_org
  log_info("Step 1/5: Obtain genes...")
  genes <- parse_feature_genes(feature)
  log_info(paste("feature for analysis:", paste(genes, collapse = ",")))

  log_info("Step 2/5: Convert gene IDs...")
  genes_id <- if (gene_type == "ENTREZID") {
    log_info("Input genes already in ENTREZID format")
    data.frame(ENTREZID = genes, stringsAsFactors = FALSE)
  } else {
    bitr(genes, fromType = gene_type, toType = "ENTREZID", OrgDb = sp, drop = TRUE)
  }
  if (is.null(genes_id) || nrow(genes_id) == 0) skill_stop("SKILL_EMPTY_DATA", "No genes could be converted to ENTREZID")

  log_info(paste("Step 3/5: GO enrichment analysis..."))
  ego_result <- enrichGO_analysis(genes_id, sp, pvalue_cutoff, qvalue_cutoff, pAdjustMethod)
  ego_df <- as.data.frame(ego_result)
  GO_list <- list(
    ego_df = ego_df,
    ego_result = ego_result,
    genes = genes,
    genes_id = genes_id,
    parameters = list(
      species = sp,
      gene_type = gene_type,
      pvalue_cutoff = pvalue_cutoff,
      qvalue_cutoff = qvalue_cutoff,
      input_genes = length(genes),
      converted_genes = nrow(genes_id)
    )
  )

  temp_dir <- file.path(output_dir, "temp")
  dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)
  save_analysis_outputs(GO_list, ego_df, "GO", temp_dir, object_name = "GO_list")

  log_info(paste("Step 4/5: KEGG enrichment analysis..."))
  ekegg <- enrichKEGG_analysis(genes_id, kegg_org, pvalue_cutoff, qvalue_cutoff, pAdjustMethod)
  script_dir <- get_script_dir()
  assets_dir <- file.path(dirname(script_dir), "assets")
  kegg_name_file <- file.path(assets_dir, "KEGG_pathway_name.txt")
  validate_existing_file(kegg_name_file, "KEGG pathway mapping")
  kegg_name <- read.table(kegg_name_file, sep='\t', header = TRUE, stringsAsFactors = FALSE)
  rownames(kegg_name) <- kegg_name$path_id
  ekegg@result$Description <- kegg_name[ekegg@result$ID, 'path_name']
  ekegg@result$ONTOLOGY <- kegg_name[ekegg@result$ID, 'path_class']
  ekegg_list <- data.frame(ekegg)
  if (nrow(ekegg_list) > 0 && gene_type != "ENTREZID") {
    entrezid_list <- strsplit(ekegg_list$geneID, "/")
    symbol_col <- sapply(entrezid_list, function(x) {
      tryCatch({
        y <- bitr(x, fromType = "ENTREZID", toType = gene_type, OrgDb = org_db)
        y <- y[!duplicated(y$ENTREZID), -1]
        if (length(y) == 0) return(NA)
        paste(y, collapse = "/")
      }, error = function(e) {
        return(NA)
      })
    })
    ekegg_list$geneID <- symbol_col
  }
  KEGG_list <- list(
    ekegg_list = ekegg_list,
    ekegg = ekegg,
    kk_df = ekegg_list,    # For compatibility with KEGGdotchart.R
    kk_result = ekegg,     # For compatibility with KEGGdotchart.R
    genes = genes,
    genes_id = genes_id,
    sp = sp,
    parameters = list(
      species = sp,
      kegg_organism = kegg_org,
      gene_type = gene_type,
      pvalue_cutoff = pvalue_cutoff,
      qvalue_cutoff = qvalue_cutoff,
      input_genes = length(genes),
      converted_genes = nrow(genes_id)
    )
  )
  save_analysis_outputs(KEGG_list, ekegg_list, "KEGG", temp_dir, object_name = "KEGG_list")
  if (nrow(ekegg_list) == 0) {
    skill_warn("SKILL_EMPTY_DATA", "KEGG analysis found no enriched pathways")
  }

  invisible(list(GO_list = GO_list, KEGG_list = KEGG_list))
}
