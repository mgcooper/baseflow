# Changelog

This file lists notable changes to the baseflow toolbox. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); the project uses
semantic versioning.

## [Unreleased]

### Fixed

- `gpfitb`, `plplotb` and `fitphidist` print nothing when they label a
  figure. The private `drawarrow` assigned its output whether or not the
  caller asked for it, and no call site ended with a semicolon, so each
  label printed a 1x2 graphics array.
- `baseflow.internal.version` draws the version it reports. The banner
  carried the digits of 1.1.0, and it now takes them from the version
  string.
- `baseflow.internal.runtests` draws test figures off screen, so a run on
  the desktop opens no window for a test that closes its own figure. It
  puts the figure default back on both exits.
- `fitphidist` draws its figure off screen when the root asks for
  invisible figures, through the new private `figurevisibility`. A figure
  created with an explicit `'Visible'` of `'on'` ignores that default, so
  `showfit` true opened a window during a test run.
- The `fitphi` warnings carry identifiers,
  `baseflow:fitphi:incompatibleLateTimeSolution` and
  `baseflow:fitphi:lateTimeSolutionImpliesB`, so a caller can suppress or
  catch one by name. The tests that ask for a solution pair `fitphi`
  falls back from now suppress the warning they expect, as do the tests
  that run a fit to the iteration limit of `nlinfit`.

## [1.2.0] - 2026-09-17

### Added

- `plotrefline` accepts `labelcolor`, `labelfontsize`, and `labelstyle`.
  `labelcolor` defaults to the line color, `labelfontsize` to 10, and
  `labelstyle` selects `'arrow'` or `'line'` for the late-time,
  early-time, and user-fit labels. `'line'` writes the label along the
  line, as the upper-envelope label does.
- `plotdqdt` accepts `labelcolor` and `labelfontsize` for its own labels,
  and a `reflines` option that selects the reference lines it draws, with
  the same values `pointcloudplot` takes.
- `plotdqdt` and `pointcloudplot` accept `labelstyle`, which `plotrefline`
  takes: `'arrow'`, the default, points an arrow at each labeled
  reference line, and `'line'` writes the label along the line. The
  `'line'` style draws no arrow, so it labels the lines on Octave.
- `pointcloudplot` accepts `labelcolor` and `labelfontsize` and passes
  both to `plotrefline`.
- `plotdqdt` and `pointcloudplot` accept `fontsize` for the axes, which
  sets the tick labels and the axis labels, and `legendfontsize` for the
  legend. Both default to 12.
- `pointcloudplot` and `plotdqdt` accept an `axislimits` option: `'snap'`
  (the default) rounds a limit out to its decade when the decade is
  within 0.25 decades, `'decades'` always rounds out, and `'none'` keeps
  the data limits.
- The private helpers `snaploglims`, `labelanchor`, `islabelcolor`,
  `islinehandle`, `labelrefline`, `breflinetext`, `sizefigure`,
  `relayoutloglogtext`, `drawarrow`, and `axespixelbox`.
- `cloudphi` accepts a `plotfit` option (default true). With `plotfit`
  false it computes phi and draws no figure.
- `fitphidist` returns the phi standard error as `h.se` for the 'cdf'
  plot type, and `phifitensemble` returns it as `PhiFit.se`. `h.pm` and
  `PhiFit.pm` keep the 95% half-width.
- `tools/m2html` holds a copy of M2HTML (rochefort-lab/m2html at
  3821fb8, GPL-2.0-or-later) for the docs build.
  `tools/m2html/VENDORED.md` records its source, license, local changes,
  and refresh steps. `CONTRIBUTING.md` explains how to build the docs.

### Changed

- `aQbString`, `QtString`, and `QtauString` each return one label.
  `aQbString` returns the -dQ/dt = aQ^b label and has no `Q0` input.
  Call `QtString` for the Q(t) label.
