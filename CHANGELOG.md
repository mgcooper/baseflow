# Changelog

This file lists notable changes to the baseflow toolbox. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); the project uses
semantic versioning.

## [1.1.0] - 2026-09-13

### Added

- `fitab` accepts a `fitopts` struct. Each field overrides the
  same-named option: `weights`, `order`, `mask`, `quantile`,
  `refqtls`, `Nboot`, `alpha`, or `plotfit`.
- `fitab` errors with `baseflow:fitab:invalidFitopt` for a `fitopts`
  field of the wrong type and with `baseflow:fitab:unknownFitopt` for an
  unknown field.
- `fitevents` and `setopts('fitevents')` accept `fitopts` and pass it
  to every `fitab` call. `weights` and `mask` must be scalars there,
  because each event fit has its own points. Any other size raises
  `baseflow:fitevents:nonscalarFitopt`. `fitab` expands a scalar
  `weights` or `mask` to every point.
- `fitevents` and `setopts('fitevents')` accept a `ctsmethod` option.
  It selects the `CTS` stencil: `B1` (the default), `B2`, `F1`, `F2`,
  `C2`, or `C4`. `fitevents` passes it to `getdqdt`.
- `fitevents` forwards a `fitorder` option to `fitab` for linear
  reservoir fits.
- `struct2varargin` converts a name-value struct to a cell array.
  `trendplot` and `formatPlotMarkers` call it in place of
  `namedargs2cell`.
- `nonnansegments` accepts a matrix or a cell array of vectors. For a
  matrix, the `option` input selects one result per column (`'each'`,
  the default), the rows where every column is non-nan (`'all'`), or the
  rows where any column is non-nan (`'any'`).
- `fitab` fits the `'ols'` method on GNU Octave. A weighted
  least-squares solve with t-based confidence intervals replaces the
  Curve Fitting Toolbox `fit` and `confint` calls, and on MATLAB the
  results match them to rounding.
- `toolbox/docs/baseflow_powerlaw_notation.m` maps the exponent
  notation of `plfit`, `r_plfit`, the MATLAB generalized Pareto
  distribution, and the toolbox `b` and `tau` conventions. It runs a
  worked comparison on synthetic data.
- Vendored helpers `yorkfit`, `nanmean`, `nanmedian`, `tocolumn`, and
  `renametimetabletimevar` make the core workflow chain self-contained.
- Example sections in the help of 16 core-workflow functions, and help
  text in many private helper functions.
- New test suites:
  - `test_fitcts`: every stencil against the analytic derivative of an
    exponential recession, the midpoint times, both errors, and the
    `getdqdt` path;
  - `test_fitopts`: the overrides, both errors, precedence, scalar
    expansion, and the `fitevents` path;
  - `test_peakfinder`: empty input, directly and through `islocalmax`;
  - `test_plfitb_hanel`: the arguments the `'hanel'` method passes to
    `r_plfit`;
  - `test_corechain`: `eventtau`, `globalfit`, `fitphi`, `gpfitb`,
    `fitphidist`, and `aQbString`;
  - `test_dependencies`: core-chain self-containment, declared
    products, the option outputs, the `'resolve'` file copies, the
    `plfitb` known-external classification, and the pending entry points
    that `Setup('dependencies')` reports;
  - `test_version`: every version source agrees.
- The demo scripts run under the suite (`tests/test_demos.m`). The
  theory demos skip when the Symbolic Math Toolbox is not installed.
- `tests/octave_smoke.m`, a plain script with bare asserts, runs the
  core workflow in GNU Octave and MATLAB: load the example data, then
  `getevents`, `fitevents`, and `fitab` with `'nls'` and `'ols'`.
- Plain unit tests of helpers that the toolbox vendors from matfunclib
  (`nanmean`, `nanmedian`, `yorkfit`, `tocolumn`, `timetablereduce`,
  `nonnansegments`, `withcd`, `listfiles`, and `mpackagefolders`) live
  in the matfunclib library test folders, next to the source functions.
  The matfunclib sources carry the help and fixes from the toolbox
  copies.
- `tests/closenewfigs.m` closes the figures a test opens, so a full
  suite run leaves zero open figures and keeps the figures a user had
  open.
- A MATLAB project definition file.
- `TODO.md` audits all work-in-progress signals: sandbox TODO lists,
  in-code markers, and disabled code blocks. It records their
  provenance, classification, and recommendations.
- This changelog and a minimal `CONTRIBUTING.md`.

### Fixed

- The project `.octaverc` starts the toolbox with
  `addpath(fullfile(pwd, 'toolbox'))` and `Setup('addpath')`. It sourced
  `Setup.m`, which is a function file in `toolbox/`, so Octave started in
  the repository root did not add the toolbox to the path.
- Getting Started lists the `baseflow.setopts` defaults and names the
  defaults that differ for direct name-value calls (`getevents` fmax,
  rmin, rmnochange, rmrain; `globalfit` aquiferslope). It no longer
  labels `plotdqdt` deprecated. The `eventfinder` help and the
  `setopts` fitevents option list match their parsers.
