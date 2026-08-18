# Changelog

All notable changes to OMIX L2P Pathway Analysis (Single) will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Version numbers correspond to Code Ocean capsule release versions (integers: v1, v2, v3, etc.).

## [Unreleased]

### Added
- A local adapter workflow-input test suite covering preferred `DEG` CSV
  discovery, ambiguity errors, inferred B-A columns, and the uniquely named
  `moo-diff.rds` fallback.
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
- Workflow input discovery now selects exactly one CSV whose filename matches
  the case-insensitive regex `DEG`, avoiding non-DEG workflow artifacts such
  as package inventories.
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
