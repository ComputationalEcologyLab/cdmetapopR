# cdmetapopR 1.1.0 (2026-08-18)

* Added `make_diseasevars()` to generate a DiseaseVars.csv template via a Shiny app, for configuring the new CDMetaPOP disease module.
* `make_patchvars()`: added disease-related columns (`disease_file`, `Env Res`, and disease-defense-allele transition columns `dd1_*`/`dd2_*`) and a new "Disease" tab in the Shiny UI. Changed default values of `K` and `N0` from 0 to 100.
* `make_popvars()`: added a "Disease" tab and `implement_disease` control, determining where in CDMetaPOP's life cycle the disease module is applied.
* `make_runvars()`: added `ncores` option to the Shiny UI and output template.

# cdmetapopR 1.0.0

* Initial CRAN submission.