- `checkevent` has no `ax` option. It always opens its own figure.
- `dndtuncertainty` combines standard errors and multiplies the result
  by the coverage factor `norminv(1-alpha/2)`, so it accepts any `alpha`
  in (0, 1). Each input term is one standard error: the bootstrap
  standard error for phi, the `GlobalFit` bootstrap bounds, and the
  standard error of the regression. On Octave it returns that regression
  term after scaling, as it did in 1.1.0. The 1.1.0 terms mixed two levels.

  - The phi and regression terms were 95% half-widths.
  - The tau and b terms were standard errors.
  - `alpha` 0.32 halved every term except the regression term, which
    stayed at 95%.

  With `bootfit` false on the example data, `sig_dndt` at the default
  `alpha` changes by 0.02%. Its help documents `alpha` and `testflag`.
- `plfitb` warns with `baseflow:plfitb:tauPoleReplicates` when a
  bootstrap replicate has alpha at or below 2. tau has its pole at
  alpha 2 and is negative below it, so such a replicate makes `tau_sig`,
  `tau_L`, and `tau_H` meaningless.
- `getdqdt` with `plotfits` true draws the event figure for
  `pickmethod` 'none', its default, and for a `fitmethod` other than
  'none'.
- `DESCRIPTION` gives the contact address matt@sierracrestanalytics.com.
- `.gitattributes` gives `.m` files the rule `text eol=lf`. This release
  converts the 14 `.m` files that used CRLF. A checkout writes LF for
  every `.m` file.
- `DESCRIPTION` requires the Octave `statistics` package 1.9.1 or later.
  `trendplot` and `dndtuncertainty` use its `fitlm` model object.
- `baseflow.internal.makedocs('functions')` builds the function pages
  with the M2HTML copy in `tools/m2html` and needs no separate M2HTML
  install. `makedocs` restores the MATLAB path when it returns.
- The demo scripts and live scripts do not call `close all`, so a demo
  keeps the figures a user has open. `makedocs('demos')` deletes the
  figures each demo export opens.
- `hyetograph` opens a new figure unless an axes handle is passed, so it
  does not resize or redraw a figure the user has open. With an axes
  handle, it draws in that axes.
- The Getting Started guide, the citing page, and the function
  documentation template give the contact address
  matt@sierracrestanalytics.com.

### Removed

- The vendored `+deps/arrow`. Every figure that drew an arrow now calls
  the private `drawarrow`, which draws the same arrow, runs on Octave,
  and stays correct when the plot-box aspect ratio is manual. A caller
  of `baseflow.deps.arrow` has no replacement in the toolbox: it was a
  copy of the File Exchange ARROW by Erik A. Johnson, which is still
  available there.
- The private helpers `fitlm_octmat` and `predictlm`. `dndtuncertainty`
  calls `fitlm` and `coefCI`, which MATLAB and the Octave `statistics`
  package both provide.

### Fixed

- `plotdqdt` labels its late-time line `b = 1`, the value of the `blate`
  reference slope. It labeled that line as an estimate, with b-hat beside
  the value and two decimals, which names the fitted line of the point
  cloud. The new private helper `breflinetext` writes the label of both
  functions, so a reference slope reads the same in each.
- `pointcloudplot` writes its legend in latex on MATLAB, so the legend of
  the point cloud and the legend of the fit plot set Q and t alike.
  Octave has no latex text interpreter, so it keeps the tex form.
- `gpfitb`, `plplotb` and `fitphidist` draw their arrows with
  `drawarrow`. The vendored arrow drew a point at or below zero on a log
  axis at that value reflected through the origin, because it took the
  real part of its complex logarithm. `gpfitb` reaches that case with a
  negative tauExp, which the tail of a power law below alpha 2 gives it,
  so the label pointed at a place the data never reaches. `drawarrow`
  draws no arrow there and warns with
  `baseflow:drawarrow:nonpositiveLogCoordinate`.
- `plotrefline` and `plotdqdt` draw the arrow of a reference-line label
  in the new private helper `drawarrow`, which builds the head from the
  drawn plot box and needs no MATLAB-only axes property. The vendored
  `+deps/arrow` reads the undocumented `WarpToFill`, and an axes with a
  manual plot-box aspect ratio, which `axis square` sets in `plotdqdt`,
  turns that property off and sends the vendored function into a branch
  its own comments call untested. The shaft then spanned the whole axis.
  The arrow keeps the head size and angle it had, and it draws on Octave,
  so the `'arrow'` label style works in both languages. `axespixelbox`
  reads the drawn box for `drawarrow` and for `loglogangle`.
