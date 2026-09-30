#!/usr/bin/env Rscript

# L2P Analysis (Single) - Simplified Main Entry Point
# Over-representation pathway analysis with automatic column detection

# ===== VERSION BANNER =====
cat("======================================\n")
cat("L2P Single Analysis\n")
cat("======================================\n")
cat(sprintf("R version: %s\n", R.version.string))
cat(sprintf("l2p package: %s\n", as.character(packageVersion("l2p"))))
cat(sprintf("l2psupp package: %s\n", as.character(packageVersion("l2psupp"))))

# Try to detect MSigDB version from package metadata
msigdb_version_detected <- FALSE
tryCatch({
  if (exists("msigdb_version", where = asNamespace("l2p"))) {
    cat(sprintf("MSigDB version: %s (from l2p)\n", get("msigdb_version", envir = asNamespace("l2p"))))
    msigdb_version_detected <- TRUE
  } else if (exists("msigdb_version", where = asNamespace("l2psupp"))) {
    cat(sprintf("MSigDB version: %s (from l2psupp)\n", get("msigdb_version", envir = asNamespace("l2psupp"))))
    msigdb_version_detected <- TRUE
  }
}, error = function(e) {
  # Silently continue if detection fails
})

if (!msigdb_version_detected) {
  cat(sprintf("Pathway databases: Bundled in l2psupp v%s\n", as.character(packageVersion("l2psupp"))))
  cat("  Pathway database details can be found at https://github.com/ccbr/l2p\n")
}
cat("======================================\n\n")

# ===== DEBUG TIMING UTILITIES =====
.timer_start <- Sys.time()
.step_times <- list()

log_time <- function(step_name) {
  current_time <- Sys.time()
  elapsed <- as.numeric(difftime(current_time, .timer_start, units = "secs"))
  cat(sprintf("[%6.1fs] %s\n", elapsed, step_name))
  .step_times[[step_name]] <<- elapsed
}

# Source the L2P function
log_time("Script initialization")
source("functions/L2P_Analysis.R")
source("adapter_io.R")
log_time("Loaded L2P_Analysis.R")

# Load optparse for command-line argument parsing
library(optparse)
log_time("Loaded optparse library")

