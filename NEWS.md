# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased] - 2026-05-26

### Highlights

- Merge & integration
	- Merged recent branch work and consolidated edits from contributors (599eaa2).

- Major updates
	- Large refactor of summary and file-reading functions to support multiple MCs, batches and custom figure workflows (81251ad, 837a05c, ac40d05).
	- Added `create_cdmat()` helper for constructing CDMetaPOP matrices (61c81fe).
	- Added `cdmetapop_to_gene()` utilities for GENEPOP/GENALEX conversion and related helpers (b3af378, 4f56853).

- New/updated functions
	- `launch_cdmetapop()` added to simplify running simulations (b8a9cc5).
	- Improvements to `summary_functions`, including multi-MC and multi-batch support (ac40d05, 81251ad).

- CRAN & examples
	- Roxygen/example fixes and dontrun adjustments to pass CRAN checks (4a866fa, e6da636, a5d231e).
	- Removed non-ASCII characters and cleaned examples for CRAN compatibility (6c903dc, 76e0673).

- Documentation & packaging
	- README and manual updates, added authors metadata (9152da6, f2f427f, 7531ad5).
	- Project configuration and .Rbuildignore improvements for cleaner builds (d9de812, 8b24355, 7adcb9a).

### Other notable recent commits

- Merge PRs and housekeeping: 6bc2ddc, f6f4a34, 4b190bc, 6646895
- Small fixes and examples: 9147f95, 4cb94eb, ce18adf, 77658be

## [0.0.1-dev] - 2024-11-20
### Added
- Added a new function `dispersal()` to calculate the proportions of individuals that move across generations


## [0.0.1-dev] - 2024-11-19
### Added
- Added a new function `age_structure_proportions()` to calculate the proportions of age structure from a given ind file

## [0.0.1-dev] - 2024-11-19
### Changed name versioning to -dev and to a more conventional numbering system of 3 numbers. 
### 1. Major change: major redesign; 
### 2. Minor change: new features (such added function); 
### 3. Patch: bug fixes or small changes