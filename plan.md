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

## Current State (as of 2026-06-28)

- Working branch: `CDMetaPOPR_wrapper` in `cdmetapopR`.
- `launch_cdmetapop()` (R/launch_cdmetapop.R) currently only invokes the
  Python subprocess on an existing RunVars.csv file/directory; it does not
  yet write input files or read outputs. Not yet updated to accept a
  `RunVars` object (Proposed Task Order, item 7).
- **All four input-file classes are implemented, exported, documented, and
  tested**: `ClassVars` (R/class_classvars.R), `PatchVars`
  (R/class_patchvars.R), `PopVars` (R/class_popvars.R), `RunVars`
  (R/class_runvars.R). They share the standalone generics (R/generics.R:
  `write_cdmetapop`/`add_rows`/`as.data.frame`, with a `.<ClassName>` method
  per class) and the `read_cdmetapop()` reader (R/read_cdmetapop.R: one
  `if (type == ...)` branch + `.read_<classname>_csv()` helper per class).
  `roxygenise()` has been run; NAMESPACE exports all four constructors plus
  their three S3 methods each. The package loads cleanly via
  `devtools::load_all()`.
- `ClassVars` (R/class_classvars.R): 23 columns + "Age class" id column,
  canonical `example_files/classvars/ClassVars_AS1.csv`. The original
  pattern-setting class — see "Conventions Established During ClassVars
  Implementation" below.
- `PatchVars` (R/class_patchvars.R): 49 columns + "PatchID" id column (50
  total), canonical `example_files/patchvars/PatchVarsS1.csv` (7 patches).
  Notable deviations/deferred pieces:
  - Disease-related columns documented in the user manual (Disease_file,
    Env Res, DiseaseDefense1_*) are NOT included, since they are absent
    from PatchVarsS1.csv (deliberate scope decision, 2026-06-24; add later
    as its own task if disease-model support is needed).
  - `class_vars` is the original implementation of Key Design Decision 2's
    object-or-path pattern (list column; resolves `|`-separated `.GlobalEnv`
    `ClassVars` names; `resolve_class_vars = FALSE` disables this on read).
  - `genes_initialize` (the `AlleleFrequency`-referencing field) is
    path/keyword-only (no object option), since `AlleleFrequency` does not
    exist yet — revisit once it does.
  - Several columns (Fitness_*, comp_coef) have format depending on
    `PopVars` fields; validation deliberately permissive (`"free_char"`).
    Now that `PopVars` exists, these *could* be tightened, but were left
    permissive (not revisited) — a candidate follow-up if stricter
    cross-file validation is wanted.
- `PopVars` (R/class_popvars.R): **81 columns, no id column** (row count is
  the plain integer arg `n_batches`; each row is a "batch"). Canonical
  `example_files/popvars/PopVars.csv` (4 rows). Key specifics (full detail
  in "Conventions Established During PopVars and RunVars Implementation"):
  - **Headers are CDMetaPOP dictionary KEYS**, not just column order — so
    every column is present, header text matches exactly, and field/binding
    names ARE the header text (no snake_case layer). `read_cdmetapop()`
    matches by header NAME, not position.
  - `cdinfect`/`transmissionprob` were dropped from the canonical 83 columns
    (confirmed stale leftovers, 2026-06-26 — CDMetaPOP runs fine without
    them), leaving 81.
  - Object-or-path **list columns**: `xyfilename` (-> `PatchVars`) plus the
    five cost-distance/probability matrix fields (`mate_cdmat`,
    `migrateout_cdmat`, `migrateback_cdmat`, `stray_cdmat`,
    `disperseLocal_cdmat`), which accept a raw `matrix` or path. Only
    `xyfilename` does `.GlobalEnv` name resolution (`resolve_xyfilename`);
    matrices are never name-resolved. `write_cdmetapop()` resolves objects
    to paths but errors on a raw matrix (matrix-csv writing is deferred to
    the graph-writer, Task Order item 6).
  - Per-field delimiter flags `allow_pipe` (`|` temporal) and `allow_tilde`
    (`~` per-sex); `:` and `;` handled as field-specific special cases
    (`alleles`, `implementSelection`/`implementPlasticgene`, `growth_Loo`).
    `cdevolveans`/`plasticgeneans` validated permissively (`"free_char"`).
- `RunVars` (R/class_runvars.R): **13 columns, no id column** (row count is
  `n_runs`; each row is a "run" — the top of the hierarchy). Canonical
  `example_files/RunVars.csv` (4 rows). Specifics:
  - Headers are dictionary KEYS (same model as PopVars). `read_cdmetapop()`
    matches by NAME; default `type` is now `"RunVars"`.
  - `Popvars` is the sole object-or-path list column (-> one or more
    `PopVars`), and uniquely uses **`;`** (not `|`) as its multi-value
    separator — multiple PopVars files = multiple species in one run.
  - Only `|` delimiters appear (`output_years`, `cdclimgentime`); no
    `~`/`:` anywhere, so the validator is simpler than PopVars'.
  - `implementcomp` enum = `Back`/`Out`/`N` (per the user, 2026-06-28).