- Continuous integration did not trigger: YAML parsed the
  space-separated branch list as one branch named "main dev". The
  workflow runs on every push and pull request to `main` and `dev`.
- The CI workflow pins its actions and uploads the JUnit results and
  Cobertura coverage as artifacts.
- Version metadata disagreed: at the 1.0.0 tag,
  `baseflow.internal.version` and `toolbox/info.xml` reported 0.1.0,
  `DESCRIPTION` reported 0.1.1, and `CITATION.cff` reported 1.0.0.
- `+deps/peakfinder` returns empty outputs for empty input. The
  empty-input branch assigned `varargout`, which left the named outputs
  `peakInds` and `peakMags` undefined.
- `fitcts` computes the `C4` stencil as the fourth-order centered
  difference. The draft stencil subtracted and added `Q(i+2)`, which
  cancelled the term, and never used `Q(i-2)`.
- `fitab` applies `fitopts`. The parser read `parser.Unmatched`, which
  is always empty, and `fitevents` discarded the option.
- `plfitb` method `'hanel'` passes `'cdat'` to `r_plfit`, so `r_plfit`
  fits the continuous tau sample and does not bin it on an integer grid.
- `plfitb` method `'hanel'` passes the exponent search bounds as
  `'exp_min'` and `'exp_max'`. `r_plfit` ignores the `'alpha_min'` and
  `'alpha_max'` names and used its default range of 0 to 5.
- `nonnansegments` returns the correct segments for data with leading or
  trailing nans. It errored or returned wrong indices for them. It keeps
  the `nmin` filter that `eventfinder` uses to remove short segments.
  For an all-nan vector, it returns empty (0-by-1) start, end, and
  length outputs.
- `fitphi` errors with `baseflow:fitphi:unsupportedSolution` for a
  solution pair with no derived formula. For example, when `b2` is
  incompatible with the Rupp and Selker (2005) solution, the non-flat
  branch with `soln1` `'RS05'` falls back to the Boussinesq (1903)
  late-time solution. The resulting pair `RS05_BS03` has no formula.
  `fitphi` returned unassigned outputs for such a pair.
- `ccdf` reads its `makeplot` option from the parser results. The option
  caused an error on every call.
- `Setup('install')` runs the dependency check, which an early return
  skipped. In `matlab -batch` runs, it does not prompt before a
  re-install.
- `fitab` defaults the `qtl` method's polynomial order to 1.
- `fitvts` computes `dt` as a number, not as a `duration` value.
- `struct2varargin` assigns default values for its outputs.
- Field names in `numfits` and `numevents` match the current structures.
- `citing_baseflow` carries the JOSS citation (doi 10.21105/joss.05492).
  It states the BSD 3-Clause license apart from the citation request.
- `toolbox/functionSignatures.json` matches the parsers. The
  `derivmethod` choices for `fitevents`, `getdqdt`, and `setopts` are
  `VTS`, `ETS`, and `CTS`. The `fitevents` and `setopts` entries list
  `ctsmethod` and `fitopts`. The `globalfit` and `setopts` entries name
  `drainagedensity`.
- The BSD 3-Clause text in `+internal/private/withcd.m` had corrupted
  characters. It matches the license template.
- The suite builder skipped `tests/test_withcd.m` because the file
  declared no test output. That test now lives in matfunclib.
- `test_conversions` checked the `b` to `k` conversion against the
  reciprocal of the gpfit relation k = (1-b)/(b-2) at b = 1.5, where both
  equal 1. It checks b = 1.4 and the inverse `k` to `b` conversion.

### Changed

- `getdqdt` method `'CTS'` (`private/fitcts.m`) is complete. It computes
  dQ/dt with six finite-difference stencils. The `ctsmethod` option
  selects `B1` (backward, first order, the default), `B2`, `F1`, `F2`,
  `C2`, or `C4`, and `fitcts` validates the name.
- `fitcts` returns the rain on the input time vector. Its `tq` output
  is the input time vector, and a seventh output, `tqmid`, holds the
  stencil midpoint times.
- `fitcts` errors with `baseflow:fitcts:nonuniformTime` when the time
  vector is not uniform, because one constant time step applies to
  every stencil.
- `plotdqdt` defaults `labelplot` to false. Pass `'labelplot', true` to
  draw the refline arrow annotations (the 1.0.0 default).
- `baseflow.internal.dependencies` analyzes the code live with
  `matlab.codetools.requiredFilesAndProducts`. It needs no saved
  `dependencies.mat` file.
- With no function name, `baseflow.internal.dependencies` analyzes the
  public API: the files that `listfiles` finds in `+baseflow` and
  `+baseflow/+util`.
- The `baseflow.internal.dependencies` options report, check, and
  resolve dependencies. The `'check'` option compares the detected
  products with the `DESCRIPTION` `MatlabProducts` line and returns
  `undeclared_products`. The comparison ignores the Signal Processing
  Toolbox and Symbolic Math Toolbox entries that
  `requiredFilesAndProducts` reports for code that does not call them.
