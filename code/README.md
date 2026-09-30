# OMIX L2P Pathway Analysis (Single)

List to pathways (L2P) over-representation analysis for differential expression results. Uses Fisher's exact test to identify enriched pathways in gene lists.

## Overview

This capsule performs pathway enrichment analysis on differential expression data to identify biological pathways that are significantly enriched in your gene lists. It supports multiple pathway databases (GO, REACTOME, KEGG, MSigDB), species conversion via ortholog mapping, and generates publication-ready bubble plots and bar charts.

## Basic Settings (Required)

Before running the analysis, configure these essential parameters in the **⭐ Basic Settings** category:

### 1. DEG Table File
**Input your differential expression data:**
- **Upload your own file**: Click to upload CSV, TSV, or RDS format
- **Use demo data**: Leave blank to use the attached demo data asset (Mouse RNA-seq example)
- **Avoid ambiguous input**: Blank selection searches only the `deg_table`
  mount. If more than one candidate remains after exact comparison matching,
  the run stops and asks you to select the intended file explicitly.

**Required columns in your file:**
- Gene identifier column (e.g., `Gene`, `symbol`)
- For each comparison, three columns with the pattern `{comparison}_tstat`, `{comparison}_pval`, `{comparison}_FC`
  
**Example for comparison "B-A":**
```
Gene        B-A_tstat   B-A_pval    B-A_FC
Serpina3f   5.23        0.0001      2.5
Abl1        -3.45       0.002       0.6
...
```

### 2. Comparison
**Which contrast to analyze** (REQUIRED)
- Specify the comparison identifier (e.g., `B-A`, `Treatment-Control`, `KO-WT`)
- Must match the prefix in your column names
- Example: If your columns are `B-A_tstat`, `B-A_pval`, enter `B-A`

### 3. Species
**Select your organism** (default: Mouse)
- Options: Human, Mouse, Rat, Rabbit, Zebrafish, Macaque, Drosophila
- Non-human genes are automatically converted to human orthologs for pathway analysis

### 4. Pathway Collections
**Select which pathway databases to search** (default: GO,REACTOME,KEGG)

Copy and paste one or more comma-separated identifiers (see full list below):

**Quick options:**
- `H` - Start here! MSigDB Hallmark gene sets (50 focused, well-defined pathways)
- `GO,REACTOME,KEGG` - Broad coverage of standard databases
- `H,C2,C6` - Cancer-focused analysis
- `GO,REACTOME,C7` - Immunology-focused analysis

See the "Available Pathway Collections" section below for the complete list and descriptions.

## Available Pathway Collections

The **Pathway Collections** parameter accepts a **comma-separated list** of pathway database identifiers. You can mix and match any combination.

### Standard Biological Databases

Copy and paste these into the "Pathway Collections" field:

```
GO
```
- Gene Ontology: Comprehensive biological processes, molecular functions, and cellular components

```
REACTOME
```
- Reactome: Curated pathway database focused on human biology

```
KEGG
```
- KEGG: Kyoto Encyclopedia of Genes and Genomes pathway database

```
PANTH
```
- PANTHER: Protein Analysis Through Evolutionary Relationships

```
PID
```
- Pathway Interaction Database: Curated cancer and signaling pathways

```
BIOCYC
```
- BioCyc: Collection of metabolic pathway databases

```
WikiPathways
```
- Community-curated pathway database

### MSigDB Collections

