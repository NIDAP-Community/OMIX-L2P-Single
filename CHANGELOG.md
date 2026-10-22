# Changelog

All notable changes to OMIX L2P Pathway Analysis (Single) will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Version numbers correspond to Code Ocean capsule release versions (integers: v1, v2, v3, etc.).

## [Unreleased]

### Added
- A deterministic adapter-only handoff for direct OMIX Limma workflow edges:
  when no `deg_table` asset is mounted, exactly one `Limma_Analysis.csv` under
  the Code Ocean result bundle is accepted. Arbitrary generic CSV files remain
  rejected.
- A partial Code Ocean validation record for successful computation `814293`
  on the merged v3.2.0 adapter. The runtime digest, platform release identifier,
  and durable output checklist remain pending and no release is claimed.
- Canonical OMIX L2P Single v3.2.0 comparison-suffix controls for ranking,
  significance, and fold-change columns, exposed in both the adapter CLI and
  App Panel.
- Adapter regression coverage for unambiguous blank-comparison inference,
  ambiguous-prefix failure, alternative suffixes, and exact-column override
  precedence.
- Static adapter-contract and mutation checks covering canonical names, types,
  choices, order, defaults, source/schema hashes, managed-file boundaries,
  and the documented mouse demo preset.
- A local adapter workflow-input test suite covering explicit-file priority,
  mount-scoped discovery, exact comparison matching, ambiguity errors, and
  inferred B-A columns, including mixed generic/prefixed tables and custom
  pathway RDS objects.
- Metadata tag improvements for better discoverability (2026-01-08)
  - Added "MSigDB" tag (tool supports MSigDB H and C collections)
  - Added "gene-sets" tag
  - Standardized tag order across OMIX suite
- File upload capability for DEG tables (2026-07-07)
  - Added "Upload DEG File (Optional)" parameter in App Panel
  - Supports RDS, CSV, and TSV file formats
  - Priority-based data loading: uploaded file > data asset > error
  - Automatic extraction of data frames from RDS list objects
  - Updated App Panel instructions to reflect flexible input options
- Demo dataset documentation (2026-07-08)
  - Exposed "Demo DEG Table" in App Panel Data section with help text
  - Updated capsule description to mention demo dataset usage
  - App Panel instructions clarify automatic demo dataset usage
- Support section footer in `/code/README.md` with NIDAP Team contact (2026-07-08)
- Keyword footer to `/code/README.md` for visual branding (2026-07-08)

### Changed
- Updated the managed scientific export byte-for-byte from canonical OMIX
  commit `5caab82a6dc89c20a30f4cf3826618620b1daf0f` and recorded its SHA-256.
- The mouse demonstration preset now explicitly uses `comparison=B-A` with
  `comparisons` blank. A blank adapter CLI comparison is accepted only when
  the loaded table contains exactly one complete canonical comparison prefix.
- Narrow per-comparison workflow files retain generic-column translation while
  wide tables use only the requested prefix and configured suffixes.
- Reorganized the App Panel into Main and clearly labeled Advanced categories
  without hiding any supported adapter CLI control.
- Replaced the deprecated deployment-only `deg_file` mode selector with the
  canonical `deg_table` file binding.
- Realigned pathway collections, minimum DEG count, label sizing, font sizing,
  plot dimensions, species/plot choices, and parameter order with the
  canonical L2P Single contract. The mouse species preset remains intentional
  for the attached mouse demonstration dataset.
- Workflow input discovery is confined to `/data/deg_table`, selects an exact
  `diff_<comparison>.csv` for single-comparison workflows, and otherwise
  rejects multiple candidates rather than selecting the first path.
- Moved Code Ocean and MOSuite input translation from `code/functions/` to
  `code/adapter_io.R`, leaving `code/functions/` as the canonical R export.
- Aligned the runtime species default with the Code Ocean App Panel (`Mouse`).
- Data loading logic now supports three input methods:
  1. Direct file upload via App Panel (highest priority)
  2. Data asset attached at `/data/deg_table/` mount point
  3. Falls back with clear error if neither provided
- Default organism changed from "Human" to "Mouse" (2026-07-08)
  - Updated in App Panel default value
- Simplified capsule name (2026-01-08)
  - "OMIX L2P Pathway Analysis (Single)" → "OMIX L2P Single"
  - Maintains consistency with concise naming pattern

### Fixed
- Automatic column selection now prefers the requested comparison prefix in
  mixed wide tables, while retaining generic names for narrow tables.
- Custom pathway `.rds` files are read with `readRDS()` and validated as either
  long-format tables or native L2P pathway lists.
- Non-interactive runs no longer create an implicit `Rplots.pdf` in the code
  directory; plots are written only to the explicit results path.
- App Panel now uses named parameters mode (2026-01-08)
  - Passes arguments as `--param value` instead of positional arguments
  - Prevents optparse errors when file uploads are left blank
  - Enables proper demo dataset functionality
- Empty string argument handling in main.R (2026-01-08)
  - Filters out blank file upload parameters before parsing
  - Resolves "not a valid option" errors when using demo data
  - Updated in `/code/README.md` documentation
- Capsule name simplified from "OMIX L2P Pathway Analysis (Single)" to "OMIX L2P Single" (2026-07-08)
- App Panel instructions restructured to numbered steps matching OMIX suite style (2026-07-08)
- Support contact updated from "OMIX Team" to "NIDAP Team" in References section (2026-07-08)
- Removed hard-coded data asset path assumptions

## [v6] - 2026-07-06

### Changed
- Minor fixes and improvements

## [v5] - 2026-07-06

### Changed
- Minor fixes and improvements

## [v4] - 2026-07-05

### Changed
- Minor fixes and improvements

## [v3] - 2026-07-03

### Added
- Enhanced reproducibility tracking with version logging
- MSigDB version detection and reporting in console output
- Harmonized parameters with L2P Multi for consistency

### Changed
- Improved parameter naming and organization
- Enhanced error messages for better user guidance

## [v2] - 2026-07-01

### Changed
- Minor enhancements and bug fixes

## [v1] - 2026-07-01

### Added
- Initial published release of L2P Single Analysis
- Over-representation analysis using Fisher's exact test
- Support for multiple pathway collections (GO, REACTOME, KEGG, MSigDB)
- Species ortholog mapping (Human, Mouse, Rat, Rabbit, Zebrafish, Macaque, Drosophila)
- Customizable bubble plots and bar charts
- Gene selection by rank or threshold
- Custom pathway database support
- Comprehensive visualization options
