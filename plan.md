# cdmetapopR Development Plan: R Wrapper for CDMetaPOP

## Goal

Allow a user to launch CDMetaPOP and read its output entirely from R, without
manually creating or editing CDMetaPOP's input .csv files or leaving R.

The intended end-to-end workflow:

1. User builds/edits a set of R6 objects representing CDMetaPOP's input file
   types (in R, with defaults, validation, and IDE-friendly field access).
2. `launch_cdmetapop()` writes the full object graph out to CDMetaPOP's
   expected input .csv files in a new run directory, runs the Python
   simulation, and records the location of the output files.
3. User reads results using cdmetapopR's existing `summary_*` output-reading
   functions, pointed at the recorded output location.

## Current State (as of 2026-06-24)

- Working branch: `CDMetaPOPR_wrapper` in `cdmetapopR`.
- `launch_cdmetapop()` (R/launch_cdmetapop.R) currently only invokes the
  Python subprocess on an existing RunVars.csv file/directory; it does not
  yet write input files or read outputs. Not yet updated to accept a
  `RunVars` object (Proposed Task Order, item 7).
- `ClassVars` is implemented and complete (R/class_classvars.R) — see
  "Conventions Established During ClassVars Implementation" below for
  design patterns to carry forward into `PatchVars`/`PopVars`/`RunVars`.
- `PatchVars` is implemented and complete (R/class_patchvars.R,
  R/generics.R, R/read_cdmetapop.R). Headers/defaults are drawn verbatim
  from `example_files/patchvars/PatchVarsS1.csv` (50 columns, 7 patches),
  following the ClassVars conventions below. Notable deviations/additions:
  - Disease-related columns documented in the user manual (Disease_file,
    Env Res, DiseaseDefense1_*) are NOT included, since they are absent
    from the basic PatchVarsS1.csv example (deliberate scope decision,
    confirmed with the user 2026-06-24; add later as its own task if
    disease-model support is needed).
  - `class_vars` is the first field implementing Key Design Decision 2's
    "ClassVars object or file path string" pattern. It is stored as a
    list column (not an atomic vector column, since R6 objects can't live
    in one), validated by `.validate_pv_class_vars()`. `write_cdmetapop()`
    resolves it to a path at write time (erroring if an embedded ClassVars
    object has no `location` set) but does NOT recursively write that
    nested object — that orchestration is deferred to the "write object
    graph to disk" routine (Proposed Task Order item 6).
  - `genes_initialize` (the `AlleleFrequency`-referencing field) is
    currently path/keyword-only (no object option), since `AlleleFrequency`
    doesn't exist yet — revisit once it does.
  - Several columns (Fitness_*, comp_coef) have format that depends on
    `PopVars` fields (`cdevolveans`, species count) not yet implemented;
    validation for these is deliberately permissive (`"free_char"` rule
    type) pending `PopVars`.
- `PopVars`, `RunVars`, `AlleleFrequency` do not exist yet.
- Input files are also produced via Shiny tutorial apps (`write_runvars.R`,
  `write_popvars.R`, `write_patchvars.R`, `write_classvars.R`), which are
  intended to remain a separate, beginner-facing path and are NOT to be
  refactored to depend on the new classes.
- Output-reading functions already exist (`summary_class.R`,
  `summary_dataframe.R`, `summary_disease.R`, `summary_functions.R`,
  `summary_genetics.R`, `summary_ind.R`, `summary_pop.R`,
  `summary_patch_map.R`) and parse CDMetaPOP's `summary_*AllTime*.csv`
  outputs, keyed off the `run[N]batch[N]mc[N]species[N]` output directory
  naming convention.
- `R6` added to `DESCRIPTION` `Imports:`.

### CDMetaPOP input file inventory (from CDMetaPOP/example_files)

File dependency graph (parent -> field -> child):

- `RunVars.csv` -> `Popvars` -> one or more `PopVars.csv`
- `PopVars.csv` -> `xyfilename` -> `PatchVars.csv`
- `PopVars.csv` -> `mate_cdmat`, `migrateout_cdmat`, `migrateback_cdmat`,
  `stray_cdmat`, `disperseLocal_cdmat` -> cost-distance matrices
  (see "Cost-distance matrices" below)
- `PopVars.csv` -> `betaFile_selection`, `subpopmort_file` -> auxiliary csvs
- `PatchVars.csv` -> `Genes Initialize` -> `allelefrequencyX.csv`
- `PatchVars.csv` -> `Class Vars` -> `ClassVars.csv`