# Define command-line options (all function parameters exposed)
option_list <- list(
  # Canonical inputs. Code Ocean passes selected files as explicit paths; when
  # deg_table is blank, adapter_io.R resolves exactly one candidate beneath
  # the attached /data/deg_table mount.
  make_option("--deg_table", type="character", default=NULL, help="DEG table (CSV, TSV, TXT, or RDS)"),
  make_option("--custom_pathways", type="character", default=NULL, help="Optional: Path to custom pathway file"),

  # Basic settings
  make_option("--comparison", type="character", default=NULL, help="Comparison to analyze"),
  make_option("--comparisons", type="character", default=NULL, help="Comma-separated comparisons for independent batched runs"),
  make_option("--species", type="character", default="Mouse", help="Species [default %default]"),
  make_option("--collections_to_include", type="character", default="GO,REACTOME,KEGG", help="Pathway collections [default %default]"),
  
  # Column overrides
  make_option("--gene_names_column", type="character", default=NULL, help="Optional: Override gene name column"),
  make_option("--t_statistic_column", type="character", default=NULL, help="Optional: Override ranking column"),
  make_option("--significance_column", type="character", default=NULL, help="Optional: Override significance column"),
  make_option("--fold_change_column", type="character", default=NULL, help="Optional: Override fold change column"),
  
  # Gene selection
  make_option("--select_by_rank", type="character", default="FALSE", help="Select by rank [default %default]"),
  make_option("--select_top_percentage_of_genes", type="character", default="TRUE", help="Select top percentage [default %default]"),
  make_option("--select_top_genes", type="integer", default=500, help="Number of top genes [default %default]"),
  make_option("--significance_threshold", type="double", default=0.05, help="Significance threshold [default %default]"),
  make_option("--fold_change_threshold", type="double", default=1.2, help="Fold change threshold [default %default]"),
  make_option("--minimum_number_of_deg_genes", type="integer", default=50, help="Minimum DEG genes [default %default]"),
  
  # Pathway settings
  make_option("--minimum_pathway_hit_count", type="integer", default=5, help="Minimum pathway hits [default %default]"),
  make_option("--p_value_threshold_for_output", type="double", default=0.05, help="P-value threshold [default %default]"),
  make_option("--use_built_in_gene_universe", type="character", default="FALSE", help="Use built-in gene universe [default %default]"),
  make_option("--use_fdr_p_values", type="character", default="FALSE", help="Use FDR p-values [default %default]"),
  
  # Custom pathway columns
  make_option("--custom_pathway_name_column", type="character", default="gene_set_name", help="Pathway name column [default %default]"),
  make_option("--custom_pathway_gene_column", type="character", default="gene_symbol", help="Gene symbol column [default %default]"),
  
  # Visualization
  make_option("--number_of_pathways_to_plot", type="integer", default=20, help="Number of pathways to plot [default %default]"),
  make_option("--pathway_axis_label_max_length", type="integer", default=50, help="Pathway label max length [default %default]"),
  make_option("--pathway_axis_label_font_size", type="integer", default=15, help="Pathway label font size [default %default]"),
  make_option("--x_axis_title_font_size", type="integer", default=20, help="X-axis title font size [default %default]"),
  make_option("--y_axis_title_font_size", type="integer", default=20, help="Y-axis title font size [default %default]"),
  make_option("--x_axis_tick_font_size", type="integer", default=15, help="X-axis tick label font size [default %default]"),
  make_option("--plot_top_pathways_up", type="character", default="TRUE", help="Plot top pathways up [default %default]"),
  make_option("--pathways_to_use_up", type="character", default=NULL, help="Custom pathways up"),
  make_option("--plot_top_pathways_down", type="character", default="TRUE", help="Plot top pathways down [default %default]"),
  make_option("--pathways_to_use_down", type="character", default=NULL, help="Custom pathways down"),
  make_option("--sort_bubble_plot_by", type="character", default="percent gene hits per pathway", help="Sort bubble plot by [default %default]"),
  make_option("--plot_bubble_size", type="character", default="number of hits", help="Bubble size variable [default %default]"),
  make_option("--plot_bubble_color", type="character", default="Fisher's Exact pval", help="Bubble color variable [default %default]"),
  make_option("--bubble_colors", type="character", default="blues", help="Bubble color scheme [default %default]"),
  make_option("--color_for_bar", type="character", default="GreentoBlue", help="Bar plot color [default %default]"),
  make_option("--export_plot_width", type="double", default=12, help="Plot width [default %default]"),
  make_option("--export_plot_height", type="double", default=12, help="Plot height [default %default]")
)

opt_parser <- OptionParser(option_list=option_list)

# Filter out empty string arguments before optparse sees them
# Code Ocean passes --param "" for blank file uploads, which optparse rejects
args <- commandArgs(trailingOnly = TRUE)

# Debug: show what we received
cat("DEBUG: Received", length(args), "arguments:\n")
for (i in seq_along(args)) {
  cat(sprintf("  [%d] '%s'\n", i, args[i]))
}

filtered_args <- character()
i <- 1
while (i <= length(args)) {
  # Skip standalone empty strings
  if (args[i] == "") {
    cat(sprintf("DEBUG: Skipping empty string at position %d\n", i))
    i <- i + 1
  } else if (i < length(args) && startsWith(args[i], "--") && args[i+1] == "") {
    # Skip flag + empty value pairs
    cat(sprintf("DEBUG: Skipping flag '%s' with empty value at positions %d-%d\n", args[i], i, i+1))
    i <- i + 2
  } else {
    filtered_args <- c(filtered_args, args[i])
    i <- i + 1
  }
}

cat("DEBUG: After filtering, passing", length(filtered_args), "arguments to optparse\n")
for (i in seq_along(filtered_args)) {
  cat(sprintf("  [%d] '%s'\n", i, filtered_args[i]))
}

