# OMIX L2P Analysis (Single)

## Canonical OMIX module

| Item | Location |
| --- | --- |
| Canonical module | [OMIX L2P Single](https://github.com/NIDAP-Community/OMIX/tree/main/modules/OMIX-L2P-Single) |
| Interface contract | [schemas/interface.yml](https://github.com/NIDAP-Community/OMIX/blob/main/modules/OMIX-L2P-Single/schemas/interface.yml) |
| Development contract | [OMIX module contract](https://github.com/NIDAP-Community/OMIX/blob/main/docs/module-contract.md) |
| Released source reference | [OMIX_MODULE_SOURCE.md](OMIX_MODULE_SOURCE.md) |

The canonical module owns scientific behavior, portable CLI operation, tests,
and the reusable input/output contract. This repository is its Code Ocean
deployment adapter.

## What this deployment adds

- The Code Ocean App Panel and capsule entry point.
- Uploaded and attached single-comparison DEG-table discovery under `/data`.
- Capsule outputs under `/results` and the pinned runtime configuration.

The attached demonstration dataset is from mouse and its example contrast is
`B-A`, so the deployment presets **Species** to `Mouse` and **Comparison** to
`B-A`. Replace or clear the comparison preset for another table. All scientific
selection, pathway, and visualization defaults otherwise follow the canonical
CLI. The App Panel places the essential controls under **Main Settings** and
keeps every supported tuning control visible in an **Advanced** category.

## Overview

**Version**: v4.0 | **Part of the OMIX analysis suite**

Over-representation pathway analysis for differential expression results. Given a gene list, this tool identifies over-represented pathways using Fisher's exact test via the [CCBR L2P package](https://github.com/ccbr/l2p).

Each run logs R version, l2p package version (0.0.14), l2psupp package version (0.0.14), and MSigDB database version for reproducibility tracking.

## Description

L2P (List to pathways) performs over-representation analysis to identify biological pathways that are significantly enriched in your differentially expressed genes. The analysis:

- Uses **Fisher's exact test** to calculate pathway enrichment significance
- Supports **multiple pathway databases**: GO, REACTOME, KEGG, MSigDB, and more
- Handles **multiple species** with automatic ortholog conversion to human genes
- Provides **flexible gene selection** methods (rank-based or threshold-based)
- Generates **publication-quality visualizations** (bubble plots and bar charts)

## Input Requirements

### Data Asset: DEG Table

Attach a data asset with mount name `deg_table`. You can either select one CSV,
TSV, TXT, or RDS file explicitly with **DEG Table File**, or leave that selector
blank. Blank selection searches only `/data/deg_table` and requires one
unambiguous DEG candidate. For a single **Comparison**, an exact
`diff_<comparison>.csv` is selected deterministically even when sibling
comparison files are present. Any other multiple-candidate case stops and
lists the paths instead of silently choosing the first file.

The selected data source should contain differential expression results with:

- **Gene names** (e.g., HGNC symbols)
- **Statistical measures** (t-statistics, p-values)
- **Fold changes** (linear or log scale)

**Supported formats**: RDS, CSV, TSV, TXT

**Expected columns** (auto-detected with override options):
- `GeneName` (preferred), `Gene Symbols`, `Gene`, `gene`, `symbol` (or custom) → Gene names
- `tstat` or `{comparison}_tstat` → t-statistics for ranking
- `pval` (preferred default), `adjpval`, or `{comparison}_pval` → p-values for filtering
- `FC`, `logFC`, or `{comparison}_FC` → fold changes for filtering

### Comparison selection

Use at most one of these settings:

- **Comparison** — one comparison to analyze (for example, `B-A`). This selects an exact `diff_<comparison>.csv` when present; for wide tables it matches the column prefix.
- **Comparisons** — an ordered comma-separated list (for example, `B-A,C-A,C-B`) for independent runs from one wide DEG table. Each comparison receives its own output directory and comparison-annotated figures. Leave the three statistic-column overrides blank in this mode.

When both are blank, the loaded table is inspected using the configured column
suffixes. The run proceeds only when exactly one complete comparison prefix is
found; no prefix or several prefixes produce an actionable error. The mouse
demo keeps `Comparison=B-A` so its default run is deterministic.

## Usage

### Quick Start (Beginners)

1. **Attach your DEG table** as a data asset
2. **Fill in Main Settings**:
   - **DEG Table File**: leave blank to use the attached `deg_table` asset, or select one file explicitly
   - **Comparison**: keep the demo preset `B-A`, replace it with your prefix, or clear it only when your table has one unambiguous prefix; use **Comparisons** for an ordered batch from a wide table
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

For a consistent alternative naming convention across one or more contrasts,
set **T-Statistic Suffix**, **Significance Suffix**, and **Fold Change Suffix**.
The defaults are `_tstat`, `_pval`, and `_FC`. For example, a table containing
`B-A_statistic`, `B-A_adjpval`, and `B-A_logFC` uses `_statistic`, `_adjpval`,
and `_logFC`. An exact single-comparison column override takes precedence over
its suffix. Fixed exact-column overrides are rejected for a multi-comparison
batch.

*Note: Parameter names `gene_names_column` and `t_statistic_column` have been harmonized with L2P Multi for consistency across the OMIX suite.*

#### Gene Selection Methods

**Threshold-based (default)**
- Filters by nominal p-value and fold change cutoffs
- Default thresholds: p ≤ 0.05 and absolute fold change ≥ 1.2

**Rank-based (optional)**
- Selects top N% or top N genes by t-statistic
- Better for well-powered bulk RNA-seq experiments
- Enable **Select By Rank** to use it.

#### Pathway Settings

- **Minimum Pathway Hits**: Filter out small pathways (default: 5 genes)
- **P-value Threshold for Output**: Only export significant pathways (default: 0.05)
- **Use Built-in Gene Universe**: Alternative background gene set
- **Use FDR P-values**: Use FDR-corrected values instead of raw p-values

#### Visualization Customization

- **Number of Pathways to Plot**: Top N pathways per direction (default: 20)
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

## Using Custom Pathway Databases

You can use your own custom pathway database instead of or in addition to the built-in collections.

### File Format Requirements

Supported custom-pathway formats are **CSV, TSV, TXT, and RDS**.

For CSV, TSV, TXT, or a long-format data frame saved as RDS, provide two
required columns:

- **Pathway name column**: Contains pathway/gene set names (default: `gene_set_name`)
- **Gene symbol column**: Contains gene symbols (default: `gene_symbol`)

**Example long-table format**:
```
gene_set_name,gene_symbol
My_Custom_Pathway_1,TP53
My_Custom_Pathway_1,BRCA1
My_Custom_Pathway_1,MYC
My_Custom_Pathway_2,EGFR
My_Custom_Pathway_2,KRAS
```

An RDS file may instead contain a native L2P pathway list. Each list entry must
be an atomic vector containing a pathway identifier, a display name, and one or
more gene symbols. The pathway-name and gene-symbol column settings apply only
to long-format tables, not to native L2P lists.

### How to Use Your Custom Database

1. Prepare a CSV, TSV, TXT, or RDS custom pathway file in one of the supported formats above
2. Open the **App Panel** (⚙️ icon) in this capsule
3. Go to **"Advanced: Custom Pathways"** section
4. **Custom Pathway File**: Click to upload your file from your local computer
5. **Pathway Name Column**: Adjust if your column name differs (default: `gene_set_name`)
6. **Gene Symbol Column**: Adjust if your column name differs (default: `gene_symbol`)
7. **Pathway Collections**: Leave blank to use *only* custom pathways, or keep filled to use custom + standard collections
8. Click **Run**

### Tips

- **Gene symbols must match your species**: Use human symbols or the tool will attempt ortholog conversion
- **Combine with standard collections**: You can use custom pathways alongside GO, REACTOME, etc.
- **Coming soon**: Curated custom pathway databases will be available as dropdown options in future releases

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

For an ordered batch, these files are written in one directory per comparison
and `l2p_single_run_manifest.csv` at the result root lists every output.

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
- Set the three suffix controls when the table uses consistent non-default
  endings such as `_adjpval` or `_logFC`

## Environment and reproducibility

This adapter uses the pinned Code Ocean runtime `OMIX Pathways v2`. The exact
canonical module commit, exported scientific-file hash, runtime tag, and
platform-validation state are recorded in
[OMIX_MODULE_SOURCE.md](OMIX_MODULE_SOURCE.md). The successful computation
currently on record is described in
[docs/code-ocean-validation.md](docs/code-ocean-validation.md); its unresolved
runtime digest and release fields remain explicitly pending. Record the
selected input asset and effective parameter values with any scientific result.
Local and GitHub checks do not replace representative Code Ocean validation.

## References

- **L2P package**: https://github.com/ccbr/l2p

## Support

For questions or issues:
- **NIDAP Team**: NCICCBRNIDAP@mail.nih.gov
- **CCBR**: CCR Collaborative Bioinformatics Resource

## For developers

Read [AGENTS.md](AGENTS.md) and [OMIX_MODULE_SOURCE.md](OMIX_MODULE_SOURCE.md)
before editing. Reusable scientific changes belong in the canonical OMIX module
and are exported here only after validation.

---

**OMIX Collection** | **Bioinformatics** | **Pathway Analysis** | **R**