- **Vocabulary** (settled 2026-06-28): rows are "age classes" (ClassVars),
  "patches" (PatchVars), "batches" (PopVars, arg `n_batches`), and "runs"
  (RunVars, arg `n_runs`). CDMetaPOP runs every RunVars run x PopVars batch
  x Monte Carlo replicate (`mcruns`) as a separate simulation.
- `AlleleFrequency` still does not exist (PatchVars' `genes_initialize`
  remains path/keyword-only pending it).
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

Field counts as actually implemented: `RunVars` (13 columns), `PopVars` (81
columns, after dropping stale `cdinfect`/`transmissionprob`), `PatchVars`
(50 columns incl. PatchID), `ClassVars` (24 columns incl. Age class).
`AlleleFrequency` (`Allele List`, `Frequency`) not yet implemented. Exact
column names/order are in each `class_*.R` file's `.<x>_fields` vector and
the canonical example file.

Note on `Popvars` multiplicity: `RunVars$Popvars` uses `;` to list multiple
PopVars files (one per species) within a single run, e.g.
`example_files/RunVars_multispecies.csv`.

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

4. **Matrix fields: a single raw matrix OR filepath(s), NOT a dedicated
   class** (decision settled 2026-06-28, after two revisions this session —
   see history note at the end of this item).
   - This covers `PopVars`' five movement matrices (`mate_cdmat`,
     `migrateout_cdmat`, `migrateback_cdmat`, `stray_cdmat`,
     `disperseLocal_cdmat`) AND its two other matrix-shaped auxiliary fields
     (`correlation_matrix`, `subpopmort_file`) — the latter two reclassified
     from bare-path `file_or_N` to matrix-or-path fields, since they are
     genuinely matrices in CDMetaPOP.
   - **Accepted value (per field, per batch row):**
     - a **single raw R matrix** — allowed ONLY as a lone value, with no
       `|` (temporal/cdclimate) or `~` (per-sex) delimiter; OR
     - a **filepath string** — including `|`/`~`-delimited multiple paths,
       or a list of paths, for the temporal/per-sex cases (`|` applies to
       all these fields; `~` only to the four per-sex-marked movement
       matrices `migrateout`/`migrateback`/`stray`/`disperseLocal`); OR
     - the literal `"N"`, for the three fields documented to allow turning
       the feature off (`migrateout_cdmat`, `correlation_matrix`,
       `subpopmort_file`).
   - **Key constraint: a matrix can never be combined with `|`/`~`.** If the
     user wants temporal or per-sex variation, they must supply filepaths
     (the `|`/`~` machinery only applies to the string/path form). This is
     the simplification that keeps a no-arg `PopVars()` valid: the canonical
     `PopVars.csv` path strings remain the field defaults (a raw matrix is
     purely an opt-in convenience for the simple single-surface case).
     Document this matrix-single-vs-filepath-for-multi rule explicitly in
     `PopVars()`'s docs. (Beta files stay path-only: `betaFile_selection`
     is a filepath, no matrix, no object.)
   - **Write mechanism (division of labor confirmed 2026-06-28):**
     `write_cdmetapop()` NEVER serializes a matrix — it only writes the
     `PopVars.csv` parameter table. A matrix-valued field writes the
     placeholder path `cdmats/<fieldname>.csv` (uniform convention for ALL
     matrix fields incl. `correlation_matrix`/`subpopmort_file` — NOT
     per-type subdirectories, so `write_cdmetapop()` needs only the field
     name); a filepath is written as-is; `"N"` writes as `"N"`. If the user
     wants control over a matrix file's location/format, they supply a
     filepath (and write that file themselves). If they supply a matrix,
     they opt into auto-naming: the standalone `write_cdmetapop()` emits a
     `cdmats/<fieldname>.csv` placeholder as a FALLBACK, but at launch the
     graph-writer overrides this with the variable-name reverse-lookup of
     Key Design Decision 6 (e.g. `mymat` -> `cdmats/mymat.csv`) and writes
     the matrix there. Consequence: a standalone-written `PopVars.csv`
     references `cdmats/*.csv` files that don't exist until launch —
     intended, but document it. (Cross-batch uniqueness/dedup is a
     launch-layer concern, settled when the graph-writer is built.)
   - Validation: confirm each value is a matrix, a path string (segments
     validated like other path fields), or `"N"` where allowed; reject a
     matrix that carries/joins `|`/`~`. Dimension-vs-patch-count checks are
     deferred to the writer/CDMetaPOP (the associated `PatchVars` may not be
     known at assignment).
   - **Decision history (this session):** started as matrix-or-path →
     briefly changed to matrix-ONLY/no-path (which broke the no-arg
     defaults, since the canonical matrices live in the separate CDMetaPOP
     repo and can't be bundled) → settled here: matrix allowed only for the
     single/no-delimiter case, filepaths required for `|`/`~`. Allowing
     matrices in the `|`/`~` multi-value cases too is parked (see Parking
     Lot) for after the package is otherwise finished.
   - **Current code does NOT yet reflect this**: as of 2026-06-28
     `class_popvars.R` still has the five cost matrices as matrix-or-path
     list columns that accept multiple matrices (no single-only constraint),
     `correlation_matrix`/`subpopmort_file` as `file_or_N`, and
     `write_cdmetapop()` erroring on a matrix. Reconciling the code to this
     decision is a pending task.

5. **Independent of Shiny tutorial apps**: the new R6 classes and the
   write/launch/read pipeline are built as a separate, production-oriented
   path. The existing `write_runvars.R`/`write_popvars.R`/
   `write_patchvars.R`/`write_classvars.R` Shiny apps remain unchanged and
   are not refactored to use the new classes.

6. **File organization/naming is the graph-writer's job, not the classes'**
   (decided 2026-06-28, after exploring and rejecting a "force the user to
   supply bare filenames + per-field canonical-directory normalizer"
   approach). The goal is that a user who builds the whole object graph in R
   never has to name or place a single csv -- yet can still trace each
   generated file back to the R object it came from.
   - **Naming via reverse `.GlobalEnv` lookup at launch.** R6 objects (and
     matrices) are references, so at `launch_cdmetapop()` time -- when the
     user's variables already exist -- the graph-writer scans `.GlobalEnv`
     and, for each node in the graph, finds the variable that `identical()`s
     it and names the file after it: `mycv1` -> `classvars/mycv1.csv`,
     `mymat` -> `cdmats/mymat.csv`, etc. This sidesteps the impossible
     variable-name-at-construction problem (a function on the RHS of `<-`
     cannot see the LHS name) precisely because it runs later, at launch,
     not at construction.
   - **Fallback + manifest.** A node with no top-level variable (built
     inline, only nested, or constructed inside a function -- the
     `.GlobalEnv`-only caveat, same as `class_vars` name resolution) gets a
     type+index name (`classvars/classvars1.csv`). The graph-writer ALWAYS
     writes a `manifest.csv` into the run directory mapping each generated
     file to a description of its object (and the variable name where
     found), so the output is self-documenting for hand-editing or sending
     to collaborators.
   - **Canonical directory structure** (matches CDMetaPOP's own
     `example_files/`): `popvars/`, `patchvars/`, `classvars/`, `cdmats/`
     (cost matrices), `otherfiles/` (correlation_matrix, subpopmort_file),
     `otherfiles/betafiles/` (beta files), `genes/` (allele-frequency
     files); `RunVars.csv` at the run-directory root. The graph-writer
     creates these and places each file by type.
   - **The `location` field is REMOVED entirely** (decided 2026-06-28).
     With naming fully launch-time (reverse-lookup) and cross-references
     resolved by the graph-writer's registry, no persistent per-object
     `location` is needed. To control a filename, name your R variable
     accordingly (reverse-lookup uses it). Removing `location` touches all
     four classes: drop the field, its active binding, and the
     `read_cdmetapop()` location-setting.
   - **`write_cdmetapop()` (the public per-object writer) is REMOVED
     entirely** (decided 2026-06-28). The R user works within R and gets the
     csvs only after `launch_cdmetapop()` (via the graph-writer). Delete the
     `write_cdmetapop` generic + its four S3 methods (generics.R) and the
     public R6 `write_cdmetapop` method on each class. The *serialization
     logic* those methods contain is not lost -- it RELOCATES into the
     graph-writer as internal helpers (the writer needs it anyway, adapted
     to resolve child references via the registry rather than via
     `location`). User-facing actions that REMAIN: `add_rows()`,
     `as.data.frame()`, `read_cdmetapop()`, `launch_cdmetapop()`.
   - **External referenced files (path strings)** -- an allele-frequency,
     beta, or matrix/PatchVars given as a *path* rather than an object --
     are kept verbatim in the data frame cell until launch; the graph-writer
     then COPIES the file (by basename) into its canonical subdir and
     rewrites the cell to the canonical relative path (e.g.
     `otherfiles/betafiles/beta.csv`). Erroring if the source path does not
     exist at launch. No filesystem side effects at field-assignment time.
   - **Run directory.** The graph-writer is UNEXPORTED, called only by
     `launch_cdmetapop()`, and AUTO-CREATES a fresh run directory each call,
     returning its path (no user-supplied directory; no overwrite of an
     existing one).
   - **Classes stay simple.** The classes do NOT gain a per-field path
     normalizer or per-field canonical-directory logic -- all of that lives
     in the graph-writer (Task Order item 6). Users still MAY supply a path
     string in any file-reference field; the recommended workflow is to hand
     in R objects/matrices and let launch name and place everything.

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
3. **CDMetaPOP reads column *order*, not header text — for ClassVars and
   PatchVars only.** For these two, csv headers exist purely for human
   readability; canonical header strings are copied verbatim from the
   canonical example file (e.g. `ClassVars_AS1.csv`) even where it has
   spelling inconsistencies, and read/write logic matches columns by
   *position*. **IMPORTANT — this does NOT hold for `PopVars`/`RunVars`**:
   CDMetaPOP reads *their* headers as dictionary KEYS, so for those two the
   header text is load-bearing, every column must be present with its exact
   name, the field/binding names ARE the header text (no snake_case layer),
   and `read_cdmetapop()` matches by NAME (see the PopVars/RunVars
   conventions section below). Establish per-class which model applies
   before writing the reader.
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
7. **`read_cdmetapop(filepath, type = ...)` for reading existing files into
   objects.** Lives in its own file, `R/read_cdmetapop.R`, since it is not a
   `UseMethod()`-dispatched generic (there is no object yet to dispatch on)
   — `type` is a plain, case-insensitive string switched on internally. Add
   one new `if (type == "...")` branch (and one `.read_<classname>_csv()`
   helper) per class. Csv columns are read as plain character (`colClasses =
   "character"`) and passed straight through the constructor so every value
   is validated identically to manual construction. **Column matching is
   per-class**: ClassVars/PatchVars match by *position* (header text is not
   load-bearing); PopVars/RunVars match by header *name* and error on any
   missing/unexpected column (headers are dict keys). The default `type` is
   `"RunVars"` (the top of the hierarchy and the most common entry point;
   updated from `"ClassVars"` 2026-06-28). Object-or-path branches pass
   `resolve_* = FALSE` so a path read from disk is never mistaken for a
   live-object name.
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

## Conventions Established During PatchVars Implementation

These patterns extend the ClassVars conventions above and should be carried
forward into `PopVars`/`RunVars`. Deviate deliberately, not accidentally.

1. **`allow_pipe` / the `|` temporal-change mechanism.** CDMetaPOP lets most
   PatchVars columns specify a value that changes partway through a run
   (its `cdclimate` module), via multiple `|`-separated values in one cell
   (e.g. `"0|0.2|0.5"`). Implemented as a per-field `allow_pipe` flag in
   `.pv_rules`; the validator (`.validate_pv_field()`) splits on `|` first,
   validates each segment independently against the column's normal rule
   (`.pv_check_segment()`), then stores the whole original string verbatim
   as character (CDMetaPOP needs the literal delimited text). This is why
   every pipe-allowed column is character-stored even when no `|` is
   present in a given value — a data frame column must have one uniform
   type. Only `x`, `y`, `PatchID`, `SubpatchNO` are excluded (immutable
   identifiers/coordinates, not "a value that changes over a run").
   **RESOLVED for `PopVars` (2026-06-26):** PopVars uses `|` (temporal) and
   `~` (per-sex) as generalized per-field flags (`allow_pipe`/`allow_tilde`,
   validator splits `|` outermost then `~`), exactly as anticipated. But the
   feared general `:` axis "combined on the same field" did NOT
   materialize — `:` (and `;`) turned out to be used only in a few specific
   fields, each handled as its own dedicated rule `type` rather than a
   global delimiter axis: `alleles` (`:`-separated per-locus counts, e.g.
   `2:5:3`), `implementSelection`/`implementPlasticgene` (`:`-joined timing
   tokens, e.g. `Out:Back`), and `growth_Loo` (`;`-separated genotype-linked
   pair `Loo_1;Loo_2`). So the lesson holds — don't assume a fixed flag set
   carries over — but the actual answer was "fewer global axes, more
   field-specific special-case types," not a three-way recursive splitter.
   `RunVars` is simpler still: only `|` (no `~`/`:`); its one multi-value
   reference field, `Popvars`, uses `;` to list species.
2. **Object-or-path fields are list columns, not atomic vectors**, since R6
   objects can't live in a plain character/numeric vector. `class_vars`'s
   pattern (`.pv_normalize_class_vars_patch()`/`.validate_pv_class_vars()`):
   each row's cell is a *flat list of items* (each item a `ClassVars`
   object or a literal path string), supporting both a single value and
   multiple `|`-joined values per row uniformly. `write_cdmetapop()`
   resolves each item to a path (object → its own `location`, erroring if
   unset; string → itself) and rejoins with `|`. Expect `PopVars`' nested
   `PatchVars` reference (and the cost-distance-matrix fields, depending on
   what's decided for them — see Task Order item 4) to need the same
   list-column treatment if they are to support `|` at all.
3. **Resolving an object by name from a string: search `.GlobalEnv` only,
   never `parent.frame()`.** Tried call-stack-based lookup first
   (`parent.frame()` inside an R6 active binding to find a variable in the
   *caller's* environment); confirmed empirically broken as soon as the
   assignment happens from inside a user-defined function one level deep
   (see `.pv_resolve_class_vars_segment()`'s doc comment for the full
   reasoning/test). `.GlobalEnv`-only lookup is the accepted fallback,
   flagged by the user as a known awkward tradeoff (Parking Lot, below).
   `PopVars`' nested `PatchVars` reference should reuse this same
   resolution helper/pattern rather than reinventing it.
4. **Construction-time-only resolution opt-out (`resolve_class_vars`).**
   `read_cdmetapop()` must disable `.GlobalEnv` name lookup (passing
   `resolve_class_vars = FALSE` through to the R6 initializer) since a
   value read from an existing csv is always a literal path, never a
   live-object-name reference — resolving it anyway risks accidentally
   picking up an unrelated same-named object in the reading session. The
   flag only applies at construction; post-construction `$field <-`
   assignment always resolves (that's the point of the mechanism). Any
   `PopVars` field with the same object-or-path-by-name pattern needs the
   analogous flag wired through its own `read_cdmetapop()` branch.
5. **`write_cdmetapop()` auto-sets/updates `location`, with a
   mismatch warning.** After a successful write, `private$location_path
   <- path` (so a single `write_cdmetapop(obj, path = ...)` call is
   sufficient — no separate `obj$location <- path` needed, including for
   a parent object referencing `obj` by R6 reference). If an explicit
   `path` differs from an already-set `location`, warn first (naming both
   values) before overwriting — silent precedence given to the explicit
   `path`, but never a silent mismatch.
6. **Recommend separate subdirectories per file type** (`classvars/`,
   `genes/`, and presumably `popvars/`/`patchvars/`/cost-distance-matrix
   equivalents) as documented good practice, both for organizational
   hygiene and to keep "object names in `.GlobalEnv`" and "literal file
   path strings" from ever plausibly colliding under convention 3's
   lookup. Mention this in each new class's docs the way `ClassVars`' and
   `PatchVars`' docs do.
7. **Good practice from ClassVars (conventions 1-9 in that section above)
   all still apply**: column-oriented active bindings, validate
   immediately in R, match csv columns by *position* not header text
   (ClassVars/PatchVars only — see corrected ClassVars item 3), defaults
   from a canonical example file (recycling + single warning past its row
   count), exported-function-wrapping-hidden-R6-generator constructor
   pattern, the standalone `generics.R` action functions,
   `read_cdmetapop()`'s per-class branch+helper, `quote = FALSE` writes,
   and the row-name reset after `df[rep(1, n), ]`-style row replication.

## Conventions Established During PopVars and RunVars Implementation

These extend the ClassVars/PatchVars conventions and apply to any future
class with the same characteristics (e.g. `AlleleFrequency`). Deviate
deliberately, not accidentally.

1. **Header-as-dictionary-key classes (PopVars, RunVars).** CDMetaPOP reads
   these files' headers as dict keys, not by column order. Consequences:
   (a) field/active-binding names ARE the header text verbatim (no
   snake_case layer — every PopVars/RunVars header is already a valid R name
   with no spaces); (b) every documented column must be present; (c)
   `read_cdmetapop()` matches by NAME and errors on any missing/unexpected
   column (`setdiff()` both directions), rather than checking only the
   column *count*. Confirm which model a new class uses before writing its
   reader — ClassVars/PatchVars are the by-position exception, not the rule.
2. **No id column / plain integer row count.** Unlike ClassVars ("Age
   class") and PatchVars ("PatchID"), PopVars and RunVars have no id column
   — row order is the only identity (CDMetaPOP numbers them from 0). So row
   count is a plain integer constructor arg, not a validated sequential-id
   vector: `n_batches` (PopVars) / `n_runs` (RunVars). The arg is read-only
   post-construction (reassigning errors); change row count via `add_row()`.
   The same length-1-or-exactly-n recycling rule as the other classes still
   applies to column assignment.
3. **Vocabulary: run / batch / patch / age class.** A RunVars row is a
   "run", a PopVars row is a "batch", and CDMetaPOP executes every run x
   batch x Monte Carlo replicate (`mcruns`) as a separate simulation. The
   row-count args follow this (`n_runs`/`n_batches`), as does user-facing
   text (print output, errors, docs). Keep this consistent in any new class.
4. **Object-or-path generalizes to matrices and to multiple separators.**
   PatchVars' `class_vars` list-column pattern was reused for: PopVars'
   `xyfilename` (-> PatchVars) and its five cost-distance/probability matrix
   fields (accepting a raw `matrix` OR path), and RunVars' `Popvars` (-> one
   or more PopVars). Two refinements emerged:
   - **Per-field target class + optional name resolution.** Only fields
     pointing at a *named-object* type resolve against `.GlobalEnv`
     (`xyfilename` -> PatchVars; `Popvars` -> PopVars). Raw matrices are
     never name-resolved (they aren't kept as long-lived named globals), so
     the matrix fields skip resolution entirely.
   - **The multi-value separator is per-field, not universal.** PatchVars'
     `class_vars` and PopVars' object fields use `|`; RunVars' `Popvars`
     uses `;` (multiple species). The normalize/rejoin helpers are
     parameterized on the separator. Don't assume `|`.
5. **Per-field rule `type`s beyond numeric/N/E.** PopVars/RunVars added
   `"enum"` (fixed string set), `"enum_numeric"` (fixed numeric set),
   `"YN"`, `"threshold"` (`max`/`Npercent max`/number), `"file_or_N"`, and
   several one-field special types (`alleles`, `colon_tokens`, `growth_loo`,
   `prob_or_wrightfisher`, `yn_or_prob`). When a field's grammar is
   open-ended or depends on unmodeled cross-file state (PopVars'
   `cdevolveans`/`plasticgeneans`), validate permissively (`"free_char"`),
   same as PatchVars did for Fitness_*/comp_coef. Prefer a dedicated rule
   type over forcing a field into an ill-fitting general axis.
6. **`write_cdmetapop()` errors rather than silently writing nested files.**
   Consistent across all classes: object-or-path fields resolve embedded R6
   objects to their `location` (erroring if unset) and rejoin with the
   field's separator, but do NOT recursively write the nested file — and
   PopVars additionally errors on a raw `matrix` (it has nowhere to write
   it yet). All nested-file/matrix writing is deferred to the graph-writer
   (Task Order item 6), which will own directory layout and dedup.
7. **Generating wide repetitive code from the canonical CSV.** For an
   80+-column class, generate the defaults list, the `initialize()`
   signature/`supplied` list, the active bindings, and the wrapper-function
   signature programmatically from the canonical csv (via anaconda Python),
   then paste — far less error-prone than hand-transcribing. The active
   bindings and constructor args were ultimately written out explicitly
   (not via a `$set()` loop) to match ClassVars/PatchVars' style and keep
   `?PopVars`/IDE tooltips populated with per-argument literal defaults.

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
4. ~~Implement `PopVars` (largest class; nested `PatchVars` reference plus~~
   ~~matrix-or-path cost-distance fields).~~ **Done** (R/class_popvars.R) —
   81 columns, canonical `PopVars.csv`. How the open design questions
   resolved (see "Conventions Established During PopVars and RunVars
   Implementation" below for full detail):
   a. **Delimiters** — per-field flags `allow_pipe` (`|`) + `allow_tilde`
      (`~`), validator splits `|` outermost then `~`. The feared general
      `:` axis didn't exist; `:`/`;` handled as dedicated field-specific
      rule types (`alleles`, `implementSelection`/`implementPlasticgene`,
      `growth_Loo`). See corrected PatchVars Conventions item 1.
   b. **Rows = batches** — kept the column-active-binding pattern (confirmed
      with the user); row count is the plain integer `n_batches` (no id
      column). Whether each batch needs its own nested graph is the
      graph-writer's problem (item 6), not the class's.
   c. **Nested `PatchVars` reference** — confirmed field is `xyfilename`;
      implemented as an object-or-path list column reusing the `class_vars`
      pattern (PatchVars object or path; `.GlobalEnv` resolution via
      `resolve_xyfilename`).
   d. **Cost-distance matrix fields** — list columns (object-or-path), same
      machinery as `xyfilename`, accepting a raw `matrix` or path; never
      name-resolved. `write_cdmetapop()` errors on a raw matrix (matrix-csv
      writing deferred to the graph-writer, item 6).
   Also: confirmed CDMetaPOP reads PopVars headers as dict KEYS (field
   names = header text; read by name); dropped stale
   `cdinfect`/`transmissionprob`; `egg_add` validated `mating`/`nonmating`
   case-insensitively.
5. ~~Implement `RunVars` (top of hierarchy; references one or more~~
   ~~`PopVars`).~~ **Done** (R/class_runvars.R) — 13 columns, canonical
   `RunVars.csv`, headers as dict keys, `n_runs` row arg. `Popvars` is a
   `;`-separated object-or-path list column (multiple species per run);
   only `|` delimiters elsewhere; `implementcomp` = `Back`/`Out`/`N`.
   `read_cdmetapop()` default `type` changed to `"RunVars"`.
6. **Cleanup refactor (prerequisite for the graph-writer; decided
   2026-06-28).** Before building item 7, simplify the classes per Key
   Design Decision 6:
   - Remove the `location` field, its active binding, and the
     `read_cdmetapop()` location-setting, from all four classes.
   - Remove the public `write_cdmetapop()` API: the generic + four S3
     methods (generics.R) and the public R6 method on each class. PRESERVE
     the serialization logic (relocate it into the graph-writer in item 7,
     or stage it as internal helpers now). Update `generics.R`'s header and
     the ClassVars-conventions note that reference `write_cdmetapop`.
   - Re-run roxygenise; the package should still load with `add_rows()`,
     `as.data.frame()`, `read_cdmetapop()`, `launch_cdmetapop()` intact.
7. Implement the "write object graph to disk" routine (UNEXPORTED; called
   only by `launch_cdmetapop()`; auto-creates a fresh run directory and
   returns its path). Walks RunVars -> PopVars -> PatchVars ->
   ClassVars/AlleleFrequency/matrices and OWNS file naming/organization per
   Key Design Decision 6:
   - reverse `.GlobalEnv` identity lookup to name each node's file after the
     user's variable (`mycv1` -> `classvars/mycv1.csv`); type+index fallback
     for nodes with no top-level variable;
   - the canonical directory structure (`popvars/`, `patchvars/`,
     `classvars/`, `cdmats/`, `otherfiles/`, `otherfiles/betafiles/`,
     `genes/`; `RunVars.csv` at root);
   - dedup by object/matrix identity (shared node -> one file, all
     referrers point at it);
   - matrices written NxN (no header/row names; CDMetaPOP `ReadCDMatrix()`
     format); external path-string references copied (by basename) into
     their canonical subdir, cell rewritten to the canonical relative path
     (erroring if the source is missing);
   - a `manifest.csv` mapping every generated file to its object.
8. Update `launch_cdmetapop()` to accept a `RunVars` object (in addition to
   or instead of a raw file path), call the write routine, invoke Python,
   and capture/return the output directory location.
9. Connect the returned output directory to the existing `summary_*`
   output-reading functions so a single `launch_cdmetapop()` call can be
   followed directly by output analysis in R.
10. Update Roxygen documentation/NAMESPACE; verify CRAN-readiness (R6 as a
    declared dependency in DESCRIPTION; ensure examples do not require a
    real Python/CDMetaPOP installation to run, e.g. via `\dontrun{}` or
    mocked paths).

## Parking Lot

Ideas worth revisiting once the core class/write/launch pipeline is working,
deferred for now to keep early implementation steps simple:

- `add_row()` / `add_rows()` (now on `ClassVars`, `PatchVars`, and
  `PopVars` -- confirmed with the user 2026-06-26 that this applies to all
  three, not just `ClassVars`): currently copy-last-row only (new row(s)
  default to the values of the current last row; user edits afterward via
  column active bindings). Revisit adding optional per-column override
  arguments (e.g. `add_rows(cv, maturation = 1)`, or
  `add_rows(mypopvars, egg_add = "nonmating")`) so specific columns can be
  set on the new row(s) at creation time instead of requiring a follow-up
  edit -- particularly valuable for `PopVars`, where the current workaround
  (reassigning the entire column with a manually-padded vector) is
  error-prone. **Now actionable** (all four classes exist as of 2026-06-28;
  the deferral condition "after RunVars is implemented" is met) — the
  override mechanism can be designed once and applied uniformly to
  `add_row()`/`add_rows()` across all four classes. Validate each override
  through the same per-field validator as `$<-`; scalar overrides recycle
  across new rows, length-n vectors apply per-row.
- `ClassVars()` constructor default-recycling: when `ages` has length > 1 and
  a column argument is omitted, the age-0 default is currently recycled
  across all age classes. Revisit whether age-class-specific defaults
  (beyond simple recycling) would be more useful once real usage patterns
  are clearer.
- `PatchVars`' `|` (temporal-change) handling for `class_vars`/`genes_initialize`:
  currently requires the user to enter object references as a quoted
  character string (e.g. `pv$class_vars <- "cv_year0|cv_year5"`), resolved
  by name-matching against objects in `.GlobalEnv` only -- a call-stack-based
  lookup (`parent.frame()`) was tried first and confirmed empirically
  unreliable once the assignment happens from inside a user-defined function,
  not at the literal top level (see class_patchvars.R's
  `.pv_resolve_class_vars_segment()` for the reasoning). This was accepted as
  "best for now" but flagged by the user as an awkward interface (quoting a
  reference to one's own R6 object). Revisit once testers/reviewers are
  available to weigh in on whether there's a better mechanism (e.g. NSE via
  a dedicated non-`$<-`-based setter, or simply leaning harder on the
  already-supported direct object/list assignment path instead of strings).
  `genes_initialize` doesn't yet do any object resolution at all (no
  `AlleleFrequency` class exists yet); apply the same scrutiny to it once
  that class exists, rather than copying the `class_vars` pattern reflexively.
- `write_cdmetapop()` standalone vs. the future "write object graph to disk"
  routine (Proposed Task Order item 6): `write_cdmetapop.PatchVars()`
  currently requires every embedded `ClassVars` object (in `class_vars`) to
  already have a `location` set, erroring otherwise -- it deliberately does
  NOT write nested `ClassVars` files itself, since that orchestration
  (choosing a run-directory layout, deduplicating when multiple patches
  share the same `ClassVars` object, etc.) was meant to live in the future
  graph-writer once `RunVars`/`PopVars` exist to give it real context. As a
  smaller, no-regrets fix, `write_cdmetapop()` (on `ClassVars` and
  `PatchVars`) now auto-sets the object's own `location` to wherever it was
  just written, so at least no separate `$location <-` assignment is needed
  once an object has been written once. This same "resolve embedded objects
  to their `location`, error if unset, never recursively write" behavior is
  now consistent across all four classes (`PopVars` additionally errors on a
  raw `matrix`, having nowhere to write it yet). The bigger question --
  should a single entry point write a whole `RunVars -> PopVars ->
  PatchVars -> ClassVars`/matrix graph in one call, auto-generating
  paths/directories and deduplicating shared objects/matrices, rather than
  requiring everything be pre-located? -- is exactly Proposed Task Order
  item 6, **now unblocked** (all four classes exist as of 2026-06-28). This
  is the recommended next major task; see Key Design Decision 4 for the
  matrix dedup-by-identity requirement it must satisfy.
- **Matrices in the `|`/`~` multi-value cases (PopVars matrix fields).**
  Per Key Design Decision 4, a raw matrix is currently accepted ONLY as a
  single value with no `|`/`~`; temporal (cdclimate) or per-sex variation
  must be supplied as filepaths. Revisit once the package is otherwise
  finished (per the user, 2026-06-28): allow the user to supply a *list of
  matrices* for the `|`/`~` cases too (the list-column storage already
  supports it), with the writer auto-naming each
  (`cdmats/<field>.csv|cdmats/<field>_2.csv|...`). Deferred now to avoid the
  messier naming/write logic and to keep the no-arg-defaults story simple.
- **`path=` argument on the constructors.** Currently the only way to
  build an object from an existing csv is `read_cdmetapop(filepath, type =
  ...)`. Revisit (per the user, 2026-06-28) adding a `path=` argument
  directly to `ClassVars()`/`PatchVars()`/`PopVars()`/`RunVars()` as a
  convenience that reads the file (delegating to the same
  `.read_<classname>_csv()` helper) — e.g. `ClassVars(path = "xyz.csv")`.
  Scope as its own task. Note the variable-name-as-filename idea
  (`mycv1 <- ClassVars(path=...)` -> `classvars/mycv1.csv`) is NOT feasible:
  a function on the RHS of `<-` cannot reliably see the LHS variable name in
  R (same limitation that sank `parent.frame()` name lookup). On read,
  `location` is set from the source file's basename instead; rename via an
  explicit `$location <-`.
- **Gene-frequency file UX helpers.** `genes_initialize` (PatchVars) is
  deliberately kept minimal for now (2026-06-28): a value is `"random"`,
  `"random_var"`, or a filepath. `|` is the outer (temporal) split; within
  each `|` group, `;` separates multiple filepaths, while `"random"`/
  `"random_var"` may appear only as a standalone value in a group (never
  `;`-joined with anything). No dedicated object, no `make_*` helper yet.
  Two future enhancements, deferred: (a) a `make_genefile()` helper function
  to build/write allele-frequency csvs from R rather than by hand; (b)
  potentially wrapping gene files in a dedicated `AlleleFrequency` R6 object
  (the long-flagged unbuilt class — see Key Design Decision 2), giving them
  the same object-or-path treatment `class_vars` has. Decide between/scope
  these once real usage shows what the gene-file workflow actually needs;
  don't build the R6 object reflexively just for symmetry with the other
  classes.

## Workflow Notes for This Project

Practical/environment notes discovered this session, to save the next
session from re-discovering them from scratch:

- **Extracting user-manual sections.** `pandoc` and `extract-text` are NOT
  on PATH in this Bash environment, and the plain Bash `python`/`Rscript -e`
  invocations have their own pitfalls (see below). What worked: unzip
  `cdmetapop3_usermanual.docx` (it is a zip) with anaconda's Python
  (`/c/Users/cday4/anaconda3/python.exe` — the bare `python`/`python3`
  commands are Windows Store stubs), then regex `<w:t[^>]*>(.*?)</w:t>` over
  `word/document.xml` to get the run-text list. The manual's section
  headings appear both in the TOC (low indices) and again in the body
  (indices > ~1000); slice the body run-text list between two consecutive
  body headings to pull one section's prose. Sections used: §3.1 "RunVars.csv
  file – run parameters apply to all species", §3.2 "Run parameters and
  output – PopVars.csv file" (subsections 3.2.1–3.2.8), §3.3 PatchVars, §3.4
  ClassVars. (Quirk: an en dash `–` renders as `�` after `html.unescape`;
  match on the surrounding text, not the dash.)
- **R environment.** The user's development R is R-4.5.0
  (`C:\Program Files\R\R-4.5.0\bin\Rscript.exe`); `roxygen2` is already
  installed there, and the user has given standing permission to run
  `roxygen2::roxygenise(".")` after editing any roxygen-documented R file,
  without asking each time. Per the user's global `CLAUDE.md`: never pass
  multi-line R code via `Rscript -e "..."` through Git Bash/MSYS2 (it
  segfaults or silently no-ops, regardless of quoting) -- write it to a
  `.R` file and run `Rscript path/to/file.R` instead. This session's
  pattern: write a throwaway test/doc-regeneration `.R` script (e.g.
  `D:\GitHub\test_*.R`, `D:\GitHub\run_document.R`), run it, then delete it
  -- these scratch files are fine to create/delete without asking each
  time (per `CLAUDE.md`'s temporary-files exception), but never leave one
  lying around at the end of a task.
- **Verifying a canonical example file's column count/order.** Manual
  counting of a wide csv's header row is error-prone (happened once this
  session). Instead: `awk -F',' 'NR==1{for(i=1;i<=NF;i++) print i": "$i}'
  path/to/File.csv` to print each column's 1-based index alongside its
  header text, and the same with `NR>1` to dump indexed values per data
  row when extracting per-column defaults.
- **`NAMESPACE`/exports.** All four constructors (`ClassVars`, `PatchVars`,
  `PopVars`, `RunVars`) plus their `write_cdmetapop`/`add_rows`/
  `as.data.frame` `S3method()` entries are exported, and `read_cdmetapop`/
  the generics. Always handled by re-running `roxygenise()`, never by
  hand-editing `NAMESPACE`. Gotcha: the first `roxygenise()` run after
  adding a new class emits "could not resolve link to topic <NewClass>"
  warnings for `[NewClass()]` cross-references in OTHER files (the new
  `.Rd` is written in the same pass, after the links are checked); a second
  run clears them. This is expected, not an error.
- **Canonical example file naming is inconsistent across file types** --
  don't assume a `*S1.csv` suffix pattern holds, and confirm the canonical
  filename per class. As used: `ClassVars` -> `classvars/ClassVars_AS1.csv`;
  `PatchVars` -> `patchvars/PatchVarsS1.csv`; `PopVars` -> `popvars/PopVars.csv`
  (NOT `PopVarsS1.csv`, though it exists); `RunVars` -> `RunVars.csv` (note:
  top level of `example_files/`, not in a subdirectory).

## Working Style Notes

- Proceed one task at a time; do not chain multiple implementation steps
  without checking in.
- Use tabs for indentation in R code; comment extensively (every function,
  non-trivial block, and key decision).
