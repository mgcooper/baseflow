# TODO

Consolidated WIP audit for the baseflow toolbox, per the DesignSpec
`.agents/plans/design-specs/2026-08-30-repo-improvement-v1.1.0.md`. Bead
bfra-3kh.19 (W1) owns this file: it consolidates every inventory source
(sandbox TODO lists, in-code markers, disabled code) and merges the stub
sections below without regenerating them. Each row records provenance,
a classification (done / todo / deferred / excluded), and a
recommendation.

Consolidation completed 2026-08-30 (bead bfra-3kh.19). The three
inventory sections at the bottom hold every mined source: the sandbox
TODO lists and notes files (169 rows), the in-code markers (23 rows),
and the disabled code blocks (91 rows). Of the 283 rows, 281 are
classified (66 done, 41 todo, 128 deferred, 46 excluded) and the 2
fitsts/fitcts rows are owned by bead bfra-3kh.23 instead of a class;
24 rows carry an unreconstructable-context flag. Nothing was deleted
in this phase. Every delete recommendation waits for the W3 user
review (bead bfra-3kh.21). After consolidation, bead bfra-3kh.24 moved
the four fitab.m fitopts rows from deferred to done (70 done, 124
deferred). The R3 sweep (2026-09-13) moved the two resolved code-marker
rows, fitcts.m:71 (bead bfra-3kh.23) and loadcalm.m:254 (bead
bfra-3kh.27), from todo to done. The current totals are 72 done and 39
todo.

Format (bead bfra-3kh.28): within each source section, items group by
category — Done, Todo, Deferred, Excluded, Other — and GitHub checkboxes
replace the status words: `[x]` done, `[ ]` todo and deferred, plain
bullets for excluded and other rows. Line-number references stay on
every item.

## Test infrastructure (bfra-3kh.8 stub)

### Done

- [x] `tests/test_withcd.m` repair (the test moved to matfunclib
  `libsys/test/testWithcd.m` on 2026-09-13). Provenance: the file declared
  `function test_withcd` with no output, so `functiontests` never built a
  suite and `TestSuite.fromFolder` skipped the file silently; it called
  `withcd`, which is unreachable from `tests/` because private functions
  are visible only to their parent folder; it held parked assertions that
  shelled out with `!touch test.txt` against the repo root. Intent:
  verify withcd cds to the target, restores on cleanup, and that files
  created in context land in the target. Resolution: rewritten as a valid
  function-based suite that tests a setup-time copy of withcd.m on a
  temporary path folder; the parked assertions are rehabilitated portably
  against a temporary target. No user decision needed.
- [x] corrupted license text in
  `toolbox/+baseflow/+internal/private/withcd.m`. Provenance: the BSD-3
  block read "Bmsg THE COPmsgRIGHT" and "EcmdPRESS": a past find-replace
  mangled Y into "msg" and X into "cmd". Resolution: bead bfra-3kh.29
  restored the disclaimer byte-identical from the matfunclib template
  `libsys/withcd.m`; a toolbox-wide scan found no other corrupted file.

### Deferred

