#!/usr/bin/env Rscript

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_arg) != 1L) {
  stop("Run this check with Rscript tests/test-workflow-input.R")
}
repo_root <- normalizePath(file.path(dirname(sub("^--file=", "", script_arg)), ".."))
source(file.path(repo_root, "code", "functions", "workflow_input.R"))

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

stopifnot(identical(normalizePath(find_workflow_csv(fixture)), normalizePath(deg_path)))
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

second_deg <- file.path(workflow_dir, "another_DEG_table.csv")
write.csv(data.frame(x = 1), second_deg, row.names = FALSE)
expect_error(find_workflow_csv(fixture), "Multiple workflow DEG CSV files")
unlink(second_deg)
unlink(deg_path)

moo_path <- file.path(workflow_dir, "moo-diff.rds")
saveRDS(list(placeholder = TRUE), moo_path)
stopifnot(identical(normalizePath(find_workflow_moo_rds(fixture)), normalizePath(moo_path)))
dir.create(file.path(fixture, "second"))
saveRDS(list(placeholder = TRUE), file.path(fixture, "second", "moo-diff.rds"))
expect_error(find_workflow_moo_rds(fixture), "Multiple workflow moo-diff.rds files")

message("L2P Single workflow-input checks passed")
