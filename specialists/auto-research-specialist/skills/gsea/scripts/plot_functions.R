required_plot_packages <- c("data.table", "ggplot2", "RColorBrewer", "gtable")
missing_plot_packages <- required_plot_packages[
  !vapply(required_plot_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_plot_packages) > 0) {
  stop(
    sprintf(
      "SKILL_PACKAGE_NOT_FOUND: Required package(s) not installed: %s",
      paste(missing_plot_packages, collapse = ", ")
    ),
    call. = FALSE
  )
}
suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(RColorBrewer)
  library(gtable)
})

format_pathway_label <- function(x) {
  if (is.null(x) || length(x) == 0) return(NA_character_)
  x <- as.character(x)[1]
  if (is.na(x) || x == "") return(x)
  if (grepl("^\\[[^\\]]+\\]\\s+", x)) return(x)

  source <- NA_character_
  name <- x

  m <- regexec("^(KEGG|Reactome|REACTOME|GO|HALLMARK)[ _]+(.+)$", x, ignore.case = TRUE)
  mm <- regmatches(x, m)[[1]]
  if (length(mm) == 3) {
    source <- mm[2]
    name <- mm[3]
  } else if (grepl("^[^_]+_", x)) {
    source <- sub("_.*$", "", x)
    name <- sub("^[^_]+_", "", x)
  }

  name <- gsub("_+", " ", name)
  name <- gsub("\\s+", " ", trimws(name))

  if (!is.na(source)) {
    src_low <- tolower(source)
    src_label <- if (src_low == "reactome") {
      "Reactome"
    } else if (src_low == "kegg") {
      "KEGG"
    } else if (src_low == "go") {
      "GO"
    } else if (src_low == "hallmark") {
      "HALLMARK"
    } else {
      source
    }

    if (tolower(src_label) == "reactome") {
      name <- tools::toTitleCase(tolower(name))
    }
    return(paste0("[", src_label, "] ", name))
  }

  name
}

gsInfo <- function(geneSetID, object) {
  gsdata <- attr(object, "gsdata")
  if (is.null(gsdata)) {
    stop("SKILL_INVALID_PARAMETER: Missing 'gsdata' attribute on enrich table", call. = FALSE)
  }
  gsdata <- as.data.frame(gsdata)

  result_df <- as.data.frame(object)
  if (is.null(rownames(result_df)) || !geneSetID %in% rownames(result_df)) {
    stop(sprintf("SKILL_INVALID_PARAMETER: geneSetID not found in enrich table: %s", geneSetID), call. = FALSE)
  }

  match_df <- gsdata[0, , drop = FALSE]
  if ("ID" %in% colnames(gsdata)) {
    match_df <- gsdata[gsdata$ID %in% geneSetID, , drop = FALSE]
  } else {
    if (!"Description" %in% colnames(gsdata)) {
      stop("SKILL_MISSING_COLUMNS: gsea_running_scores.csv must contain column 'ID' or 'Description'", call. = FALSE)
    }
    desc <- as.character(result_df[geneSetID, "Description"])[1]
    match_df <- gsdata[gsdata$Description %in% desc, , drop = FALSE]
  }

  if (nrow(match_df) == 0) {
    stop(
      sprintf(
        "SKILL_INVALID_PARAMETER: No running score rows found for geneSetID '%s'; gsea_running_scores.csv must match enrichGSEA.csv by ID or Description",
        geneSetID
      ),
      call. = FALSE
    )
  }

  match_df
}

tableGrob2 <- function(pd, p) {
  if (!requireNamespace("gridExtra", quietly = TRUE)) {
    stop("SKILL_PACKAGE_NOT_FOUND: pvalue_table=TRUE requires package 'gridExtra'", call. = FALSE)
  }
  tp <- gridExtra::tableGrob(pd, rows = NULL)
  tp
}

