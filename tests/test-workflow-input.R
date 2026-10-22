#!/usr/bin/env Rscript

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_arg) != 1L) {
  stop("Run this check with Rscript tests/test-workflow-input.R")
}
repo_root <- normalizePath(file.path(dirname(sub("^--file=", "", script_arg)), ".."))
source(file.path(repo_root, "code", "functions", "L2P_Analysis.R"))
source(file.path(repo_root, "code", "adapter_io.R"))

expect_error <- function(expression, pattern) {
  error <- tryCatch({
    force(expression)
    NULL
  }, error = identity)
  stopifnot(inherits(error, "error"), grepl(pattern, conditionMessage(error), fixed = TRUE))
}

fixture <- tempfile("l2p-workflow-")
dir.create(file.path(fixture, "workflow-id"), recursive = TRUE)
workflow_dir <- file.path(fixture, "workflow-id")
on.exit(unlink(fixture, recursive = TRUE), add = TRUE)

deg_path <- file.path(workflow_dir, "DEG_Analysis.csv")
write.csv(
  data.frame(
    GeneName = c("GeneA", "GeneB"),
    `B-A_tstat` = c(1, -1),
    `B-A_pval` = c(0.001, 0.002),
    `B-A_adjpval` = c(0.01, 0.02),
    `B-A_FC` = c(2, -2),
    check.names = FALSE
  ),
  deg_path,
  row.names = FALSE
)
write.csv(data.frame(Package = "example"), file.path(workflow_dir, "r-packages.csv"), row.names = FALSE)

# One named workflow result is selected while unrelated supported tables are
# ignored. Discovery remains confined to the caller-supplied mount root.
resolved <- resolve_deg_input(data_root = fixture, comparison = "B-A")
stopifnot(
  identical(resolved$path, normalizePath(deg_path)),
  identical(resolved$source, "attached DEG data asset")
)
columns <- resolve_workflow_deg_columns(read.csv(deg_path, check.names = FALSE), "B-A")
stopifnot(
  identical(columns$gene_names_column, "GeneName"),
  identical(columns$t_statistic_column, "B-A_tstat"),
  identical(columns$significance_column, "B-A_pval"),
  identical(columns$fold_change_column, "B-A_FC")
)

# A mixed table can contain generic narrow-table columns alongside multiple
# comparison-prefixed columns. The requested comparison must win so the adapter
# never silently analyzes another or stale generic contrast.
mixed_table <- read.csv(deg_path, check.names = FALSE)
mixed_table$tstat <- c(99, 99)
mixed_table$pval <- c(0.9, 0.9)
mixed_table$FC <- c(99, 99)
mixed_columns <- resolve_workflow_deg_columns(mixed_table, "B-A")
stopifnot(
  identical(mixed_columns$t_statistic_column, "B-A_tstat"),
  identical(mixed_columns$significance_column, "B-A_pval"),
  identical(mixed_columns$fold_change_column, "B-A_FC")
)

# Generic names remain supported for an unambiguous narrow single-comparison
# table when no requested-comparison prefix is present.
narrow_table <- data.frame(
  GeneName = c("GeneA", "GeneB"),
  tstat = c(1, -1),
  pval = c(0.001, 0.002),
  FC = c(2, -2),
  check.names = FALSE
)
narrow_columns <- resolve_workflow_deg_columns(narrow_table, "B-A")
stopifnot(
  identical(narrow_columns$t_statistic_column, "tstat"),
  identical(narrow_columns$significance_column, "pval"),
  identical(narrow_columns$fold_change_column, "FC")
)

# Alternative suffixes are canonical user controls. They resolve both wide
# comparison-prefixed columns and the equivalent generic narrow handoff.
alternative_table <- data.frame(
  GeneName = c("GeneA", "GeneB"),
  `B-A_statistic` = c(1, -1),
  `B-A_adjpval` = c(0.001, 0.002),
  `B-A_logFC` = c(1.5, -1.5),
  check.names = FALSE
)
alternative_columns <- resolve_workflow_deg_columns(
  alternative_table,
  "B-A",
  t_statistic_suffix = "_statistic",
  significance_suffix = "_adjpval",
  fold_change_suffix = "_logFC"
)
stopifnot(
  identical(alternative_columns$t_statistic_column, "B-A_statistic"),
  identical(alternative_columns$significance_column, "B-A_adjpval"),
  identical(alternative_columns$fold_change_column, "B-A_logFC")
)