Field lists (in csv column order) are recorded for: `RunVars`, `PopVars`
(~78 fields), `PatchVars` (~45 fields), `ClassVars` (~23 fields),
`AlleleFrequency` (`Allele List`, `Frequency`). See chat history / CDMetaPOP
example_files for exact column names when implementing each class.

Python-side reading happens in:
- `CDMetaPOP/src/CDmetaPOP_PreProcess.py` (`loadFile()`, `ReadCDMatrix()`) —
  minimal validation, generic csv loader.
- `CDMetaPOP/src/CDmetaPOP.py` (entry point; takes `datadir`,
  `input_filename` [RunVars.csv], `output_directory`).
- `CDMetaPOP/src/CDmetaPOP_mainloop.py` — extracts ~120 variables per
  PopVars row; prepends `datadir` to relative file paths read from PopVars.

## Key Design Decisions

1. **Class system: R6**, not S4.
   - Rationale: the object graph (RunVars -> PopVars -> PatchVars ->
     ClassVars/AlleleFrequency) will be edited interactively and repeatedly
     by users re-running scenarios with tweaked parameters (e.g., changing a
     mortality or carrying-capacity vector deep in the graph). R6's
     reference semantics mean edits to a nested sub-object are reflected
     immediately in the parent object graph, with no manual reassignment
     back up the chain. S4's copy-on-modify semantics would silently lose
     edits made to a sub-object pulled into its own variable unless the
     edit is written through the full `@` chain from the top-level object.
   - R6 is a stable, ubiquitous, CRAN-safe dependency; the added
     `Imports:` entry is not considered a meaningful installation burden.

2. **One R6 class per CDMetaPOP input file type**: `RunVars`, `PopVars`,
   `PatchVars`, `ClassVars`, `AlleleFrequency`.
   - Fields appear in the same order as the corresponding csv columns.
   - Each field has a default matching CDMetaPOP's basic example input
     files.
   - Fields that reference another input file (e.g., `PopVars$xyfilename`,
     `PatchVars`' `Class Vars` field) accept **either** the corresponding
     R6 object directly **or** a file path string (read in on demand via
     `read_cdmetapop()`). This generalizes decision 4's matrix-or-path
     pattern to every inter-file reference, not just cost-distance
     matrices — confirmed 2026-06-24.
   - Each class instance also stores its own intended on-disk location
     (a `location` field), so the write step knows where to put it. Set
     automatically to the source path when read in via `read_cdmetapop()`.

3. **Validation**: each class performs basic validation on construction/
   assignment — type checks, and for fields with a constrained set of
   valid values, a check against that set (style consistent with base R
   function argument checking). This is in addition to, not a replacement
   for, CDMetaPOP's own internal validation.

4. **Cost-distance matrices**: NOT wrapped in a dedicated class.
   - Fields such as `mate_cdmat`, `migrateout_cdmat`, `stray_cdmat`,
     `disperseLocal_cdmat` on `PopVars` accept **either** a raw R matrix
     object **or** a file path string, at the user's choice (read in
     manually, built with `create_cdmat.R`, constructed by hand, or
     pointing to an existing properly-formatted csv).
   - Validation at this stage is limited to confirming the field is a
     matrix or a character path, and (where the patch count is already
     known from the associated `PatchVars`) that matrix dimensions are
     consistent with the number of patches.
   - At write time (inside the "write object graph to disk" step used by
     `launch_cdmetapop`):
     - If the field holds a file path string, it is referenced/copied
       into the new run directory as-is.
     - If the field holds a matrix, it is written to a csv named after the
       field/variable name (e.g., `mate_cdmat.csv`) in the run directory.
     - Deduplication: matrices are tracked by identity/value within a
       single write operation. If the same matrix object (or a
       value-identical matrix) is used for more than one field, it is
       written once and all referencing fields point to that single file.

5. **Independent of Shiny tutorial apps**: the new R6 classes and the
   write/launch/read pipeline are built as a separate, production-oriented
   path. The existing `write_runvars.R`/`write_popvars.R`/
   `write_patchvars.R`/`write_classvars.R` Shiny apps remain unchanged and
   are not refactored to use the new classes.

## Conventions Established During ClassVars Implementation

These patterns were worked out while building `ClassVars` and should be
followed for `PatchVars`/`PopVars`/`RunVars` too, to keep the package
consistent. Deviate deliberately, not accidentally.

