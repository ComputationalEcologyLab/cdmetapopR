# cdmetapopR 2.0.0 (2026-10-07)

## Breaking changes

* `launch_cdmetapop()` has a completely redesigned API. The old signature with separate `runvarsDirectory`, `runvarsFilename`, and `outputDirectory` arguments has been replaced with a new signature that accepts either a `RunVars` object or a path to an existing run directory. This change enables the new R6 class system and automatic input file writing. Users must update their code to use the new signature (see function documentation for details).

## Major new features

* **Disease module support**: Added comprehensive support for CDMetaPOP's disease module, including:
  - New `DiseaseVars` R6 class for disease model configuration
  - `make_diseasevars()` Shiny app to generate DiseaseVars.csv templates
  - Disease-related columns in `PatchVars` (`disease_file`, `Env Res`, `dd1_*`/`dd2_*` transition columns)
  - Disease integration in `PopVars` via `implement_disease` control
  - Validation functions for disease transition rates and cross-field consistency

* **R6 class system**: Implemented R6 classes for all CDMetaPOP input file types:
  - `ClassVars` for age-class specifications
  - `PatchVars` for patch configuration
  - `PopVars` for population batch definitions
  - `RunVars` for simulation run settings
  - `DiseaseVars` for disease model parameters
  - All classes include comprehensive validation and helper methods

* **Read/write functionality**:
  - `read_cdmetapop()` reads existing CDMetaPOP input files into R6 objects
  - `write_cdmetapop()` writes R6 objects to CDMetaPOP-formatted CSV files
  - Supports all five input file types

* **New vignette**: Added "Building CDMetaPOP input files in R" vignette with comprehensive examples for creating, validating, and launching simulations using the R wrapper

## Enhancements to existing functions

* `make_classvars()`: Refactored age-sex input format, improved Shiny UI
* `make_patchvars()`: Added disease tab with disease-related columns; changed default `K` and `N0` from 0 to 100
* `make_popvars()`: Added disease tab and `implement_disease` control
* `make_runvars()`: Added `ncores` option to Shiny UI and output template
* `launch_cdmetapop()`: Enhanced to support disease module and R6 class system
* Removed quotes from character fields in CSV output files for CDMetaPOP compatibility

## Testing and validation

* Added comprehensive test coverage for disease functionality
* Added validation functions for all input file types and fields
* Added cross-field validation for disease models
* Added helper functions for normalizing and resolving input segments

## Other changes

* Added explicit R6 import to fix CRAN check warning
* Fixed non-ASCII characters throughout the codebase
* Updated README with new disease module information

# cdmetapopR 1.0.0

* Initial CRAN submission.