alternative_narrow <- alternative_table
names(alternative_narrow) <- c("GeneName", "statistic", "adjpval", "logFC")
alternative_narrow_columns <- resolve_workflow_deg_columns(
  alternative_narrow,
  "B-A",
  t_statistic_suffix = "_statistic",
  significance_suffix = "_adjpval",
  fold_change_suffix = "_logFC"
)
stopifnot(
  identical(alternative_narrow_columns$t_statistic_column, "statistic"),
  identical(alternative_narrow_columns$significance_column, "adjpval"),
  identical(alternative_narrow_columns$fold_change_column, "logFC")
)

# Exact single-comparison overrides retain precedence over suffix-derived names.
override_table <- alternative_table
override_table$my_stat <- c(2, -2)
override_table$my_p <- c(0.01, 0.02)
override_table$my_fc <- c(2, -2)
override_columns <- resolve_workflow_deg_columns(
  override_table,
  "B-A",
  t_statistic_column = "my_stat",
  significance_column = "my_p",
  fold_change_column = "my_fc",
  t_statistic_suffix = "_statistic",
  significance_suffix = "_adjpval",
  fold_change_suffix = "_logFC"
)
stopifnot(
  identical(override_columns$t_statistic_column, "my_stat"),
  identical(override_columns$significance_column, "my_p"),
  identical(override_columns$fold_change_column, "my_fc")
)

# Blank comparison controls are resolved from table content only. One complete
# prefix succeeds; multiple complete prefixes stop and list the candidates.
stopifnot(identical(
  resolve_l2p_comparisons(
    column_names = colnames(alternative_table),
    t_statistic_suffix = "_statistic",
    significance_suffix = "_adjpval",
    fold_change_suffix = "_logFC"
  ),
  "B-A"
))
ambiguous_table <- cbind(
  alternative_table,
  `C-A_adjpval` = c(0.03, 0.04),
  `C-A_logFC` = c(1.2, -1.2)
)
expect_error(
  resolve_l2p_comparisons(
    column_names = colnames(ambiguous_table),
    significance_suffix = "_adjpval",
    fold_change_suffix = "_logFC"
  ),
  "Multiple comparison prefixes were detected: B-A, C-A"
)
expect_error(
  resolve_l2p_comparisons(
    comparison = "B-A",
    comparisons = "C-A",
    column_names = colnames(ambiguous_table),
    significance_suffix = "_adjpval",
    fold_change_suffix = "_logFC"
  ),
  "Supply either `--comparison` or `--comparisons`, not both"
)

gene_symbols_table <- read.csv(deg_path, check.names = FALSE)
names(gene_symbols_table)[names(gene_symbols_table) == "GeneName"] <- "Gene Symbols"
stopifnot(identical(
  resolve_workflow_deg_columns(gene_symbols_table, "B-A")$gene_names_column,
  "Gene Symbols"
))

# An exact comparison file is deterministic even when the workflow contains
# sibling comparison outputs.
diff_ba <- file.path(workflow_dir, "diff_B-A.csv")
diff_ca <- file.path(workflow_dir, "diff_C-A.csv")
file.copy(deg_path, diff_ba)
file.copy(deg_path, diff_ca)
resolved_comparison <- resolve_deg_input(data_root = fixture, comparison = "B-A")
stopifnot(
  identical(resolved_comparison$path, normalizePath(diff_ba)),
  identical(resolved_comparison$source, "comparison-specific workflow result")
)

# Without a single-comparison selector, multiple DEG candidates are never
# silently ranked or reduced to the first path.
expect_error(
  resolve_deg_input(data_root = fixture),
  "Multiple named DEG candidates"
)