1. **Column-oriented editing, not row-oriented.** Users are expected to
   edit/rerun whole parameter columns (e.g. a mortality schedule), not
   individual rows. Each column is an R6 active binding (`cv$maturation <-
   c(...)`), backed by a private data frame. (`ClassVars` happens to have
   one row per age class; other classes may have one row per patch, etc. —
   the column-as-active-binding pattern still applies wherever a class
   wraps a multi-row csv.)
2. **Validate immediately, in R, on assignment.** Never defer validation to
   CDMetaPOP/Python. Each column has its own validation rule (numeric
   bounds, whether `"N"` is accepted as an "off" value, whether `"~"`-
   separated per-sex values are accepted, whether those parts must sum to
   1). These rules are **per-column and per-file-type** — e.g. ClassVars'
   `[0, 1]` bounds and Sex Ratio's sum-to-1 requirement are not general
   rules and must not be assumed to carry over to PatchVars/PopVars
   columns without checking the user manual (`CDMetaPOP/doc/
   cdmetapop3_usermanual.docx`) and confirming with the user. Cross-check
   actual example files in `CDMetaPOP/example_files/` against the manual's
   per-file-type "controls" section (e.g. section 3.4 for ClassVars) when
   establishing each new class's rules.
3. **CDMetaPOP reads column *order*, not header text.** csv headers exist
   purely for human readability of written files; canonical header strings
   should be copied verbatim from the package's chosen canonical example
   file (e.g. `ClassVarsAS1.csv`) even where that file has spelling
   inconsistencies. Read/write logic must match columns by *position*.
4. **Defaults come from a canonical example file**, matched per-row where
   relevant (e.g. ClassVars' age-indexed defaults from `ClassVarsAS1.csv`).
   When the canonical file has fewer rows than requested, recycle the last
   row's default and warn **once per construction call** (not once per
   column).
5. **Constructor pattern: exported plain function, hidden R6 generator.**
   Each class is constructed via a plain function matching the class name
   exactly (e.g. `ClassVars()`, not `ClassVars$new()`). The R6 generator
   itself is named distinctly (e.g. `.ClassVarsR6`) and never exported.
   - The wrapper function's own argument defaults should be the literal
     canonical-example values (not `NULL`), so `?ClassName` and IDE
     argument tooltips show real numbers. Internally, detect whether the
     caller actually supplied each argument via `missing()` (evaluated in
     the wrapper's own frame, e.g. via `eval(substitute(missing(x), list(x
     = as.name(field))), envir = this_env)`), and forward `NULL` to the R6
     initializer for anything not supplied — preserving the initializer's
     own ages/row-count-based default-resizing logic, which must not be
     short-circuited by the wrapper's literal defaults.
   - R6 + roxygen2 gotcha: roxygen2 auto-documents any top-level `<-
     R6::R6Class(...)` assignment unconditionally, regardless of comments.
     Suppress it by wrapping the call in `local(...)` and tagging it `#'
     @noRd`. Inner R6 methods must then use plain `#` comments, not `#'`
     roxygen comments — mixing the two causes a roxygen parser error
     ("@noRd must not be followed by any text"). All user-facing
     documentation lives on the exported wrapper function instead.
