# Code Ocean input translation for the L2P Single deployment adapter.
#
# This file is intentionally outside code/functions/: code/functions/ is the
# byte-identical export of the canonical OMIX module R/ tree, while this file
# owns Code Ocean mount discovery and legacy MOSuite workflow translation.

.l2p_supported_deg_extensions <- c("csv", "tsv", "txt", "rds")

.l2p_supported_deg_files <- function(data_root) {
  if (!dir.exists(data_root)) {
    return(character())
  }

  files <- list.files(
    data_root,
    full.names = TRUE,
    recursive = TRUE,
    all.files = FALSE
  )
  files <- files[file.info(files)$isdir %in% FALSE]
  extensions <- tolower(tools::file_ext(files))
  sort(normalizePath(
    files[extensions %in% .l2p_supported_deg_extensions],
    mustWork = TRUE
  ))
}

.l2p_choose_unique <- function(paths, label, data_root) {
  if (length(paths) == 1L) {
    return(paths[[1L]])
  }
  if (length(paths) > 1L) {
    stop(
      "ERROR: Multiple ", label, " were found under ", data_root,
      ". Select the intended file explicitly with --deg_table.\n",
      paste(paths, collapse = "\n")
    )
  }
  NULL
}

resolve_deg_input <- function(
  deg_table = NULL,
  data_root = "/data/deg_table",
  comparison = NULL
) {
  explicit <- if (is.null(deg_table)) "" else trimws(as.character(deg_table)[1L])
  if (nzchar(explicit)) {
    if (!file.exists(explicit) || dir.exists(explicit)) {
      stop("ERROR: The selected DEG table does not exist or is not a file: ", explicit)
    }
    extension <- tolower(tools::file_ext(explicit))
    if (!extension %in% .l2p_supported_deg_extensions) {
      stop(
        "ERROR: DEG table must be CSV, TSV, TXT, or RDS: ", explicit
      )
    }
    return(list(
      path = normalizePath(explicit, mustWork = TRUE),
      source = "explicit DEG table"
    ))
  }

  candidates <- .l2p_supported_deg_files(data_root)
  if (length(candidates) == 0L) {
    stop(
      "ERROR: No supported DEG table was found under ", data_root,
      ". Attach the DEG input with mount name 'deg_table' or select a file explicitly."
    )
  }

  comparison <- if (is.null(comparison)) "" else trimws(as.character(comparison)[1L])
  if (nzchar(comparison)) {
    comparison_name <- paste0("diff_", comparison, ".csv")
    exact_comparison <- candidates[
      tolower(basename(candidates)) == tolower(comparison_name)
    ]
    selected <- .l2p_choose_unique(
      exact_comparison,
      paste0("files named '", comparison_name, "'"),
      data_root
    )
    if (!is.null(selected)) {
      return(list(path = selected, source = "comparison-specific workflow result"))
    }
  }

  # Recognize established OMIX and MOSuite workflow names, plus clearly named
  # DEG tables. Metadata, run summaries, figures, and package inventories are
  # intentionally excluded from this candidate set.
  basenames <- tolower(basename(candidates))
  named_candidates <- candidates[
    grepl("^deg_analysis\\.(csv|tsv|txt|rds)$", basenames) |
      grepl("^diff(_filt|_[^/]+)\\.csv$", basenames) |
      basenames == "moo-diff.rds" |
      grepl("deg.*(table|result).*\\.(csv|tsv|txt|rds)$", basenames)
  ]
  selected <- .l2p_choose_unique(named_candidates, "named DEG candidates", data_root)
  if (!is.null(selected)) {
    return(list(path = selected, source = "attached DEG data asset"))
  }

  selected <- .l2p_choose_unique(candidates, "supported data files", data_root)
  if (!is.null(selected)) {
    return(list(path = selected, source = "attached DEG data asset"))
  }

  stop("ERROR: DEG input resolution failed unexpectedly under ", data_root)
}

is_workflow_moo_path <- function(path) {
  identical(tolower(basename(path)), "moo-diff.rds")
}

load_workflow_moo_rds <- function(path) {
  moo <- readRDS(path)
  diff_tables <- tryCatch(moo@analyses$diff, error = function(e) NULL)

  if (is.null(diff_tables) || !is.list(diff_tables) || length(diff_tables) == 0L) {
    stop(
      "ERROR: Workflow RDS does not contain MOSuite differential-analysis results: ",
      path
    )
  }
  if (is.null(names(diff_tables)) || any(!nzchar(names(diff_tables)))) {
    stop("ERROR: MOSuite differential-analysis results must be named by comparison.")
  }

  tryCatch(
    as.data.frame(MOSuite::join_dfs_wide(diff_tables)),
    error = function(e) {
      stop(
        "ERROR: Could not convert workflow moo-diff.rds into a DEG table: ",
        conditionMessage(e)
      )
    }
  )
}

first_comparison_column <- function(comparison, suffixes, available_cols) {
  direct_candidates <- paste0(comparison, suffixes)
  direct <- direct_candidates[direct_candidates %in% available_cols]
  if (length(direct) > 0L) {
    return(direct[[1L]])
  }

  prefixed <- available_cols[
    startsWith(available_cols, paste0(comparison, "_")) &
      vapply(
        available_cols,
        function(column) any(endsWith(column, suffixes)),
        logical(1)
      )
  ]
  if (length(prefixed) > 0L) {
    return(prefixed[[1L]])
  }

  fallback <- sub("^_", "", suffixes)
  fallback <- fallback[fallback %in% available_cols]
  if (length(fallback) > 0L) fallback[[1L]] else NULL
}

resolve_workflow_deg_columns <- function(df, comparison) {
  gene_candidates <- c(
    "GeneName", "Gene Symbols", "Gene", "gene_name", "gene_symbol", "GeneSymbol"
  )
  gene_matches <- gene_candidates[gene_candidates %in% colnames(df)]
  columns <- list(
    gene_names_column = if (length(gene_matches) > 0L) gene_matches[[1L]] else NULL,
    t_statistic_column = first_comparison_column(
      comparison,
      c("_tstat", "_t.stat", "_t_stat", "_stat"),
      colnames(df)
    ),
    significance_column = first_comparison_column(
      comparison,
      c("_pval", "_adjpval", "_padj", "_pvalue", "_p.value", "_FDR"),
      colnames(df)
    ),
    fold_change_column = first_comparison_column(
      comparison,
      c("_FC", "_fc", "_FoldChange", "_logFC"),
      colnames(df)
    )
  )

  missing <- names(columns)[vapply(columns, is.null, logical(1))]
  if (length(missing) > 0L) {
    stop(
      "ERROR: Workflow input lacks required column(s) for comparison '",
      comparison, "': ", paste(missing, collapse = ", "),
      "\nAvailable columns: ", paste(colnames(df), collapse = ", ")
    )
  }

  columns
}