- `plotdqdt` labels its reference lines with the arrow `pointcloudplot`
  draws, in the new private helper `labelrefline`. It drew its own arrow,
  which scaled its length by the factor that raises the label anchor, so
  an arrow could span the whole x range, and its head could stop left of
  the axes instead of on the line. The arrow of both figures now spans a
  twenty-fifth of the drawn x decades and points at the line.
- `pointcloudplot` and `plotdqdt` reset the angle of a label written
  along a line after they set the final axis limits, in the new private
  helper `relayoutloglogtext`. The angle of a line on a log-log plot
  follows the limits, and a MATLAB listener keeps it current, but Octave
  has no such event, so an envelope that raised the y limit left the
  Octave label off its line.
- `plotrefline` writes its labels in tex on Octave, which has no latex
  text interpreter. It asked for latex, so a point cloud drawn on Octave
  with `reflabels` true showed the math delimiters.
- `functionSignatures.json` lists the `labelstyle`, `labelcolor`,
  `labelfontsize`, `fontsize`, and `legendfontsize` options, so name-value
  completion offers them. Its two `+baseflow/private/subtight` entries are
  one entry that names every option the function parses.
- `plotrefline` starts a label a twentieth of the x decades inside the
  left limit, in `labelanchor`. A label of a line that reaches the anchor
  height near the left limit sat against the y axis.
- `pointcloudplot` and `plotdqdt` open a figure where the window manager
  puts it. They pinned the figure to [0 0] and [1 1], the bottom-left
  corner of the screen, where the dock covers the axis labels. Both take
  their size, 640 by 600 points, from the new private helper
  `sizefigure`, so the axis labels fit.
- `pointcloudplot` and `plotdqdt` set the axis ticks after the final axis
  limits, so every decade inside the limits carries a tick.
- `pointcloudplot` passes `precision` and `timestep` to its envelope
  lines. The envelope intercept ignored both, so it always described a
  one-day timestep and a precision of one.
- `pointcloudplot` draws in the axes a caller supplies: it keeps the size
  of the parent figure, and `setlogticks` handles an axis whose data
  reach zero.
- `plotdqdt` draws in its own axes. It drew through the current axes, so
  a caller with another axes current split the figure.
- `plotdqdt` and `pointcloudplot` list rain in their legends. The
  `plotdqdt` guard tested for an axes, and both guards tested `isobject`,
  which is false for the numeric handle Octave returns from `plot`, so
  the rain entry never appeared on Octave. The new private helper
  `islinehandle` takes the handle of either language. `pointcloudplot`
  gives rain one entry for its several circles, and keeps the entry of
  each reference line it names, for a `reflines` row or column.
- `plotdqdt` runs on Octave, so `getdqdt` with `plotfits` true draws its
  event figure there. Its input parser asked `validateattributes` for the
  `scalartext` attribute, which Octave does not define, and it read the
  marker size of the plotted line with dot indexing, which a numeric
  handle does not take.
- `plotrefline` and `plotdqdt` give their labels an explicit color and
  font size, so a figure theme does not recolor them and a large axes
  font does not enlarge them. The label font size falls from 13 and 11
  points to 10.
- `plotrefline` raises a label anchor that falls left of the axes, in the
  shared private helper `labelanchor`. A late-time label drew its arrow
  across the left spine and its text over the leftmost markers.
- `plotrefline` places the upper-envelope label on the line. The label
  sat at `2*x`, which ignores the intercept `a = 2/timestep`, so it
  drifted from the line for any timestep other than one day.
- `private/rotatedLogLogText` draws its label at the angle of the line.
  It had three defects. It read the axes offsets where it needed the
  axes size. It applied the slope outside the arctangent. It worked in
  figure-normalized units. No single value of its `rtxt` factor served
  every layout. The new private helper `loglogangle` computes the angle
  from the axes size in pixels and the axis limits. In a live MATLAB
  figure, a listener keeps the angle correct after a resize or a limit
  change. Octave installs no
  listener, and a figure saved with `savefig` keeps its saved angle.
  `rotatedLogLogText` takes the axes and the slope in place of `rtxt`.