6. **Standalone function-call interface, layered on top of R6.** Users
   should not need to call `$method()` for *actions* (writing, adding
   rows). Instead, define plain S3 generics in `R/generics.R` (e.g.
   `write_cdmetapop()`, `add_rows()`), each dispatching to a thin
   `.<ClassName>` method that calls the underlying R6 method (e.g.
   `write_cdmetapop.ClassVars <- function(x, path = NULL)
   x$write_cdmetapop(path)`). The R6 methods stay public (S3 methods
   defined outside the class can't reach private fields) but are otherwise
   undocumented in favor of the generic. `$` is still the correct/expected
   interface for column get/set (active bindings) — only *actions* get the
   function-call wrapper. Add one new `.<ClassName>` method per generic to
   `generics.R` for each new class, rather than inventing new function
   names per class.
   - Avoid naming a standalone function after a common existing function
     (e.g. `write_csv` collides with `readr::write_csv`); prefix
     package-specific actions, e.g. `write_cdmetapop()`.
   - `as.data.frame()` follows the same pattern but hooks into base R's
     existing generic rather than defining a new one — only the
     `.<ClassName>` method needs to be added.
7. **`read_cdmetapop(filepath, type = "ClassVars")` for reading existing
   files into objects.** Lives in its own file, `R/read_cdmetapop.R`, since
   it is not a `UseMethod()`-dispatched generic (there is no object yet to
   dispatch on) — `type` is a plain, case-insensitive string switched on
   internally. Add one new `if (type == "...")` branch (and one
   `.read_<classname>_csv()` helper) per class. Csv columns are read in as
   plain character (`colClasses = "character"`) and matched to constructor
   arguments by *position*, then passed straight through the constructor
   so every value is validated identically to manual construction.
8. **Write with `quote = FALSE`** (`utils::write.csv(..., quote = FALSE)`)
   so written files byte-match CDMetaPOP's own example files, rather than
   default-quoting character-stored columns (`"N"`, `"~"`-joined values).
9. **R6 row-replication row-name gotcha.** Subsetting a data frame with
   plain-digit row names via repeated single-row indexing (e.g. `df[rep(1,
   n), ]`) mangles row names (e.g. `"61"` instead of a clean label) rather
   than producing the usual `.1`/`.2` suffixes. Reset with
   `rownames(df) <- NULL` after any such operation; row names carry no
   semantic meaning in these classes (the real row identifier, e.g. `Age
   class`, is its own column).

## Proposed Task Order

1. Design the class hierarchy skeleton: confirm field lists (from CDMetaPOP
   example_files) for `RunVars`, `PopVars`, `PatchVars`, `ClassVars`,
   `AlleleFrequency`; decide which fields are plain values vs. nested R6
   object references vs. matrix-or-path fields; sketch validation rules per
   field.
2. ~~Implement one self-contained class first to establish the pattern:~~
   ~~`ClassVars` (no nested file references) — defaults, Roxygen docs,~~
   ~~validation, a `write_csv()`/similar method.~~ **Done** (R/class_classvars.R,
   R/generics.R, R/read_cdmetapop.R) — see "Conventions Established During
   ClassVars Implementation" above.
3. ~~Implement `PatchVars` (introduces nested object references: `Class~~
   ~~Vars`, `Genes Initialize`/`AlleleFrequency`).~~ **Done** (R/class_patchvars.R)
   — see "Current State" above for notable deviations/deferred pieces
   (`AlleleFrequency` object support, disease columns, Fitness_*/comp_coef
   validation pending `PopVars`).
4. Implement `PopVars` (largest class; nested `PatchVars` reference plus
   matrix-or-path cost-distance fields).
5. Implement `RunVars` (top of hierarchy; references one or more `PopVars`).
6. Implement the "write object graph to disk" routine: walks
   RunVars -> PopVars -> PatchVars -> ClassVars/AlleleFrequency/matrices,
   writes each csv (and deduplicated matrix csvs) into a new run directory,
   restoring the file-path-string format CDMetaPOP/Python expects.
7. Update `launch_cdmetapop()` to accept a `RunVars` object (in addition to
   or instead of a raw file path), call the write routine, invoke Python,
   and capture/return the output directory location.
8. Connect the returned output directory to the existing `summary_*`
   output-reading functions so a single `launch_cdmetapop()` call can be
   followed directly by output analysis in R.
9. Update Roxygen documentation/NAMESPACE; verify CRAN-readiness (R6 as a
   declared dependency in DESCRIPTION; ensure examples do not require a
   real Python/CDMetaPOP installation to run, e.g. via `\dontrun{}` or
   mocked paths).

## Parking Lot

Ideas worth revisiting once the core class/write/launch pipeline is working,
deferred for now to keep early implementation steps simple:

- `ClassVars$add_row()` / `add_rows()`: currently copy-last-row only (new
  row(s) default to the values of the current last age class; user edits
  afterward via column active bindings). Revisit adding optional per-column
  override arguments (e.g. `add_rows(cv, maturation = 1)`) so specific
  columns can be set on the new row(s) at creation time instead of requiring
  a follow-up edit.
- `ClassVars()` constructor default-recycling: when `ages` has length > 1 and
  a column argument is omitted, the age-0 default is currently recycled
  across all age classes. Revisit whether age-class-specific defaults
  (beyond simple recycling) would be more useful once real usage patterns
  are clearer.

## Working Style Notes

- Proceed one task at a time; do not chain multiple implementation steps
  without checking in.
- Use tabs for indentation in R code; comment extensively (every function,
  non-trivial block, and key decision).