opt <- parse_args(opt_parser, args = filtered_args)
log_time("Parsed command-line arguments")

# Resolve one comparison or an ordered batch. A batch expects a wide DEG table
# with comparison-prefixed columns; fixed column overrides are necessarily
# single-comparison settings and are rejected below.
comparison_raw <- opt[["comparison"]]
if (is.null(comparison_raw)) {
  comparison_raw <- ""
}
comparisons_raw <- opt[["comparisons"]]
if (is.null(comparisons_raw)) {
  comparisons_raw <- ""
}
single_comparison <- trimws(as.character(comparison_raw)[1L])
batch_comparisons <- trimws(strsplit(as.character(comparisons_raw)[1L], ",", fixed = TRUE)[[1L]])
batch_comparisons <- batch_comparisons[nzchar(batch_comparisons)]
if (nzchar(single_comparison) && length(batch_comparisons) > 0L) {
  stop("ERROR: Supply either 'Comparison' or 'Comparisons', not both.")
}
if (!nzchar(single_comparison) && length(batch_comparisons) == 0L) {
  stop("ERROR: Specify a Comparison (for example, 'B-A') or a comma-separated Comparisons list.")
}
if (anyDuplicated(batch_comparisons)) {
  stop("ERROR: 'Comparisons' must not contain duplicate comparison IDs.")
}
is_batch <- length(batch_comparisons) > 0L
comparisons_to_run <- if (is_batch) batch_comparisons else single_comparison
primary_comparison <- comparisons_to_run[[1L]]
opt$comparison <- primary_comparison

if (is_batch && any(vapply(
  c("t_statistic_column", "significance_column", "fold_change_column"),
  function(name) !is.null(opt[[name]]) && nzchar(trimws(opt[[name]])),
  logical(1)
))) {
  stop(
    "ERROR: Batched Comparisons uses automatic comparison-prefixed columns. ",
    "Leave T-Statistic, Significance, and Fold Change column overrides blank."
  )
}

# Find and read DEG table: uploaded file > selected data asset mode
log_time("Starting data loading")

deg_data <- NULL
deg_table_path <- NULL

load_flat_file <- function(path) {
  file_ext <- tolower(tools::file_ext(path))
  if (file_ext == "csv") {
    read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  } else if (file_ext %in% c("tsv", "txt")) {
    read.delim(path, stringsAsFactors = FALSE, check.names = FALSE)
  } else {
    stop(sprintf("ERROR: File must be .rds, .csv, .tsv, or .txt: %s", path))
  }
}

load_rds_as_df <- function(path) {
  obj <- readRDS(path)
  if (is.data.frame(obj)) {
    return(obj)
  }
  if (is.list(obj)) {
    df_elements <- sapply(obj, is.data.frame)
    if (any(df_elements)) {
      cat("Extracted data frame from list\n")
      return(obj[[which(df_elements)[1]]])
    }
  }
  stop(sprintf("ERROR: RDS file does not contain a data frame: %s", path))
}

load_deg_file <- function(path) {
  file_ext <- tolower(tools::file_ext(path))
  if (file_ext == "rds") {
    load_rds_as_df(path)
  } else {
    load_flat_file(path)
  }
}

warn_gene_duplicates <- function(df, gene_col, file_label) {
  if (is.null(gene_col) || !gene_col %in% colnames(df)) {
    return(invisible(NULL))
  }

  dups <- df[[gene_col]][duplicated(df[[gene_col]])]
  if (length(dups) > 0) {
    uniq_dups <- unique(dups)
    sample_str <- paste(head(uniq_dups, 5), collapse = ", ")
    if (length(uniq_dups) > 5) {
      sample_str <- paste0(sample_str, " ...")
    }
    cat(sprintf(
      "\nWARNING: %d duplicate value(s) in '%s' column of '%s': %s\n\n",
      length(dups), gene_col, file_label, sample_str
    ))
  }
}

