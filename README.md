# OMIX L2P Analysis (Single)

## Overview

Over-representation pathway analysis for differential expression results. Given a gene list, this tool identifies over-represented pathways using Fisher's exact test via the [CCBR L2P package](https://github.com/ccbr/l2p).

**Part of the OMIX analysis suite** - A collection of genomics tools for reproducible bioinformatics workflows.

**Version Information**: Each run logs R version, l2p package version (0.0.14), l2psupp package version (0.0.14), and MSigDB database version for reproducibility tracking.

## Description

L2P (List to pathways) performs over-representation analysis to identify biological pathways that are significantly enriched in your differentially expressed genes. The analysis:

- Uses **Fisher's exact test** to calculate pathway enrichment significance
- Supports **multiple pathway databases**: GO, REACTOME, KEGG, MSigDB, and more
- Handles **multiple species** with automatic ortholog conversion to human genes
- Provides **flexible gene selection** methods (rank-based or threshold-based)
- Generates **publication-quality visualizations** (bubble plots and bar charts)

## Input Requirements

### Data Asset: DEG Table

Attach a data asset containing differential expression results with:

- **Gene names** (e.g., HGNC symbols)
- **Statistical measures** (t-statistics, p-values)
- **Fold changes** (linear or log scale)

**Supported formats**: RDS, CSV, TSV

**Expected columns** (auto-detected with override options):
- `Gene`, `gene`, `symbol` (or custom) → Gene names
- `{comparison}_tstat` → t-statistics for ranking
- `{comparison}_pval` → p-values for filtering
- `{comparison}_FC` → fold changes for filtering

### Required Parameters

**Comparison** - Which comparison to analyze (e.g., 'B-A', 'C-A', 'Treatment-Control'). Must match the column prefix in your DEG table.

## Usage

### Quick Start (Beginners)

1. **Attach your DEG table** as a data asset
2. **Fill in Basic Settings**:
   - **Comparison**: e.g., "B-A" (matches your column prefixes)
   - **Species**: Select from Human, Mouse, Rat, etc.
   - **Pathway Collections**: Keep default "GO,REACTOME,KEGG" or customize
3. **Run** - The tool auto-detects columns and uses smart defaults

### Advanced Usage

#### Column Overrides

If your data uses non-standard column names, override auto-detection:

- **Gene Names Column**: e.g., "HGNC_Symbol", "gene_id" (harmonized parameter name; plural form matches Multi tool)
- **Ranking Column (T-Statistic Column)**: e.g., "logFC", "stat" (more explicit name than generic "ranking column")
- **Significance Column**: e.g., "padj", "FDR"
- **Fold Change Column**: e.g., "log2FC", "foldChange"

*Note: Parameter names `gene_names_column` and `t_statistic_column` have been harmonized with L2P Multi for consistency across the OMIX suite.*

#### Gene Selection Methods

**Rank-based (Recommended)**
- Selects top N% or top N genes by t-statistic
- Better for well-powered bulk RNA-seq experiments
- Default: Top 10% of ranked genes

**Threshold-based**
- Filters by p-value and fold change cutoffs
- Better for heterogeneous data (e.g., single-cell RNA-seq)
- Default thresholds: p < 0.05, FC > 1.2

#### Pathway Settings

- **Minimum Pathway Hits**: Filter out small pathways (default: 5 genes)
- **P-value Threshold for Output**: Only export significant pathways (default: 0.05)
- **Use Built-in Gene Universe**: Alternative background gene set
- **Use FDR P-values**: Use FDR-corrected values instead of raw p-values

#### Visualization Customization

- **Number of Pathways to Plot**: Top N pathways per direction (default: 12)
- **Bubble Plot Variables**: Customize size, color, and sorting
- **Color Schemes**: Blues, reds, greens, or gradients
- **Plot Dimensions**: Width and height in inches

## Supported Pathway Collections

- **GO**: Gene Ontology (biological processes, molecular functions, cellular components)
- **REACTOME**: Curated pathway database
- **KEGG**: Kyoto Encyclopedia of Genes and Genomes
- **PANTH**: PANTHER pathways
- **PID**: Pathway Interaction Database
- **BIOCYC**: BioCyc metabolic pathways
- **WikiPathways**: Community-curated pathways
- **H**: MSigDB Hallmark gene sets
- **C1-C8**: MSigDB curated, motif, computational, oncogenic, immunologic, and cell type gene sets

## Supported Species

Human, Mouse, Rat, Rabbit, Zebrafish, Macaque, Drosophila

*Non-human genes are automatically converted to human orthologs before analysis.*

## Outputs

### Results File: `l2p_results.csv`

A comprehensive table including:
- **Pathway name** and **category**
- **Direction** (up/downregulated)
- **Number of hits** (genes in pathway)
- **Percent hits** (proportion of pathway genes)
- **Enrichment score**
- **P-value** (Fisher's exact test)
- **FDR** (Benjamini-Hochberg corrected)
- **Gene lists** (genes found in each pathway)

### Visualization: `l2p_plots.png`

Multi-panel figure with:
- **Bubble plots**: Size = number of hits, Color = p-value, X-axis = percent hits
- **Bar charts**: -log₁₀(p-value) for easy interpretation
- Separate panels for upregulated and downregulated pathways

## Algorithm Details

1. **Gene Selection**: Ranks genes by t-statistic or filters by p-value/fold change thresholds
2. **Pathway Enrichment**: Fisher's exact test for over-representation
3. **Multiple Testing Correction**: Benjamini-Hochberg FDR adjustment
4. **Ortholog Mapping**: Non-human genes converted to human via built-in mappings
5. **Visualization**: Interactive bubble plots and bar charts with ggplot2

## Tips & Troubleshooting

### If you get too few enriched pathways:
- Lower the **Significance Threshold** (e.g., 0.10 instead of 0.05)
- Increase the **Fold Change Threshold** (e.g., 1.5 instead of 1.2)
- Add more **Pathway Collections**
- Try **threshold-based selection** if using rank-based

### If you get too many pathways:
- Increase **Minimum Pathway Hits** (e.g., 10 instead of 5)
- Lower **P-value Threshold for Output** (e.g., 0.01 instead of 0.05)
- Use **FDR p-values** for stricter correction

### If column auto-detection fails:
- Check the **Available columns** message in the output log
- Manually specify columns in **Column Overrides** section
- Ensure your comparison prefix exactly matches (case-sensitive)

## References

- **L2P package**: https://github.com/ccbr/l2p
- **CCBR**: CCR Collaborative Bioinformatics Resource
- **Contact**: NCICCBRNIDAP@mail.nih.gov

## Version History

- **v1.1** (2025-03): 
  - Added MSigDB version logging to run outputs for improved reproducibility tracking
  - Harmonized parameter names with L2P Multi: `gene_names_column` (plural) and `t_statistic_column` (explicit)
  - Fixed optparse default value handling for comparison parameter
- **v1.0**: Initial release with progressive disclosure UI and smart column detection

---

**OMIX Collection** | **Bioinformatics** | **Pathway Analysis** | **R**
