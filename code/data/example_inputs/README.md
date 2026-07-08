# Example DEG Table

This directory contains example differential expression (DEG) analysis results to help users test the L2P pathway analysis tool.

## File: deg_table.csv

A sample DEG table with the following structure:
- **Gene**: Gene symbol
- **B-A_tstat, C-A_tstat, B-C_tstat**: T-statistics for each comparison
- **B-A_pval, C-A_pval, B-C_pval**: P-values for each comparison  
- **B-A_FC, C-A_FC, B-C_FC**: Fold changes for each comparison

This data comes from the Demo DEG_table data asset (var_DEGAnalysis.rds converted to CSV format).

## Usage

In the Run dialog, select `../data/example_inputs/deg_table.csv` from the "DEG Table File" dropdown to use this example data.