[MSigDB (Molecular Signatures Database)](http://www.gsea-msigdb.org/gsea/msigdb/) provides expertly curated gene sets:

```
H
```
- **Hallmark gene sets**: Well-defined biological states/processes (50 gene sets)

```
C1
```
- **Positional gene sets**: Genes grouped by chromosomal location

```
C2
```
- **Curated gene sets**: Chemical and genetic perturbations, canonical pathways (KEGG, REACTOME, BIOCARTA, PID)

```
C3
```
- **Regulatory target gene sets**: microRNA and transcription factor targets

```
C4
```
- **Computational gene sets**: Cancer-related gene sets from computational analyses

```
C5
```
- **Ontology gene sets**: GO biological process, cellular component, molecular function

```
C6
```
- **Oncogenic signature gene sets**: Gene sets from cancer-related studies

```
C7
```
- **Immunologic signature gene sets**: Cell types, states, and perturbations from immunology studies

```
C8
```
- **Cell type signature gene sets**: Gene sets from single-cell sequencing studies

### Common Examples

**Default (comprehensive but focused):**
```
H
```

**Broad pathway coverage:**
```
GO,REACTOME,KEGG
```

**Cancer-focused analysis:**
```
H,C2,C6
```

**Immunology-focused analysis:**
```
GO,REACTOME,C7
```

**Comprehensive MSigDB analysis:**
```
H,C1,C2,C3,C4,C5,C6,C7,C8
```

**All available databases:**
```
GO,REACTOME,KEGG,PANTH,PID,BIOCYC,WikiPathways,H,C1,C2,C3,C4,C5,C6,C7,C8
```

## Species Support

The analysis supports multiple species with automatic ortholog mapping to human gene symbols:

- Human, Mouse, Rat, Rabbit, Zebrafish, Macaque, Drosophila

All genes are mapped to human orthologs internally for pathway matching, ensuring compatibility across species.

## Custom Pathways

You can provide your own pathway definitions via the "Custom Pathway File" parameter:

**Format**: TSV or CSV file with two columns:
- Pathway name column (default: `gene_set_name`)
- Gene symbol column (default: `gene_symbol`)

Custom pathways can be used **with** or **without** standard collections.

## Output Files

The analysis generates:

1. **l2p_results.csv**: Complete pathway enrichment results
   - Pathway names, categories, direction
   - Number of hits, percent gene hits, enrichment score
   - P-values and FDR-adjusted p-values
   - Genes in pathway and overlapping genes

2. **Visualization plots**:
   - `l2p_plots_upregulated_pathways_bubble.png`
   - `l2p_plots_upregulated_pathways_bar.png`
   - `l2p_plots_downregulated_pathways_bubble.png`
   - `l2p_plots_downregulated_pathways_bar.png`

3. **l2p_results_provenance.csv**: Analysis metadata and parameters

## Optional: Advanced Configuration

Beyond the basic settings, you can fine-tune the analysis using optional parameters in the App Panel:

### Column Overrides
If automatic column detection doesn't work for your data:
- **Gene Name Column**: Specify which column contains gene identifiers
- **Ranking Column**: Override the auto-detected `{comparison}_tstat` column
- **Significance Column**: Override the auto-detected `{comparison}_pval` column
- **Fold Change Column**: Override the auto-detected `{comparison}_FC` column

### Gene Selection
Control which genes are included:
- **Select by rank** (default: FALSE): Use top-ranked genes instead of the default significance and fold-change thresholds
- **Select top percentage** (default: TRUE): Select top % of genes vs. fixed number
- **Select top genes** (default: 500): Number of top genes when not using percentage
- **Significance threshold** (default: 0.05): P-value cutoff when selecting by significance
- **Fold change threshold** (default: 1.2): FC cutoff when selecting by significance
- **Minimum DEG genes** (default: 50): Minimum genes required to proceed

### Pathway Filtering
Refine pathway results:
- **Minimum pathway hits** (default: 5): Minimum genes required per pathway
- **P-value threshold for output** (default: 0.05): Filter output to significant pathways (set to 0 for all)
- **Use built-in gene universe** (default: FALSE): Use curated gene lists vs. detected genes
- **Use FDR p-values** (default: FALSE): Report FDR-adjusted p-values instead of raw p-values

### Visualization
Customize plot appearance:
- **Number of pathways to plot** (default: 20): Top N pathways in each plot
- **Pathway label max length** (default: 50): Truncate long pathway names
- **Font sizes**: Customize pathway labels, axis titles, and tick labels
- **Custom pathway selection**: Manually specify pathways to visualize
- **Plot dimensions** (default: 12×12 inches): Width and height for saved plots
- **Bubble plot variables**: Control bubble size, color, and sorting

---

## For Advanced Users: Command-Line Usage

If running via command line or scripts (most users should use the App Panel above):

```bash
Rscript main.R \
  --deg_table /data/deg_table/var_DEGAnalysis.rds \
  --comparison "B-A" \
  --species Mouse \
  --collections_to_include "H,C2" \
  --select_top_genes 500 \
  --minimum_pathway_hit_count 5
```

## Tips

1. **Start with Hallmark (H)**: If unsure which collections to use, start with `H` for a focused set of well-defined pathways
2. **Adjust filtering**: If you get too few or too many results, adjust the p-value threshold or gene selection criteria
3. **Use demo data**: Leave "DEG Table File" blank to test with the attached demo data
4. **Custom visualization**: Use the "Custom Pathways Up/Down" parameters to highlight specific pathways of interest

## Citation

If you use this tool in your research, please cite:
- The l2p R package: https://github.com/ccbr/l2p
- MSigDB (if using MSigDB collections): Liberzon et al., Cell Systems 2015

## Support

For questions or issues:
- **NIDAP Team**: NCICCBRNIDAP@mail.nih.gov
- **CCBR**: CCR Collaborative Bioinformatics Resource

---

**OMIX Collection** | **Bioinformatics** | **Pathway Analysis** | **R**
