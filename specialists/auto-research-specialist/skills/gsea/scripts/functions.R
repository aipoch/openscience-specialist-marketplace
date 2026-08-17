# GSEA Analysis Functions
# Part of GSEA-analysis skill for OpenCode

# Function to load MSigDB gene sets
resolve_rds_gene_set_type <- function(type, available_types) {
  alias_map <- c(HALLMARKS = "Hallmarks")
  candidates <- unique(c(type, unname(alias_map[type])))
  match_type <- candidates[candidates %in% available_types][1]
  if (is.na(match_type) || length(match_type) == 0) {
    skill_stop(
      "SKILL_INVALID_PARAMETER",
      paste(
        "Requested gene set type", type,
        "not found in RDS data. Available types:",
        paste(available_types, collapse = ", ")
      )
    )
  }
  match_type
}

load_msigdb_sets <- function(species = "human", type = "KEGG", msigdbr_data = NULL,
                            chunk_size = 1000, verbose = FALSE) {
  if (!is.null(msigdbr_data)) {
    if (!"Gene" %in% names(msigdbr_data)) {
      skill_stop("SKILL_INVALID_PARAMETER", "RDS data does not contain top-level key 'Gene'")
    }
    available_types <- names(msigdbr_data[["Gene"]])
    resolved_type <- resolve_rds_gene_set_type(type, available_types)
    term2gene <- generate_term2gene(msigdbr_data[["Gene"]][[resolved_type]], chunk_size = chunk_size)
    if (verbose) {
      log_info(paste("Loaded", length(unique(term2gene$term)), "gene sets from preloaded RDS data using key", resolved_type))
    }
    return(term2gene)
  }
  
  # Otherwise, load from msigdbr package
  # Map species to msigdbr species code
  species_map <- list(
    human = "Homo sapiens",
    mouse = "Mus musculus", 
    rat = "Rattus norvegicus"
  )
  
  if (!species %in% names(species_map)) {
    skill_stop("SKILL_INVALID_PARAMETER", paste("Unsupported species:", species, ". Supported: human, mouse, rat"))
  }
  
  msigdb_species <- species_map[[species]]
  
  # Map type to msigdbr category
  type_map <- list(
    KEGG = "C2",
    HALLMARKS = "H",
    GO_BP = "C5",
    GO_MF = "C5", 
    GO_CC = "C5"
  )
  
  if (!type %in% names(type_map)) {
    skill_stop("SKILL_INVALID_PARAMETER", paste("Unsupported gene set type:", type, ". Supported: KEGG, HALLMARKS, GO_BP, GO_MF, GO_CC"))
  }
  
  msigdb_category <- type_map[[type]]
  
  # Load gene sets
  if (verbose) {
    log_info(paste("Loading MSigDB gene sets for", species, "(", type, ")..."))
  }
  
  gene_sets <- msigdbr::msigdbr(species = msigdb_species, category = msigdb_category)
  
  # Filter for specific subcategory if needed
  if (type %in% c("GO_BP", "GO_MF", "GO_CC")) {
    subcategory_map <- list(
      GO_BP = "GO:BP",
      GO_MF = "GO:MF",
      GO_CC = "GO:CC"
    )
    gene_sets <- gene_sets[gene_sets$gs_subcat == subcategory_map[[type]], ]
  } else if (type == "KEGG") {
    gene_sets <- gene_sets[gene_sets$gs_subcat == "CP:KEGG", ]
  }
  
  # Convert to term2gene format
  term2gene <- gene_sets[, c("gs_name", "gene_symbol")]
  colnames(term2gene) <- c("term", "gene")
  
  if (verbose) {
    log_info(paste("Loaded", length(unique(term2gene$term)), "gene sets with", nrow(term2gene), "gene-term associations"))
  }
  
  return(term2gene)
}