- `getdqdt` on MATLAB keeps the random stream of its caller. `plotdqdt`
  fits the point cloud to draw its line. A 'qtl' fit bootstraps, so
  `getdqdt` saves and restores the stream around the plot call.
- `+deps/plvar` keeps the random seed a caller sets. It called
  `rng('shuffle')` on its first call in a session, so a seeded script
  could not reproduce its bootstrap uncertainties.
- `dndtuncertainty` propagates the uncertainty of b to N* = 1/(4-2b)
  with the derivative 2/(4-2b)^2, in the new private helper
  `nstaruncertainty`. The plain factor 2 holds only for b = 3/2. The
  1.1.0 term was (4-2b)^2 times too large, which is 1.7 at the Kuparuk
  global b of 1.3541. The term is zero when `globalfit` runs with
  `bootfit` false.
- `dndtuncertainty` holds the dq/dt trend uncorrelated with the
  event-scale variables. Its column is constant, and `corr` returns nan
  for a constant column.
- `fitevents` passes `plotfits` to `getdqdt`, which draws one figure per
  event for a `fitmethod` other than 'none'. `fitevents` parsed the
  option and ignored it.
- `plotrefline` draws its reference line and its label in the axes a
  caller supplies. It gives the caller back its current figure and
  current axes. On MATLAB the arrow of the late-time, early-time, and
  user-fit labels goes to the same axes. Octave draws no arrow and no
  label text for those three labels.
- `checkevent` runs without an input parser error. The parser gives the
  `Q` and `q` inputs distinct names. The Octave parser compares names
  without case, and the MATLAB parser does so by default.
- `checkevent` draws an event that has no valid flow.
- `globalfit` with `plotfits` false opens no figure.
- `fitphidist` with `showfit` false leaves no hidden figure open, so
  `phifitensemble`, `dndtuncertainty`, and `globalfit` do not accumulate
  figures. Its `'probplot'` plot type runs without an input error and
  follows `showfit`. Its help documents `'probplot'` and `showfit`.
- `plotaquifertrend` plots the GRACE period without a legend error and
  returns the third trend handle as `trendplot3`. Its help documents the
  GRACE input.
- `trendplot` and `dndtuncertainty` run on Octave, so the Kuparuk demo
  runs on Octave.
- The `fitevents` help example runs as written.
- `private/siUnitsToTex` wraps each negative exponent once, so labels
  such as 'm3 d-1' in `hyetograph` show the correct superscript.
- `private/fillnans` fills only interior nan runs of length `fmax` or
  less and accepts a row vector.
- `private/smoothnoise` keeps each year together on the 'annual' path
  and accepts a call with no method input.
- `private/setrainnan` accepts vector input.
- `private/preparecalendar` assigns `timestep` for every calendar.
- `private/fitcts` returns nan for a single sample.
- `private/runlength` and `private/anomaly` accept row vectors.
- `private/getplotdata` skips axes children that have no `XData`.
- `private/formatPlotMarkers` calls `round` with one input, which Octave
  requires.
- `fitab` and `loadflow` call the shared private helpers in place of
  local copies.
- The GitHub Actions workflow uses action versions that run on Node.js 24.
- The GitHub Actions `Tests` workflow runs the test suite. With the
  project file `bfra.prj` at the repository root, `matlab-actions/run-tests`
  selected zero tests, and the runs in 1.1.0 passed without running a
  test. The workflow builds the suite from `tests/` and fails when the
  suite is empty.
- The `cloudphi` and `fitphi` help describe `dispfit` correctly: it
  prints each phi value.
- The Getting Started function list shows dQ/dt as italic text, not as
  oversized equation images, and its author email is one mailto link.
- `makedocs('demos')` does not overwrite the Octave m-files in
  `demos/mfiles`, and the demo pages show the output of the current code.
- The m2html dependency graph matches the current functions.

## [1.1.0] - 2026-09-14

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
- `nonnansegments` accepts a vector, a matrix, or a cell array whose
  elements are vectors or matrices, and applies the same rules to each
  element. For a matrix, the `option` input selects one result per
  column (`'each'`, the default), the rows where every column is non-nan
  (`'all'`), or the rows where any column is non-nan (`'any'`).
