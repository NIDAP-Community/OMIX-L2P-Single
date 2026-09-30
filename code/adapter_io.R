# Code Ocean input translation for the L2P Single deployment adapter.
#
# This file is intentionally outside code/functions/: code/functions/ is the
# byte-identical export of the canonical OMIX module R/ tree, while this file
# owns Code Ocean mount discovery and legacy MOSuite workflow translation.

.l2p_supported_deg_extensions <- c("csv", "tsv", "txt", "rds")
.l2p_supported_pathway_extensions <- c("csv", "tsv", "txt", "rds")

load_custom_pathways_file <- function(path) {
  if (!file.exists(path) || dir.exists(path)) {
    stop("ERROR: Custom pathway file does not exist or is not a file: ", path)
  }

  extension <- tolower(tools::file_ext(path))
  if (!extension %in% .l2p_supported_pathway_extensions) {
    stop("ERROR: Custom pathway file must be CSV, TSV, TXT, or RDS: ", path)
  }

  object <- switch(
    extension,
    csv = read.csv(path, stringsAsFactors = FALSE, check.names = FALSE),
    tsv = read.delim(path, stringsAsFactors = FALSE, check.names = FALSE),
    txt = read.delim(path, stringsAsFactors = FALSE, check.names = FALSE),
    rds = readRDS(path)
  )

  if (is.data.frame(object)) {
    return(object)
  }

  # A native L2P custom-pathway list contains one atomic vector per pathway:
  # identifier, display name, then at least one gene. Reject arbitrary R lists
  # here so an incompatible serialized object cannot fail later inside l2p().
  compatible_entry <- function(entry) {
    is.atomic(entry) && !is.object(entry) && length(entry) >= 3L &&
      !anyNA(entry) && all(nzchar(trimws(as.character(entry))))
  }
  if (
    identical(extension, "rds") &&
      is.list(object) &&
      length(object) > 0L &&
      all(vapply(object, compatible_entry, logical(1)))
  ) {
    return(object)
  }

  stop(
    "ERROR: Custom pathway RDS must contain a data frame or a non-empty ",
    "L2P pathway list whose entries contain an identifier, name, and gene(s)."
  )
}

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

resolve_workflow_deg_columns <- function(
  df,
  comparison,
  gene_names_column = NULL,
  t_statistic_column = NULL,
  significance_column = NULL,
  fold_change_column = NULL,
  t_statistic_suffix = "_tstat",
  significance_suffix = "_pval",
  fold_change_suffix = "_FC",
  select_by_rank = FALSE
) {
  gene_candidates <- c(
    "GeneName", "Gene Symbols", "Gene", "gene_name", "gene_symbol", "GeneSymbol"
  )
  gene_matches <- gene_candidates[gene_candidates %in% colnames(df)]
  if (!is.null(gene_names_column) && nzchar(trimws(gene_names_column))) {
    gene_matches <- trimws(gene_names_column)
  }

  # Reuse the canonical column-precedence rule. This guarantees that an exact
  # single-comparison override wins, while the configured suffixes determine
  # every automatically derived comparison-prefixed name.
  canonical_columns <- resolve_l2p_comparison_columns(
    comparison = comparison,
    t_statistic_column = t_statistic_column,
    significance_column = significance_column,
    fold_change_column = fold_change_column,
    t_statistic_suffix = t_statistic_suffix,
    significance_suffix = significance_suffix,
    fold_change_suffix = fold_change_suffix
  )

  # A Code Ocean workflow may hand off one narrow diff_<comparison>.csv whose
  # columns are generic (tstat, pval, FC). Permit that platform translation only
  # when the table has no complete prefixed comparison for the configured
  # method. A wide table must use an explicit comparison prefix and is never
  # silently redirected to generic or another contrast's columns.
  detected_comparisons <- detect_l2p_comparisons(
    column_names = colnames(df),
    select_by_rank = select_by_rank,
    t_statistic_suffix = t_statistic_suffix,
    significance_suffix = significance_suffix,
    fold_change_suffix = fold_change_suffix
  )
  allow_generic <- length(detected_comparisons) == 0L
  nonempty <- function(value) {
    !is.null(value) && length(value) == 1L && !is.na(value) &&
      nzchar(trimws(as.character(value)))
  }
  resolve_adapter_column <- function(canonical_name, override, suffix) {
    if (canonical_name %in% colnames(df) || nonempty(override) || !allow_generic) {
      return(canonical_name)
    }
    generic_name <- sub("^_", "", trimws(as.character(suffix)))
    if (generic_name %in% colnames(df)) generic_name else canonical_name
  }

  columns <- list(
    gene_names_column = if (length(gene_matches) > 0L) gene_matches[[1L]] else NULL,
    t_statistic_column = resolve_adapter_column(
      canonical_columns$t_statistic_column,
      t_statistic_column,
      t_statistic_suffix
    ),
    significance_column = resolve_adapter_column(
      canonical_columns$significance_column,
      significance_column,
      significance_suffix
    ),
    fold_change_column = resolve_adapter_column(
      canonical_columns$fold_change_column,
      fold_change_column,
      fold_change_suffix
    )
  )

  required_names <- c(
    "gene_names_column",
    if (isTRUE(select_by_rank)) "t_statistic_column" else c(
      "significance_column", "fold_change_column"
    )
  )
  missing <- required_names[vapply(
    columns[required_names],
    function(value) is.null(value) || !value %in% colnames(df),
    logical(1)
  )]
  if (length(missing) > 0L) {
    stop(
      "ERROR: Workflow input lacks required column(s) for comparison '",
      comparison, "': ", paste(missing, collapse = ", "),
      "\nAvailable columns: ", paste(colnames(df), collapse = ", ")
    )
  }

  columns
}