# Function to generate term2gene from list
generate_term2gene <- function(term2gene_list, chunk_size = 1000) {
  # Helper function to convert list to data frame
  list2term <- function(listD) {
    Reduce(rbind, lapply(names(listD), function(x) {
      geneList <- listD[[x]]
      data.frame("term" = rep(x, length(geneList)), "gene" = geneList, stringsAsFactors = FALSE)
    }))
  }
  
  # Check if term2gene_list is a list
  if (!is.list(term2gene_list)) {
    skill_stop("SKILL_INVALID_PARAMETER", "Input data must be a list.")
  }
  
  # Check chunk_size
  if (!is.numeric(chunk_size) || chunk_size <= 0) {
    skill_stop("SKILL_INVALID_PARAMETER", "Chunk size must be greater than 0")
  }
  
  # If list length is small, don't use parallel processing
  if (length(term2gene_list) <= chunk_size) {
    pathway <- list2term(term2gene_list)
  } else {
    # Split large data
    n_chunks <- ceiling(length(term2gene_list) / chunk_size)
    dat_chunk <- split(term2gene_list, 
                      cut(seq_along(term2gene_list), n_chunks, labels = FALSE))
    
    # Use parallel processing
    cl <- parallel::makeCluster(min(n_chunks, parallel::detectCores()))
    doParallel::registerDoParallel(cl)
    pathway <- foreach::foreach(x = dat_chunk, .combine = "rbind") %dopar% list2term(x)
    parallel::stopCluster(cl)
  }
  
  return(pathway)
}

# Function to run GSEA analysis
run_gsea_analysis <- function(gene_list, term2gene, method = "fgsea", 
                             pAdjustMethod = "BH", pvalueCutoff = 0.05,
                             max_attempts = 5, verbose = FALSE,
                             dose_nPerm = 1000) {
  
  # Sort gene list by logFC (descending)
  gene_list <- gene_list[order(gene_list$logFC, decreasing = TRUE), ]
  ranked_genes <- gene_list$logFC
  names(ranked_genes) <- gene_list$gene
  
  # Run GSEA with retry logic
  for (attempt in 1:max_attempts) {
    if (verbose) {
      log_info(paste("Running GSEA analysis (attempt", attempt, "/", max_attempts, ")..."))
    }
    
    tryCatch({
      if (method == "fgsea") {
        gsea_result <- clusterProfiler::GSEA(ranked_genes, TERM2GENE = term2gene, 
                           verbose = FALSE, by = "fgsea", 
                           pAdjustMethod = pAdjustMethod, 
                           pvalueCutoff = pvalueCutoff)
      } else {
        gsea_result <- clusterProfiler::GSEA(
          ranked_genes,
          TERM2GENE = term2gene,
          verbose = FALSE,
          by = "DOSE",
          nPerm = dose_nPerm,
          pAdjustMethod = pAdjustMethod,
          pvalueCutoff = pvalueCutoff
        )
      }
      
      # If successful, return result
      return(gsea_result)
      
    }, error = function(e) {
      if (attempt == max_attempts) {
        skill_stop("SKILL_ANALYSIS_FAILED", paste("GSEA analysis failed after", max_attempts, "attempts:", e$message))
      }
      if (verbose) {
        log_warn(paste("Attempt", attempt, "failed:", e$message))
      }
    })
  }
}

resolve_gsea_result_index <- function(object, geneSetID) {
  result_df <- object@result
  if (is.numeric(geneSetID) && length(geneSetID) == 1 && geneSetID >= 1 && geneSetID <= nrow(result_df)) {
    return(as.integer(geneSetID))
  }
  if (!is.null(rownames(result_df)) && geneSetID %in% rownames(result_df)) {
    return(match(geneSetID, rownames(result_df)))
  }
  if ("ID" %in% colnames(result_df) && geneSetID %in% result_df$ID) {
    return(match(geneSetID, result_df$ID))
  }
  skill_stop("SKILL_INVALID_PARAMETER", paste("geneSetID not found in GSEA result:", geneSetID))
}

# Function to extract running score info for one pathway
extract_gsea_data <- function(object, geneSetID) {
  result_idx <- resolve_gsea_result_index(object, geneSetID)
  result_df <- object@result
  result_id <- if ("ID" %in% colnames(result_df)) result_df$ID[result_idx] else geneSetID

  # Get the running score info
  # gsInfo returns a data frame with columns: x, runningScore, position, ymin, ymax
  d <- enrichplot:::gsInfo(object, result_idx)
  
  # Get the description for this ID
  desc <- result_df$Description[result_idx]
  
  # Get the gene symbols corresponding to the rank x
  gene_symbols <- names(object@geneList)[d$x]
  
  # Add columns
  d$Description <- desc
  d$ID <- result_id
  d$Symbol <- gene_symbols
  
  # Add metric values
  d$geneList <- object@geneList[d$x]
  
  # Reorder columns
  d <- d[, c("ID", "Description", "Symbol", "x", "runningScore", "position", "ymin", "ymax", "geneList")]
  
  return(d)
}