# Resolve the canonical DEG-table input. Explicit file selection wins. When it
# is blank, discovery is confined to the declared /data/deg_table mount and
# ambiguity is an error. For a single comparison, an exact diff_<comparison>
# workflow result is deterministic even when sibling comparison files exist.
resolved_deg <- resolve_deg_input(
  deg_table = opt$deg_table,
  data_root = "/data/deg_table",
  comparison = if (is_batch) NULL else primary_comparison
)
deg_table_path <- resolved_deg$path
cat(sprintf("Loading %s: %s\n", resolved_deg$source, deg_table_path))
deg_data <- if (is_workflow_moo_path(deg_table_path)) {
  load_workflow_moo_rds(deg_table_path)
} else {
  load_deg_file(deg_table_path)
}
log_time("Loaded DEG input")

# Verify we have a data frame
if (!is.data.frame(deg_data)) {
  stop("ERROR: Loaded data is not a data frame")
}

cat(sprintf("Loaded DEG table: %d rows x %d columns\n", nrow(deg_data), ncol(deg_data)))
if (!is.null(deg_table_path)) {
  cat(sprintf("Loaded DEG table path/mode: %s\n", deg_table_path))
}
cat(sprintf("Available columns: %s\n\n", paste(colnames(deg_data), collapse=", ")))

warn_gene_duplicates(
  deg_data,
  opt$gene_names_column,
  if (!is.null(deg_table_path)) basename(deg_table_path) else "DEG table"
)

# ===== ENVIRONMENT & DATABASE VERSION INFO =====
cat("\n======================================\n")
cat("L2P Single-Comparison Analysis\n")
cat("======================================\n")
cat(sprintf("R version: %s\n", R.version.string))
cat(sprintf("l2p package: %s\n", as.character(packageVersion("l2p"))))
cat(sprintf("l2psupp package: %s\n", as.character(packageVersion("l2psupp"))))

# Try to detect MSigDB version
msigdb_version_detected <- FALSE
tryCatch({
  if (exists("msigdb_version", where = asNamespace("l2p"))) {
    cat(sprintf("MSigDB version: %s (from l2p)\n", get("msigdb_version", envir = asNamespace("l2p"))))
    msigdb_version_detected <- TRUE
  } else if (exists("msigdb_version", where = asNamespace("l2psupp"))) {
    cat(sprintf("MSigDB version: %s (from l2psupp)\n", get("msigdb_version", envir = asNamespace("l2psupp"))))
    msigdb_version_detected <- TRUE
  }
}, error = function(e) {
  # Silent - will show warning below
})

if (!msigdb_version_detected) {
  cat(sprintf("Pathway databases: Bundled in l2psupp v%s\n", as.character(packageVersion("l2psupp"))))
  cat("  Pathway database details can be found at https://github.com/ccbr/l2p\n")
}

cat("======================================\n\n")

# Convert string boolean parameters to logical
opt$select_by_rank <- as.logical(opt$select_by_rank)
opt$select_top_percentage_of_genes <- as.logical(opt$select_top_percentage_of_genes)
opt$use_built_in_gene_universe <- as.logical(opt$use_built_in_gene_universe)
opt$use_fdr_p_values <- as.logical(opt$use_fdr_p_values)
opt$plot_top_pathways_up <- as.logical(opt$plot_top_pathways_up)
opt$plot_top_pathways_down <- as.logical(opt$plot_top_pathways_down)

# Parse collections (comma-separated string to vector)
collections <- strsplit(opt$collections_to_include, ",")[[1]]
collections <- trimws(collections)  # Remove whitespace

# Parse custom pathways if provided
pathways_up <- if (!is.null(opt$pathways_to_use_up) && opt$pathways_to_use_up != "") {
  trimws(strsplit(opt$pathways_to_use_up, ",")[[1]])
} else {
  NULL
}

pathways_down <- if (!is.null(opt$pathways_to_use_down) && opt$pathways_to_use_down != "") {
  trimws(strsplit(opt$pathways_to_use_down, ",")[[1]])
} else {
  c()
}

