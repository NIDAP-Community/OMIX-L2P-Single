#!/usr/bin/env Rscript

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_arg) != 1L) {
  stop("Run this check with Rscript tests/test-workflow-input.R")
}
repo_root <- normalizePath(file.path(dirname(sub("^--file=", "", script_arg)), ".."))
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

unsupported <- file.path(workflow_dir, "not-a-table.pdf")
writeLines("test", unsupported)
expect_error(resolve_deg_input(deg_table = unsupported), "must be CSV, TSV, TXT, or RDS")

message("L2P Single workflow-input checks passed")