- [ ] the demo scripts' `close all` headers. Provenance:
  `toolbox/demos/mfiles/*.m` open with `clearvars`, `close all`, `clc`;
  with the demos running under the suite (tests/test_demos.m), the
  `close all` would close figures a user had open before an interactive
  suite run. tests/test_demos.m hides pre-existing figure handles during
  the demo runs, so the suite is safe; the demo files themselves still
  close visible figures when a user runs one directly. Recommendation:
  strip or guard the `close all` line the next time the mfiles are
  regenerated from their .mlx sources.
  - correction (2026-09-13, R3 sweep records#20): each of the six
    `toolbox/demos/*.mlx` sources holds `close all`, so a regeneration
    writes the line back into the mfiles. Recommendation: remove or
    guard `close all` in the six `.mlx` sources, then regenerate
    `toolbox/demos/mfiles/`. An edit to the mfiles alone does not survive
    a regeneration. The four demo mfiles hold the line in the header
    (`baseflow_demo_1.m:25`, `baseflow_demo_2.m:19`,
    `baseflow_demo_3.m:19`, `baseflow_demo_kuparuk.m:21`). The two theory
    mfiles hold it at `baseflow_linear_theory.m:80` and
    `baseflow_nonlinear_theory.m:86`. This correction supersedes "the next
    time the mfiles are regenerated from their .mlx sources".

## Dependency tooling and self-containment (bfra-3kh.6 stub)

Resolved 2026-09-14 (bead bfra-3kh.25, user decision): `loadcalm`,
`loadghcnd`, `loadgrace`, `mapbasins`, and `mapgages` left the toolbox;
the analysis project (mgcooper/arctic_baseflow) keeps synced copies
(commit ae8edec there). The `pendingentries` list and the
`pending_decision` report field are gone. The dependency check lists
the matfunclib `getlist` chain that only `loadflow`'s parked `readflow`
reaches as known external. The rows below record the earlier state.

### Done

- [x] dependency tooling repaired. `baseflow.internal.dependencies`
  analyzes live with `matlab.codetools.requiredFilesAndProducts` (no
  saved `dependencies.mat`), knows the current `private/` vendoring
  layout, treats a same-named vendored copy as satisfying a
  path-shadowed reference, and compares detected products against the
  DESCRIPTION `MatlabProducts` line. The `Setup.m` `checkdependencies`
  early return is gone; the real check runs on install and on
  `Setup('dependencies')`, and skips cleanly on Octave.
- [x] five core-chain dependencies vendored into
  `toolbox/+baseflow/private/`: `yorkfit` (fitab), `nanmean` and
  `nanmedian` (eventtau), `tocolumn` (smoothnoise, loadgrace), and
  `renametimetabletimevar` (timetablereduce). The core workflow chain
  (getevents, fitevents, fitab, eventfinder, eventtau, globalfit,
  fitphi) is self-contained; tests/test_dependencies.m asserts it.
- [x] `r_plfit` README requirement note (bead bfra-3kh.31). Provenance:
  `plfitb.m:52` marks an undocumented branch "requires r_plfit function,
  not in toolbox" (R. Hanel, PLOS ONE 2017 supplementary code, no
  license grant). R2 settled decision: keep external, do not vendor; the
  check reports it as a known external reference; README documents the
  requirement. The user's edited working copy at
  `~/MATLAB/fexlib/libstats/DISTRIBUTIONS/rplfit/` is preserved.
  Resolved: README (Requirements) documents the external `r_plfit`
  requirement, and the dependency check reports it as a known external
  reference.
  - correction (2026-09-13, R3 sweep records#3 and records#14): the
    known-external report holds on every machine. `dependencies.m:113`
    names `r_plfit.m` as the external file that `plfitb.m` requires, and
    the check lists it in `known_external` whenever it analyzes
    `plfitb.m`. The list does not depend on `requiredFilesAndProducts`,
    which omits `r_plfit` on a machine where it does not resolve. plfitb
    is not a pending entry point. `tests/test_dependencies.m`
    `test_plfitbClassification` verifies both facts. Working-tree anchor
    for `plfitb.m:52`: `plfitb.m:62`.

### Todo

- [ ] (user decision, bead bfra-3kh.25) periphery self-containment.
  Provenance: the repaired live check found 31 files that resolve
  outside the toolbox with no vendored copy, all reached from the
  data-loading and mapping periphery: `loadcalm` (the matfunclib
  `setpath`/`timetabletrends` chains), `loadghcnd` (`readGHCND` plus two
  station .mat files, one 3.1 MB), `loadgrace` (its GRACE data is not
  shipped), `mapbasins` and `mapgages` (`loadworldborders`,
  `world_borders.mat`, colorbar helpers). The 2023 audit believed the
  toolbox self-contained; the clean-path analysis drops unresolvable
  names without a warning, which hid these. Options: vendor the chains, gate
  the functions with a clear missing-dependency error, or de-advertise
  them. R2 finding: bfra's copies of the five functions are the
  reference copies; the analysis-project `mapgages` copy is broken;
  findings and options in
  `.agents/plans/drafts/2026-08-30-periphery-reconciliation-findings.md`.
  - correction (2026-09-13, R3 sweep records#2): six public functions
    reach the 31 files. `loadcalm`, `loadghcnd`, `loadgrace`,
    `mapbasins`, and `mapgages` reach 26 of them. `loadflow` reaches the
    other 5: matfunclib `functools/optionParser.m`,
    `libsys/fnamefromlist.m`, `libsys/getlist.m`,
    `libsys/rmdotfolders.m`, and `libsys/showlist.m`. The chain starts at
    the `getlist` calls at `loadflow.m:130,144`. `dependencies.m:144-145`
    lists `loadflow.m` in `pendingentries`. This correction supersedes
    "all reached from the data-loading and mapping periphery" and the
    five-function list above.
  - correction (2026-09-13, R3 repair): `dependencies.m:127-128` lists
    five entry points in `pendingentries`: `loadcalm.m`, `loadghcnd.m`,
    `loadgrace.m`, `mapbasins.m`, and `mapgages.m`. `loadflow.m` is not
    in the list. On 2026-09-13, `baseflow.internal.dependencies('',
    'check')` on the author's machine (R2025b) reported these five in
    `pending_decision` and 31 files in `missing_dependencies`. This
    correction supersedes "`dependencies.m:144-145` lists `loadflow.m` in
    `pendingentries`".

## Example sections (bfra-3kh.13 stub)

### Done

- [x] 16 core-workflow functions have verified Example sections (each
  example ran verbatim headless): getevents, eventfinder, eventtau,
  globalfit, fitphi, getdqdt, setopts, loadExampleData, plfitb, gpfitb,
  plotdqdt, pointcloudplot, baseflowtrend, wrapevents,
  generateTestData, fitab. fitevents and conversions already had them.
  - correction (2026-09-13, R3 sweep records#11): seven functions had
    Example sections before bead bfra-3kh.13: aQbString, conversions,
    fitevents, getstring, help, hyetograph, and mapbasins. Bead
    bfra-3kh.13 did not run them. The fitevents example
    (`fitevents.m:40-53`) fails headless on R2025b (2026-09-13). It uses
    an undefined `EventData` (`MATLAB:UndefinedFunction`), and its
    `baseflow.fitab` call passes `'order'` as the method argument
    (`MATLAB:unrecognizedStringChoice`). The fitevents example repair is
    pending. With the 16 above, 23 of the 66 public functions carry
    Example sections. This correction supersedes "fitevents and
    conversions already had them".

### Deferred

- [ ] Example sections for the remaining 44 public functions
  (DesignSpec area H2b tier 2). The per-function list is in the bead
  bfra-3kh.13 report; most are loaders, plotters, and string or
  utility helpers outside the core workflow.
  - correction (2026-09-13, R3 sweep records#12): the bead bfra-3kh.13
    report is a session scratchpad file (`r13-examples-report.md`) that
    no saved location holds. 43 public functions remain, not 44:
    `help.m` carries a one-line example. The list comes from
    `grep -L '% Example' toolbox/+baseflow/*.m`, less `Contents.m`:
    aquiferprops, aquiferstorage, aquiferthickness, aquifertrend,
    basinlist, basinname, characteristicTime, checkevent, cloudphi,
    dndtuncertainty, eventphi, eventpicker, eventplotter, expectedQ,
    fdcurve, fitphidist, getEventsData, getFitsData, getfunction,
    loadbasins, loadcalm, loadflow, loadghcnd, loadgrace, loadmeta,
    loadprops, mapgages, open, phifitensemble, plotaquifertrend,
    plotrefline, plplotb, pointcloudintercept, prepfits, printtrend,
    privatefunction, Qnonlin, QtauString, QtString, specialfunctions,
    stationlist, stationname, trendplot. This correction supersedes "the
    remaining 44 public functions" and "The per-function list is in the
    bead bfra-3kh.13 report".

## Core-chain coverage (bfra-3kh.9 stub)

### Todo

- [ ] `globalfit` opens one figure even with `plotfits` false. Provenance:
  found by tests/test_corechain.m (bead .9); the default `'pointcloud'`
  phimethod estimates phi through `pointcloudplot`, which always draws
  (pointcloudplot.m creates a figure when no axis is passed).
  Recommendation: refactor the cloud-phi path to compute the reference
  lines without plotting, then tighten the test_corechain figure
  assertion to zero.
  - correction (2026-09-13, R3 sweep records#8): cloudphi estimates phi
    without plotting. It calls `pointcloudintercept`
    (`cloudphi.m:71-72`) and `fitphi` (`cloudphi.m:77-87`). It then
    always draws the point cloud and the phi legend
    (`cloudphi.m:90-101`). `globalfit.m:90-91` calls cloudphi without
    `plotfits`. Recommendation: pass `plotfits` from globalfit to
    cloudphi, and skip the `pointcloudplot` and legend block when
    `plotfits` is false. Then tighten the test_corechain figure assertion
    to zero. This correction supersedes "estimates phi through
    `pointcloudplot`" and the refactor recommendation above.

## Sandbox rehabilitation (bfra-3kh.20 stub, W2)

### Done

- [x] capture-before-cleanup: `sandbox/examples/kuparuk_published_opts.m`
  reconstructs the opts structs that produced the published Kuparuk
  results (the only recorded copy, `sandbox/notes_bfra_tmp.txt`
  L100-151, which stays in place as the citation anchor). Verified
  headless: the printed structs match the recorded dumps field for
  field.
- [x] four diagnostic scripts rehabilitated to the current `baseflow.*`
  namespace, each with a header stating purpose, every rename, and why
  it still cannot run (author-machine data, matfunclib utilities, or
  lost workspace state): `bfra_kuparuk_test.m`,
  `bfra_kuparuk_diagnose.m`, `diagnose_replication.m` (its header
  preserves the replication forensics: wrapevents+smoothflow, plfit
  limit 20, the R2020b/R2021b K-S difference), and `temp2.m`, moved
  from `sandbox/tests/` to `sandbox/rehabilitated/`.
- [x] the finished nlinfit-warning explanation copied to
  `sandbox/examples/notes_warnings_nlinfit.m` (original stays in
  `sandbox/notes/`).
- [x] status folders created (`rehabilitated/`, `examples/`,
  `needs-context/`, `superseded/`); the last two are empty because
  every excluded or unreconstructable-context classification sits
  inside a do-not-move file (the TODO lists and notes files, which
  stay in place as provenance anchors). Full move map and per-file
  outcomes: the bead bfra-3kh.20 notes record the report location.
  - correction (2026-09-13, R3 sweep records#12): the bead bfra-3kh.20
    notes point to a session scratchpad report (`w2-rehab-report.md`)
    that no saved location holds. The move map, checked against the
    sandbox folders:
    - moved from `sandbox/tests/` to `sandbox/rehabilitated/`:
      `bfra_kuparuk_test.m`, `bfra_kuparuk_diagnose.m`,
      `diagnose_replication.m`, and `temp2.m`;
    - written new in `sandbox/examples/`: `kuparuk_published_opts.m`;
    - copied to `sandbox/examples/`: `notes_warnings_nlinfit.m` (the
      original stays in `sandbox/notes/`);
    - `sandbox/needs-context/` and `sandbox/superseded/` hold no files.

    The rows in this section record the per-file outcomes. This
    correction supersedes "the bead bfra-3kh.20 notes record the report
    location".

### Demo nominations (for the W3 review)

- [ ] `sandbox/examples/kuparuk_published_opts.m` as a test fixture and
  Kuparuk-demo companion (diff against `baseflow.setopts` defaults).
- [ ] `sandbox/rehabilitated/bfra_kuparuk_test.m` as the skeleton for a
  full-analysis demo once its data loading targets
  `baseflow.loadExampleData`.
- [ ] `sandbox/examples/notes_warnings_nlinfit.m` as a doc page: the
  expected nlinfit warnings for recession fitting.
- [ ] `sandbox/rehabilitated/bfra_kuparuk_diagnose.m`'s
  `baseflow.checkevent` comparison pattern as a short
  diagnose-one-event demo.
- [ ] the `diagnose_replication.m` header knowledge as a
  known-issues/reproducibility doc note.

## Commented-assertion adjudication (bfra-3kh.10 stub)

### Done

- [x] tests/test_nonnansegements.m (moved to matfunclib
  `libspatial/test/testNonnansegments.m` on 2026-09-13), 12 asserts in 4 parked edge-nan
  cases: RE-ENABLED by fixing the function. The parked comment was
  accurate: the old toolbox nonnansegments errored on leading or
  trailing nans (verified: 3 of the 4 cases errored, 1 returned wrong
  values), and its own TODO asked to merge the matfunclib version. The
  matfunclib `libspatial/polygon/nonnansegments.m` passes all four
  cases with the parked expected values and takes the same (x, nmin)
  signature, so it is vendored over
  `toolbox/+baseflow/private/nonnansegments.m`, and the test file is
  converted to a function-based suite with all six cases live.
  - correction (2026-09-13, R3 sweep records#9): the toolbox copy is a
    modified matfunclib version. The matfunclib source accepts nmin and
    ignores it: its `processOneVector(x, ~)` keeps the length filter
    commented out. The toolbox copy enables the filter
    (`private/nonnansegments.m:117-122`) because `eventfinder.m:62`
    depends on it. The toolbox copy also calls the shared private
    `rmleadingnans` and `rmtrailingnans`, and it returns empty columns
    for an all-nan vector. `tests/test_nonnansegements.m`
    `test_minimumLength` covers the nmin filter. This correction
    supersedes "takes the same (x, nmin) signature, so it is vendored
    over".
- [x] tests/test_islocalmax.m:86, three-way peak-index agreement:
  RE-ENABLED as a live verification (the three implementations agree on
  the fixture data).
- [x] tests/test_islocalmax.m:89, prominence comparison against
  findpeaks: DELETED with rationale — findpeaks needs the undeclared
  Signal Processing Toolbox, and the re-enabled index comparison covers
  the agreement claim. The intent is recorded here.
- [x] tests/TestBaseflow.m:448-457 (assertequal pair plus its
  texp/qexp/figure debug scaffolding): DELETED — duplicates of the live
  verifyEqual pair directly above them.
- [x] tests/TestBaseflow.m:464-468 ("for scripting" assertequal and the
  strict 1:1 verifyEqual): DELETED — superseded by the live
  intersect-tolerance comparison, which exists because events can
  differ by up to four edge elements; the strict 1:1 aspiration is
  recorded here.
- [x] tests/TestBaseflow.m:522-524 (verifyError for an event shorter than nmin):
  DELETED — the author's own note says eventfinder returns empty
  instead of erroring; the fact is kept as a live comment beside the
  equality checks that cover the path.

Note: two asserts inside the parked script block at the bottom of
tests/test_islocalmax.m belong to that block's W1 disabled-block row
(keep parked; W3 reviews it) and are outside the 19 audited assertion
rows this bead adjudicates.

## fitcts and fitsts assessment (bfra-3kh.23 stub)

### Done

- [x] CTS assessment and implementation. CTS (constant time step) is the
  standard method: Brutsaert and Nieber (1977) approximate dQ/dt with
  fixed-step differences of daily flow, and the toolbox's ETS
  (private/fitets.m, exponential window) and VTS (private/fitvts.m,
  Rupp and Selker variable step) are its refinements, so CTS is the
  baseline and comparison case. `private/fitcts.m` is implemented: six
  stencils (B1 the traditional backward difference and default, B2, F1,
  F2, C2, C4), method validation, uniform-step dt from median(diff(T)),
  rain output aligned with the returned time vector (the fitcts.m:71
  `rq = []` marker), and a repaired C4 stencil (the sketch ended with
  +Qip2, cancelling the leading term and never using Q_{i-2}).
  tests/test_fitcts.m verifies every stencil against the analytic
  derivative of an exponential recession with order-dependent
  tolerances, plus defaults, alignment, error, and the public
  getdqdt('CTS') path.

### Deferred

- [ ] fitsts (recommendation: defer, keep parked; W3 reviews this
  disposition). Provenance: `private/fitsts.m` is a fully commented
  sketch of four smoothing-derivative variants: SPN (splinefit with
  optimal knots via a baseflow.splinebreaks helper), SLM (D'Errico's
  slmengine), pchip (empty stub), and SGO (Savitzky-Golay via
  sgolayfilt plus the vendored movingslope). Assessment: smoothing
  before differencing is a legitimate noise-control idea, but ETS
  already addresses recession noise with its exponential window and is
  the published method; every sketched variant needs an external FEX
  function (splinefit, slmengine) or the undeclared Signal Processing
  Toolbox (sgolayfilt), against the self-containment goal; and the
  method has no established comparative value for recession analysis.
  Implementation is not justified this pass; removal is not needed (a
  private file, accurately listed as not implemented). Keep parked.
  - correction (2026-09-13, R3 sweep records#10): `splinefit` ships in
    `toolbox/+baseflow/private/splinefit.m`. SPN needs the absent
    `baseflow.splinebreaks` helper and `fnder` (Curve Fitting Toolbox, a
    declared product). SLM needs `slmengine` (File Exchange, not
    shipped). SGO needs `sgolayfilt` (Signal Processing Toolbox, not
    declared); `movingslope` ships in
    `toolbox/+baseflow/+deps/movingslope.m`. The fitsts H1 line and
    `toolbox/docs/baseflow_contents.m:107` say "Not implemented".
    `toolbox/+baseflow/Contents.m:147` lists the commented signature
    until a Contents.m regeneration reads the H1 line. This correction
    supersedes "(splinefit, slmengine)" and "accurately listed as not
    implemented".

## Power-law notation explainer (bfra-3kh.31 stub)

### Done

- [x] notation explainer and worked comparison:
  `toolbox/docs/baseflow_powerlaw_notation.m` (runnable; asserts all
  estimators recover a known synthetic exponent). Resolves the
  three-way lambda-alpha confusion (bfra_phone_notes.txt:60-71 kept as
  provenance), verifies the mgc `out.b = 1+1/Aml` edit in the working
  r_plfit copy, and records the Kondlo plaweiv MLE
  (matfunclib/libstats/testbed/plaweiv) as the genuine
  lower-plus-upper-cutoff estimator with measurement error. plfitb's
  'hanel' call passes 'cdat' so continuous tau is not integer-binned.
  r_plfit stays external (no license grant; README documents the
  requirement); the working copy at
  `~/MATLAB/fexlib/libstats/DISTRIBUTIONS/rplfit/` is preserved.

### Deferred

- [ ] gpfitb confidence-interval propagation for `tau0 = sigma/k` (the
  point estimate is verified exact; gpfitb.m:50 records the CI to-do;
  working tree, R3 sweep records#14: gpfitb.m:60).
- [ ] promote the Kondlo plaweiv MLE into a callable estimator when a
  doubly-truncated tau fit is needed; the folder's local reference PDF
  is the wrong paper (an extreme-value tutorial), so fetch the Kondlo
  2010 thesis when resuming.

## loadcalm site selection (bfra-3kh.27 stub)

### Deferred

- [ ] optional site-selection name-value input for
  `toolbox/+baseflow/loadcalm.m`. Provenance: the Kuparuk nine-site pin
  (loadcalm.m, documented under bead .27 per the R2 settled decision:
  the CALM source data changed and the published results must stay
  reproducible). An input to control site selection is welcome; it is
  deferred because loadcalm needs the author-machine data paths (bead
  bfra-3kh.25 periphery decision) before the option is testable.

## Octave smoke verification (bfra-3kh.15 stub)

### Deferred

- [ ] vendored `toolbox/+baseflow/+deps/arrow.m` reads the MATLAB-only
  hidden axes property WarpToFill (arrow_WarpToFill) and errors on
  Octave before it reaches the handle allocation. `tests/octave_smoke.m`
  runs its arrow section on MATLAB only. The sandbox/ReplaceArrowNotes.m
  section lists the functions that use arrow (plotrefline, fitphidist,
  gpfitb, plplotb, plotdqdt); their Octave behavior on those paths is
  unverified. Rec: guard the WarpToFill read on Octave or replace arrow
  with a built-in annotation.

## Helper defects from the R3 sweep (bfra-3kh.40 stub)

The R3 root-cause sweep (2026-09-13) found these defects. Each is
present at HEAD in a file that the R3 batch touched. Findings with
evidence and fixes:
`.agents/plans/execution/evidence/2026-09-12-bfra-3kh-r3/r3_L64_sweep.json`,
class "vendored and private helper behavior".

### Todo

- [ ] `private/smoothnoise.m` 'annual' path. Provenance: finding
  helpers#3. The path reshapes rows in column-major order, which mixes
  years. It also misreads sizes and returns a column.
  `smoothnoise(x)` with no method errors.
- [ ] `private/predictlm.m` degrees of freedom. Provenance: finding
  helpers#6. The interval uses N-2 of the query points, not the
  residual degrees of freedom of the fit.
- [ ] `eventfinder.m` local `islocalmax`. Provenance: finding
  helpers#12. The local function is identical to
  `private/islocalmax.m`. Rec: remove the local copy and call the
  shared helper with unchanged results.
- [ ] `fitab.m` local fitNLS copies. Provenance: finding helpers#13.
  The local `fitNLS_matlab`, `fitNLS_octave`, and `nlparci_octave`
  shadow the private files. Rec: remove the local copies and call the
  shared helpers with unchanged results.
- [ ] `loadflow.m` anonymous `cms2cmd`. Provenance: finding helpers#20.
  The anonymous function shadows `private/cms2cmd.m`.
- [ ] `private/preparecalendar.m` timestep. Provenance: finding
  helpers#21. The function never assigns `timestep` for a leap-free or
  irregular calendar.

Acceptance: each defect gets a fix and a test that covers the changed
behavior. A fix that changes analysis results waits for a user decision.

## Generated-doc defects from the R3 sweep (bfra-3kh.41 stub)

The R3 root-cause sweep (2026-09-13) found these defects. Findings:
`.agents/plans/execution/evidence/2026-09-12-bfra-3kh-r3/r3_L64_sweep.json`,
class "generated and published documentation that contradicts the code".

### Todo

- [ ] m2html dependency graph out of date. Provenance: finding docs#3.
  `toolbox/docs/html/m2html/+baseflow/graph.png` and `graph.map` are
  the 2023 render, because Graphviz `dot` is not installed. The image
  shows edges that the regenerated `graph.dot` does not have. Rec:
  install Graphviz and rerun `makedocs('functions')`, or turn the graph
  off.
- [ ] demo 2 published outputs out of date. Provenance: finding
  docs#12. `toolbox/docs/html/baseflow_demo_2.html` prints
  `GlobalFit.b` 1.2764 and alpha 3.6175. The demo code gives 1.2777 and
  3.6004. HEAD has the same mismatch. Rec:
  export the demo again with Run true and without `convertlivescripts`.
- [ ] `toolbox/GettingStarted.mlx` out of sync. Provenance: finding
  docs#8. The live script does not match
  `toolbox/docs/baseflow_gettingStarted.m` (Mapping, the fitopts row,
  the mapping section, and the function-name fixes). Rec: regenerate
  the live script from the source after the source is final.

## User decisions from the R3 sweep (bfra-3kh.42 stub)

The R3 root-cause sweep (2026-09-13) raised these items. Each needs a
user decision before any change. Findings with evidence:
`.agents/plans/execution/evidence/2026-09-12-bfra-3kh-r3/r3_L64_sweep.json`.

### Todo

- [x] (user decision, item 1, done 2026-09-14: `option` implemented for matrix and cell elements) `private/nonnansegments.m` option input.
  Provenance: finding helpers#11. The function accepts a third input
  `option` and ignores it (parked matfunclib WIP). Options: drop the
  input, or raise an error when a caller passes it.
- [x] (user decision, item 2, done 2026-09-14: monotone-branch patch plus no threshold in the trough and peak wrappers; Kuparuk b matches the published value) `+deps/peakfinder.m` single interior
  maximum. Provenance: finding helpers#14. When `includeEndpoints` is
  false, the monotone branch never reports a single interior maximum.
  `private/islocalmax.m` inherits the result. A fix changes vendored
  third-party code.
- [x] (user decision, item 3, done 2026-09-14: the event parsers take their defaults from `setopts`) Getting Started defaults. Provenance:
  finding docs#5. The Getting Started API defaults come from `setopts`,
  but the function parsers use other defaults for direct name-value
  calls. Decision: choose the set of defaults that governs.
- [x] (user decision, item 4, done 2026-09-13) plotdqdt deprecated label. Provenance:
  findings docs#7 and userdocs#24. Getting Started labels `plotdqdt`
  deprecated; the code does not.
- [x] (user decision, item 5, done 2026-09-13) getdqdt help methods. Provenance: finding
  userdocs#3. The help lists `derivmethod` values and options that the
  parser lacks (B1..C4, SGO/SPN/SLM, fitwindow, ax, fitab, plotfit). It
  omits CTS and `ctsmethod`. Options: remove them, mark them not
  implemented, or implement them.
- [x] (user decision, item 6, done: release date 2026-09-14) 1.1.0 release date. Provenance: finding
  userdocs#14. The date 2026-08-30 in CHANGELOG, DESCRIPTION,
  CITATION.cff, and .zenodo.json predates the content. Rec: set the
  real release date at J2.
- [x] (user decision, item 7, done 2026-09-13) CITATION.cff authors. Provenance: finding
  userdocs#16. CITATION.cff lists one author. .zenodo.json, Zenodo,
  JOSS, and README list Cooper and Tian Zhou.
- [x] (user decision, item 8, done 2026-09-13) eventfinder `qmin` and `cmax`.
  Provenance: finding userdocs#26. The eventfinder help documents
  `qmin`, `cmax`, and an opts struct that the parser rejects.
- [x] (user decision, item 9, done 2026-09-13) `toolbox/functionSignatures.json`.
  Provenance: finding userdocs#28. Its `derivmethod` choices, the
  missing `fitopts`, the `drainagedens` name, and the eventphi options
  disagree with the parsers.
- [x] (user decision, item 10, done 2026-09-13) `toolbox/docs/citing_baseflow.m` license
  wording. Provenance: finding records#17. The page attaches a citation
  condition to the BSD 3-Clause license.

Note: the bead notes record a user direction (2026-09-13). Batch R3-A
makes the obvious fixes for items 5, 7, 9, and 10. Item 5 includes
`ctsmethod` as a fitevents and setopts option, so the CTS stencils are
selectable. R3-A covers part of item 6: the CHANGELOG heading reads
'Unreleased' until J2 sets the date. Items 1, 2, 3, 4, and 8 wait for
the user's review.

---

## W1 sandbox TODO and notes inventory — baseflow toolbox

- Bead: bfra-3kh.19 (DesignSpec area W1, WIP inventory)
- Repository: /Users/mattcooper/MATLAB/projects/bfra (read-only; nothing modified)
- Date: 2026-08-30
- Method: read the two TODO files and every notes file in full; verified done-claims
  against toolbox code (toolbox/+baseflow/...). Contiguous runs of DONE-prefixed items
  are grouped into one batch row with the items enumerated; every open item gets its
  own row. "delete" is a recommendation only — nothing was deleted.
- Convention: the author prefixes completed items with `DONE` in these files.

## Summary counts (rows)

Counted by each row's primary (first-listed) classification. One row
(git-notes-joss-revisions.txt L3-5) bundles a todo and a done; it counts once,
as todo.

| Classification | Count |
| -------------- | ----- |
| done           | 37    |
| todo           | 19    |
| deferred       | 76    |
| excluded       | 37    |
| **total rows** | 169   |

Rows flagged `unreconstructable-context`: 16.

## Source files found

Primary TODO lists:

- sandbox/TODO_bfra.m (359 lines, live list) — mined below
- sandbox/TODO_bfra_old.m (400 lines) — mined below

Notes files (the "~11 notes files"; 18 text files found plus 2 non-text):

- sandbox/notes/bfra_notes.m (145 lines) — mined
- sandbox/notes/bfra_algorithm_structure.m (36 lines) — mined
- sandbox/notes/bfra_dimensions.m (53 lines) — mined
- sandbox/notes/bfra_methods.m (244 lines) — mined
- sandbox/notes/bfra_phone_notes.txt (77 lines) — mined
- sandbox/notes/git-notes-joss-revisions.txt (36 lines) — mined
- sandbox/notes/notes_aquiferprops.m (143 lines) — mined
- sandbox/notes/notes_docs.m (41 lines) — mined
- sandbox/notes/notes_merge_branch.m (347 lines) — mined
- sandbox/notes/notes_warnings_nlinfit.m (12 lines) — mined
- sandbox/notes/stash-notes.txt (180 lines) — mined
- sandbox/notes/git_notes.pptx — binary PowerPoint, not mined (flag for manual review)
- sandbox/notes_bfra_tmp.txt (267 lines) — mined
- sandbox/ReplaceArrowNotes.m (11 lines) — mined
- sandbox/octave_compat.txt (185 lines) — mined
- sandbox/joss/paper_notes.md (71 lines) — mined
- sandbox/joss/notes-revisions-Sep-2023.txt (38 lines) — mined
- sandbox/joss/submission_notes.txt (79 lines) — mined
- sandbox/joss/final-release-notes.txt (89 lines) — mined
- sandbox/joss/Untitled-1.md (99 lines) — inspected; JOSS paper draft copy, one row below

---

## sandbox/TODO_bfra.m

Live TODO list. Mixes the final JOSS revision pass, the general toolbox TODO, WRR
paper items, and debugger-time workspace fragments.

### Done

- [x] **L4-12** — batch: DONE replace trendplot partial-match calls with full param names;
  DONE fitphidist 'PD' option audit; DONE convert kuparuk demo Data timetable to
  struct for Octave; DONE refactor plotaquifertrend for Octave
  (author-marked; Octave work corroborated by toolbox/+baseflow/plotaquifertrend.m
  and the Octave shims in toolbox/+baseflow/private/) — Intent: final JOSS revision
  punch list. — Rec: keep parked (record only).
- [x] **L30-32** — batch: DONE move tests to top-level; DONE implement
  baseflow.help(funcname); DONE move +util (and +deps candidates) to
  +internal/private — Evidence: tests/ exists at repo root
  (tests/TestBaseflow.m etc.); toolbox/+baseflow/help.m exists;
  +internal has 13 files, +util is down to 4 (numevents/numfits/numtau), private/
  holds 83 helpers. — Rec: keep parked (record only).
- [x] **L46-48, L50** — batch: DONE change to opts.getevents/opts.fitevents/
  opts.fitglobal; DONE add `if nargin == 0, open ...` to main funcs; DONE wrapevents
  works year by year; DONE move stuff to +internal — Evidence: setopts.m
  documents funcname 'getevents'|'fitevents'|'globalfit'; wrapevents.m and +internal
  exist. — Rec: keep parked (record only).
- [x] **L49, L51-54** — DONE add 'tag' to point cloud figure, with the
  `findall(groot,'Type','figure','Tag','baseflow')` snippet
  (author-marked) — Verification gap: no Tag or findall(groot,...) found in the
  current pointcloudplot.m, so the mechanism may have been removed or lives
  elsewhere. — Intent: re-activate an existing point-cloud figure instead of opening
  new ones. — Rec: keep parked; re-verify before deleting the snippet.
- [x] **L111-134** — batch of 24 DONE WRR paper items (phi uncertainty, figure sizes,
  equation refs, pareto figure, flow chart, GRACE handling, trend significance,
  etc.) — Rec: delete (paper published; the record lives in the paper).
- [x] **L273** — "DEFINITELY RETURN TO LOADFLOW - it loads the raw .csv files, good for
  reproducibility" — Evidence: toolbox/+baseflow/loadflow.m:51-158
  implements the raw-.csv method (readtable on '*.csv' lists). — Rec: keep parked
  (record only).
- [x] **L283-285** — "renamed to deal with namespace collisions: refline, pointcloud" —
  Evidence: toolbox/+baseflow/plotrefline.m and pointcloudplot.m exist. —
  Rec: delete (record only).
- [x] **L289-296** — batch: DONE rewrite dn/dt in terms of n0; DONE merge dev into main;
  DONE replace non-refline uses of refline; DONE replace refline-for-ab with fitab;
  DONE reconcile ahat method in globalfit with eventphi/cloudphi; DONE settle on the
  median method — Rec: keep parked (decision record for the ahat/phi
  reconciliation).
- [x] **L297-303** — "CHANGE OF PLANS - replace all uses of pointcloudintercept with
  fitab ... I think it can make sense to keep this" (kept: only called in globalfit
  and cloudphi; returns xbar/ybar; the intercept difference only affects the unused
  'mean' method) — (decision made and explained) — Evidence:
  pointcloudintercept.m still exists and is the documented path. — Rec: keep parked —
  this paragraph is the only place the keep-pointcloudintercept rationale is written
  down; consider moving it into pointcloudintercept.m's header.
- [x] **L304-316** — batch: globalfit function-by-function review, all DONE (expected
  discharge into a function; phifit out of refline + envelope; eventtau aggfunc;
  fitdistphi; eventphi -> pointcloudintercept; plfitb; cloudphi; fitphi; refline
  cleanup) — Evidence: eventtau.m:14,26,79-80 implements 'aggfunc';
  expectedQ.m exists; plotrefline.m exists. — Rec: delete (record only).

### Todo

- [ ] **L13** — "compare behavior of corr and corrcoef for two column vectors"
  — Evidence still live: toolbox/+baseflow/dndtuncertainty.m:148,155 uses `corr`;
  private/nancorr.m:25-29 branches between `corrcoef` (2 args) and `corr`. — Intent:
  confirm the two give identical results for the two-column case so the toolbox can
  drop the Statistics Toolbox dependency where possible. — Rec: implement as a small
  unit test in tests/.
- [ ] **L16-22** — baseflow.help/open shadowing: debugging a package function prompts a
  path change, and a package function named `help` breaks built-in help —
  Evidence: toolbox/+baseflow/help.m and open.m exist, so the shadowing scenario is
  live. — Intent: record a usability trap with the custom help function. — Rec:
  formalize — document the limitation in help.m's header or guard against it.
- [ ] **L26** — "remove all 'useax' or 'ax' optional inputs, replace with parsegraphics"
  — Evidence: no `parsegraphics` anywhere in toolbox/; `useax` still in
  trendplot.m, plotaquifertrend.m, loadcalm.m, plotdqdt.m. — Intent: standardize axes
  handling across plotting functions. — Rec: implement (mechanical refactor).
- [ ] **L27** — "write examples for each function" — Evidence: only 7 of 67
  top-level +baseflow functions have an Example section; demos exist
  (toolbox/demos/*.mlx) but per-function examples do not. — Intent: complete the API
  documentation. — Rec: implement incrementally; formalize as runnable examples.
- [ ] **L28** — "make fitab run fast" — Intent: performance of the per-event
  curve fit (toolbox/+baseflow/fitab.m), the hot loop of fitevents. — Rec: keep
  parked until profiled; then implement.
- [ ] **L40** — "need to be able to use eventplotter quickly to diagnose issues" —
  Intent: make eventplotter a fast one-line diagnostic. — Rec: formalize
  as runnable example (a short demo showing the diagnose workflow) and note gaps.
- [ ] **L41** — "move notes/baseflow_dimensions to a function" — Evidence: the
  content still lives only in sandbox/notes/bfra_dimensions.m; conversions.m has no
  dimensions documentation. — Intent: make the dimensional-analysis rules (units of
  a, dQ/dt, S, c) part of the toolbox itself. — Rec: implement — fold into
  baseflow.conversions help or a docs page (see the bfra_dimensions.m rows below).
- [ ] **L43** — "remove inputParser from non-entry-point functions" —
  Evidence: 64 files under toolbox/+baseflow still use inputParser. — Intent: reduce
  parsing overhead and complexity in internal code paths (STYLE prefers arguments
  blocks). — Rec: implement incrementally, entry points last.
- [ ] **L44** — "change prepfits to preparedata and add more cases like getevents" —
  Evidence: toolbox/+baseflow/prepfits.m still exists under the old name.
  — Intent: generalize data preparation into one function. — Rec: keep parked until
  the rename's call-site impact is scoped; then implement.
- [ ] **L331-336** — commented snippet: `baseflow.findevents` then a semilogy/pause loop
  over events — Intent: minimal event-browsing loop for visual QC. — Rec:
  formalize as runnable example (pairs with the L40 eventplotter item).

### Deferred

- [ ] **L29** — "fminspleas and/or batchpleas" — Evidence: no fminspleas
  in toolbox/; scratch experiment survives at sandbox/tests/test_FMINSPLEAS.m and the
  idea recurs at notes_merge_branch.m L184-185 and notes_bfra_tmp.txt L90-92. —
  Intent: use separable least squares (partitioned linear/nonlinear) to speed up or
  stabilize ab fitting. — Rec: keep parked; fold into any future fitab performance
  work.
- [ ] **L34-36** — "Try using chunk inds in getevents instead of wrapevents, maybe they
  can even be unified where the chunk equals the number of data points for the
  non-annual case" — Evidence: wrapevents.m survives as a separate
  annual wrapper around getevents (see its header). — Intent: unify the annual and
  whole-record event-detection paths into one chunked implementation. — Rec: keep
  parked; real design work, and wrapevents' header carries a related TODO (adaptive
  sgolay filter).
- [ ] **L42** — "check fitcox, for survival analysis" — Intent: explore
  Cox proportional hazards as an alternative lens on event duration/tau. — Rec: keep
  parked (research idea).
- [ ] **L59-63** — m2html fork links (distrep/DMLT, rickynite/m2html, PymatFlow/m2html,
  firdavsmd9/M2HTMLProject, tmxkn1/m2htmlext) — Intent: candidate
  m2html replacements/extensions for the docs build
  (+internal/makedocs.m uses m2html). — Rec: keep parked as reference.
- [ ] **L65-66** — "for a few numerical derivative methods see velocity_estimation in
  physics toolbox" — Intent: alternative derivative estimators for
  dQ/dt (relates to the ETS/VTS machinery in private/fitets.m, fitvts.m). — Rec:
  keep parked.
- [ ] **L72-76** — "we need a way to eliminate D or solve for it independently ... start
  with Troch's approach that converts to average water table height ... then use that
  to find phi" — Intent: break the circular dependency between aquifer
  thickness D and drainable porosity phi in aquiferprops/globalfit; the theme recurs
  in TODO_bfra_old.m L26-28 and notes_aquiferprops.m. — Rec: keep parked (the most
  important open science thread in these files).
- [ ] **L179-253** — debugger workspace fragments: GlobalFit.a probes; nanmedian dqdt/q^b
  identities; a1/a2 pointcloudintercept comparisons with `(3-2*bhat)/(3-bhat)`
  ratios; Qexpcheck; asamp/bsamp allfitdist/loghist/plfitb explorations
  — flag: unreconstructable-context — Intent: numerically validate the theoretical
  ratios linking early/late-time intercepts, tau0, and Qexp (the material behind
  expectedQ.m and pointcloudintercept.m). — Rec: formalize the a1/a2 and Qexp ratio
  checks as a runnable example or test against generateTestData.m; delete the rest.
- [ ] **L255-267** — "point cloud vs beta dist phi": phi=0.019 with beta fit (trends too
  big); Troch-method D gives 0.37/0.93; 5th-pctl late-time event fits give phi=0.046
  (trends 0.23/0.58 at D=0.3) vs phi=0.027 (0.40/1.01 at D=0.5) —
  Intent: sensitivity record for the phi estimation method choice; documents why
  'pointcloud' is the default phimethod in the kuparuk opts. — Rec: keep parked;
  candidate for a methods-sensitivity docs page.
- [ ] **L287-288** — "get correct L/H on ahat; propagate that into Qexp, pQexp, and
  dQ/dt" — Intent: carry stream length / aquifer thickness
  corrections through the derived quantities (expectedQ.m, dndtuncertainty.m). —
  Rec: keep parked with the L72-76 phi/D thread.
- [ ] **L319-327** — deleted from baseflow_kuparuk: "NOW I AM GETTING THE RIGHT ANSWER
  again, 0.31 and 0.77 ... key thing is that L is NOT INVOLVED in estimating phi ...
  drainage density is about 0.03 so L prob needs to be a factor of 10 higher ...
  other than clarifying a method to get Q0 I am not sure Troch provides anything
  else" — Intent: closing assessment of the Troch method; explains why
  L is not reported with phi. — Rec: keep parked; candidate for aquiferprops.m
  documentation.
- [ ] **L343-357** — Qexp exceedance check: rank-based `P = n/N` vs
  `1-GlobalFit.pQexp` vs `P = sum(Q<Qexp)/numel(Q)` — flag:
  unreconstructable-context (needs GlobalFit and Q in scope) — Intent: verify the
  probability attached to expected discharge. — Rec: formalize as a test of
  expectedQ.m using generateTestData.m; then delete the fragment.

### Excluded

- **L45** — "one reason year-by-year is good is for eventplotter" —
  (observation, not actionable on its own; context for the L34-36 unification row)
  — Rec: delete once L34-36 is resolved.
- **L78-105** — reconstruction of the old globalfit -> eventphi -> refline call chain
  and refslope quantile logic, prefaced "I think this can be deleted it was me
  figuring out how to make ahat and phi consistent" — (author-marked
  superseded; the refline refactor it documents is closed out as DONE at L289-316) —
  Rec: delete.
- **L107, L109-110** — FINAL WRR PAPER TODO, still open: "update kuparuk basin
  outline"; "linear analysis" — (WRR paper published — Cooper et al.
  2023, see submission_notes.txt L1; paper-scoped, not toolbox-scoped) — Rec: delete,
  or move to the arctic-analysis project if the linear analysis is still wanted.
- **L136** — `that = GlobalFit.tau0*(1/(3-2*bhat))` — flag:
  unreconstructable-context (needs a live GlobalFit workspace) — Rec: delete.
- **L138-175** — "summary of where i am at" — CALM data workflow narrative
  (save_new_CALM.m, b_add_CALM, save_kuparuk_calm, calm_thermistors, private
  save_CALM, plotalttrend dependency chain) — (references
  interface/scripts in the separate baseflow-arctic project, not this repo) — flag:
  unreconstructable-context (depends on that project's file state) — Intent:
  checkpoint of the CALM ingest refactor feeding baseflow.loadcalm. — Rec: keep
  parked, but relocate to the arctic project's notes.
- **L269-272, L275-279** — baseflow_test vs dev-bk branch comparison ("DO NOT DELETE
  _test", per-function diffs) — (2022-era branch archaeology; the merge
  chronicled in notes_merge_branch.m completed and v1.0.0 shipped) — Rec: delete.

## sandbox/TODO_bfra_old.m

Header (L2-5) says this was README.m in the baseflow arctic project, moved here
26 Aug 2024 because it is more relevant to the toolbox. Much of it is nonetheless
arctic-analysis or WRR-paper scoped; classifications below reflect toolbox scope.

### Done

- [x] **L19-23** — batch: DONE add all months for grace; DONE remove snow trend from
  dSg/dt; DONE water years; DONE dS/dt from baseflow; DONE grace min/max
  — Rec: delete (arctic record).
- [x] **L46-72** — batch of 26 DONE items (star footnote on 1-b; section moves; merra
  water balances; b=3/b=1 lines; slope change detection; mosart huc12; ahat from
  bhat+tau0hat; quantreg trend; MERIT network; presentations; rclonesync; Dralle
  outline and overlap analysis; etc.) — Rec: delete (mixed paper/arctic
  record; completed).
- [x] **L199-203** — batch: DONE trends in annual flow quantiles; DONE min/max flow
  trends; DONE glacier map; DONE basin map; DONE GRACE vs BFRA storage for Kuparuk —
  Rec: delete (arctic record).
- [x] **L213-214** — "confirm ktime is correct for each run DONE; compute storage trends
  DONE-ish" — (author-marked; the "-ish" caveat noted) — Rec: delete.
- [x] **L227-231** — batch: run base analysis; set b=1 DONE; a for all catchments point
  cloud DONE; a for all catchments all events DONE — Rec: delete.
- [x] **L238-244** — batch: DONE obtain/implement Clauset code; DONE basin shapefiles;
  DONE Dralle decorrelation; DONE gagesII/RHBN download; DONE NLS fitting option;
  DONE PDO metric; DONEish gridded T/PPT/SM extraction — Evidence: plfit
  (Clauset) is in +deps; fitmethod 'nls' is the default in the kuparuk opts. — Rec:
  delete (record only).
- [x] **L370-400** — V0 event_filters salvage: filter list 1-7, the d2q/dt
  sign-switch subdivision plan, kept "1) TO REMEMBER MY THINKING ON THE FILTER
  ORDERING, AND 2) THE D2QDT2 FILTER ISN'T USED I THINK IN MY NEW METHODS AND I WANT
  TO MAKE SURE THIS IS NOT A MISTAKE" — Evidence: the second-derivative
  filter IS in the current code — eventfinder.m:125-179 computes d2qdt/d2qdtS and
  builds icon/icon2 exactly along these lines, so the feared omission did not
  happen. — Rec: keep parked or fold the filter-ordering rationale into
  eventfinder.m comments, then delete.

### Todo

- [ ] **L8-9** — "add Copyright line to all functions for auto help" (with MathWorks
  doc link) — Evidence: only 1 of 67 top-level +baseflow functions
  contains "Copyright". — Intent: make `help` auto-detection treat trailing lines
  correctly and standardize attribution. — Rec: implement (mechanical, scriptable).
- [ ] **L91-93** — "add this to baseflow.somewhere, it should be the non-dimensional
  outflow for RS05 solution: q = 1/2*(((1-2*mu)*kD*phi*D^3)/((1-mu)*(n+2)*(n+1))^1/2
  * t^(-1/2)" — Evidence: specialfunctions.m carries the related RS05
  coefficients (fR1 at specialfunctions.m:75 uses the same (1-2*mu) structure) but
  not this non-dimensional outflow. — Intent: complete the RS05 special-function
  set. — Rec: implement in specialfunctions.m (verify the expression's parenthesis
  placement first — the exponent looks garbled in the note).

### Deferred

- [ ] **L11-12** — PERMAFROST DATA: data.permafrostnet.ca ERDDAP link —
  Intent: candidate data source for permafrost analyses. — Rec: keep parked.
- [ ] **L26-28** — "eliminate D from the phi estimation and figure out a way to get B/E
  and theta from Dd and A. OR use some other method to get phi. or maybe the mean D
  from CALM" — Intent: same D/phi circularity thread as TODO_bfra.m
  L72-76; keep with it. — Rec: keep parked.
- [ ] **L30** — "search matlab double broken power law" — Intent: model
  the kinked point cloud (early/late regimes) with a two-regime power law. — Rec:
  keep parked.
- [ ] **L74-82** — "Second tier": finish dALT function; apply to all CALM sites;
  summarize; satellite image of river ice in Sag; USGS river temperature below
  freezing; outline methods paper building on Dralle; power law in standard control
  system form — Intent: post-paper research program. — Rec: keep
  parked (the Dralle-methods-paper thread recurs in bfra_methods.m).
- [ ] **L86-89** — "for b between 1 and 1.5, compare: tau = tau0*(2-b)/(3-2b); tau =
  tau0*(b-3)/(b-2)^(b-1); tofq = tau0/(b-1)*((b-3)/(b-2)^(b-1)-1)" —
  Intent: reconcile competing tau expressions in the b in (1,1.5) regime. — Rec:
  formalize as a symbolic/numeric check (fits +baseflow/+sym); keep parked until
  then.
- [ ] **L96-98** — "if rmrain and rmconvex are false and nmin is 4 days, then we get tau
  out to >1000 days, and a clear transition around 45 days to the curved
  exponential-looking ccdf" — Intent: empirical record of filter
  settings vs tau tail; pairs with bfra_notes.m L1-49. — Rec: keep parked; feed a
  future filter-sensitivity docs page.
- [ ] **L100-119** — research list: review Rupp appendix; rainfall interarrival vs tau;
  center Q and reinterpret a; dimensions of a vs Rupp's b; hydraulic conductivity
  from phi; cite Zheng/Muskett; table of greeks; table of inferred aquifer
  properties; differentiate+spline vs sgolay+movingslope; tau from summed Q; Taylor
  expansion tref; plot b vs time/tau for self-similarity — Intent:
  WRR-era analysis ideas; the spline-derivative option (L115) and b-vs-time
  self-similarity plot (L119) remain toolbox-relevant. — Rec: keep parked; extract
  L115 into any future derivative-method work.
- [ ] **L121-125** — TODO mar 2020: "now that i figured out lomax Q(t) probability, need
  to try getting expected duration with p(Q(t)) ... I think we end up with
  expected(Q) = Q0*(b-2)/(b-3) but confirm" — Evidence: expectedQ.m
  exists and implements the expected-value relation, so the core landed; the
  expected-duration integral confirmation is the remaining open bit. — Rec: keep
  parked; candidate +sym check.
- [ ] **L131-159** — whiteboard salvage: solutions to a = c1*D^N + c2 with c2 != 0
  (cases ix, xi, ...; c1/c2 in terms of k, L, phi, A, B, tan(theta)), ending "NOTE:
  need to double check these, esp. the sqrt term ... might be a mistake" —
  flag: unreconstructable-context (transcribed from an erased
  whiteboard; the case numbering references an Excel table) — Intent: extend the a-D
  relations beyond the c2=0 cases used in aquiferprops. — Rec: keep parked with
  notes_aquiferprops.m; do not delete — this is the only record.
- [ ] **L168-178** — plan: pick the early/late transition point (manual or Jachens ratio
  method); use eventpicker on sag 1/2, kuparuk, colville, meade, atigun, nested
  yukon basins; save events; play with filters; ALT recession trend vs CALM; scaling
  from nested basins — Evidence: eventpicker.m exists as the intended
  tool. — Intent: multi-basin campaign design. — Rec: keep parked (arctic-leaning
  but exercises toolbox features).
- [ ] **L180-182** — confirm effect of Scrit on dALT/dt derivation wrt partial
  derivatives and wrt S from phi*p*d vs 1/a/(2-b)*Q^(2-b) — Intent:
  derivation audit for the ALT trend theory. — Rec: keep parked.
- [ ] **L183-185** — "find a better way to detect events e.g. ginput (the trib catchment
  has good long recessions but the algorithm doesn't get them b/c of the convexity)"
  — Evidence: manual picking exists (eventpicker.m, ginputc in
  +deps); the convexity-tolerance part is the same thread as L222-224. — Rec: keep
  parked.
- [ ] **L186** — "nail down specific yield" — Intent: settle the
  drainable porosity / specific yield value; literature values recorded in
  bfra_notes.m L68-79. — Rec: keep parked with that row.
- [ ] **L206-210** — reminders: HYSETS has discharge/catchment/SWE/weather data; read
  the esajournals 11-0538.1 paper — Rec: keep parked as references.
- [ ] **L220-221** — "determine baseflow period for each gage — single Aug-Oct window or
  per-gage windows for high latitude" — Intent: seasonal-window
  selection policy for event detection. — Rec: keep parked.
- [ ] **L222-224** — "relax the convex criteria so longer baseflow events get through —
  might need to determine if there are events within a longer event, and then smooth
  over the convex jump" — Evidence: the events-within-events
  mechanism now exists (eventfinder.m:125-179 builds icon/icon2 from d2qdt and
  subdivides), so the detection half is substantially implemented; the
  criteria-relaxation tuning is still open. — Rec: keep parked; verify against
  eventfinder before further work.
- [ ] **L234-237** — open: delineate drainage networks/density re Biswal; build an
  evaluation script for residuals/normality; detrend a/b and plot against PDO;
  consider framing as "we actually test for power law" — Intent:
  large-sample follow-on analyses. — Rec: keep parked; the residual-evaluation
  script idea is toolbox-relevant.
- [ ] **L247-248** — intamap R package for copulas — Rec: keep parked as
  reference.
- [ ] **L251-256** — "the late time behavior doesn't appear to be scale dependent ...
  since it always occurs near the end of events, it could be due to the
  savitzky-golay filter" — Intent: methodological caveat on
  end-of-event dq/dt bias. — Rec: keep parked; candidate for fitets/smoothing
  documentation.
- [ ] **L266-278** — Cheng et al criteria C1-C9 (transcribed) — Intent:
  reference criteria for event extraction, for comparison against the toolbox's
  filters. — Rec: formalize into eventfinder documentation alongside the L351-368
  block and bfra_methods.m criteria; keep parked until then.
- [ ] **L280-301** — StackExchange quotes: NLLS valid for additive normal errors; LLS in
  log space for multiplicative log-normal; error propagation into log space and
  weighted LSQ — Intent: recorded rationale for fitting-method
  choice; underpins the error-model work in sandbox/demo_errormodel/. — Rec: keep
  parked; cite in fitab/fitNLS documentation when the error-model demo is
  formalized.
- [ ] **L307-313** — possible ground-up approach: test -dq/dt and q marginal
  distributions; joint distribution and qmin/qmax; fit events; estimate parameters
  from event-parameter distribution; examine generating mechanisms via the PDE
  (Rupp, Troch 2003) — Intent: methods-paper redesign of the whole
  inference chain. — Rec: keep parked (methods-paper thread).
- [ ] **L316-323** — links: power-law sampling (comsol, GJI, ApJ) and measurement error
  models (umass mepro) — Rec: keep parked as references.
- [ ] **L341-347** — hydrograph-reading notes: use regular years (not water years) so
  sep/oct work; fit lower 5% of sep/oct (maybe aug); jan/feb is one long steady
  recession — could compare winter/summer — Intent: seasonal window
  and lower-envelope strategy; pairs with L220-221. — Rec: keep parked.
- [ ] **L351-368** — "Apply the filters" numbered block (6 filter rules, Brutsaert-style)
  — Intent: transcribed canonical filter description the current
  implementation was built from. — Rec: formalize into eventfinder/eventpicker docs;
  keep parked until then.

### Excluded

- **L14-18** — from d_read_all_data, open items: scattered interpolant to basin
  boundaries; vic data; other met station precip; wind-speed trend (undercatch
  hypothesis) — (arctic-project data pipeline, not this repo) — Rec:
  move to the arctic project if still wanted; delete here.
- **L32-39** — paper edits: move Fig 5 to supp; combine 9/10; cut citations/figure
  refs/printed numbers; DOI under pnnl github; add b=1 result; eq 10 novelty to
  conclusion — (WRR paper published) — Rec: delete.
- **L40-45** — organize raw/annual data into per-basin timetables (getQmin + Merra +
  CALM + GRACE); figure of trend as function of b; early/late time tags —
  (arctic-project analysis infrastructure) — Rec: move to the arctic
  project; the "trend as function of b" figure idea is worth carrying there.
- **L127-129** — limit behavior b=1,2 for the lit review; x->-infty of 1/x^r —
  (paper lit-review task; paper published) — Rec: delete.
- **L162-166** — TODO feb 2020: "make sure the different dALT/dt calculations are
  correct, including the observations ... opposing direction for sag also present in
  kuparuk with dALT(:,2)" — (arctic dALT analysis) — flag:
  unreconstructable-context (dALT(:,2) refers to a workspace array) — Rec: move to
  arctic project or delete.
- **L189-197** — wet-get-wetter flags per basin (annual flow trend sign, quantile
  trends, curran categories, water-year ordering, metadata, category plots) —
  (arctic multi-basin analysis) — Rec: move to arctic project.
- **L215-217** — determine gages with adequate record; fit trends, save slope and
  intercept; make the summary_figs-style figure — (arctic analysis) —
  Rec: move to arctic project.
- **L259-264** — list: lsqcurvefit, lsqnonlin, fit, fitnlm, nlinfit —
  (superseded: the toolbox settled on nlinfit-based fitNLS_matlab.m /
  fitNLS_octave.m in private/) — Rec: delete.
- **L303-304** — "NOTE THAT THIS IS HOW I SHOULD HAVE USED THE ERROR PROPAGATION
  VALUES IN MY LIGHT PENETRATION PAPER!!" — (other project) — Rec:
  delete here; copy to that project if wanted.
- **L333-339** — draft paragraph on basin-scale selection (area X±Y km2 so active
  stream network changes are negligible) — (paper prose fragment,
  incomplete sentence) — Rec: delete.

## sandbox/notes/bfra_notes.m

### Done

- [x] **L52-64** — diagnosis of why the taufit plot differed: "the convex requirement
  ... combined with incorrect inputparsing" — (diagnosis closed by the
  author: "yes that was the problem") — Rec: delete (record only).

### Deferred

- [ ] **L1-49** — filter-experiment log: islineconvex on/off, sgolay on/off, Dralle d2q
  vs concave filter, and the autofilter/rainfilter/easyfilter results table (event q:
  b=1.34/1.37/1.44; fit q: b=1.30/1.33/1.40), concluding "overall, autofilter w/
  event q is best" and "the only situation that appears defensible is easyfilter
  with fits.q" — Intent: empirical tuning record behind the default
  filter choices. — Rec: keep parked; primary source for a future filter-sensitivity
  docs page (with TODO_bfra_old.m L96-98).
- [ ] **L68-79** — drainable porosity / specific yield literature values: Spence et al.
  2010 0.15-0.19 by landcover; Guan et al. 2010 0.15-0.25; the un-found Spence & Woo
  sy=0.13 — Intent: literature grounding for the phi/sy value
  (pairs with TODO_bfra_old.m L186). — Rec: formalize as citations in aquiferprops
  or globalfit documentation.
- [ ] **L84-86** — mean value theorem thought wrt the drainable porosity definition
  (libretexts link) — Rec: keep parked.
- [ ] **L88-96** — revisit Sgrace min after modifying the find-Qmin script; S blows up
  for some stations (b too high?); feb 2022 update on Sref: GRACE and baseflow may
  each need their own Sref — Intent: storage reference-datum design
  for GRACE comparison. — flag: unreconstructable-context (depends on arctic-project
  scripts and station set). — Rec: keep parked in the arctic project.
- [ ] **L114-133** — dALT sensitivity notes: "larger b = larger trend; larger sy =
  smaller trend; flat = smaller trend"; sy=0.1 vs 0.01 equivalence between
  b=1.8/sloped and b=1/flat; two truncated sentences ("for Kuparuk, in order to get
  a signal at all, I have to set"; "for a sloped aquifer, if") — flag:
  unreconstructable-context (both closing sentences cut off mid-thought) — Intent:
  parameter sensitivity of the ALT-trend result. — Rec: keep parked (arctic).

### Excluded

- **L99-110** — station IDs (yukon/kuparuk/colville) and commented load/mapbasins
  scratch — (scratch) — Rec: delete.

## sandbox/notes/bfra_algorithm_structure.m

### Done

- [x] **L2-9** — pipeline maps: current (Aug 2023) `getevents -> eventfinder ->
  eventsplitter -> flattenevents` and `fitevents -> getdqdt -> fitets -> fitab ->
  fitNLS`; old pre-fitevents chain — (documentation of the shipped
  architecture; matches current code: private/ contains findevents, flattenevents,
  fitets, fitNLS_*; eventsplitter has since been folded into eventfinder) — Rec:
  formalize into a developer-docs page; this is the clearest statement of the
  pipeline anywhere in the repo.

### Excluded

- **L11-33** — naming discussion: fitdqdt/getdqdt misnomers; whether wrapevents
  should be renamed getevents/geteventfits; role of wrapevents flattening cell
  arrays with nan separators — (superseded: the fitevents/getevents/
  wrapevents naming shipped and is documented in the current function headers) —
  Rec: delete.

## sandbox/notes/bfra_dimensions.m

### Todo

- [ ] **L1-47** — dimensional analysis: [a] = L^(1-b)/T^(2-b); [dQ/dt]; [1/a][Q^(1-b)] =
  T; S and c dimensions for Q=cS^d; the T1/T2 mismatch when Q is m3/s but dt is
  days; why the code converts m3/s to m3/d — (the TODO_bfra.m L41 item is
  precisely to promote this into the toolbox) — Intent: preserve the units
  convention that downstream storage calculations depend on. — Rec: formalize into
  baseflow.conversions help text or a docs page; the content is load-bearing and
  currently invisible to users.

### Deferred

- [ ] **L49-53** — data caveats: drainage area in km2; station 10ED007 missing darea
  (not in hydat either); "need to compare S in linear to nlin_free to double check"
  the m3/d scaling — flag: unreconstructable-context (linear vs
  nlin_free refers to run configurations of an old multi-basin analysis) — Rec: keep
  parked; carry the 10ED007 fact into any basin-metadata docs.

## sandbox/notes/bfra_methods.m

### Deferred

- [ ] **L6-36** — methods-paper design: research questions (gof/rank-ordering/
  distribution/wetness-correlation sensitivity to methods); summary of what Dralle
  addressed (M/S/C/L) and found; methods Dralle did not address; issues to address
  (MLE fitting bias, scale dependence, base 10 vs e) — Intent:
  outline of the methods paper building on Dralle (same thread as TODO_bfra_old.m
  L74-82). — Rec: keep parked (paper-scale effort).
- [ ] **L40-54** — early dQdt-era notes: use fnder/splinefit for spline derivatives; TLS
  is unbiased for Gaussian noise; "bias-eliminating least squares"; the point that
  gof between Q and dQ/dt is conflated with utility (Qhat vs Q is what matters) —
  Rec: keep parked; the Qhat-vs-Q point deserves a place in the docs'
  methods discussion.
- [ ] **L61-131** — criteria compendium: Evans, Lyons, Kirchner (binning without
  excluding positive dq/dt), Sjoberg/Jachens/Santos placeholders (L96-101 are empty
  headers — never filled), extraction rules E1-E3, parameter estimation P1-P3 —
  Intent: literature criteria survey for the methods comparison. —
  Rec: formalize into documentation with the Cheng criteria; note the
  Sjoberg/Jachens/Santos sections were never written.
- [ ] **L85-94** — step-by-step plan to implement Kirchner's binning (1% log-Q bins,
  widen until stderr < mean/2, fit binned means) — Evidence: no
  binning implementation in toolbox/+baseflow (opts have no bin option). — Intent:
  add binned point-cloud fitting as a method option. — Rec: keep parked; implement
  only if the methods comparison proceeds.
- [ ] **L133-152** — draft methods-comparison option grid: time_stepping {ETS,VTS,NTS},
  parameter_estimation {OLS,MLE,MED}, fit_threshold {5,100}, bin_dqdt; plus the
  full-period-vs-windowed-fit uncertainty question — Evidence:
  private/ has fitets.m, fitvts.m, fitcts.m, fitsts.m, so the time-stepping axis is
  largely built. — Rec: keep parked as the harness design for the methods paper.
- [ ] **L155-181** — Brutsaert & Hiyama 2012 criteria (yL5 5-day running average; three
  sources of subjective error) and "MY CRITERIA" workflow (aug-oct, rainfall id,
  2-d moving average, ETS, per-year lower envelope, Kirchner binning, OLS+MLE; or
  Jachens ETS+median-individual) — Rec: keep parked with the
  criteria compendium.
- [ ] **L184-198** — ideas: sgolay/cubic spline both smooth and differentiate, so
  VTS/ETS may be unnecessary; relax the 7-day minimum for non-ETS fits; weight the
  point cloud (or the aggregation) by the fraction of convex points instead of
  deleting them — Intent: concrete algorithm enhancements. — Rec:
  keep parked; the convex-weighting idea is the most actionable of the three.
- [ ] **L201-212** — methods taxonomy list (event detection, convexity interruption,
  error vs process noise, differentiation, smoothing, five fitting axes) —
  Rec: keep parked (outline material).

### Excluded

- **L214-230** — plot scratch: 1/x vs sqrt(x) reservoir sketch; "might need this
  later" refline/diff snippets — flag: unreconstructable-context
  (operates on undefined workspace variables xexp/yexp/q2) — Rec: delete.

## sandbox/notes/notes_aquiferprops.m

Header: "These were at the end of aquiferprops" — deliberately parked WIP moved out
of toolbox/+baseflow/aquiferprops.m.

### Deferred

- [ ] **L3-55** — expressions to get D directly from alate (RS05 nonlinear late time,
  the Q(t=0) route with Bn = beta((n+2)/(n+3),1/2), RS06 sloped), plus the pick-up
  plan: three whiteboard expressions for D, hope of canceling k/phi, "note that phi
  cancels when setting a1 = a2 so that may be the key", and the derivation of
  Q0 = 4*Bn*L*k*Dd*D^2/((n+3)(n+1)) — flag: unreconstructable-context
  (references the whiteboard state and the RS06 table) — Intent: extend aquiferprops
  to solve for D rather than requiring it as input; the strongest surviving science
  WIP in the sandbox. — Rec: keep parked; when resumed, formalize as a +sym
  derivation script so it is checkable.
- [ ] **L59-107** — PK62/BS04 attempts: the failed three-equation approach ("the answer
  is non sensical"), the realization D cancels, and the corrected set-a1=a2 result
  "D = (1.133/4.804)*sqrt(A*Q0/(k*L^2)) % this is correct" with the Dd-units caveat
  — Intent: record of dead ends and the one believed-correct D
  expression. — Rec: keep parked; verify the "correct" expression symbolically
  before any implementation.
- [ ] **L110-137** — RS05/RS05 exploration: probably a dead end because D appears in
  both early and late a; can get D(Q0,L,k,Dd) leaving k unknown (literature values)
  — Rec: keep parked with the rows above.

## sandbox/notes/bfra_phone_notes.txt

Header says: saved from phone, moved here june 2023; possibly tied to diagnosing
replication.

### Deferred

- [ ] **L13-19** — interpretation ideas: merra/grace mismatch as a bfra success for
  small basins; plot trend vs record midpoint when periods differ; Q*tau/S ratio as
  an applicability/catchment-order measure — Rec: keep parked
  (analysis ideas).
- [ ] **L17** — hypothesis: b>1.5 predictable from active-stream-network change; SOC
  arxiv paper; Biswal predicts b=2; "maybe kuparuk works because the drainage
  network is stable" — Rec: keep parked (research idea).
- [ ] **L35** — "Use mean or median event flow to compute event tau then exclude" —
  flag: unreconstructable-context (sentence cut off; exclude what is
  unrecoverable) — Rec: keep parked only if the eventtau aggfunc work resumes;
  otherwise delete.
- [ ] **L38-56** — nlme design notes: fixed vs random effects for a and b;
  FEParamsSelect; group variables per event (antecedent peak SWE, day of year);
  hierarchical/multilevel framing; the "machine learning layer on top of the theory
  layer" idea; suspicion that the SA algorithm differs because the population may
  not be Gaussian — Evidence: sandbox/test_nlmefit/ holds the
  parked experiments (bfra_nlmefit.m, nlmefit_subjects.m, etc.). — Intent: mixed-
  effects extension of recession fitting. — Rec: keep parked; substantial research
  thread with working scratch code.
- [ ] **L44-48** — "I should then be able to make a point cloud that looks like this:
  [missing embedded image]" — flag: unreconstructable-context (the
  figure did not survive the phone export) — Rec: keep parked with the nlme rows.
- [ ] **L52** — linear vs nonlinear as the hydrologic-change question: if watersheds
  are linear, recession is fixed by geology; "this is a really important insight" —
  Rec: keep parked (framing for the methods/nlme papers).
- [ ] **L58-74** — Hanel exponent bookkeeping: 1+1/(1/N) arithmetic; reconciling
  Hanel's lambda sign convention with b (normalization problem for lambda<=1) —
  Rec: keep parked (theory bookkeeping; feeds the Pareto-tail
  interpretation).

### Excluded

- **L3-9** — alternative phrasings for the "eq. X can be derived from the
  groundwater flow equation" caveat — (paper prose drafting; paper
  published) — Rec: delete.
- **L21-31** — Sean Carroll podcast musings (recurrence theorem, entropy, finite
  states vs superpositions) mapped loosely onto watersheds — (podcast
  notes; no actionable content beyond the Pareto-limits speculation) — Rec: delete.
- **L76** — "Chehalem ridge" — (stray fragment) — Rec: delete.

## sandbox/notes/git-notes-joss-revisions.txt

### Todo

- [ ] **L3-5** — pick-up list: "finish confirming eventplotter works as desired" /
  "maybe check on checkevent" / "commit the move to private" — first two **todo**
  (no completion evidence; eventplotter.m and checkevent.m exist, and checkevent.m
  still ends in commented scratch), the commit is **done** (private/ holds 83
  files) — counted as one todo row and one done row:
  - eventplotter/checkevent confirmation — **todo** — Rec: formalize as tests in
    tests/ for eventplotter and checkevent.
  - private-move commit — **done** — Rec: delete (record only).

### Done

- [x] **L11-14** — Octave private/ concern: "confirm the eventplotter addlistener works
  in octave (if not, need to remove the ylabel set)" plus SO/savannah bug links —
  Evidence: current eventplotter.m contains no addlistener (plain ylabel
  calls at eventplotter.m:167-171); the addlistener pattern survives only in
  hyetograph.m:106-109 inside a MATLAB-only branch. — Rec: delete.
- [x] **L17-23** — PICK UP batch: DONE function signatures for private refactor; DONE
  fix plotalttrend breaking demo_kuparuk; DONE commit private refactor; DONE
  magicParser commit; DONE rename live scripts; DONE address other reviewer
  comments — Rec: delete.

### Excluded

- **L7-9** — plan to move fitphidist to private (callers: globalfit,
  phifitensemble) — (superseded: fitphidist.m remains a public
  +baseflow function) — Rec: delete.
- **L25-37** — reconstructed git commands for already-made commits (demo renames,
  gettingStarted docs, convertlivescripts backup option) — (historical
  command log; commits exist) — Rec: delete.

## sandbox/notes/notes_docs.m

### Done

- [x] **L3-25** — m2html mechanics: how m2html installs its own docs; the abandoned
  plan to relocate makedocs under docs/ ("m2html accepts relative paths only ...
  just make everything relative to the top") — (decision record; makedocs
  lives at +internal/makedocs.m and runs from the top) — Rec: keep parked; move the
  relative-path rationale into makedocs.m's header.

### Deferred

- [ ] **L27-31** — m2html template notes: master.tpl / mdir.tpl / mfile.tpl roles —
  Intent: map of the docs templates (toolbox/docs/templates). — Rec:
  formalize into a comment in makedocs.m or a docs README.
- [ ] **L33-42** — docs tooling survey: m2docgen ("calls builddocsearchdb"), makehtmldoc,
  doxygen-matlab, sphinxcontrib-matlabdomain links — Rec: keep parked
  as reference for any docs-toolchain change (pairs with the jekyll/tossh idea in
  notes_merge_branch.m L189-196).

## sandbox/notes/notes_merge_branch.m

### Done

- [x] **L24-103** — 5 Apr 2023 pre-JOSS move ledger: ~30 DONE moves to +util, 10 DONE
  moves to a validation namespace, 16 DONE moves to +deps, demo .mlx moves,
  smoothnoise to private, fdcurve/hyetograph/trendplot to +baseflow —
  Evidence: the named helpers now live in toolbox/+baseflow/private/ (islineconvex,
  islinepositive, prepCurveData, rmnan, subtight, ...) and +deps. — Rec: delete
  (fully realized; Git history is the durable record).
- [x] **L107-128** — dependency-report decisions: keep m2html (undocumented); loadcalm
  DONE, loadbasins/loadflow/loadghcnd left public; mapbasins/mapgages helper deps;
  r_plfit for plfitb — (decision record; the loadXXX/map functions are
  still public, matching the "keep" outcome) — Rec: delete.
- [x] **L144-147** — Octave renames: stderr -> stderror, printf -> printnum —
  Evidence: private/stderror.m and private/printnum.m exist. — Rec: delete.
- [x] **L149-153** — warning/Octave plan: "might move fitab into a dedicated function
  probably in private; might make separate matlab/octave versions" —
  Evidence: private/fitNLS_matlab.m and fitNLS_octave.m exist; withwarnoff.m
  handles warning state. — Rec: delete.
- [x] **L162-163** — "TODO: add isoctave check to prefs in Setup, see ~/.octave_prefs
  file, and add toolbox checks a la stats/curve fitting" — (first half) —
  Evidence: toolbox/Setup.m has inoctave() (Setup.m:114) gating behavior (L34,94)
  and prefs management (inittoolboxprefs, Setup.m:135-144). Toolbox-availability
  checks: not found — that half remains open. — Rec: keep parked; split out the
  toolbox-checks half if Octave support work resumes.
- [x] **L170-180** — commit choreography batch (git diff for prefix edits, staged
  commits, regenerate Contents.m/functionSignatures/docs; commit +deps/+test/+util,
  Contents, function docs, docsearchdb) — all DONE — Rec: delete.
- [x] **L199-230** — main-stage merge choreography: merged main and dev into
  main-stage, matlab folder compare, "SHOULD BE READY TO MERGE MAIN-STAGE INTO
  MAIN"; post-merge list (clean up Setup DONE; finish baseflow_demo.m; rebuild
  docs; builddocsearchdb?; util-into-private rejected with reason); mpm install
  README instructions DONE — (the merge shipped; v1.0.0 exists per
  final-release-notes.txt) — Rec: delete; preserve only the "util cannot go in
  private because private functions cannot call each other across the boundary"
  rationale (L213) somewhere durable if +internal is ever reorganized.
- [x] **L232-246** — stuff removed from main-stage (peakfinder, eventsplitter notes,
  plotdiag, querymeta, miss_hit, merrafilelist, paper.md/bib — all DONE) plus the
  unresolved "not sure about these: loadXXX / mapbasins / basins database" —
  Evidence: the loadXXX/map functions were kept (still public), so the
  open question resolved itself by retention. — Rec: delete.
- [x] **L249-265** — add-to-dev list: ISSUE_TEMPLATE, license, dependencies to +util,
  icon/icon2 handling in eventsplitter, plplotb nargin=0, remove figformat/macfig
  deps from six functions, copy nancorr — (spot-checked: icon/icon2 logic
  is in eventfinder.m; private/nancorr.m exists; +internal/dependencies.m exists) —
  Rec: delete.
- [x] **L316-347** — Oct 2022 merge reconciliation table (git vs mat folder names,
  DIFF column, custom comparisons for loadcalm/loadmeta/fittau->plfitb/pointcloud)
  — (historical; all renames shipped) — Rec: delete.

### Todo

- [ ] **L16-21** — "pick up on n = 3, event 8, figure out why islinepositive isn't
  working. answer: islinepositive only checks q, not dqdt; fitets can modify the
  data; so, in fitab, might want to apply a check" — Evidence: the check
  is still only a parked comment at fitab.m:592 ("might check metrics such as
  islineconvex(y)..."). — flag: unreconstructable-context for the trigger case
  (n=3, event 8 was debugger state). — Intent: guard fitab against non-recession
  input that slips past event filters. — Rec: implement the guard in fitab;
  reproduce via generateTestData rather than the lost case.
- [ ] **L153** — "fitets might need an islinepositive check on q and/or dq/dt also
  islineconvex" — Same thread as L16-21; no such check visible in
  private/fitets.m. — Rec: implement with the fitab guard, or record the decision
  not to.
- [ ] **L166-167** — "prepalttrend is not used anywhere, may have removed from
  baseflow_kuparuk" — Evidence: private/prepalttrend.m still exists;
  usage unverified. — Intent: dead-code audit candidate. — Rec: verify callers; if
  none, recommend removal in a cleanup pass (do not delete now).

### Deferred

- [ ] **L2-13** — Octave scratch: pkg list syntax, shadowed-function warning, optimset
  defaults — Rec: keep parked as reference.
- [ ] **L155-161** — design note: islinepositive on Q is definitional (not a user
  option) but islinepositive(derivative(Q)) should be a user setting; islineconvex
  is ambiguous ("maybe it should be" a setting — indicates rainfall)
  — Intent: which event filters deserve user-facing options. — Rec: keep parked;
  input to any options redesign.
- [ ] **L184-185** — "batchpleas / test_FMINSPLEAS" — (same item as
  TODO_bfra.m L29) — Rec: keep parked with that row.
- [ ] **L187-196** — docs idea: adopt tossh-style jekyll .md docs instead of
  index.html; would need matlab->md conversion, easiest from live scripts —
  Intent: docs-platform migration to fix the GitHub Pages
  single-page problem (see submission_notes.txt L40-79). — Rec: keep parked; pairs
  with the m2html-alternatives survey.
- [ ] **L273-314** — r2021b replication-failure diagnosis: candidate plan
  (test-getevents-new branch), suspicion of the longer concave tail on event 3,
  "global fit doesn't replicate on main-stage", 173 fits / 2,997 tau values
  reference figures, ecdf change since r2020b — Intent: forensic
  record of the cross-version replication problem; the conclusion landed in
  submission_notes.txt L1 (R2021a K-S statistic differs). — Rec: formalize the
  bottom line into a known-issues docs note (see submission_notes row), then
  delete the forensics.

### Excluded

- **L268-271** — "NEVERMIND move tauexp legend string out of plfitb" with the
  keep-in-function reason (sprintf includes the value) — (explicitly
  withdrawn by the author, reason recorded) — Rec: delete.

## sandbox/notes/notes_warnings_nlinfit.m

### Todo

- [ ] **L1-13** — polished explanation of nlinfit warning classes during recession
  fitting (rankDeficientMatrix, ModelConstantWRTParam for increasing dQ/dt;
  IllConditionedJacobian for convex Q vs -dQ/dt; IterationLimitExceeded) —
  Intent: user-facing documentation of expected warnings; reads as finished prose
  with no home. — Rec: formalize — paste into fitab.m or fitNLS_matlab.m help (or
  the docs FAQ); this is done writing awaiting placement.

## sandbox/notes/stash-notes.txt

### Excluded

- **L1-181** — Aug 2023 git-stash recovery investigation: reconstruction of a
  stash/apply/soft-reset sequence on the joss branch, reflog analysis, the
  git rm / git add recovery lists for the util->private refactor —
  (one-time git surgery, resolved; the refactor it protected is committed —
  private/ holds the files listed at L175-179) — flag: unreconstructable-context
  (depends on branches, stashes, and reflog state that no longer exist) — Rec:
  delete; if any lesson is wanted, it is "use git stash --keep-index / apply
  --index", one line.

## sandbox/notes_bfra_tmp.txt

### Done

- [x] **L1-60** — toolbox dependency audit: which functions need stats/curve-fitting
  (fitdqdt, fitets, fitevents, getdqdt, getevents DONE...), what depends on rxy,
  symbolic (globalfit, plfitb, plvar via zeta/deta), signal processing
  (findchangepts via plotdqdt), deep learning (plotfit with MiP), matlab-only list
  — (audit complete; its product is +internal/dependencies.m and the
  tested-dependency story in tests/test_dependencies.m) — Rec: keep parked; the
  root-cause notes (L57-59: which call pulls in which toolbox) are worth folding
  into dependencies.m comments.
- [x] **L94-98** — tag 0.1.0 comparison r2021b vs r2022b: point cloud same, difference
  due to tau0, pareto fit also differs — (superseded root cause recorded
  in submission_notes.txt L1: the R2021a K-S statistic) — Rec: delete after the
  known-issues note exists.

### Deferred

- [ ] **L70-83** — Octave pkg install/load-on-startup notes (struct/statistics/optim,
  SO link) — Rec: keep parked with the other Octave reference
  notes.
- [ ] **L90-92** — "need to add this to fminspleas / batchminspleas if it isn't
  already: y = ax^b, f = {@(c,x) c(1)*x^c(2)}" — Evidence:
  fminspleas was never adopted into the toolbox. — Rec: keep parked with the
  TODO_bfra.m L29 row.
- [ ] **L100-151** — opts struct dumps for r2022b:joss — the canonical Kuparuk
  parameter sets for getevents (qmin=1, nmin=4, rmax=2, rmrain=1, ...), fitevents
  (ETS, etsparam=0.2, nls, free), globalfit (aquiferdepth=0.47, drainagedens=0.8,
  earlyqtls=[.95 .95], lateqtls/refqtls=[.5 .5], phimethod=pointcloud,
  streamlength=6923600, drainagearea=8.6545e9) — Intent: recorded
  reference configuration that produced the published results. — Rec: formalize as
  a test fixture / example (compare against setopts defaults and the kuparuk demo);
  do not delete until captured.
- [ ] **L156-187** — joss-vs-tag pipeline diff walkthrough: Events.q provenance,
  datetime-vs-datenum tsave, smoothflow namespacing, "the diff is probably in
  fitets"; for-loop vs while-loop comparison (old q higher, new dqdt higher, +1 day
  shift; while-loop nearly identical but truncated 1-3 values) —
  flag: unreconstructable-context (compares two working trees that no longer
  exist) — Intent: replication forensics; the observed 1-3 sample truncation is a
  concrete behavioral fact about the fitets loop rewrite. — Rec: keep parked until
  the known-issues note is written, then delete.

### Excluded

- **L62-65** — requiredFilesAndProducts snippet — (scratch; the
  technique lives in +internal/dependencies.m) — Rec: delete.
- **L190-242** — old-naming opts dumps (opts.Events/opts.Fits/opts.Global) —
  (superseded by the L100-151 dumps and current setopts) — Rec:
  delete.

## sandbox/ReplaceArrowNotes.m

### Deferred

- [ ] **L1-11** — "I searched for annotation and nothing came up. These are the ones
  that use arrow: plotrefline, fitphidist, gpfitb, plplotb, plotdqdt" —
  Intent: preparation for replacing the +deps arrow.m dependency with a built-in
  (annotation was investigated and rejected). — Rec: keep parked; the call-site
  list is the useful artifact if arrow replacement is attempted again.

## sandbox/octave_compat.txt

### Done

- [x] **L3-25** — datenum/datetime compatibility work for getevents/fitevents/fitets;
  prepareCurveData -> bfra.util.prepCurveData; try-catch and PartialMatching
  removals for Octave — Evidence: private/prepCurveData.m exists;
  private/fitets.m handles both paths. — Rec: delete (record only).
- [x] **L26-27** — "PICK UP HERE - omitnan is not supported by movmean [in Octave],
  need a replacement b/c it will very much change the result (I get 325 events on
  octave and around 230 on matlab)" — Evidence:
  eventfinder.m:117-119 branches to private/nanmovmean.m under Octave. — Residual:
  whether the nanmovmean branch actually reconciles the 325-vs-230 event count was
  never re-verified in these notes. — Rec: formalize a cross-platform event-count
  check in tests/ if Octave support is still claimed; otherwise delete.
- [x] **L103-186** — request to rewrite hyetograph with plotyy instead of yyaxis, with
  the old yyaxis implementation pasted — Evidence: hyetograph.m:66 uses
  plotyy; the yyaxis version survives as comments in that file (hyetograph.m:179+).
  — Rec: delete.

### Deferred

- [ ] **L28-49** — Octave solver mapping: nlinfit is octave-optim vs matlab-stats;
  optimset works with nlinfit for overlapping options; statset options recognized
  by octave nlinfit (DerivStep/Display/MaxIter/TolFun); 'Weights' accepted; "BUT
  remember ... i could pass in the weights instead of using robust option" —
  Intent: the weights-instead-of-robust idea connects to
  sandbox/demo_errormodel/. — Rec: keep parked with the error-model thread; the
  solver mapping facts could annotate fitNLS_octave.m.

### Excluded

- **L52-57** — "NOTE: need to remove this from fitets i think: if inoctave
  opts=optimset... else opts=statset..." — (superseded: the block was
  kept deliberately — fitets.m:40-49 now caches it in a persistent variable) —
  Rec: delete the note.
- **L60-101** — liboctinterp.11.dylib version-mismatch troubleshooting (8.1.0 vs
  8.2.0 paths, symlink fix, pkg reinstalls) — (machine-specific
  environment repair, resolved) — Rec: delete.

## sandbox/joss/paper_notes.md

### Deferred

- [ ] **L11** — "`baseflow` ... would benefit from incorporating some of the signatures
  provided by `TOSSH` [which would] likely increase its appeal" —
  Evidence the idea has legs: toolbox/data/tossh exists and
  sandbox/tests/test_tossh_data.m is a started experiment. — Intent: TOSSH
  signature integration as a feature direction. — Rec: keep parked; promote to a
  bead if feature work resumes.

### Excluded

- **L1-31** — JOSS paper drafting: state-of-the-field survey (HYDRORECESSION,
  TOSSH), features section drafts, theory-assumptions paragraph —
  (paper published; prose absorbed or superseded) — Rec: delete, except the next
  row.
- **L31-72** — JOSS template leftovers (math/citation/figure syntax examples) —
  (template boilerplate) — Rec: delete.

## sandbox/joss/notes-revisions-Sep-2023.txt

### Excluded

- **L1-37** — reviewer-response drafting: five successive rewrites of the baseflow
  definition paragraph, converging on the L31 version (aquifers, recession curve
  as aquifer drawdown, properties: hydraulic conductivity, drainable porosity,
  saturated zone thickness) — (revision complete; the final text
  shipped in the published paper) — Rec: delete; if any docs page needs a baseflow
  definition, lift the L31 paragraph first.

## sandbox/joss/submission_notes.txt

### Todo

- [ ] **L1** — "On R2021a, the K-S statistic calculation that determines the best-fit
  Pareto distribution produces a different result than all other tested Matlab
  versions (R2020b, R2021b, R2022b). The results in bfra_kuparuk.mlx will
  therefore not replicate the html help files or the figures in Cooper et al.
  2023." — Intent: a user-facing replication caveat that currently
  lives only in a sandbox note. — Rec: formalize into README/known-issues docs;
  this is the distilled conclusion of the replication forensics in
  notes_merge_branch.m and notes_bfra_tmp.txt.

### Deferred

- [ ] **L35** — plain-language description of the paper and software (Pareto lifetime
  of streamflow, permafrost storage) — Intent: reusable
  general-audience summary. — Rec: keep parked; good source text for README or
  docs landing page.
- [ ] **L40-79** — GitHub Pages problem: docs/index.html (copy of
  bfra_gettingStarted.html) is the only published page; helptoc.xml table of
  contents (welcome, getting started, function index, 3 examples, 2 theory pages)
  is not navigable on GitHub — Intent: publish the full help set on
  GitHub Pages. — Rec: keep parked; solved properly by the jekyll/tossh docs idea
  (notes_merge_branch.m L187-196); verify current state of the published site
  before working it.

### Excluded

- **L3-31** — JOSS reviewer candidate lists — (submission logistics,
  complete) — Rec: delete.

## sandbox/joss/final-release-notes.txt

### Excluded

- **L1-37** — v1.0.0 release post-mortem: TLDR (stale version/DOI in CITATION.cff
  across v1.0.0-joss-branch and v1.0.0; three throwaway commits; should have
  reserved a Zenodo DOI first; deleting a GitHub release does not delete its tag)
  plus the never-executed cleanup plan (reset to commit 1, delete releases,
  reserve DOI, re-release) — (the releases stand and are cited;
  rewriting them now would break the JOSS/Zenodo record) — Rec: keep parked as a
  release-process lesson; better, distill L1-7 into a release checklist if the
  next tagged release approaches, then delete the rest.
- **L40-90** — repeated partial retellings of the same event sequence —
  (redundant drafts of the section above) — Rec: delete.

## sandbox/joss/Untitled-1.md

### Excluded

- **L1-99** — draft copy of the JOSS paper markdown (front matter with authors,
  affiliations, "DD February YYYY" date placeholder) — (superseded by
  the published paper; the repo has a top-level paper/ directory) — Rec: delete
  after confirming paper/ holds the final source.

---

## Cross-cutting observations

1. Recurring open science thread: eliminate the D/phi circularity
   (TODO_bfra.m L72-76, TODO_bfra_old.m L26-28, notes_aquiferprops.m throughout).
   These belong together in any future planning record.
2. Recurring open engineering threads: inputParser removal (64 files), useax ->
   parsegraphics (4 files), per-function examples (7/67), Copyright lines (1/67),
   fitab/fitets non-recession guard (parked at fitab.m:592).
   Correction (2026-09-13, R3 sweep records#21): inputParser stays.
   STYLE.local.md keeps inputParser and bars `arguments` blocks in core
   analysis functions and demos, because Octave cannot parse them. Bead
   bfra-3kh.13 added 16 Example sections, so 23 of the 66 public
   functions carry examples and 43 remain (see the Example sections stub
   above). Working-tree anchor for fitab.m:592: fitab.m:602. This
   correction supersedes "inputParser removal (64 files)" and
   "per-function examples (7/67)".
3. Two pieces of finished writing await placement, not work:
   notes_warnings_nlinfit.m (nlinfit warning explanation) and
   submission_notes.txt L1 (R2021a replication caveat).
4. The kuparuk opts dumps in notes_bfra_tmp.txt L100-151 are the only recorded
   copy of the published-results configuration; capture before any sandbox
   cleanup.
5. sandbox/notes/git_notes.pptx was not mined (binary); flag for manual review.

## W1 code-marker inventory — baseflow toolbox production code

Scope: `toolbox/` (the `+baseflow` package, subpackages, `private/` folders,
`Setup.m`, `toolbox/demos`). Excludes `sandbox/` and generated `docs/html`.
Source: `grep -rniE '\b(TODO|FIXME|XXX|HACK|WIP)\b|\bBUG\b' toolbox --include='*.m'`
(35 raw matches), plus a sweep of `toolbox/demos` (`.m` and unzipped `.mlx`)
and non-`.m` files. Every genuine marker was read in surrounding context.
Bead: bfra-3kh.19, DesignSpec area W1. Date: 2026-08-30.

## Summary

| Classification | Count |
| --- | --- |
| done | 1 |
| todo | 4 |
| deferred | 17 |
| excluded (obsolete) | 1 |
| **Total genuine markers** | **23** |

Reclassification after consolidation: beads bfra-3kh.23 and bfra-3kh.27
resolved the fitcts.m:71 and loadcalm.m:254 markers, and the R3 sweep
(2026-09-13, finding records#13) moved both rows from Todo to Done. The
current counts are done 3 and todo 2; the table above keeps the
consolidation counts.

Raw grep matches: 35 in `.m` files. 12 are false positives or prose
references (listed at the bottom). Demos contain no genuine markers.

## Markers by category

### Done

- [x] **toolbox/+baseflow/private/bootstrapci.m:26** `% Just call isoctave. TODO: check if function overhead matters.`
  - **marker**: `% Just call isoctave. TODO: check if function overhead matters.`
    (followed by a commented-out `persistent inoctave` caching block)
  - **context**: same function; the marker sits above a disabled
    persistent-variable cache for the `isoctave` result.
  - **classification rationale**: the "just call isoctave" decision demonstrably
    happened: line 65 calls `isoctave` directly, once per invocation, and the
    caching alternative stays commented out. Only the micro-benchmark question
    ("does overhead matter") was never answered.
  - **inferred intent**: decide between a direct `isoctave` call and a
    persistent cache; direct call won.
  - **recommendation**: delete-the-marker (and the dead cache block with it) —
    one call per `bootstrapci` invocation cannot matter; no fragility encoded.

- [x] **toolbox/+baseflow/private/fitcts.m:71** `rq = []; % TODO`
  - **resolved (2026-08-30, bead bfra-3kh.23)**: fitcts is implemented;
    rq returns the rain aligned with the returned time vector, matching
    the ETS convention. See the fitcts stub section above.
  - **marker**: `rq = []; % TODO`
  - **context**: `fitcts` (H1 line: "fit q/dqdt using constant time step. not
    implemented.") computes dq/dt by finite differences; `rq` is the
    rain-during-event output that every sibling fitter returns. It is returned
    empty to `getdqdt.m:63`, which forwards it downstream.
  - **classification rationale**: the empty `rq` is a live gap on a reachable
    path (`getdqdt` exposes `ctsmethod` as a parameter), and downstream code
    that consumes `rq` gets `[]` with no warning.
  - **inferred intent**: subset `R` onto the derivative time vector the way
    `fitets`/`fitvts` do, so the cts path returns real rain values.
  - **recommendation**: keep parked with the function's broader
    "not implemented" status, or implement `rq` if the cts path is ever
    promoted; do not delete the marker while `rq` stays empty.

- [x] **toolbox/+baseflow/loadcalm.m:254** `% temp hack to check against the og list`
  - **resolved (2026-08-30, R2 settled decision, bead bfra-3kh.27)**: keep
    and document. The CALM source data changed and the published results
    must stay reproducible with the original nine sites; the pin is
    documented in the function help and the block comment. The optional
    site-selection input is a deferred row in the loadcalm stub section.
  - **marker**: `% temp hack to check against the og list`
  - **context**: active code in `loadcalm` (loads CALM active-layer data):
    when the basin is `'KUPARUK R NR DEADHORSE AK'`, it filters the CALM table
    to a hardcoded nine-site list (`U11A ... U32B`) — the "og" (original) site
    list — overriding whatever the site-selection logic above returned.
  - **classification rationale**: this is live behavior for the flagship basin,
    labeled temporary; it silently changes results for anyone loading Kuparuk
    CALM data and needs a decision (promote to documented behavior with a
    reason, or remove once the general site selection is trusted).
  - **inferred intent**: reproduce the site set used in the original/published
    analysis while the newer metadata-driven selection was validated.
  - **recommendation**: keep parked until deliberately resolved — the marker
    flags that Kuparuk output depends on this override; deleting the marker
    without a decision would hide a reproducibility-sensitive filter.

### Todo

- [ ] **toolbox/+baseflow/loadbasins.m:31** `% TODO: accept stationname. see loadcalm, it worked as soon as i added support`
  - **marker**: `% TODO: accept stationname. see loadcalm, it worked as soon as i added support`
    (continues: relies on the basinname returned by loadmeta; doing that with
    boundaries "would simplify thigns here")
  - **context**: `loadbasins` loads basin boundary shapefiles by basin name;
    the marker sits between the no-input open-file shortcut and input parsing.
  - **classification rationale**: actionable; `loadcalm` proves the pattern
    (stationname support landed there via `baseflow.loadmeta`).
  - **inferred intent**: let callers pass a USGS station name, not only the
    basin name, by routing through the same `loadmeta` lookup `loadcalm` uses.
  - **recommendation**: implement — a working precedent exists in `loadcalm`;
    low effort, real API convenience.

- [ ] **toolbox/+baseflow/private/bootstrapci.m:23** `% TODO` / `% add a check if x has a column of ones and add one if not`
  - **marker**: `% TODO` / `% add a check if x has a column of ones and add one if not`
  - **context**: `bootstrapci` (adapted from Aslak Grinsted's quantreg code)
    bootstraps confidence intervals by resampling residuals; it assumes the
    design matrix `x` already carries an intercept column.
  - **classification rationale**: a genuine robustness gap, though low risk
    today because the only caller (`private/quantreg.m:116`) builds `x`
    correctly.
  - **inferred intent**: guard against callers passing a design matrix without
    an intercept column, which would silently misfit.
  - **recommendation**: keep parked — single well-behaved caller; implement the
    guard only if `bootstrapci` gains callers.

### Deferred

- [ ] **toolbox/+baseflow/pointcloudintercept.m:22** `% TODO: consider making this a call to fitab. however, fitab does not return xbar/ybar, and I confirmed the results are identical, but it would be preferable to reduce the potential for inconsistent methods ...`
  - **marker**: `% TODO: consider making this a call to fitab. however, fitab does not return xbar/ybar, and I confirmed the results are identical, but it would be preferable to reduce the potential for inconsistent methods ...`
  - **context**: `pointcloudintercept` estimates the point-cloud intercept
    parameter `a` for a fixed slope `b`; it duplicates a fit that `fitab`
    also performs.
  - **classification rationale**: a consolidation, verified equivalent today,
    but the marker records a real divergence risk (two code paths that must
    agree on the fitting method).
  - **inferred intent**: delegate to `fitab` once `fitab` returns
    `xbar`/`ybar`, so one function owns the fit.
  - **recommendation**: keep parked — the marker encodes why the duplication is
    fragile (silent method divergence); do not delete without the refactor.

- [ ] **toolbox/+baseflow/+internal/dependencies.m:212** `% TODO: add method to clone from https://github.com/mgcooper/matfunclib`
  - **marker**: `% TODO: add method to clone from https://github.com/mgcooper/matfunclib`
  - **context**: inside `resolvedependencies`, which builds the
    missing-dependencies report and directs users to matfunclib for missing
    functions.
  - **classification rationale**: its fate hangs on the bfra-3kh.25
    vendor/gate/de-advertise decision tracked in `TODO.md`; auto-cloning may be
    mooted if the remaining externals are vendored or removed.
  - **inferred intent**: automate fetching missing helper functions from
    matfunclib instead of telling the user to download them.
  - **recommendation**: keep parked until the bfra-3kh.25 dependency decision
    resolves; then implement or delete with that decision.
  - **working-tree anchor (2026-09-13, R3 sweep dependencies#11)**:
    `dependencies.m:367`, inside `resolvedependencies`.
  - **working-tree anchor (2026-09-13, R3 repair)**: `dependencies.m:225`,
    inside `resolvedependencies`. This anchor supersedes 367.

- [ ] **toolbox/+baseflow/aQbString.m:47** `% TODO: merge this with baseflow.strings. See note below about $ after = sign.`
  - **marker**: `% TODO: merge this with baseflow.strings. See note below about $ after = sign.`
  - **context**: `aQbString` builds the latex string for -dQ/dt = aQ^b
    annotations; a sibling latex-string builder exists as
    `toolbox/+baseflow/getstring.m` (no `baseflow.strings` exists — the target
    name is stale, likely renamed to `getstring`).
  - **classification rationale**: the consolidation is still sensible but not
    near-term; the marker also points at a latex-rendering subtlety (`$` after
    the `=` sign) documented further down.
  - **inferred intent**: fold `aQbString` into the shared string builder so
    latex conventions live in one place.
  - **recommendation**: keep parked — update the stale name to `getstring` if
    touched; the `$`-placement note is trap knowledge worth keeping.

- [ ] **toolbox/+baseflow/fitevents.m:48** `% TODO: move subfunctions to private/ to manage warnings, input parsing, and special-case fitting routines including octave compatibility once, here. This will be most problematic for fitab, because it is useful as a standalone function ...`
  - **marker**: `% TODO: move subfunctions to private/ to manage warnings, input parsing, and special-case fitting routines including octave compatibility once, here. This will be most problematic for fitab, because it is useful as a standalone function ...`
  - **context**: `fitevents` fits all detected recession events; it duplicates
    warning management and Octave special-casing that its subfunctions repeat.
  - **classification rationale**: a real architecture cleanup, but the marker
    itself records why the obvious move is hard (`fitab` must stay public).
  - **inferred intent**: centralize warning/input/Octave handling in one
    private layer without demoting `fitab` from the public API.
  - **recommendation**: keep parked — the fitab constraint is the trap; any
    future refactor should start from this note.

All five markers are upstream FIXMEs in a vendored Octave-Forge function
(Copyright 2013 Erik Kjellson, GPL). Note: the only call site in the toolbox
is commented out (`private/smoothflow.m:13`); the Octave branch uses
`nanmovmean` instead, and the MATLAB branch uses `smoothdata`. The file is
currently dead code kept for a possible Octave sgolay path.

- [ ] **toolbox/+baseflow/private/smooth.m:218** `%# FIXME: Check how Matlab takes care of the beginning and the end. Reduce polynomial degree?`
  - **marker**: `%# FIXME: Check how Matlab takes care of the beginning and the end. Reduce polynomial degree?`
  - **context**: the `'sgolay'` case; the loop hand-rolls edge handling at the
    start and end of the series, where the fit window cannot be centered.
  - **classification rationale**: upstream note; edge behavior may differ
    from MATLAB's `smooth`, which matters for recession analysis because event
    endpoints are exactly the edges.
  - **inferred intent**: verify edge-window behavior matches MATLAB before
    trusting sgolay output near series boundaries.
  - **recommendation**: keep parked — this is trap-avoidance knowledge about
    edge effects; revisit only if `smoothflow` re-enables this code path.

- [ ] **toolbox/+baseflow/private/smooth.m:248** `%# FIXME: implement smoothing method 'lowess'`
  - **marker**: `%# FIXME: implement smoothing method 'lowess'`
  - **context**: the `'lowess'` switch case, which raises
    `error('smooth: method ''lowess'' not implemented yet')`.
  - **classification rationale**: upstream feature gap; the error guard makes
    the gap explicit, and no toolbox code requests this method.
  - **inferred intent**: port MATLAB's lowess smoother to the Octave function.
  - **recommendation**: keep parked — the error path is the correct behavior
    until someone needs lowess under Octave.

- [ ] **toolbox/+baseflow/private/smooth.m:253** `%# FIXME: implement smoothing method 'loess'`
  - **marker**: `%# FIXME: implement smoothing method 'loess'`
  - **context**: same pattern — the `'loess'` case raises a not-implemented
    error.
  - **classification rationale**: same upstream gap, unused method.
  - **inferred intent**: implement loess under Octave.
  - **recommendation**: keep parked.

- [ ] **toolbox/+baseflow/private/smooth.m:258** `%# FIXME: implement smoothing method 'rlowess'`
  - **marker**: `%# FIXME: implement smoothing method 'rlowess'`
  - **context**: same pattern — `'rlowess'` raises a not-implemented error.
  - **classification rationale**: same upstream gap, unused method.
  - **inferred intent**: implement robust lowess under Octave.
  - **recommendation**: keep parked.

- [ ] **toolbox/+baseflow/private/smooth.m:263** `%# FIXME: implement smoothing method 'rloess'`
  - **marker**: `%# FIXME: implement smoothing method 'rloess'`
  - **context**: same pattern — `'rloess'` raises a not-implemented error.
  - **classification rationale**: same upstream gap, unused method.
  - **inferred intent**: implement robust loess under Octave.
  - **recommendation**: keep parked.

- [ ] **toolbox/+baseflow/globalfit.m:33** `% TODO make the inputs more general, rather than these hard-coded structures and tables`
  - **marker**: `% TODO make the inputs more general, rather than these hard-coded structures and tables`
  - **context**: `globalfit` estimates global-fit parameters (tau, phi, pQexp)
    from event fits; its interface expects the specific structures produced by
    the standard workflow (`Events`, `Fits`, opts from `setopts`).
  - **classification rationale**: an API-generalization wish, not blocking the
    documented workflow.
  - **inferred intent**: accept looser inputs so `globalfit` can run outside
    the packaged Events/Fits pipeline.
  - **recommendation**: keep parked — revisit with any interface redesign
    (pairs with the `aquiferprops.m:126` marker).

- [ ] **toolbox/+baseflow/eventpicker.m:29** `% TODO: compare subfunction eventPlotter here to baseflow.eventplotter and to versions in dev-bk. Cursory glance - eventPlotter includes option to plot rain, but does not include 3rd subplot of d2q/dt in baseflow.eventplotter`
  - **marker**: `% TODO: compare subfunction eventPlotter here to baseflow.eventplotter and to versions in dev-bk. Cursory glance - eventPlotter includes option to plot rain, but does not include 3rd subplot of d2q/dt in baseflow.eventplotter`
  - **context**: `eventpicker` supports manual event picking and carries a
    private `eventPlotter` subfunction that overlaps `baseflow.eventplotter`.
  - **classification rationale**: the in-repo comparison (subfunction vs.
    `baseflow.eventplotter`) is still real duplicated logic; the `dev-bk`
    reference is stale (no `dev-bk` exists anywhere in the repository).
  - **inferred intent**: reconcile the two plotters into one (rain option plus
    the d2q/dt subplot) and delete the duplicate.
  - **recommendation**: keep parked — the marker already records the feature
    diff between the two implementations; drop the `dev-bk` clause whenever the
    comment is next touched.

- [ ] **toolbox/+baseflow/loadgrace.m:41** `%       % temporary hack to get the 2022 data`
  - **marker**: `%       % temporary hack to get the 2022 data`
  - **context**: a fully commented-out block in `loadgrace` that loaded a
    Kuparuk-specific 2022 GRACE file, renamed/removed variables, and
    re-normalized it; the active code below carries the note "delete this and
    replace w/above if using 2022 data".
  - **classification rationale**: inert code, but it documents both how to
    switch to the 2022 dataset and the normalization trap (other data is
    normalized to 2002-2020; the 2022 file is not and must be demeaned).
  - **inferred intent**: keep a ready-made path to the 2022 GRACE data until it
    is integrated properly.
  - **recommendation**: keep parked — the normalization mismatch note is
    trap-avoidance knowledge; deleting the block without integrating 2022 data
    properly would lose it.

- [ ] **toolbox/+baseflow/aquiferprops.m:126** `% TODO move 'soln' before or after phi, accept opts.globalfit for A,D,L, and possibly phi, try to combine with fitphi for two paths - either D is known or phi is known`
  - **marker**: `% TODO move 'soln' before or after phi, accept opts.globalfit for A,D,L, and possibly phi, try to combine with fitphi for two paths - either D is known or phi is known`
  - **context**: `aquiferprops` estimates aquifer depth/hydraulic conductivity;
    the marker follows a long comment block recording how the BS04 vs RS05
    early-time solutions respond to parameter choices (BS04 much more sensitive
    to k than RS05).
  - **classification rationale**: an API/architecture redesign
    (aquiferprops + fitphi unification), valuable but not near-term.
  - **inferred intent**: restructure the signature so the caller supplies
    either D or phi, share globalfit outputs, and merge the two estimation
    paths with `fitphi`.
  - **recommendation**: keep parked — the surrounding sensitivity notes are
    hard-won solver knowledge; keep marker and notes together.

- [ ] **toolbox/+baseflow/basinname.m:27** `% Todo: 'ALL_BASINS' should return all of the basin names, see baseflow.stationlist which appends 'ALL_BASINS' to the stationlist for use with loaddata functions`
  - **marker**: `% Todo: 'ALL_BASINS' should return all of the basin names, see baseflow.stationlist which appends 'ALL_BASINS' to the stationlist for use with loaddata functions`
  - **context**: `basinname` validates/returns a basin name; today
    `basinname('ALL_BASINS')` returns the literal sentinel string, and the
    loaders (`loadbasins`, `loadcalm`) each expand the sentinel themselves.
  - **classification rationale**: a design alternative (expand the sentinel at
    the source instead of in every loader); current sentinel flow works and is
    documented in the help text.
  - **inferred intent**: centralize ALL_BASINS expansion in `basinname` so
    loaders stop special-casing the sentinel.
  - **recommendation**: keep parked — changing the return type
    (char -> cellstr) is a compatibility break for every sentinel consumer;
    the marker records that coupling.

- [ ] **toolbox/+baseflow/fitab.m:141** `% TODO: replace this with octave compatible fitting`
  - **marker**: `% TODO: replace this with octave compatible fitting`
  - **context**: inside subfunction `fitOLS` (ordinary least squares in
    log-log space); under Octave it raises
    `error('ordinary least squares not currently supported in octave, use nls')`
    because it depends on Curve Fitting Toolbox `fittype`/`fit`.
  - **classification rationale**: genuine Octave-compatibility gap with an
    explicit error guard and a working alternative (`nls`) in place.
  - **inferred intent**: reimplement weighted OLS with `polyfit`-class
    primitives so the `ols` method works under Octave.
  - **recommendation**: keep parked — implement if Octave parity becomes a
    goal; the error guard keeps current behavior honest.

- [ ] **toolbox/+baseflow/+deps/ktaub.m:120** `%  Note:  if data are not temporally evenly spaced, Sen's slope becomes inaccurate (a future TODO).`
  - **marker**: `%  Note:  if data are not temporally evenly spaced, Sen's slope becomes inaccurate (a future TODO).`
  - **context**: header of the vendored third-party Mann-Kendall/Sen's slope
    function (Jeff Burkey); documents a known limitation of the implementation.
  - **classification rationale**: upstream limitation statement in a vendored
    dependency; not baseflow's code to fix, but the caveat matters for callers
    passing gappy annual series.
  - **inferred intent**: warn users (and a future maintainer) that uneven time
    spacing degrades the Sen's slope estimate.
  - **recommendation**: keep parked — this is exactly the trap-avoidance kind
    of marker; removing it would hide a correctness caveat.

- [ ] **toolbox/+baseflow/wrapevents.m:10** `... TODO: construct an adaptive sgolay filter that adjusts the filter parameters on an annual (or shorter) basis.`
  - **marker**: `... TODO: construct an adaptive sgolay filter that adjusts the filter parameters on an annual (or shorter) basis.`
  - **context**: header of `wrapevents`, which wraps `baseflow.getevents` to
    process one year at a time precisely so the Savitzky-Golay noise filter
    sees per-year measurement variability.
  - **classification rationale**: a research/algorithm idea; the annual
    wrapper is the current workaround and the marker explains why it exists.
  - **inferred intent**: replace the one-year-at-a-time workaround with a
    filter that adapts its parameters to local variability.
  - **recommendation**: keep parked — the marker documents the rationale for
    the wrapper's whole design; keep until an adaptive filter exists.

### Excluded

- **toolbox/+baseflow/plotaquifertrend.m:73** `% TODO: Replace with set/get`
  - **marker**: `% TODO: Replace with set/get`
  - **context**: `plotaquifertrend` styles trendplot handles after plotting;
    the lines below assign `Color`/`FaceColor`/`LineWidth` via dot indexing on
    handle objects.
  - **classification rationale**: (obsolete) — dot indexing on graphics handles
    is the current recommended MATLAB style; converting to `set`/`get` would be
    a step backward, and the code works as written.
  - **inferred intent**: batch the property assignments through `set` calls,
    an older stylistic preference.
  - **recommendation**: delete-the-marker — the marked work no longer reflects
    preferred practice and encodes no trap knowledge.

## Excluded matches (false positives)

- `toolbox/+baseflow/+deps/arrow.m:148,154,155,163,164,165` — third-party
  changelog entries ("Fixed bug ...") describing past fixes, not WIP.
- `toolbox/+baseflow/+deps/arrow.m:1012` — comment explaining an in-place
  workaround for a MATLAB 6.x OpenGL defect in third-party code; historical,
  not actionable WIP.
- `toolbox/+baseflow/+internal/dependencies.m:106,114` — prose referencing
  the `TODO.md` tracking file (vendor-or-remove decision, bead bfra-3kh.25),
  not markers themselves.
  - correction (2026-09-13, R3 sweep dependencies#11 and records#3): the
    one `TODO.md` reference in `dependencies.m` is the prose at 137-143.
    It names the pending entry points and their vendor, gate, or
    de-advertise decision (bead bfra-3kh.25). The `r_plfit` comment at
    `dependencies.m:160-166` cites the R2 settled decision (keep
    `r_plfit` external; README Requirements) and does not reference
    `TODO.md`. This correction supersedes "106,114" and "vendor-or-remove
    decision".
  - working-tree anchors (2026-09-13, R3 repair): the `TODO.md`
    reference is the prose at `dependencies.m:122-126`, and the
    `r_plfit` comment is at `dependencies.m:108-112`. These anchors
    supersede 137-143 and 160-166.
- `toolbox/Setup.m:349` — the word "bug" in prose describing a defect in
  MATLAB's built-in `requiredFilesAndProducts` (over-reports products); an
  explanation, not a work marker.
  - working-tree anchor (2026-09-13, R3 sweep dependencies#11):
    `Setup.m:368`.
  - working-tree anchor (2026-09-13, R3 repair): `Setup.m:355`. This
    anchor supersedes 368.
- `toolbox/Setup.m:377,380` — prose and a printed user message referencing
  `TODO.md`; not markers.
  - correction (2026-09-13, R3 sweep dependencies#11): `Setup.m` holds no
    `TODO.md` reference. The not-satisfied message at `Setup.m:402-406`
    points to the baseflow issues page. This row matches no line in the
    working tree.
  - correction (2026-09-13, R3 repair): `Setup.m` holds two `TODO.md`
    references. The prose is at `Setup.m:382-383`, and the printed
    pending-decision note is at `Setup.m:385-386`. The not-satisfied
    message at `Setup.m:373-378` points to matfunclib and the baseflow
    issues page. This correction supersedes "`Setup.m` holds no
    `TODO.md` reference" and "This row matches no line in the working
    tree".
- `toolbox/demos/baseflow_demo_1.mlx`, `baseflow_demo_kuparuk.mlx` — grep
  hits inside base64-encoded output blobs in the zipped live-script XML; not
  text markers (the plain `.m` twins in `toolbox/demos/mfiles/` contain no
  markers).
- `toolbox/docs/html/**` — m2html-generated HTML copies of the source
  docstrings above plus binary search-index files; duplicates of already
  inventoried markers, and generated output is out of scope.

## W1 disabled-block inventory — baseflow toolbox

Bead: bfra-3kh.19 (DesignSpec area W1). Date: 2026-08-30.
Scope: production code under `toolbox/` (`+baseflow` and subpackages, `private/`
folders, `Setup.m`). Excluded: `sandbox/`, `docs/`, `tests/`, and the 28
function help headers (docstrings with usage examples) that a comment-run scan
also matches. Method: scan for runs of 5 or more consecutive comment lines
whose stripped content is code-like (assignments, calls, control flow), then
read each block in its surrounding function. All paths are relative to
`/Users/mattcooper/MATLAB/projects/bfra`.

Nothing is deleted in this phase. Every recommendation is a recommendation only.

## Summary

| Classification | Rows |
|---|---|
| done (superseded by live code) | 28 |
| todo (unfinished feature worth implementing) | 18 |
| deferred (parked WIP, diagnostics, alternatives) | 35 |
| excluded (demonstrably dead, evidence cited) | 8 |
| owned by bead bfra-3kh.23 (fitsts.m, fitcts.m) | 2 |
| **Total rows** | **91** |

Reclassification after consolidation: bead bfra-3kh.24 moved the four
fitab.m fitopts rows from deferred to done. The current counts are done 32
and deferred 31; the table above keeps the consolidation counts.

Recommendations: implement 4, formalize (example/test/docs) 8, delete 26,
keep parked 51 (plus the 2 rows owned by bfra-3kh.23).
Rows flagged `unreconstructable-context`: 8.

Counting note: the eight `%!test` blocks in `private/smooth.m` are one row.
Counted as separate blocks, the block total is 98.

Legend: class = done | todo | deferred | excluded. Flag `URC` =
unreconstructable-context (block only makes sense with debugger-time workspace
state or with helpers absent from the toolbox).

## toolbox/+baseflow/+deps (vendored third-party code)

These files are vendored File Exchange / Octave sources. Do not edit them to
tidy comments; every recommendation here defaults to keep parked.

### Done

- [x] **peakfinder.m:330-337** Old varargout packing: "varargout = {peakInds,peakMags};" behind nargout checks.
  - class rationale: — signature (line 1) uses named outputs `[peakInds,peakMags]`
  - inferred intent: Output plumbing from the varargout era.
  - recommendation: keep parked (vendored). Note: live line 100 still assigns `varargout = {[],[]};` on the early-return path; with named outputs that is a latent bug (outputs undefined on that path).
  - resolved (2026-08-31, bead bfra-3kh.32): the latent bug in the note
    above is fixed. The empty-input path assigns `peakInds = []` and
    `peakMags = []`. tests/test_peakfinder.m verifies the empty outputs
    directly and through `private/islocalmax.m`. This disabled block
    stays parked.
  - flags: vendored
  - working-tree anchor (2026-09-13, R3 sweep records#14): 334-341.
- [x] **peakfinder.m:339-349** Second varargout variant with a plot branch; "% mgc switched order back to loc,mag".
  - class rationale: — same supersession as above
  - inferred intent: Plot-when-no-output behavior plus the mgc output-order record.
  - recommendation: keep parked (vendored)
  - flags: vendored
  - working-tree anchor (2026-09-13, R3 sweep records#14): 343-353.

### Deferred

- [ ] **arrow.m:107-124** Recipe (prose plus code) for legend support: wrapper `function arrow2(varargin)` with a `global test`, and `H(k) = patch(xyz{:},'HandleVisibility','off')` to hide arrows from legends.
  - inferred intent: Keep FEX-comment-thread instructions for legend handling near the live note at 104-105 ("if I want the arrow i need to add the other stuff below").
  - recommendation: keep parked
  - flags: vendored
- [ ] **deta.m:180-197** Demo after `return`, wrapped in `if 1==2`: meshgrid over a complex grid, "f = deta(z,1);", mesh plot.
  - inferred intent: Upstream demo of the Dirichlet-eta routine.
  - recommendation: keep parked
  - flags: vendored
- [ ] **rsquare.m:74-80** Disabled warning `'baseflow:deps:rsquare:NegativeRsquared'` and disabled clamp `%r2 = 0;`.
  - class rationale: — mgc's live note: "until warnings are managed in one central location I am leaving this commented out."
  - inferred intent: Warn on negative R-squared once the toolbox has central warning management.
  - recommendation: keep parked

### Excluded

- **arrow.m:744-752** Original author's alternative vectorized 3-space-to-2-space transform: "tmp1=[(x-axm)./axr; ones(1,size(x,1))]".
  - class rationale: — commented in the upstream FEX source; the live code below (755 on) does the work
  - inferred intent: Upstream author's derivation note.
  - recommendation: keep parked (vendored file)
  - flags: vendored

## toolbox/+baseflow/+internal

### Deferred

- [ ] **dependencies.m:241-262** Loop over `funclist` calling "matlab.codetools.requiredFilesAndProducts(thisfunc)" and building a per-function `Depends` table. Known parked WIP per the W1 task statement.
  - inferred intent: Per-function dependency attribution, used to trace spurious requirements ("functions that were returned as required but sholdn't be like the Cupid toolbox"). Companion 2-line block at 238-239.
  - recommendation: keep parked
  - correction (2026-09-13, R3 sweep records#0 and dependencies#11): the
    block is commented-out parked WIP at `dependencies.m:384-414`, at the
    end of `resolvedependencies`. A "Parked WIP" comment opens it at 384.
    The companion `dependentFunctions` block is at 390-391, the "Cupid
    toolbox" rationale comment at 393-396, and the `Depends` loop at
    398-414. The R3 sweep found the block missing from the working tree.
    The R3 repair restored it line for line from
    `HEAD:toolbox/+baseflow/+internal/dependencies.m:189-218`. The class
    stays deferred, and the recommendation stays keep parked. This
    correction supersedes the anchors 241-262 and 238-239.
  - working-tree anchors (2026-09-13, R3 repair): the block is at
    `dependencies.m:246-276`. The "Parked WIP" comment is at 246, the
    `dependentFunctions` block at 252-253, the "Cupid toolbox" rationale
    comment at 255-258, and the `Depends` loop at 260-276. These anchors
    supersede 384-414, 390-391, 393-396, and 398-414.

## toolbox/Setup.m

### Deferred

- [ ] **Setup.m:403-414** License diagnostic: "v = ver % Get all your version info into one variable." then a loop printing `getFeatureName` results per toolbox.
  - class rationale: — the live comment at 398-401 tells users to "run the loop below and raise an issue on github" when the toolbox check fails
  - inferred intent: User-runnable troubleshooting for the `required_toolboxes` feature-name check (386-396).
  - recommendation: formalize — promote to a callable diagnostic subfunction or documented troubleshooting step
  - working-tree anchors (2026-09-13, R3 sweep dependencies#11): the
    license diagnostic is at `Setup.m:442-453`, the live comment at
    437-440, and the `required_toolboxes` check at 427-435. The check
    reads its names from `requiredtoolboxes` (`Setup.m:456-464`).
  - working-tree anchors (2026-09-13, R3 repair): the license diagnostic
    is at `Setup.m:409-420`, the live comment at 404-407, and the
    `required_toolboxes` check at 392-402. The check defines its names
    inline at `Setup.m:393-394`. These anchors supersede 442-453,
    437-440, and 427-435, and "reads its names from `requiredtoolboxes`
    (`Setup.m:456-464`)".

## toolbox/+baseflow (main package)

### QtauString.m

#### Done

- [x] **50-63** Manual nargin/varargin parsing: "printvalues  = false;", `ab = [varargin{1};varargin{2}]`, `Q0 = varargin{3}`.
  - class rationale: — superseded by the live inputParser (33-48)
  - inferred intent: Pre-inputParser argument handling.
  - recommendation: delete

### checkevent.m

#### Deferred

- [ ] **293-319 (core 305-316)** Trailing "--------------- extra stuff" region after the last subfunction: yyaxis semilogy additions, and a debug block reconstructing the fit — "f = @(a,b,Q0,x) (Q0^(1-b)-(1-b).*a.*x).^(1/(1-b));" — then six figures comparing obs, fit function, and fit test.
  - inferred intent: Debugger-time verification that the plotted `qfit`/`dqfit` match the analytic recession solution. Uses `t,q,qfit,dqfit,ab` from the `plotfits` subfunction (215) workspace; the code cannot run where it sits.
  - recommendation: keep parked
  - flags: URC

### cloudphi.m

#### Todo

- [ ] **138-166** Switch on `blate` (1, 3/2, otherwise) mapping to `baseflow_fitphi` solution pairs (PK62/BS03, PK62/BS04, RS05/RS05; sloped: BR94/RS06). Header: "found this in an older test version, need to integrate or delete".
  - class rationale: — the author's own note demands adjudication
  - inferred intent: Route cloud-phi estimation through fitphi solution pairs, including the sloped-aquifer (`theta`) path that the live function dropped.
  - recommendation: keep parked pending comparison with the live eventphi/fitphi path

### dndtuncertainty.m

#### Deferred

- [ ] **164-300** 137-line "Methods comparison": symbolic setup ("syms tausym phisym bsym Qsym"), vector-valued error-propagation handles `FsigX`, `FsigX2`, `FlamX`, `FdndtX`, jacobian/covariance construction, and cross-checks via `PropError`/`propUncertSym`/`propUncertCD`.
  - class rationale: — high-value parked WIP
  - inferred intent: Validate the live first-order uncertainty formula for dn/dt against symbolic and covariance-aware alternatives.
  - recommendation: formalize as example — a methods-comparison script under demos, once the missing helpers are restored
  - flags: URC — needs the main-function workspace (`tauhat`,`phihat`,`bhat`,`dbfdt`,`sig_*`) and `PropError`/`propUncertSym`/`propUncertCD`, none of which exist in the toolbox

### eventfinder.m

#### Deferred

- [ ] **237-242** Inside the live `if debug` block (gated by hardcoded `debug = false`, 224): "loglog(Q{iplot},-derivative(Q{iplot}))" in a pause-and-clear loop.
  - inferred intent: Per-event visual QA of q vs -dq/dt during event detection. Note: `iplot` is undefined in scope (the loop index is `n`); the block needs a one-line fix to run.
  - recommendation: keep parked

### eventphi.m

#### Done

- [x] **135-141** "% No longer supported" parser parameters: `method`, `theta`, `isflat` addParameter calls and result reads.
  - class rationale: — the live parser (120-133) omits them by design
  - inferred intent: Record of the removed sloped-aquifer/method options.
  - recommendation: delete

### eventplotter.m

#### Deferred

- [ ] **231-245** "other options not in use": 50th-percentile refline via `baseflow.deps.hline`, re-plotting findevents output as a check, and a legend variant with a "keep (check)" entry.
  - inferred intent: Optional plot layers for the event-detection figure. Mixed nesting: the doubly-commented lines were already disabled inside this disabled variant.
  - recommendation: keep parked

### expectedQ.m

#### Deferred

- [ ] **76-99** "error propagation notes": `sigQexp = abs(Qexp/tauexp/(1-bhat)*sig_tau)`, then a numeric cross-check "F = @(X) (X(1)*X(2))^(1/(1-X(3))); % (a*tau)^(1/(1-b))" with bootstrap-replicate correlation and `propUncertCD`/`propUncertSym` calls.
  - inferred intent: Derive and verify the uncertainty on Qexp from the global-fit bootstrap replicates.
  - recommendation: keep parked
  - flags: URC — uses `GlobalFit` bootstrap fields from the caller's workspace; `propUncertCD`/`propUncertSym` absent from the toolbox
- [ ] **102-185** "below here various ways of computing Q0/Qexp": alternative derivations equating early- and late-time fits, with recorded numeric results ("[Q0 Qexp] % 9.1069e+05   3.6818e+05") and the identity "Qexp/Q0 = ((2-b)/(3-2*b))^(1/(1-b)) = 0.136 ..." tied to eq. 8 of Troch 1993.
  - class rationale: — high-value parked WIP
  - inferred intent: Working notes for the Q0/Qexp relationship the live function encodes; keeps the rejected variants and the observed numbers.
  - recommendation: formalize as example — this is derivation documentation, better as a demo/doc page than a comment block
  - flags: URC — depends on a specific session's `q`,`dqdt`,`b`,`tau0` values

### fdcurve.m

#### Todo

- [ ] **93-113** Entire commented local function "function [F,x] = ecdfpot(x,xmin,alpha,sigma)" marked "% not implemented": peaks-over-threshold exceedance probability `F = N/n.*(1+gamma.*(x-x0)/beta)^(-1/gamm)`.
  - inferred intent: Add a POT (generalized Pareto) variant of the flow-duration curve. Sketch-grade: `b`, `tau0`, `x0` undefined and `gamm` is a typo.
  - recommendation: keep parked

### fitab.m

#### Done

- [x] **169-173** In fitLIN: "% not sure if this was ever functional" — `fitopts.order` override check.
  - class rationale: — part of the unresolved `fitopts` mechanism
  - inferred intent: Let callers override the forced slope via a fitopts struct.
  - recommendation: keep parked until the fitopts decision (see 282-291)
  - adjudication (2026-08-31, bead bfra-3kh.24): fitopts kept and
    implemented. The fitab input parser applies each fitopts field as a
    validated override of the same-named option (weights, order, mask,
    quantile, refqtls, Nboot, alpha, plotfit). A wrong type errors with
    `baseflow:fitab:invalidFitopt`; an unknown field errors with
    `baseflow:fitab:unknownFitopt`. fitevents and
    `setopts('fitevents')` accept `fitopts` and pass it to fitab.
    tests/test_fitopts.m (7 tests) covers the overrides, both errors,
    precedence, scalar expansion, and the fitevents path. This
    centralized parser supersedes the per-method block, so the row moves
    from deferred to done. The disabled block stays in fitLIN as
    provenance; W3 reviews whether to retire it.
  - working-tree anchor (2026-09-13, R3 sweep records#14): 179-183.
- [x] **199-204** In fitMED: same `fitopts.order` check plus "% not sure why this was here, order is passed in with default 1".
  - inferred intent: Same fitopts override for the median fit.
  - recommendation: keep parked (with 282-291)
  - adjudication (2026-08-31, bead bfra-3kh.24): superseded by the
    centralized fitopts parser; see 169-173. The disabled block stays
    in fitMED as provenance.
  - working-tree anchor (2026-09-13, R3 sweep records#14): 209-214.
- [x] **241-249** "% removed fitopts for now": `fitopts.order` and `fitopts.quantile` overrides for the quantile-regression path.
  - inferred intent: Same fitopts mechanism for fitQTL.
  - recommendation: keep parked (with 282-291)
  - correction: the block sits in fitENV (the envelope fit), not in
    fitQTL. It overrides `order` and `quantile` for the envelope path.
    This correction supersedes "quantile-regression path" and "fitQTL"
    in the two lines above.
  - adjudication (2026-08-31, bead bfra-3kh.24): superseded by the
    centralized fitopts parser; see 169-173. The disabled block stays
    in fitENV as provenance.
  - working-tree anchor (2026-09-13, R3 sweep records#14): 251-259.
- [x] **282-291** "% If fitopts is abandoned, need to figure out how to deal with extra parameters for quantile regression." — fitopts-based `qtl`/`order`/`Nboot` extraction; live code (293-294) applies default `qtl = 0.05`.
  - class rationale: — this block is the decision record for the whole fitopts question
  - inferred intent: Pass quantile-regression tuning through one options struct.
  - recommendation: keep parked; adjudicate fitopts once, then resolve 169-173, 199-204, 241-249 together
  - adjudication (2026-08-31, bead bfra-3kh.24): decided keep. The
    centralized fitopts parser resolves this block and 169-173, 199-204,
    and 241-249 together; `fitopts.quantile`, `fitopts.order`, and
    `fitopts.Nboot` reach fitQTL through it. The disabled block stays
    in fitQTL as provenance. The per-method extension ideas (for
    example `fitopts.sigx` for 'mle') stay as parked design notes at
    the end of the fitab input parser.
  - working-tree anchor (2026-09-13, R3 sweep records#14): 292-301; the
    live default `qtl = 0.05` is at 303-305.

#### Deferred

- [ ] **386-396** Reference notes on CI ordering: "% any log-log regressions need the ci's transormed like this:" `aL = exp(ci(1,1))` ... and the nlinfit/confint row-column mapping.
  - inferred intent: Document how `ci` rows map to aL/aH/bL/bH per regression backend — a real convention the live code relies on.
  - recommendation: keep parked (or fold into the fitting docstrings)
  - working-tree anchor (2026-09-13, R3 sweep records#14): 396-406.

### fitevents.m

#### Done

- [x] **245-255** Re-assignment of `K.a ... K.fitTag` to nan on fit failure. Live comment 243: "this shouldn't be necessary since they're initialized to nan".
  - class rationale: — `initFitStruct` (269-277) preallocates nan
  - inferred intent: Defensive re-initialization from before preallocation existed.
  - recommendation: delete
- [x] **257-261** "K(idx).method = method;" struct-array style assignments.
  - class rationale: — the flat preallocated struct replaced the struct-array design
  - inferred intent: Older output layout.
  - recommendation: delete

#### Todo

- [ ] **219-223** "K.method(fitcount) = fitmethod;" plus order/deriv/station/date assignments into the fits struct.
  - class rationale: — blocked only by field types (see 279-284)
  - inferred intent: Store fit metadata (method, order, derivative, station, date) with each event fit.
  - recommendation: implement together with 279-284
- [ ] **279-284** Commented nan preallocation for the metadata fields with the live note "these need to be redefined as strings or chars or soemthing other than nan".
  - inferred intent: Preallocate the metadata fields with type-correct values (strings/categorical), enabling 219-223.
  - recommendation: implement

### fitphi.m

#### Todo

- [ ] **140-155** Alternative phi expressions for the sloped solution: "c1c2 = 1.133*pi^2*p/(a1*a2*D^2*A^2);" ... "phi = sqrt(c1*c2*(1+c3)/(a1*a2))", introduced by "Need to double check these notes ... need to revisit the sloped case".
  - class rationale: — author flags the sloped case as unresolved
  - inferred intent: Independent cross-check of the sloped-aquifer phi solution.
  - recommendation: keep parked; the derivation belongs with the solution docs
- [ ] **176-189** Hydraulic-conductivity estimates: "k1 = fR1/(D^3*L^2*a1*c1c2/a1a2); % uses early-time" and the late-time k, with "% this is in aquiferprops. probably better to use that, but should combine."
  - class rationale: — explicit consolidation intent
  - inferred intent: Compute k inside fitphi; duplicate of the aquiferprops method (see aquiferprops.m Step 9/10).
  - recommendation: keep parked pending consolidation with aquiferprops
- [ ] **395-412** "% THIS IS A BETTER WAY BUT NOT IMPLEMENTED": binary `modelstruct` matrix encoding flat/sloped, k(z) form, linearized/nonlinear per solution, plus `modopts` labels.
  - class rationale: — design sketch for the solution registry
  - inferred intent: Generate the valid solution-pair ensemble from a model-space table instead of hand-maintained lists.
  - recommendation: keep parked (top implement candidate)
- [ ] **420-429** "% started to build this" — half-built loop over `modopts` with an empty `case 1`.
  - class rationale: — abandoned mid-construction, same feature as 395-412
  - inferred intent: Loop skeleton for consuming the modelstruct table.
  - recommendation: keep parked with 395-412

#### Excluded

- **414-418** `ensembleList(slope,conductivity,solutiontype)` all-combos build, rejected: "can't use this becaue we don't want all combos".
  - class rationale: — author-rejected, and `ensembleList` does not exist in the toolbox
  - inferred intent: Rejected precursor of 395-412.
  - recommendation: delete

### generateTestData.m

#### Deferred

- [ ] **53-72** Recipes from the retired ParameterizedTestBfra suite: "data = genCurveData('exponential');" then dqdt construction and loglog/semilogy checks, investigating "why the data falls off".
  - inferred intent: Diagnose synthetic-data behavior (noise vs sign convention) for the linear and nonlinear test cases.
  - recommendation: keep parked
  - flags: URC — `genCurveData` is not defined anywhere in the toolbox

### globalfit.m

#### Done

- [x] **97-106** Point-cloud plot on `plotfits`: "% turned this off b/c phicloud makes one" — `baseflow.pointcloudplot(...)` with reflines and an `xbar/ybar` scatter.
  - class rationale: — the phi-estimation path (cloudphi) produces the same figure
  - inferred intent: Avoid a duplicate point-cloud figure.
  - recommendation: delete

### gpfitb.m

#### Deferred

- [ ] **187-192** "% test using plplot instead": build `aci`, prep data, call `baseflow.plplotb(x,xmin,alpha,...)`.
  - inferred intent: Cross-check the generalized-Pareto fit plot against the power-law plot.
  - recommendation: keep parked

### hyetograph.m

#### Done

- [x] **177-214** Old yyaxis implementation at file bottom: "yyaxis left; h1 = plot(time,flow,...)" then `bar(time,prec,...)` on the right axis, with the note "% With yyaxis, there is only one axis, so I don't track them separately".
  - class rationale: — the live function builds the same figure with two overlaid axes `ax(1)`/`ax(2)` and returns `H = [fig ax(1) h1 h2]` (through line 118)
  - inferred intent: First-generation hyetograph rendering.
  - recommendation: delete

### loadbasins.m

#### Deferred

- [ ] **85-94** "% sort the Bounds, Meta, and Poly by station": `sortrows(Meta,'station')` and index-sorting of Bounds/Poly; then "% not sure what this was from" and a truncated fragment "Basins   = sort".
  - inferred intent: Deterministic station ordering across the three returned structures — a coherent feature; the tail fragment is dead.
  - recommendation: keep parked (drop the truncated fragment if ever revived)

### loadcalm.m

#### Done

- [x] **66-72** "% if requested, aggregate the multi-site data" — switch on `aggfunc` calling `aggregateCalm` per case.
  - class rationale: — the live line 57 calls `aggregateCalm(Calm, Meta, aggfunc, ...)` unconditionally and the local function (81+) switches internally
  - inferred intent: Pre-refactor aggregation dispatch.
  - recommendation: delete

#### Todo

- [ ] **210-218** "% make a shapefile": site stats via `stderror`, subset `MetaCalm(Points.inpolyb,:)`, rename LAT/LON, "S = geopoint(S);".
  - inferred intent: Export CALM sites with mean/std as a geopoint/shapefile layer; pairs with the live idea note (207-208) about buffer-based site selection.
  - recommendation: keep parked
  - flags: URC — `Data`, `MetaCalm`, `Points` are debugger-time variables of a deleted workflow

### loadghcnd.m

#### Done

- [x] **161-166** Unit-setting loop over variables; live note: "% readGHCND sets the units so only reset if converted".
  - class rationale: — readGHCND owns unit assignment
  - inferred intent: Pre-readGHCND unit bookkeeping.
  - recommendation: delete
- [x] **181-194** "% old method:" — `load` from hardcoded "/Users/coop558/mydata/interface/weather/matfiles/", Kuparuk-only rename/retime pipeline.
  - class rationale: — superseded by the live readGHCND-based load; the path is machine-specific and dead
  - inferred intent: First-generation rain-data ingest.
  - recommendation: delete

### loadgrace.m

#### Todo

- [ ] **74-83** "% for now I return monthly S, but this is what is returned in BFRA_drive": richer `G` struct with `S`, `SL`, `SH`, `TL`, `TH`, `Tref`.
  - inferred intent: Return GRACE storage with uncertainty bounds and reference time, matching the BFRA_drive interface.
  - recommendation: keep parked

#### Deferred

- [ ] **41-55** "% temporary hack to get the 2022 data": Kuparuk-specific `load([pathdata 'grace_kuparuk'],'Grace')`, variable renames, re-normalization "Grace.S = Grace.S-nanmean(Grace.S);".
  - class rationale: — the live line 57 says "% delete this and replace w/above if using 2022 data"; this is a deliberate data-version toggle
  - inferred intent: Swap in the extended-2022 GRACE series for the Kuparuk basin.
  - recommendation: keep parked

### mapbasins.m

#### Done

- [x] **190-205** Per-basin `plotm` loop and a pause-per-basin loop "% I used this to confirm that the sorting by area after".
  - class rationale: — live 187-188 draws all outlines at once via `polyjoin` + `plotm`
  - inferred intent: Outline drawing before the polyjoin optimization, plus a one-off sort check.
  - recommendation: delete
- [x] **264-271** Label-position experiments: `quantile`, `mean`, `median`, `min`/`max` of basin Lon/Lat.
  - class rationale: — live 261-262 places labels with the precomputed `xpos(n)`/`ypos(n)`
  - inferred intent: Tuning history for basin-label placement.
  - recommendation: delete

#### Deferred

- [ ] **66-73** "OTHER METHODS": `worldmap('North America')`, `usamap('ak')`, `worldmap([45 90],[-58 -165])`, plus setm limit calls.
  - inferred intent: Alternative map-projection setups kept for reference next to the live axesm/plotm path (63).
  - recommendation: keep parked
- [ ] **300-311** "% Now change the ColorBinding back" — colorbar `Face.ColorBinding` toggling, colormap swap, re-applying alpha to `Texture.CData`.
  - inferred intent: Second half of the transparent-colorbar hack (live-adjacent 297 keeps the 'discrete' line commented too); undocumented-graphics territory, version-sensitive.
  - recommendation: keep parked

### mapgages.m

#### Done

- [x] **42-47** "% Old method before migrating updates from mapbasins": `worldmap(latlims,lonlims)` + `plotm` coastlines.
  - class rationale: — live 39-40 uses the migrated axesm/plotm setup
  - inferred intent: Pre-migration map setup.
  - recommendation: delete

### phifitensemble.m

#### Deferred

- [ ] **59-63** "[F1,h1]  = baseflow.fitphidist(phi1,'PD','cdf');" through phi4 and the pooled `[phi1;phi2]`.
  - inferred intent: Compare fitted phi distributions per ensemble member against the pooled fit.
  - recommendation: keep parked

### plfitb.m

#### Todo

- [ ] **206-227** Commented function "bootstrap_alpha(x,range,limit)": fix xmin, bootstrap alpha via `bootstrp(1000,@(x,xmin)plfit(...))`, plus appendix bias-correction formulas "alphatrue = (1 + alpha*(N-1))/N". Header: "% this might still be a good approach, just need to figure out how to get the stdv of xmin".
  - class rationale: — author explicitly keeps the approach open
  - inferred intent: Faster alpha-only bootstrap alternative to plbootfit (which is kept because it returns xmin_sig).
  - recommendation: keep parked (top implement candidate)

#### Deferred

- [ ] **181-192** "%% extra" — histograms of bootstrap replicates: "histogram(reps.b); title('Bootstrap estimates of $b$');" etc.
  - inferred intent: Visual check on the sampling distributions of b, tau0, alpha.
  - recommendation: formalize as example (bootstrap-diagnostics demo)

#### Excluded

- **194-203** `stderror`-based CI loop with the verdict "% it is incorrect to apply the standard formula so don't use this".
  - class rationale: — author states the method is wrong for these estimators
  - inferred intent: Record of a rejected CI method.
  - recommendation: keep parked — the verdict comment guards against re-introducing the standard-formula CI

### plotdqdt.m

#### Excluded

- **330-335** Rotated in-axis labels: "axpos = baseflow.deps.plotboxpos(gca);" then `addRotatedText(...)` for b=3, b=1, upper envelope; note "only works with correct axes position".
  - class rationale: — `addRotatedText` is not defined anywhere in the toolbox
  - inferred intent: Slope-line labeling; the equivalent live capability is `rotatedLogLogText` in plotrefline.m.
  - recommendation: delete
- **476-480** "ab1   = baseflow.wols(log(q1), log(-dq1));" per segment; live note: "Jul 2024 - commented out b/c 'wols' is not a function in the toolbox. Not sure if this is supposed to be 'ols' or a weighted version."
  - class rationale: — `wols` does not exist in the toolbox (verified)
  - inferred intent: Slope-based classification of three consecutive segments (flat vs recession).
  - recommendation: keep parked until the containing three-segment logic is either fixed (with olsfit) or removed
- **487-492** The consumer of those fits: "if ab1(2)>1 && ab2(2)<1 && ab3(2)>1" then drop the middle segment. Same Jul 2024 note.
  - class rationale: — same missing-`wols` evidence
  - inferred intent: Merge recessions separated by a flat period.
  - recommendation: keep parked with 476-480

### plotrefline.m

#### Todo

- [ ] **204-208** In the `'lowerenvelope'` case: "% for now, add this after the fact" — xtxt/ytxt placement for the label.
  - inferred intent: Label the lower envelope in-axis, mirroring the live `'upperenvelope'` label (197-201, `rotatedLogLogText`).
  - recommendation: implement

### pointcloudintercept.m

#### Deferred

- [ ] **100-105** "xbar = quantile(q(mask),qtls(1),'Method','approximate');" pair, with the note "use this to show that ahat returned by this function is identical to the case where a0 is returned ... and then passed to the a(a0...) function from baseflow.getfunction('aofa0')".
  - inferred intent: Equivalence proof between method 'cooper' and 'envelope' + `aofa0`.
  - recommendation: formalize as example — this is a ready-made unit-test assertion

### pointcloudplot.m

#### Done

- [x] **167-182** Dual-legend variant: "tbest = [baseflow.aQbString(ab(ibest,:),'printvalues',true) ' (NLS fit)'];" and userfit text swap.
  - class rationale: — live 184-185 deliberately puts "only bestfit in the legend"
  - inferred intent: Show both bestfit and userfit lines in the legend.
  - recommendation: delete
- [x] **222-229** Octave/MATLAB legend-interpreter branch: 'tex' vs 'latex'.
  - class rationale: — the live legend call (219-220) uses 'tex' unconditionally
  - inferred intent: Interpreter selection from the Octave-compat pass.
  - recommendation: delete

### printtrend.m

#### Done

- [x] **63-86** Old metric machinery: "% no longer used: metric = parser.Results.metric;" then the alpha-to-CI/SE switch and per-metric fprintf formats "fprintf(['\\n dQ/dt = %.2f ' char(177) ' %.2f (95% CI) \\n']...)".
  - class rationale: — the live body prints one unified CI string (36-38)
  - inferred intent: Metric-dependent trend printing. Note: the live parser still accepts the now-unused 'metric' parameter (line 49).
  - recommendation: delete

### privatefunction.m

#### Done

- [x] **21-26** "switch funcName / case 'todatenum' / funcHandle = @todatenum;" dispatch.
  - class rationale: — live 13-16 uses `validatestring` over `completions('private')` plus `str2func`
  - inferred intent: Manual dispatch before the generic mechanism.
  - recommendation: delete

### specialfunctions.m

#### Todo

- [ ] **25-31** "% for extended functionality" (fR1 case): read kD/L/phi from varargin, set b=3, N=-3, "c = fR1./(kD.*phi.*L.^2);".
  - inferred intent: Return the recession coefficient c (not just the shape factor) when aquifer properties are supplied.
  - recommendation: keep parked
- [ ] **41-49** Same pattern for fR2: "c = fR2./phi.*( (kD.*L.*L) ./ (2.^n.*(n+1).*A.^(n+3)));".
  - inferred intent: Late-time counterpart of the fR1 extension.
  - recommendation: keep parked (implement both together if ever)

### trendplot.m

#### Done

- [x] **175-182** "% this is an old note not sure / % prior method, delete if above is considered best" — isregular/isdatetime time-axis conversion.
  - class rationale: — the live conversion above has been in service; the author pre-authorized deletion once it was accepted
  - inferred intent: Prior time-axis normalization.
  - recommendation: delete
- [x] **203-207** Explanation plus one disabled probe: "legobj = findobj(gcf,'Type','Legend');" — why the figure-parented legend cannot be found this way with subplots.
  - class rationale: — live 209-210 walks `get(gcf,'Children')`/`findobj('Type','Axes')` instead
  - inferred intent: Records why the obvious findobj approach fails; documentation value.
  - recommendation: keep parked (or fold the why-not into a comment on the live code)
- [x] **254-261** "% this is the original" errorbounds line-index computation.
  - class rationale: — live 247-252 computes `thislineidx`
  - inferred intent: Pre-refactor color-order indexing.
  - recommendation: delete

#### Deferred

- [ ] **135-139** In the OLS loop: "% Plot the fit" — plot data, yfit, yconf per column.
  - inferred intent: Per-fit visual QA under a debugger stop. Adjacent 141-142 keep a `regress`-based CI alternative.
  - recommendation: keep parked
- [ ] **162-172** Quantile-regression diagnostics: histogram of `S.ab_boot(:,2)`, fit vs bootstrapped-CI plots, "[S.ab_boot(2)+1.96*S.se_boot(2) ...]" stderr printouts.
  - inferred intent: Verify quantreg bootstrap output visually and numerically.
  - recommendation: keep parked

## toolbox/+baseflow/private

### bootstrapci.m

#### Todo

- [ ] **26-30** "% Just call isoctave. TODO: check if function overhead matters." — persistent `inoctave` caching.
  - inferred intent: Cache the isoctave probe if profiling shows overhead.
  - recommendation: keep parked

### fitets.m

#### Deferred

- [ ] **143-152** "gamma checks": fit-vs-data plot, the constraint "1./(gamma.*t) - log(etsparam./(max(t)-1))" that "must be >= 0", and the observation "if gamma is between about -0.2 and 0 it blows up" with a sweep plot.
  - class rationale: — numerical-stability knowledge not recorded anywhere else
  - inferred intent: Characterize the stability region of the ETS gamma parameter.
  - recommendation: formalize — the blowup range belongs in the fitets docstring or a test
  - flags: URC — uses `xexp`,`yexp`,`abc`,`fnc` from the fitting scope

### fitlm_octmat.m

#### Todo

- [ ] **49-53** Extra output fields: "Fit.Predictor = x; Fit.Response = y; ... Fit.Design = [ones(N,1), x(:)];".
  - inferred intent: Return the design matrix and inputs with the fit for downstream use.
  - recommendation: keep parked (implement if a caller needs them)

### fitsts.m / fitcts.m (owned by bead bfra-3kh.23)

#### Other

- **fitsts.m:1-69** Entire file commented, 0 live code lines: "function [q,dqdt,dt,tq,rq,dq] = fitsts(T,Q,R,varargin)" — "%FITSTS fit recession events using splines. not implemented."
  - class rationale: owned by bead bfra-3kh.23
  - inferred intent: Spline-based (STS) recession fitting method; listed in Contents.m and the getting-started doc as "not implemented".
  - recommendation: adjudicated by bfra-3kh.23
  - adjudication (2026-08-30, bead bfra-3kh.23): defer, keep parked; see
    the fitcts/fitsts stub section for the assessment. W3 reviews this
    disposition.
- **fitcts.m (78 lines; disabled alternatives at 27-34)** Partial stub with live finite-difference code (B1/B2/F1/F2/C2/C4 cases) plus commented `/dt` variants of Qfwd/Qbwd/Qctr ("not sure why the /dt's are above"); `rq = []; % TODO`; live caller exists (getdqdt.m:63).
  - class rationale: owned by bead bfra-3kh.23
  - inferred intent: Constant-time-step derivative method; reachable from getdqdt, so its stub state matters.
  - recommendation: adjudicated by bfra-3kh.23
  - adjudication (2026-08-30, bead bfra-3kh.23): implemented, with the
    C4 stencil repaired and tests/test_fitcts.m shipped; the commented
    /dt variants stay parked with the author's note.

### fitvts.m

#### Deferred

- [ ] **76-80** "% retime to the original timestep" — interp1 of q/dq/dqdt back onto T.
  - class rationale: — the live patch below (82-84, `tq = T`) states "It is unclear what value should be used"
  - inferred intent: Alternative posting of VTS estimates onto the original time vector.
  - recommendation: keep parked until the posting question is settled

#### Excluded

- **101-105** Fragment: "tn = t(n); tn_m = t(n-m);" then two dangling `if 4*(tn-tn_m)` lines.
  - class rationale: — syntactically broken; the live comment at 96-99 preserves the notation idea
  - inferred intent: Aborted readability rewrite of the 4*dt check.
  - recommendation: delete

### formatPlotMarkers.m

#### Deferred

- [ ] **191-196** Candidate `isa` checks for line-like graphics classes ("matlab.graphics.chart.primitive.Line.Type", FunctionLine, ConstantLine, ...), headed "but there are others, and I am not sure of them all".
  - inferred intent: Validate the `suppliedline` input across all line-like classes.
  - recommendation: keep parked

### olsfit.m

#### Deferred

- [ ] **98-102** "% before transforming a back:" — plot of logged data and fit.
  - inferred intent: Debug view of the log-log fit before `ab(1) = exp(ab(1))`.
  - recommendation: keep parked
- [ ] **108-122** "% after transforming a back:" — three figure variants verifying the back-transformed fit against data in log and linear space.
  - inferred intent: Verify the log-space/linear-space display convention; documents the transform pitfalls.
  - recommendation: keep parked

### predictlm.m

#### Deferred

- [ ] **54-58** "% For reference:" — `stats.coeffs` column map: sderr (2), confi (3:4), tstat (5), pvals (6).
  - inferred intent: Record the regstats coefficient-matrix layout the function depends on.
  - recommendation: keep parked (or fold into the docstring)

### preparecalendar.m

#### Done

- [x] **40-45** Two rejected `numyears` computations (unique-year count; first/last-year span) with "% both of these fail if water years are passed in".
  - class rationale: — live 38 (`numyears = numel(T)/365`, "% this is correct") does the job
  - inferred intent: Year counting; the failure note is the durable content.
  - recommendation: keep parked — the water-year failure rationale prevents regression

### quantreg.m

#### Done

- [x] **175-240** "% mgc: this is the stuff that the call to bootstrapci replaced" — full bootstrap-CI implementation (`bootstrp`, `bootci` with type/timing notes: "norm = 0.7515 seconds ... 'stud' = 67 sec", "'bca' (default) fails on call to jacknife").
  - class rationale: — live line 116 calls `bootstrapci(x,y,ab,Frho,Nboot,alpha,opts)`
  - inferred intent: Pre-extraction bootstrap code; the method-selection and timing notes are the durable content.
  - recommendation: delete after migrating the timing/method notes into bootstrapci.m's header

#### Todo

- [ ] **134-152** "% this is copied out of ktaub to see how the CI's are computed in case I can adapt it to quantreg" — `norminv`-based Calpha, interp1q of ranked slopes, `ztest(s,0,sigma,alpha)`.
  - inferred intent: Adapt the Mann-Kendall/Sen CI construction to quantile regression.
  - recommendation: keep parked
  - flags: URC — `C3`, `sigma`, `s` exist only in the ktaub context

#### Excluded

- **156-172** "function ps=invtranspoly(p,kx)" of unknown origin: "% not sure where this came from ... maybe this was something the og author had in here commented out"; references undefined `kk`.
  - class rationale: — disowned by the author and broken (`kk` undefined)
  - inferred intent: Unknown; polynomial transform inversion.
  - recommendation: delete

### setnan.m

#### Done

- [x] **109-118** Row-wise table nan-setting loop: "dataout(i,:) = table(nan);" per nan index, with a non-table else branch.
  - class rationale: — the live body above (through 106) handles table and non-table inputs
  - inferred intent: First-generation table handling.
  - recommendation: delete

### siUnitsToTex.m

#### Done

- [x] **53-60** "% My original approach - got complicated to detect positive versus negative exponents" — strrep loop over `-1..-5` plus `texlabel`.
  - class rationale: — live 50-51 strrep pipeline does the conversion; the adjacent live note (62-63) records why texlabel fails
  - inferred intent: Exponent TeX-ification, first attempt.
  - recommendation: delete

### smooth.m (vendored, Octave-style)

#### Deferred

- [ ] **275-357 (8 blocks)** Octave BIST tests: "%!test" blocks with "%! yy = smooth (y); %! assert (yy, yy2);" covering span defaults, x-vector input, sgolay, etc.
  - class rationale: — executable under Octave's `test` runner, inert in MATLAB
  - inferred intent: Vendored embedded test suite.
  - recommendation: keep parked
  - flags: vendored
- [ ] **361-370** "%!demo" — moving average vs Savitzky-Golay comparison plot.
  - inferred intent: Vendored demo.
  - recommendation: keep parked
  - flags: vendored

### struct2varargin.m

#### Done

- [x] **33-39** "% old method:" — fieldname/value interleaving loop.
  - class rationale: — live 30 does it with one `reshape(transpose([fieldnames(S) struct2cell(S)]),1,[])`
  - inferred intent: Pre-vectorization implementation.
  - recommendation: delete

### struct2vec.m

#### Done

- [x] **91-107** "% NOTES:" — cellfun-based implementation with the row/column concatenation reasoning and a `cellflatten` variant (helper not in the toolbox).
  - class rationale: — the live body (through 88) implements the chosen method
  - inferred intent: Alternative implementations plus the shape reasoning.
  - recommendation: formalize — fold the ordering/shape caveats into the docstring, then retire the code
- [x] **109-114** "% This method does not preserve the original order of the vectors." — struct2cell + ismember reorder sketch.
  - class rationale: — same supersession; the order warning is the content
  - inferred intent: Rejected ordering-unsafe variant.
  - recommendation: formalize with 91-107

### yorkfit.m

#### Todo

- [ ] **197-215** Inside local `statsOLS` (191): live code returns only `stats.a`/`stats.b`; disabled lines "stats.a_sig = siga; ... stats.rsq = corr(Y,stats.yhat,'Type','Pearson')^2;" mirror the full stats struct the main yorkfit returns (155-182). Live comment 193: "% need to fill in the rest of the values for OLS".
  - class rationale: — the author states the remaining work
  - inferred intent: Give the OLS fallback the same stats interface as the York fit so callers can switch estimators.
  - recommendation: implement

## Near-misses (scanned, judged not disabled code)

Recorded so the scan is reproducible; these are prose or pseudocode, not
parked code, and get no inventory row above:

- `aquiferprops.m:209-215` — prose note on early/late-time k equivalence at
  b=3/2 (adjacent single disabled equation at 207).
- `fitab.m:438-444` and `private/fitNLS_matlab.m:41-47` — "Summary of the
  method" pseudocode describing the live rsq-cascade fit selection
  (duplicated between the two files; a consolidation candidate, not WIP).
- `loadghcnd.m:168-178` — sub-5-line gap-fill spot-check fragments.
- `private/fitets.m:154+` — prose note on the older m-truncation method.
- 28 function help headers (docstring position) matched by the comment-run
  scan and excluded after verification; list available from the scan script.

## Cross-cutting observations

### Done

- [x] The `fitopts` mechanism in fitab.m is the largest single WIP theme (4
  blocks). One decision — keep or abandon fitopts — resolves all four.
  - resolved (2026-08-31, bead bfra-3kh.24): decided keep. The fitab
    input parser applies fitopts fields as validated overrides
    (`baseflow:fitab:invalidFitopt`, `baseflow:fitab:unknownFitopt`),
    and fitevents and `setopts('fitevents')` pass fitopts to fitab.
    tests/test_fitopts.m (7 tests) verifies it. This centralized parser
    supersedes the four parked per-method blocks; the fitab.m rows above
    are done, and the blocks stay parked as provenance.
- [x] Latent live bug noticed in passing (not a disabled block):
  `+deps/peakfinder.m:100` assigns `varargout = {[],[]};` on the
  no-maxima early-return path, but the signature (line 1) declares named
  outputs `[peakInds,peakMags]` — that path returns undefined outputs.
  - correction: the early return is the empty-input branch
    (`isempty(x0)`), not a no-maxima path. This correction supersedes
    "no-maxima early-return path" above.
  - resolved (2026-08-31, bead bfra-3kh.32): the empty-input path
    assigns `peakInds = []` and `peakMags = []`. tests/test_peakfinder.m
    verifies empty outputs from peakfinder directly and through
    `private/islocalmax.m`, plus one nominal interior peak.

### Other

- Uncertainty-propagation studies (dndtuncertainty.m, expectedQ.m,
  quantreg.m, plfitb.m) all reference an external error-propagation kit
  (`PropError`, `propUncertSym`, `propUncertCD`) that is not in the toolbox.
  Restoring or vendoring that kit is a precondition for reviving any of them.
- `printtrend.m` still parses a `'metric'` parameter (line 49) whose result
  is unused (dead option surfaced by row printtrend.m:63-86).