# Explicit selection has highest priority and is stable in a crowded mount.
resolved_explicit <- resolve_deg_input(deg_table = deg_path, data_root = fixture)
stopifnot(
  identical(resolved_explicit$path, normalizePath(deg_path)),
  identical(resolved_explicit$source, "explicit DEG table")
)

empty_root <- tempfile("l2p-empty-")
dir.create(empty_root)
on.exit(unlink(empty_root, recursive = TRUE), add = TRUE)
expect_error(resolve_deg_input(data_root = empty_root), "No supported DEG table")

# A direct Code Ocean result edge mounts Limma's complete output bundle at
# /data, not at the optional deg_table asset mount. The adapter may use only
# the stable Limma_Analysis.csv filename; sibling CSV artifacts remain ignored.
limma_root <- tempfile("l2p-limma-result-")
dir.create(limma_root)
on.exit(unlink(limma_root, recursive = TRUE), add = TRUE)
limma_path <- file.path(limma_root, "Limma_Analysis.csv")
file.copy(deg_path, limma_path)
write.csv(data.frame(Sample = "sample-1"), file.path(limma_root, "Sample_Metadata.csv"), row.names = FALSE)
write.csv(data.frame(Mean = 1), file.path(limma_root, "Variance_Diagnostic.csv"), row.names = FALSE)
resolved_limma <- resolve_deg_input(
  data_root = empty_root,
  workflow_root = limma_root,
  comparison = "B-A"
)
stopifnot(
  identical(resolved_limma$path, normalizePath(limma_path)),
  identical(resolved_limma$source, "Limma workflow result")
)

# Duplicate result names remain an actionable ambiguity rather than selecting
# the first recursively discovered workflow output.
dir.create(file.path(limma_root, "second-result"))
file.copy(deg_path, file.path(limma_root, "second-result", "Limma_Analysis.csv"))
expect_error(
  resolve_deg_input(data_root = empty_root, workflow_root = limma_root),
  "Multiple Limma workflow results named 'Limma_Analysis.csv'"
)

# Generic workflow bundles remain strict: a CSV with another name cannot be
# mistaken for a Limma differential result.
non_limma_root <- tempfile("l2p-non-limma-result-")
dir.create(non_limma_root)
on.exit(unlink(non_limma_root, recursive = TRUE), add = TRUE)
file.copy(deg_path, file.path(non_limma_root, "Other_Analysis.csv"))
expect_error(
  resolve_deg_input(data_root = empty_root, workflow_root = non_limma_root),
  "No supported DEG table"
)

unsupported <- file.path(workflow_dir, "not-a-table.pdf")
writeLines("test", unsupported)
expect_error(resolve_deg_input(deg_table = unsupported), "must be CSV, TSV, TXT, or RDS")

# Custom pathway input supports both advertised RDS forms: a long table and a
# native L2P pathway list. Incompatible serialized objects fail at the adapter
# boundary with a deterministic diagnostic.
pathway_table <- data.frame(
  gene_set_name = c("Pathway 1", "Pathway 1", "Pathway 2"),
  gene_symbol = c("GeneA", "GeneB", "GeneC"),
  stringsAsFactors = FALSE
)
pathway_table_rds <- file.path(workflow_dir, "custom-pathways-table.rds")
saveRDS(pathway_table, pathway_table_rds)
stopifnot(identical(load_custom_pathways_file(pathway_table_rds), pathway_table))

pathway_list <- list(
  c("CUSTOM_1", "Custom pathway 1", "GeneA", "GeneB"),
  c("CUSTOM_2", "Custom pathway 2", "GeneC")
)
pathway_list_rds <- file.path(workflow_dir, "custom-pathways-list.rds")
saveRDS(pathway_list, pathway_list_rds)
stopifnot(identical(load_custom_pathways_file(pathway_list_rds), pathway_list))

invalid_pathway_rds <- file.path(workflow_dir, "custom-pathways-invalid.rds")
saveRDS(list(metadata = data.frame(source = "not an L2P pathway list")), invalid_pathway_rds)
expect_error(
  load_custom_pathways_file(invalid_pathway_rds),
  "Custom pathway RDS must contain a data frame or a non-empty L2P pathway list"
)

message("L2P Single workflow-input checks passed")