- The `'missing'` and `'check'` reports list the entry points
  `loadcalm`, `loadghcnd`, `loadgrace`, `mapbasins`, and `mapgages` in
  `pending_decision`. These functions await a decision on their
  external references.
- The dependency report lists `r_plfit` in `known_external` whenever it
  analyzes `plfitb`, and does not count `r_plfit` as missing.
- `Setup('dependencies')` and `Setup('install')` run the live
  dependency check. The `dependencies_checked` preference is true only
  when no required file is missing. A failed check points to the
  baseflow issues page. On Octave, the check prints a message and skips
  the analysis.
- The `DESCRIPTION` file lists the dependencies. `Depends` lists the
  Octave packages, and a `MatlabProducts` line lists the required
  MATLAB toolboxes.
- The upstream project renamed the Octave package
  `statistics-bootstrap` to `statistics-resampling`. `Setup` and
  `.octaverc` load the installed name, and `DESCRIPTION` lists
  `statistics-resampling` and `financial`.
- README requirements list the Statistics and Machine Learning and
  Curve Fitting toolboxes, plus the Mapping Toolbox for `mapbasins` and
  `mapgages`. They also list the six Octave packages the toolbox loads.
- README states that Octave support covers the core analysis functions
  and the demos. It states that `tests/octave_smoke.m` verifies the core
  workflow on GNU Octave 11.3.0, and that the toolbox ran on Octave 8.2.0
  in 2023. It lists the install commands for the six Octave packages and
  their `io` and `datatypes` dependencies.
- README lists the nine public functions that need data files or
  functions that the toolbox does not ship.
- README documents the external `r_plfit` requirement of the `plfitb`
  method `'hanel'`. `r_plfit` has no license grant, so the toolbox does
  not vendor it.
- `CONTRIBUTING.md` states the input-parsing rule. Core analysis
  functions and demos use `inputParser`. The MATLAB-only `+internal`
  maintenance tooling and its private helpers may use `arguments`
  blocks.
- Core analysis functions and demos parse inputs with `inputParser`. On
  Octave 11.3.0, `baseflow_demo_1`, `baseflow_demo_2`, and
  `baseflow_demo_3` run. `baseflow_demo_kuparuk` errors in `trendplot`
  at its `fitlm` call, and the theory demos need the `symbolic` package.
- `+deps/arrow` allocates numeric handles when `gobjects` is absent.
  Note: `arrow` errors on Octave at the MATLAB-only `WarpToFill`
  axes property, before it reaches that allocation. `TODO.md` records
  the incompatibility.
- Tests follow the no-magic-variables rule in `CONTRIBUTING.md`. A test
  names a value that a reader cannot identify, such as a non-obvious
  expected value or a tolerance. A comment says what each case
  checks. Option sweeps use parameterized test classes.
- The `loadcalm` help documents the Kuparuk nine-site selection for the
  default `'current'` version. The selection keeps the output
  reproducible against the published results.
- Every version source reads 1.1.0: `baseflow.internal.version`,
  `DESCRIPTION`, `CITATION.cff`, `.zenodo.json`, and `toolbox/info.xml`.
- `CITATION.cff` cites the Zenodo concept DOI, which covers all versions.
- `CITATION.cff` lists both authors, Matthew G Cooper and Tian Zhou.
- The two-entry `toolbox/+baseflow/private/functionSignatures.json`
  (private `fitets` and `fitvts`) is deleted.
  `toolbox/functionSignatures.json` covers the public functions only.
- The contents page source (`toolbox/docs/baseflow_contents.m`) lists
  the public API, the `+util` functions, and
  `baseflow.internal.version`, and links the Examples page. It lists the
  private helpers under a separate heading.
- The Getting Started page source
  (`toolbox/docs/baseflow_gettingStarted.m`) spells `aQbString`
  correctly, names `baseflow.internal.completions`, lists
  `privatefunction` once, and lists the `+util` folder.
- Function help names the options that the parsers accept: `bootreps`
  in `plfitb`, `ax` in `plotdqdt`, and `earlyqtls` and `lateqtls` in
  `cloudphi`. The "See also" lines name `fitphidist`, `aquifertrend`,
  `loadbasins`, `fitevents`, and `getdqdt` in place of names that match
  no function, and they omit `eventsplitter`.
- The `getdqdt` help lists the `VTS`, `ETS`, and `CTS` methods and the
  options that its parser accepts: `ctsmethod`, `etsparam`, `vtsparam`,
  `fitmethod`, `pickmethod`, `plotfits`, and `eventID`.
- The `Contents.m` manifests and the m2html function pages are
  regenerated for 1.1.0.

## [1.0.0] - 2023-10-02

The JOSS release: Cooper and Zhou (2023), Journal of Open Source
Software, 8(90), 5492. https://doi.org/10.21105/joss.05492

[1.1.0]: https://github.com/mgcooper/baseflow/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/mgcooper/baseflow/releases/tag/v1.0.0
