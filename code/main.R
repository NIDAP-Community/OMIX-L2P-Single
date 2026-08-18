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
log_time("Loaded L2P_Analysis.R")

# Load optparse for command-line argument parsing
library(optparse)
log_time("Loaded optparse library")

# Define command-line options (all function parameters exposed)
option_list <- list(
  # Basic settings
  make_option("--deg_file", type="character", default=NULL, help="Input mode or uploaded DEG file (CSV, TSV, TXT, or RDS)"),
  make_option("--comparison", type="character", default=NULL, help="Comparison to analyze"),
  make_option("--species", type="character", default="Mouse", help="Species [default %default]"),
  make_option("--collections_to_include", type="character", default="GO,REACTOME,KEGG", help="Pathway collections [default %default]"),
  
  # Column overrides
  make_option("--gene_names_column", type="character", default=NULL, help="Optional: Override gene name column"),
  make_option("--t_statistic_column", type="character", default=NULL, help="Optional: Override ranking column"),
  make_option("--significance_column", type="character", default=NULL, help="Optional: Override significance column"),
  make_option("--fold_change_column", type="character", default=NULL, help="Optional: Override fold change column"),
  
  # Gene selection
  make_option("--select_by_rank", type="character", default="TRUE", help="Select by rank [default %default]"),
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
  
  # Custom pathways
  make_option("--custom_pathways", type="character", default=NULL, help="Optional: Path to custom pathway file"),
  make_option("--custom_pathway_name_column", type="character", default="gene_set_name", help="Pathway name column [default %default]"),
  make_option("--custom_pathway_gene_column", type="character", default="gene_symbol", help="Gene symbol column [default %default]"),
  
  # Visualization
  make_option("--number_of_pathways_to_plot", type="integer", default=12, help="Number of pathways to plot [default %default]"),
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

# Validate required parameters
if (is.null(opt$comparison) || opt$comparison == "") {
  stop("ERROR: 'Comparison' parameter is required. Please specify which comparison to analyze (e.g., 'B-A', 'C-A').")
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

find_named_csv <- function(base_dir, filename, mode_label) {
  all_csv <- list.files(
    base_dir,
    pattern = "\\.csv$",
    full.names = TRUE,
    recursive = TRUE,
    ignore.case = TRUE
  )
  matches <- all_csv[tolower(basename(all_csv)) == tolower(filename)]
  if (length(matches) == 0) {
    cat(sprintf("\n=== ERROR: '%s' mode could not find '%s' ===\n", mode_label, filename))
    # List available diff_*.csv files to help the user identify available comparisons
    diff_files <- all_csv[grepl("^diff_.*\\.csv$", tolower(basename(all_csv)))]
    filt_file  <- all_csv[tolower(basename(all_csv)) == "diff_filt.csv"]
    if (length(diff_files) > 0 || length(filt_file) > 0) {
      cat("  This looks like a MOSuite moo-properties dataset.\n")
      if (length(diff_files) > 0) {
        available <- sub("^diff_", "", sub("\\.csv$", "", basename(diff_files), ignore.case = TRUE),
                         ignore.case = TRUE)
        cat(sprintf("  Available comparisons: %s\n", paste(sort(available), collapse = ", ")))
        cat("  Set the 'Comparison' parameter to one of the above.\n")
      }
    } else if (length(all_csv) == 0) {
      all_files <- list.files(base_dir, full.names = TRUE, recursive = TRUE, all.files = FALSE)
      if (length(all_files) == 0) {
        cat("  No data found under /data/.\n")
        cat("  For 'All DEG' mode: attach a MOSuite moo-properties dataset with mount name 'deg_table'.\n")
        cat("  For standalone use: switch DEG Table File to 'Table' or blank and attach a flat CSV/RDS.\n")
      } else {
        cat(sprintf("  No CSV files found. %d file(s) present but none match diff_*.csv.\n",
                    length(all_files)))
      }
    } else {
      cat(sprintf("  Found %d CSV file(s) but none named '%s'.\n", length(all_csv), filename))
      cat(sprintf("  Available: %s\n", paste(basename(head(all_csv, 5)), collapse = ", ")))
    }
    cat("\n")
    stop(sprintf("'%s' mode could not find '%s'. See details above.", mode_label, filename))
  }
  if (length(matches) > 1) {
    cat(sprintf("  Multiple '%s' files found; using: %s\n", filename, matches[1]))
  }
  matches[1]
}

first_existing_column <- function(candidates, available_cols) {
  candidates <- candidates[!is.na(candidates) & nzchar(candidates)]
  match <- candidates[candidates %in% available_cols]
  if (length(match) > 0) {
    return(match[1])
  }
  NULL
}

set_default_column_override <- function(param_name, candidates, mode_label) {
  current_value <- opt[[param_name]]
  if (!is.null(current_value) && nzchar(trimws(current_value))) {
    return(invisible(NULL))
  }

  selected <- first_existing_column(candidates, colnames(deg_data))
  if (!is.null(selected)) {
    opt[[param_name]] <<- selected
    cat(sprintf("  %s mode: using %s='%s'\n", mode_label, param_name, selected))
  }
}

source("functions/workflow_input.R")

# Priority 1: Check for uploaded file path. Code Ocean mode strings such as
# "All DEG" and "Filtered DEG" are intentionally not treated as file paths.
if (!is.null(opt$deg_file) && opt$deg_file != "" && file.exists(opt$deg_file)) {
  deg_table_path <- opt$deg_file
  cat(sprintf("Loading DEG table from uploaded file: %s\n", deg_table_path))
  deg_data <- load_deg_file(deg_table_path)
  log_time("Loaded uploaded DEG file")
}

# Priority 2: Use a DEG table from an upstream Code Ocean workflow capsule.
# Workflow connections mount source results in an implementation-specific
# subdirectory beneath /data, so search recursively by filename.
if (is.null(deg_data)) {
  workflow_csv_path <- find_workflow_csv()
  workflow_moo_rds_path <- if (is.null(workflow_csv_path)) {
    find_workflow_moo_rds()
  } else {
    NULL
  }

  if (!is.null(workflow_csv_path) || !is.null(workflow_moo_rds_path)) {
    deg_table_path <- if (!is.null(workflow_csv_path)) {
      workflow_csv_path
    } else {
      workflow_moo_rds_path
    }
    deg_data <- if (!is.null(workflow_csv_path)) {
      load_flat_file(deg_table_path)
    } else {
      load_workflow_moo_rds(deg_table_path)
    }
    comp <- trimws(opt$comparison)
    workflow_columns <- resolve_workflow_deg_columns(deg_data, comp)
    opt$gene_names_column <- workflow_columns$gene_names_column
    opt$t_statistic_column <- workflow_columns$t_statistic_column
    opt$significance_column <- workflow_columns$significance_column
    opt$fold_change_column <- workflow_columns$fold_change_column

    cat(sprintf(
      paste0(
        "Loading workflow DEG table: %s\n",
        "  Gene=%s; t-stat=%s; p-value=%s; FC=%s\n"
      ),
      deg_table_path,
      opt$gene_names_column,
      opt$t_statistic_column,
      opt$significance_column,
      opt$fold_change_column
    ))
    log_time(if (!is.null(workflow_csv_path)) {
      "Loaded workflow CSV"
    } else {
      "Loaded workflow moo-diff.rds"
    })
  }
}

# Priority 3: Check selected data mode against attached data assets.
if (is.null(deg_data)) {
  deg_input_mode <- ""
  if (!is.null(opt$deg_file) && nchar(trimws(opt$deg_file)) > 0) {
    candidate <- trimws(opt$deg_file)
    if (tolower(candidate) %in% c("filtered deg", "all deg", "table")) {
      deg_input_mode <- tolower(candidate)
      cat(sprintf("DEG Table File mode: '%s'\n", candidate))
    }
  }

  csv_files <- list.files(
    "/data/deg_table",
    pattern = "\\.(csv|tsv|txt)$",
    full.names = TRUE,
    recursive = TRUE,
    ignore.case = TRUE
  )
  rds_files <- list.files(
    "/data/deg_table",
    pattern = "\\.rds$",
    full.names = TRUE,
    recursive = TRUE,
    ignore.case = TRUE
  )

  if (deg_input_mode == "filtered deg") {
    cat("  Mode: Filtered DEG - searching for diff_filt.csv under /data\n")
    deg_table_path <- find_named_csv("/data", "diff_filt.csv", "Filtered DEG")
    deg_data <- load_flat_file(deg_table_path)
    log_time("Loaded diff_filt.csv")

  } else if (deg_input_mode == "all deg") {
    if (is.null(opt$comparison) || !nzchar(trimws(opt$comparison))) {
      stop("ERROR: 'All DEG' mode requires the 'Comparison' parameter.")
    }
    comp <- trimws(opt$comparison)
    target <- paste0("diff_", comp, ".csv")
    cat(sprintf("  Mode: All DEG - searching for %s under /data\n", target))
    deg_table_path <- find_named_csv("/data", target, "All DEG")
    deg_data <- load_flat_file(deg_table_path)
    log_time(sprintf("Loaded %s", target))

    set_default_column_override(
      "gene_names_column",
      c("GeneName", "Gene Symbols", "Gene", "gene", "symbol", "Symbol", "gene_name", "gene_symbol", "GeneSymbol"),
      "All DEG"
    )
    set_default_column_override(
      "t_statistic_column",
      c("tstat", paste0(comp, "_tstat"), "t.stat", "t_stat", "stat"),
      "All DEG"
    )
    set_default_column_override(
      "significance_column",
      c("pval", "adjpval", paste0(comp, "_pval"), paste0(comp, "_adjpval"), "padj", "FDR"),
      "All DEG"
    )
    set_default_column_override(
      "fold_change_column",
      c("FC", "logFC", paste0(comp, "_FC"), paste0(comp, "_logFC"), "fc", "FoldChange"),
      "All DEG"
    )

  } else {
    if (deg_input_mode == "table") {
      cat("  Mode: Table - auto-detecting flat DEG table in /data/deg_table\n")
    } else {
      cat("No uploaded file or explicit mode found. Looking for DEG table in /data/deg_table/...\n")
      cat(sprintf(
        "  Found %d flat file(s) [CSV/TSV/TXT] and %d RDS file(s)\n",
        length(csv_files), length(rds_files)
      ))
    }

    if (length(csv_files) == 1) {
      deg_table_path <- csv_files[1]
      cat(sprintf("Loading DEG table from flat file: %s\n", deg_table_path))
      deg_data <- load_flat_file(deg_table_path)
      log_time("Loaded flat file")
    } else if (length(csv_files) > 1) {
      comp <- trimws(opt$comparison)
      scores <- sapply(csv_files, function(path) {
        as.integer(grepl(comp, path, fixed = TRUE))
      })
      deg_table_path <- if (max(scores) > 0) {
        csv_files[scores == max(scores)][1]
      } else {
        csv_files[1]
      }
      cat(sprintf("Multiple flat files found; loading: %s\n", deg_table_path))
      deg_data <- load_flat_file(deg_table_path)
      log_time("Loaded selected flat file")
    } else if (length(rds_files) == 1) {
      deg_table_path <- rds_files[1]
      cat(sprintf("Loading DEG table from RDS file: %s\n", deg_table_path))
      deg_data <- load_rds_as_df(deg_table_path)
      log_time("Loaded RDS file")
    } else if (length(rds_files) > 1) {
      deg_table_path <- rds_files[1]
      cat(sprintf("Multiple RDS files found; loading first: %s\n", deg_table_path))
      deg_data <- load_rds_as_df(deg_table_path)
      log_time("Loaded selected RDS file")
    } else {
      stop(paste0(
        "ERROR: No DEG table found. Attach a flat table with mount name ",
        "'deg_table', or use 'All DEG'/'Filtered DEG' with a MOSuite ",
        "moo-properties asset."
      ))
    }
  }
}

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

# Set output file paths to /results/
export_plot <- file.path("/results", "l2p_plots.png")
export_results <- file.path("/results", "l2p_results.csv")

# Run L2P analysis
cat(sprintf("Starting L2P Analysis for comparison: %s\n", opt$comparison))
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
  # Try to auto-detect based on comparison
  sig_candidates <- c(
    "pval",
    "adjpval",
    "padj",
    "FDR",
    paste0(opt$comparison, "_pval"),
    paste0(opt$comparison, "_adjpval"),
    paste0(opt$comparison, "_padj"),
    paste0(opt$comparison, "_pvalue"),
    paste0(opt$comparison, "_p.value"),
    paste0(opt$comparison, "_FDR")
  )
  significance_column <- NULL
  for (col in sig_candidates) {
    if (col %in% colnames(deg_data)) {
      significance_column <- col
      break
    }
  }
  
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
  # Try to auto-detect based on comparison
  fc_candidates <- c(
    "FC",
    "logFC",
    "fc",
    "FoldChange",
    paste0(opt$comparison, "_FC"),
    paste0(opt$comparison, "_fc"),
    paste0(opt$comparison, "_FoldChange"),
    paste0(opt$comparison, "_logFC")
  )
  fold_change_column <- NULL
  for (col in fc_candidates) {
    if (col %in% colnames(deg_data)) {
      fold_change_column <- col
      break
    }
  }
  
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
  # Try to auto-detect based on comparison
  rank_candidates <- c(
    "tstat",
    "t.stat",
    "t_stat",
    "stat",
    paste0(opt$comparison, "_tstat"),
    paste0(opt$comparison, "_t.stat"),
    paste0(opt$comparison, "_t_stat"),
    paste0(opt$comparison, "_stat")
  )
  ranking_column <- NULL
  for (col in rank_candidates) {
    if (col %in% colnames(deg_data)) {
      ranking_column <- col
      break
    }
  }
  
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
    # Detect file type and read
    file_ext <- tolower(tools::file_ext(opt$custom_pathways))
    if (file_ext == "csv") {
      custom_pathways_data <- read.csv(opt$custom_pathways, stringsAsFactors = FALSE, check.names = FALSE)
    } else {
      custom_pathways_data <- read.delim(opt$custom_pathways, stringsAsFactors = FALSE, check.names = FALSE)
    }
    cat(sprintf("Loaded custom pathways: %d rows\n", nrow(custom_pathways_data)))
    cat(sprintf("Available columns: %s\n", paste(colnames(custom_pathways_data), collapse=", ")))
    
    # Verify required columns exist
    if (!(opt$custom_pathway_name_column %in% colnames(custom_pathways_data))) {
      stop(sprintf("ERROR: Custom pathway name column '%s' not found in custom pathway file", opt$custom_pathway_name_column))
    }
    if (!(opt$custom_pathway_gene_column %in% colnames(custom_pathways_data))) {
      stop(sprintf("ERROR: Custom pathway gene column '%s' not found in custom pathway file", opt$custom_pathway_gene_column))
    }
    cat(sprintf("Using pathway name column: '%s'\n", opt$custom_pathway_name_column))
    cat(sprintf("Using gene symbol column: '%s'\n", opt$custom_pathway_gene_column))
  } else {
    stop(sprintf("ERROR: Custom pathway file not found: %s", opt$custom_pathways))
  }
}

cat("\n=== Starting L2P pathway analysis ===\n")

results <- l2p_single(
  deg_table = deg_data,
  gene_names_column = gene_names_column,
  t_statistic_column = ranking_column,
  significance_column = significance_column,
  fold_change_column = fold_change_column,
  comparison = opt$comparison,
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

log_time("L2P analysis function completed")

cat("\n=== L2P Analysis completed successfully! ===\n")
cat(sprintf("Results saved to: %s\n", export_results))
cat(sprintf("Plots saved to: %s\n", export_plot))

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