myGSEA<-function (x, geneSetID, title = "", color = "green", base_size = 11, 
                  rel_heights = c(1.5, 0.5, 1), subplots = 1:3, pvalue_table = FALSE, NES_table=TRUE,
                  ES_geom = "line",
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
                  NES_label_size = 4,
                  NES_label_x = 0.75,
                  NES_label_y = 0.75,
                  NES_label_color = "black",
                  NES_label_hjust = 0,
                  NES_label_vjust = 1,
                  hit_height = 1,
                  hit_gap = 0,
                  hit_linewidth = 0.5,
                  rank_bar_alpha = 0.9,
                  rank_bar_height_ratio = 0.3,
                  rank_metric_segment_color = "grey",
                  rank_metric_segment_width = 0.3,
                  rank_metric_segment_alpha = 1) 
  # x: GSEA enrichment result table with gsdata attribute
  # geneSetID: vector of pathway IDs to plot
  # title: plot title
  # color: line colors for pathways
  # base_size: base font size for plot theme
  # rel_heights: relative heights of subplots (enrichment score, gene set position, ranked list metric)
  # subplots: which subplots to show (1=enrichment score, 2=gene set position, 3=ranked list metric)
  # pvalue_table: whether to show p-value table overlay (TRUE/FALSE)
  # NES_table: whether to show NES/p.adj/FDR annotation label (TRUE/FALSE)
  # ES_geom: geometry for enrichment score curve ("line" or "dot")
  # NES_label_size: font size for NES annotation label (when NES_table=TRUE and single pathway)
  # line_width: width of enrichment score line (when ES_geom="line")
{

  ES_geom <- match.arg(ES_geom, c("line", "dot"))
  geneList <- position <- NULL
  if (length(geneSetID) == 1) {
    gsdata <- gsInfo(geneSetID, object = x)
  }
  else {
    gsdata <- do.call(rbind, lapply(geneSetID, gsInfo, object = x))
  }
  if (nrow(gsdata) == 0) {
    stop("SKILL_EMPTY_DATA: No plotting rows available after matching enrichGSEA.csv and gsea_running_scores.csv", call. = FALSE)
  }

  fmt_levels <- vapply(geneSetID, format_pathway_label, character(1))
  gsdata$Description_fmt <- vapply(gsdata$Description, format_pathway_label, character(1))
  gsdata$Description_fmt <- factor(gsdata$Description_fmt, levels = fmt_levels)

  p <- ggplot(gsdata, aes(x = x)) + xlab(NULL) + theme_classic(base_size) + 
    theme(panel.grid.major = element_line(colour = grid_major_color), 
          panel.grid.minor = element_line(colour = grid_minor_color), 
          panel.grid.major.y = element_blank(), panel.grid.minor.y = element_blank()) + 
    scale_x_continuous(expand = c(0, 0))
  if (ES_geom == "line") {
    es_layer <- geom_line(aes(y = runningScore, color = Description_fmt), 
                          linewidth = line_width)
  } else {
    es_layer <- geom_point(aes(y = runningScore, color = Description_fmt),
                           size = dot_size)
  }
  if (legend_position == "auto") {
    legend_position <- if (length(geneSetID) == 1) "none" else "inside"
  }

  if (legend_position == "none") {
    legend_theme <- theme(legend.position = "none")
  } else if (legend_position == "right") {
    legend_theme <- theme(
      legend.position = "right",
      legend.title = element_blank(),
      legend.text = element_text(size = legend_text_size),
      legend.key.size = grid::unit(legend_key_size, "lines"),
      legend.background = element_rect(fill = grDevices::adjustcolor("white", alpha.f = legend_bg_alpha), colour = NA),
      legend.key = element_rect(fill = "transparent", colour = NA)
    )
  } else {
    if (utils::packageVersion("ggplot2") >= "3.5.0") {
      legend_theme <- theme(
        legend.position = "inside",
        legend.position.inside = c(legend_x, legend_y),
        legend.justification = c(legend_just_x, legend_just_y),
        legend.direction = "vertical",
        legend.title = element_blank(),
        legend.text = element_text(size = legend_text_size),
        legend.key.size = grid::unit(legend_key_size, "lines"),
        legend.background = element_rect(fill = grDevices::adjustcolor("white", alpha.f = legend_bg_alpha), colour = NA),
        legend.key = element_rect(fill = "transparent", colour = NA)
      )
    } else {
      legend_theme <- theme(
        legend.position = c(legend_x, legend_y),
        legend.justification = c(legend_just_x, legend_just_y),
        legend.direction = "vertical",
        legend.title = element_blank(),
        legend.text = element_text(size = legend_text_size),
        legend.key.size = grid::unit(legend_key_size, "lines"),
        legend.background = element_rect(fill = grDevices::adjustcolor("white", alpha.f = legend_bg_alpha), colour = NA),
        legend.key = element_rect(fill = "transparent", colour = NA)
      )
    }
  }

  p.res <- p + es_layer + legend_theme
  p.res <- p.res + ylab(ylab_es) + theme(axis.text.x = element_blank(), 
                                                    axis.ticks.x = element_blank(), axis.line.x = element_blank(), 
                                                    plot.margin = margin(t = 0.2, r = 0.2, b = 0, l = 0.2, 
                                                                         unit = "cm"))
  if (isTRUE(NES_table) && length(geneSetID) == 1) {
    gs_for_label <- geneSetID[1]
    nes_val <- suppressWarnings(as.numeric(x[gs_for_label, "NES"]))[1]
    padj_val <- suppressWarnings(as.numeric(x[gs_for_label, "p.adjust"]))[1]
    fdr_col <- if ("qvalues" %in% colnames(x)) "qvalues" else if ("qvalue" %in% colnames(x)) "qvalue" else NA_character_
    fdr_val <- if (!is.na(fdr_col)) suppressWarnings(as.numeric(x[gs_for_label, fdr_col]))[1] else NA_real_
    fmt_p <- function(label, v) {
      if (length(v) == 0 || is.na(v)) return(paste0(label, " = NA"))
      if (v < 0.001) return(paste0(label, " < 0.001"))
      paste0(label, " = ", sprintf("%.4f", v))
    }
    label_str <- paste0(
      "NES = ", ifelse(is.na(nes_val), "NA", sprintf("%.4f", nes_val)),
      "\n", fmt_p("P.adj", padj_val),
      "\n", fmt_p("FDR", fdr_val)
    )

    if (nrow(p.res$data) == 0) {
      stop("SKILL_EMPTY_DATA: No enrichment score rows available for plotting", call. = FALSE)
    }
    min_x <- min(p.res$data$x)
    max_x <- max(p.res$data$x)
    min_y <- min(p.res$data$runningScore)
    max_y <- max(p.res$data$runningScore)

    x_pos <- min_x + (max_x - min_x) * NES_label_x
    y_pos <- min_y + (max_y - min_y) * NES_label_y

    p.res <- p.res + annotate(
      "text",
      x = x_pos,
      y = y_pos,
      label = label_str,
      size = NES_label_size,
      colour = NES_label_color,
      hjust = NES_label_hjust,
      vjust = NES_label_vjust
    )
  }
  
  i <- 0
  for (term in unique(as.character(gsdata$Description_fmt))) {
    idx <- which(gsdata$position == 1 & gsdata$Description_fmt == term)
    gsdata[idx, "ymin"] <- i
    gsdata[idx, "ymax"] <- i + hit_height
    i <- i + hit_height + hit_gap
  }
  ymax_limit <- suppressWarnings(max(gsdata$ymax, na.rm = TRUE))
  if (!is.finite(ymax_limit)) {
    stop("SKILL_EMPTY_DATA: No hit bar rows available for plotting", call. = FALSE)
  }
  p2 <- ggplot(gsdata, aes(x = x)) + geom_linerange(aes(ymin = ymin, 
                                                        ymax = ymax, color = Description_fmt), linewidth = hit_linewidth) + xlab(NULL) + ylab(NULL) + 
    theme_classic(base_size) + theme(legend.position = "none", 
                                     plot.margin = margin(t = -0.1, b = 0, unit = "cm"), axis.ticks = element_blank(), 
                                     axis.text = element_blank(), axis.line.x = element_blank()) + 
    scale_x_continuous(expand = c(0, 0)) + 
    scale_y_continuous(expand = c(0, 0), limits = c(0, ymax_limit))
  if (length(geneSetID) == 1) {
    v <- seq(1, sum(gsdata$position), length.out = 9)
    inv <- findInterval(rev(cumsum(gsdata$position)), v)
    if (min(inv) == 0) 
      inv <- inv + 1
    max_inv <- max(inv)
    rdbu_palette <- rev(brewer.pal(11, "RdBu"))
    if (max_inv <= 2) {
      col <- if (max_inv == 1) "grey50" else c("#2166AC", "#B2182B")
    } else if (max_inv <= 11) {
      idx <- round(seq(1, 11, length.out = max_inv))
      col <- rdbu_palette[idx]
    } else {
      col <- grDevices::colorRampPalette(rdbu_palette)(max_inv)
    }
    ymin <- min(p2$data$ymin)
    yy <- max(p2$data$ymax - p2$data$ymin) * rank_bar_height_ratio
    xmin <- which(!duplicated(inv))
    xmax <- xmin + as.numeric(table(inv)[as.character(unique(inv))])
    d <- data.frame(ymin = ymin, ymax = yy, xmin = xmin, 
                    xmax = xmax, col = col[unique(inv)])
    p2 <- p2 + geom_rect(aes(xmin = xmin, xmax = xmax, 
                              ymin = ymin, ymax = ymax, fill = I(col)), data = d, 
                         alpha = rank_bar_alpha, inherit.aes = FALSE)
  }
  df2 <- p$data
  df2$y <- p$data$geneList[df2$x]
  p.pos <- p + geom_segment(
    data = df2,
    aes(x = x, xend = x, y = y, yend = 0),
    color = rank_metric_segment_color,
    linewidth = rank_metric_segment_width,
    alpha = rank_metric_segment_alpha
  )
  p.pos <- p.pos + ylab(ylab_rank) + xlab(xlab_rank) + 
    theme(plot.margin = margin(t = -0.1, r = 0.2, b = 0.2, 
                               l = 0.2, unit = "cm"))
  if (!is.null(title) && !is.na(title) && title != "") 
    p.res <- p.res + ggtitle(title)
  if (length(color) == length(geneSetID)) {
    color_map <- stats::setNames(color, fmt_levels)
    p.res <- p.res + scale_color_manual(values = color_map)
    if (length(color) == 1) {
      p.res <- p.res + theme(legend.position = "none")
      p2 <- p2 + scale_color_manual(values = "black")
    }
    else {
      p2 <- p2 + scale_color_manual(values = color_map)
    }
  }
  if (pvalue_table) {
    pd <- x[geneSetID, c("Description", "pvalue", "p.adjust")]
    rownames(pd) <- pd$Description
    pd <- pd[, -1]
    pd <- round(pd, 4)
    tp <- tableGrob2(pd, p.res)
    p.res <- p.res + theme(legend.position = "none") + annotation_custom(tp, 
                                                                         xmin = quantile(p.res$data$x, 0.5), xmax = quantile(p.res$data$x, 
                                                                                                                             0.95), ymin = quantile(p.res$data$runningScore, 
                                                                                                                                                    0.75), ymax = quantile(p.res$data$runningScore, 
                                                                                                                                                                           0.9))
  }
  plotlist <- list(p.res, p2, p.pos)[subplots]
  n <- length(plotlist)
  plotlist[[n]] <- plotlist[[n]] + theme(axis.line.x = element_line(), 
                                         axis.ticks.x = element_line(), axis.text.x = element_text())
  if (length(subplots) == 1) 
    return(plotlist[[1]] + theme(plot.margin = margin(t = 0.2, 
                                                      r = 0.2, b = 0.2, l = 0.2, unit = "cm")))
  if (length(rel_heights) > length(subplots)) 
    rel_heights <- rel_heights[subplots]
  stack_ggplots_vertical(plotlist, rel_heights)
}