# Set output root. A single comparison retains the historical root-level
# filenames; batched comparisons receive isolated subdirectories.
results_root <- "/results"
dir.create(results_root, showWarnings = FALSE, recursive = TRUE)
comparison_slug <- function(comparison) {
  slug <- gsub("[^A-Za-z0-9._-]+", "_", comparison)
  slug <- gsub("^_+|_+$", "", slug)
  if (!nzchar(slug)) {
    stop("ERROR: A comparison ID must contain at least one letter, number, dot, dash, or underscore.")
  }
  slug
}
comparison_slugs <- vapply(comparisons_to_run, comparison_slug, character(1))
if (anyDuplicated(comparison_slugs)) {
  stop("ERROR: Comparisons resolve to duplicate result-directory names.")
}

# Run L2P analysis
cat(sprintf("Starting L2P Analysis for comparison(s): %s\n", paste(comparisons_to_run, collapse = ", ")))
cat(sprintf("Species: %s\n", opt$species))
cat(sprintf("Collections: %s\n\n", paste(collections, collapse=", ")))

# Auto-detect gene name column (or use user override)
if (!is.null(opt$gene_names_column) && opt$gene_names_column != "") {
  # User provided override
  gene_names_column <- opt$gene_names_column
  if (!(gene_names_column %in% colnames(deg_data))) {
    stop(sprintf("ERROR: Specified gene column '%s' not found in data.\nAvailable columns: %s", 
                 gene_names_column, paste(colnames(deg_data), collapse=", ")))
  }
  cat(sprintf("Using user-specified gene name column: '%s'\n", gene_names_column))
} else {
  # Auto-detect
  gene_col_candidates <- c("GeneName", "Gene Symbols", "Gene", "gene", "symbol", "Symbol", "gene_name", "gene_symbol", "GeneSymbol")
  gene_names_column <- NULL
  for (col in gene_col_candidates) {
    if (col %in% colnames(deg_data)) {
      gene_names_column <- col
      break
    }
  }
  
  if (is.null(gene_names_column)) {
    # Default to first column if no match
    gene_names_column <- colnames(deg_data)[1]
    cat(sprintf("Warning: Could not auto-detect gene column. Using first column: '%s'\n", gene_names_column))
    cat("If this is incorrect, specify the correct column in 'Gene Name Column (Optional)' in Advanced Options.\n")
  } else {
    cat(sprintf("Auto-detected gene name column: '%s'\n", gene_names_column))
  }
}

# Handle significance column (or use user override)
if (!is.null(opt$significance_column) && opt$significance_column != "") {
  significance_column <- opt$significance_column
  if (!(significance_column %in% colnames(deg_data))) {
    stop(sprintf("ERROR: Specified significance column '%s' not found in data.\nAvailable columns: %s", 
                 significance_column, paste(colnames(deg_data), collapse=", ")))
  }
  cat(sprintf("Using user-specified significance column: '%s'\n", significance_column))
} else {
  # Prefer the requested comparison in a wide workflow table. Generic column
  # names remain a deterministic fallback for narrow, single-contrast tables.
  significance_column <- first_comparison_column(
    opt$comparison,
    c("_pval", "_adjpval", "_padj", "_pvalue", "_p.value", "_FDR"),
    colnames(deg_data)
  )
  
  if (!is.null(significance_column)) {
    cat(sprintf("Auto-detected significance column: '%s'\n", significance_column))
  } else {
    cat("Note: Could not auto-detect significance column. Function will handle internally.\n")
  }
}

# Handle fold change column (or use user override)
if (!is.null(opt$fold_change_column) && opt$fold_change_column != "") {
  fold_change_column <- opt$fold_change_column
  if (!(fold_change_column %in% colnames(deg_data))) {
    stop(sprintf("ERROR: Specified fold change column '%s' not found in data.\nAvailable columns: %s", 
                 fold_change_column, paste(colnames(deg_data), collapse=", ")))
  }
  cat(sprintf("Using user-specified fold change column: '%s'\n", fold_change_column))
} else {
  # Prefer the requested comparison in a wide workflow table. Generic column
  # names remain a deterministic fallback for narrow, single-contrast tables.
  fold_change_column <- first_comparison_column(
    opt$comparison,
    c("_FC", "_fc", "_FoldChange", "_logFC"),
    colnames(deg_data)
  )
  
  if (!is.null(fold_change_column)) {
    cat(sprintf("Auto-detected fold change column: '%s'\n", fold_change_column))
  } else {
    cat("Note: Could not auto-detect fold change column. Function will handle internally.\n")
  }
}

