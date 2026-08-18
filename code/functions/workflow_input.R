# Code Ocean workflow-input helpers for the L2P Single adapter.
#
# These functions intentionally live in the adapter: they understand the
# Code Ocean /data mount convention and MOSuite's optional moo-diff.rds
# fallback. The canonical OMIX module accepts explicit paths instead.

first_existing_column <- function(candidates, available_cols) {
  candidates <- candidates[!is.na(candidates) & nzchar(candidates)]
  match <- candidates[candidates %in% available_cols]
  if (length(match) > 0) {
    return(match[1])
  }
  NULL
}

find_workflow_csv <- function(base_dir = "/data") {
  all_csv <- list.files(
    base_dir,
    pattern = "\\.csv$",
    full.names = TRUE,
    recursive = TRUE,
    ignore.case = TRUE
  )
  matches <- all_csv[grepl("DEG", basename(all_csv), ignore.case = TRUE)]

  if (length(matches) > 1) {
    stop(
      "ERROR: Multiple workflow DEG CSV files were found under ", base_dir,
      ". Specify an uploaded file or provide exactly one CSV whose filename ",
      "matches the regex 'DEG'.\n",
      paste(matches, collapse = "\n")
    )
  }

  if (length(matches) == 1) matches[1] else NULL
}

find_workflow_moo_rds <- function(base_dir = "/data") {
  all_rds <- list.files(
    base_dir,
    pattern = "\\.rds$",
    full.names = TRUE,
    recursive = TRUE,
    ignore.case = TRUE
  )
  matches <- all_rds[tolower(basename(all_rds)) == "moo-diff.rds"]

  if (length(matches) > 1) {
    stop(
      "ERROR: Multiple workflow moo-diff.rds files were found under ",
      base_dir, ".\n", paste(matches, collapse = "\n")
    )
  }

  if (length(matches) == 1) matches[1] else NULL
}

load_workflow_moo_rds <- function(path) {
  moo <- readRDS(path)
  diff_tables <- tryCatch(moo@analyses$diff, error = function(e) NULL)

  if (is.null(diff_tables) || !is.list(diff_tables) || length(diff_tables) == 0) {
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
  direct <- first_existing_column(direct_candidates, available_cols)
  if (!is.null(direct)) {
    return(direct)
  }

  prefixed <- available_cols[
    startsWith(available_cols, paste0(comparison, "_")) &
      vapply(
        available_cols,
        function(column) any(endsWith(column, suffixes)),
        logical(1)
      )
  ]
  if (length(prefixed) > 0) {
    return(prefixed[1])
  }

  first_existing_column(sub("^_", "", suffixes), available_cols)
}

resolve_workflow_deg_columns <- function(df, comparison) {
  columns <- list(
    gene_names_column = first_existing_column(
      c("GeneName", "Gene", "gene_name", "gene_symbol", "GeneSymbol"),
      colnames(df)
    ),
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
  if (length(missing) > 0) {
    stop(
      "ERROR: Workflow input lacks required column(s) for comparison '",
      comparison, "': ", paste(missing, collapse = ", "),
      "\nAvailable columns: ", paste(colnames(df), collapse = ", ")
    )
  }

  columns
}