build_stacked_ggplot_gtable <- function(plotlist, heights) {
  grobs <- lapply(plotlist, ggplotGrob)
  max_widths <- do.call(grid::unit.pmax, lapply(grobs, function(g) g$widths))
  grobs <- lapply(grobs, function(g) {
    g$widths <- max_widths
    g
  })
  if (!requireNamespace("gtable", quietly = TRUE)) {
    stop("SKILL_PACKAGE_NOT_FOUND: Required package not installed: gtable", call. = FALSE)
  }
  heights <- heights / sum(heights)
  layout <- gtable::gtable(
    widths = grid::unit(1, "npc"),
    heights = grid::unit(heights, "null")
  )
  for (i in seq_along(grobs)) {
    layout <- gtable::gtable_add_grob(
      layout,
      grobs[[i]],
      t = i,
      l = 1,
      clip = "off",
      name = paste0("plot_", i)
    )
  }
  layout
}

stack_ggplots_vertical <- function(plotlist, heights) {
  structure(
    list(plotlist = plotlist, heights = heights),
    class = "stacked_ggplots"
  )
}

parse_bool <- function(x) {
  if (is.logical(x)) return(x)
  tolower(as.character(x)) %in% c("true", "t", "1", "yes", "y")
}

parse_num_vec <- function(x) {
  if (is.null(x) || is.na(x) || x == "") return(NULL)
  as.numeric(strsplit(x, ",", fixed = TRUE)[[1]])
}

parse_int_vec <- function(x) {
  if (is.null(x) || is.na(x) || x == "") return(NULL)
  as.integer(strsplit(x, ",", fixed = TRUE)[[1]])
}

draw_plot_object <- function(p) {
  if (inherits(p, "stacked_ggplots")) {
    p <- build_stacked_ggplot_gtable(p$plotlist, p$heights)
  }
  if (inherits(p, c("grob", "gTree", "gtable"))) {
    grid::grid.newpage()
    grid::grid.draw(p)
  } else {
    print(p)
  }
}

save_plot_file <- function(filename, p, format, width, height) {
  if (format == "pdf") {
    grDevices::pdf(filename, width = width, height = height)
    draw_plot_object(p)
    grDevices::dev.off()
  } else if (format == "png") {
    grDevices::png(filename, width = width, height = height, units = "in", res = 300)
    draw_plot_object(p)
    grDevices::dev.off()
  } else {
    stop(sprintf("SKILL_INVALID_PARAMETER: Unsupported format: %s", format), call. = FALSE)
  }
}