# Handle ranking column (or use user override)
if (!is.null(opt$t_statistic_column) && opt$t_statistic_column != "") {
  ranking_column <- opt$t_statistic_column
  if (!(ranking_column %in% colnames(deg_data))) {
    stop(sprintf("ERROR: Specified ranking column '%s' not found in data.\nAvailable columns: %s", 
                 ranking_column, paste(colnames(deg_data), collapse=", ")))
  }
  cat(sprintf("Using user-specified ranking column: '%s'\n", ranking_column))
} else {
  # Prefer the requested comparison in a wide workflow table. Generic column
  # names remain a deterministic fallback for narrow, single-contrast tables.
  ranking_column <- first_comparison_column(
    opt$comparison,
    c("_tstat", "_t.stat", "_t_stat", "_stat"),
    colnames(deg_data)
  )
  
  if (!is.null(ranking_column)) {
    cat(sprintf("Auto-detected ranking column: '%s'\n", ranking_column))
  } else {
    cat("Note: Could not auto-detect ranking column. Function will handle internally.\n")
  }
}

log_time("Completed column detection and parameter setup")

# Handle custom pathways if provided
custom_pathways_data <- NULL
if (!is.null(opt$custom_pathways) && opt$custom_pathways != "") {
  cat("\n=== Loading custom pathway database ===\n")
  if (file.exists(opt$custom_pathways)) {
    custom_pathways_data <- load_custom_pathways_file(opt$custom_pathways)
    if (is.data.frame(custom_pathways_data)) {
      cat(sprintf("Loaded custom pathways: %d rows\n", nrow(custom_pathways_data)))
      cat(sprintf("Available columns: %s\n", paste(colnames(custom_pathways_data), collapse=", ")))

      # Long-format tables require the two configured mapping columns. Native
      # L2P pathway lists have already been structurally validated by the
      # adapter loader and are passed through unchanged.
      if (!(opt$custom_pathway_name_column %in% colnames(custom_pathways_data))) {
        stop(sprintf("ERROR: Custom pathway name column '%s' not found in custom pathway file", opt$custom_pathway_name_column))
      }
      if (!(opt$custom_pathway_gene_column %in% colnames(custom_pathways_data))) {
        stop(sprintf("ERROR: Custom pathway gene column '%s' not found in custom pathway file", opt$custom_pathway_gene_column))
      }
      cat(sprintf("Using pathway name column: '%s'\n", opt$custom_pathway_name_column))
      cat(sprintf("Using gene symbol column: '%s'\n", opt$custom_pathway_gene_column))
    } else {
      cat(sprintf("Loaded custom pathways: %d L2P pathway-list entries\n", length(custom_pathways_data)))
    }
  } else {
    stop(sprintf("ERROR: Custom pathway file not found: %s", opt$custom_pathways))
  }
}

cat("\n=== Starting L2P pathway analysis ===\n")

