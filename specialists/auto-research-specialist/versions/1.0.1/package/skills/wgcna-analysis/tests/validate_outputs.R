#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) {
  stop("Usage: Rscript tests/validate_outputs.R <output_dir>", call. = FALSE)
}

output_dir <- args[[1]]
required_files <- c(
  "session_info.txt",
  file.path("plots", "soft_threshold.pdf"),
  file.path("plots", "sample_clustering.pdf"),
  file.path("plots", "gene_cluster_modules.pdf"),
  file.path("plots", "module_eigengene_heatmap.pdf"),
  file.path("plots", "tom_heatmap.pdf"),
  file.path("plots", "module_trait_relationships.pdf"),
  file.path("tables", "sft_fit_indices.csv"),
  file.path("tables", "module_trait_cor.csv"),
  file.path("tables", "module_trait_p.csv"),
  file.path("tables", "module_assignments.csv"),
  file.path("tables", "selected_modules.csv"),
  file.path("tables", "analysis_summary.csv"),
  file.path("data", "net.rds"),
  file.path("data", "analysis_objects.rds")
)

missing_files <- required_files[!file.exists(file.path(output_dir, required_files))]
if (length(missing_files) > 0) {
  stop(
    sprintf("Missing expected output files: %s", paste(missing_files, collapse = ", ")),
    call. = FALSE
  )
}

cat(sprintf("Validated %d required output files in %s\n", length(required_files), output_dir))