- `tests/test_eqstrings.m` checks the value and symbolic labels of
  `aQbString`, `QtString`, and `QtauString`.
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
    `plfitb` known-external classification, the `loadflow` parked
    reader, and the `Setup('dependencies')` report;
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
- `eventfinder` detects hydrograph troughs again. In 1.0.0 its
  Octave-compatible `islocalmin` and `islocalmax` wrappers called
  `peakfinder` with a threshold of 0, which dropped every minimum of
  positive flow and every negative local maximum of dQ/dt. The wrappers
  apply no threshold, which restores the v0.1.0 behavior of the MATLAB
  `islocalmax` and `islocalmin` functions, and the vendored `peakfinder`
  keeps a single interior peak when endpoints are excluded. Event counts
  change: the example data gives 287 events with the `setopts` defaults
  (327 in 1.0.0). The Kuparuk annual workflow gives 230 events and a
  global b of 1.3541, which matches the published 1.3540 (1.3519 in
  1.0.0).
- `QtString` and `QtauString` value labels showed an italic "e" with the
  latex interpreter and printed the wrong mantissa for a >= 10 (for
  example 1250000e^{3} for a = 1250). They build the label the way
  `aQbString` does.
- Getting Started lists the `baseflow.setopts` defaults, which direct
  name-value calls also use. It no longer
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

- `getevents`, `eventfinder`, and `wrapevents` take their name-value
  defaults from `baseflow.setopts('getevents')`, the values that produced
  the published results and that the demos use. A direct call without an
  options struct uses `fmax` = 1, `rmin` = 1, `rmnochange` = true, and
  `rmrain` = true. In 1.0.0 these parsers used `fmax` = 2, `rmin` = 0,
  and `rmrain` = false (and `rmnochange` = false in `getevents` and
  `eventfinder`), so direct-call results change.
- `globalfit` defaults `aquiferslope` to 0, the `setopts` value. `globalfit`
  does not use this input, so results do not change.
- `getevents` and `eventfinder` require `rmax` > 1. The `rmnochange`
  filter counts each nan as a run of length 1, so `rmax` <= 1 rejected
  every day.
- `aQbString`, `QtString`, and `QtauString` share one help layout, input
  parser, and label format. Their symbolic labels come from
  `baseflow.getstring`.
- The `runlength` and `isminlength` help state that each nan is a run of
  length 1 and that callers use nan to break runs.
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
- The dependency report lists `r_plfit` in `known_external` whenever it
  analyzes `plfitb`, and does not count `r_plfit` as missing. It does not
  count the matfunclib `getlist` chain as missing either; only the parked
  `readflow` function in `loadflow` reaches it.
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
  Curve Fitting toolboxes. They also list the six Octave packages the
  toolbox loads.
- README states that Octave support covers the core analysis functions
  and the demos. It states that `tests/octave_smoke.m` verifies the core
  workflow on GNU Octave 11.3.0, and that the toolbox ran on Octave 8.2.0
  in 2023. It lists the install commands for the six Octave packages and
  their `io` and `datatypes` dependencies.
- README lists the four public functions that need data files or
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

### Removed

- `loadcalm`, `loadghcnd`, `loadgrace`, `mapbasins`, and `mapgages`.
  They need data files and functions that the toolbox does not ship, and
  no demo, test, or core function uses them. The analysis project
  (mgcooper/arctic_baseflow) keeps working copies.
- The `pending_decision` field of the `baseflow.internal.dependencies`
  report and of `Setup('dependencies')`.
- The Mapping Toolbox from the `DESCRIPTION` `MatlabProducts` line, the
  README requirements, Getting Started, and the `Setup` preferences. No
  toolbox function calls a Mapping Toolbox function.

## [1.0.0] - 2023-10-02

The JOSS release: Cooper and Zhou (2023), Journal of Open Source
Software, 8(90), 5492. https://doi.org/10.21105/joss.05492

[1.2.0]: https://github.com/mgcooper/baseflow/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/mgcooper/baseflow/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/mgcooper/baseflow/releases/tag/v1.0.0