run_records <- vector("list", length(comparisons_to_run))
for (i in seq_along(comparisons_to_run)) {
  comparison <- comparisons_to_run[[i]]
  comparison_dir <- if (is_batch) {
    file.path(results_root, comparison_slugs[[i]])
  } else {
    results_root
  }
  dir.create(comparison_dir, showWarnings = FALSE, recursive = TRUE)
  export_plot <- file.path(comparison_dir, "l2p_plots.png")
  export_results <- file.path(comparison_dir, "l2p_results.csv")

  cat(sprintf("Running L2P for comparison: %s\n", comparison))
  results <- l2p_single(
    deg_table = deg_data,
    gene_names_column = gene_names_column,
    t_statistic_column = if (is_batch) NULL else ranking_column,
    significance_column = if (is_batch) NULL else significance_column,
    fold_change_column = if (is_batch) NULL else fold_change_column,
    comparison = comparison,
    plot_title_prefix = if (is_batch) comparison else NULL,
    species = opt$species,
    collections_to_include = collections,
    custom_pathways = custom_pathways_data,
    custom_pathway_name_column = opt$custom_pathway_name_column,
    custom_pathway_gene_column = opt$custom_pathway_gene_column,
    select_by_rank = opt$select_by_rank,
    select_top_percentage_of_genes = opt$select_top_percentage_of_genes,
    select_top_genes = opt$select_top_genes,
    significance_threshold = opt$significance_threshold,
    fold_change_threshold = opt$fold_change_threshold,
    minimum_number_of_deg_genes = opt$minimum_number_of_deg_genes,
    number_of_pathways_to_plot = opt$number_of_pathways_to_plot,
    pathway_axis_label_max_length = opt$pathway_axis_label_max_length,
    plot_top_pathways_up = opt$plot_top_pathways_up,
    pathways_to_use_up = pathways_up,
    plot_top_pathways_down = opt$plot_top_pathways_down,
    pathways_to_use_down = pathways_down,
    sort_bubble_plot_by = opt$sort_bubble_plot_by,
    plot_bubble_size = opt$plot_bubble_size,
    plot_bubble_color = opt$plot_bubble_color,
    bubble_colors = opt$bubble_colors,
    pathway_axis_label_font_size = opt$pathway_axis_label_font_size,
    x_axis_title_font_size = opt$x_axis_title_font_size,
    y_axis_title_font_size = opt$y_axis_title_font_size,
    x_axis_tick_font_size = opt$x_axis_tick_font_size,
    use_fdr_p_values = opt$use_fdr_p_values,
    color_for_bar = opt$color_for_bar,
    use_built_in_gene_universe = opt$use_built_in_gene_universe,
    minimum_pathway_hit_count = opt$minimum_pathway_hit_count,
    p_value_threshold_for_output = opt$p_value_threshold_for_output,
    export_plot_file = export_plot,
    export_plot_width = opt$export_plot_width,
    export_plot_height = opt$export_plot_height,
    export_results_file = export_results
  )

  run_records[[i]] <- data.frame(
    comparison = comparison,
    output_directory = comparison_dir,
    results_file = export_results,
    provenance_file = sub("\\.csv$", "_provenance.csv", export_results),
    plot_prefix = export_plot,
    result_row_count = if (is.data.frame(results)) nrow(results) else NA_integer_,
    stringsAsFactors = FALSE
  )
}

run_manifest <- do.call(rbind, run_records)
utils::write.csv(
  run_manifest,
  file.path(results_root, "l2p_single_run_manifest.csv"),
  row.names = FALSE
)

log_time("L2P analysis function completed")

cat("\n=== L2P Analysis completed successfully! ===\n")
cat(sprintf("Run manifest saved to: %s\n", file.path(results_root, "l2p_single_run_manifest.csv")))
cat(sprintf("Results saved under: %s\n", results_root))

# Print timing summary
cat("\n=== Timing Summary (Sorted by Duration) ===\n")

# Calculate step durations
step_durations <- list()
prev_time <- 0
for (step_name in names(.step_times)) {
  elapsed <- .step_times[[step_name]]
  step_duration <- elapsed - prev_time
  step_durations[[step_name]] <- list(
    duration = step_duration,
    cumulative = elapsed
  )
  prev_time <- elapsed
}

# Sort by duration (descending)
sorted_steps <- names(step_durations)[order(sapply(step_durations, function(x) x$duration), decreasing = TRUE)]

# Print sorted
for (step_name in sorted_steps) {
  info <- step_durations[[step_name]]
  cat(sprintf("[%6.1fs] (+%5.1fs) %s\n", info$cumulative, info$duration, step_name))
}

total_time <- as.numeric(difftime(Sys.time(), .timer_start, units = "secs"))
cat(sprintf("\n[%6.1fs] TOTAL RUNTIME\n", total_time))
