# Project-specific code style — bfra

Conventions specific to this project, extending `STYLE.md` (and any language conventions
merged into it).

## Naming

- Public functions in `+baseflow` use short all-lowercase names
  (`fitab`, `getevents`, `eventfinder`), per the canonical MATLAB rule.
- Test files use `tests/test_<snake_case>.m`. Test classes use PascalCase
  (`TestBaseflow.m`).
- Variables use short lowercase or camelCase names (`q`, `dqdt`, `gotopath`).

## Formatting

- Indent with 3 spaces; no tabs.
- Wrap at roughly 80 columns; continue long lines with `...`.
- Close every function with an explicit `end`.
- Function help uses an uppercase H1 (`%FITAB fit event-scale ...`) followed
  by `Syntax`, `Description`, input, and output sections for public
  functions. See `toolbox/+baseflow/fitab.m` for the reference format.

## Idioms and patterns

- Parse inputs with `inputParser` (64 files use it). Do not add `arguments`
  blocks to core analysis functions or demos: Octave cannot parse them,
  and a user with only Octave must be able to run an analysis.
- The `+internal` maintenance tooling and its private helpers are MATLAB-only.
  They may use `arguments` blocks. Before adding an `arguments` block, confirm
  that no core function or demo calls the function.
- Branch Octave-specific behavior on the toolbox `isoctave` helper.

## New-test convention (required for new tests)

- Use parameterized `classdef` suites to sweep parameter values and keep test
  code compact. `TestBaseflow.m` is the existing example.
- Always prefer parameterized tests over function-based tests.
- Write unit tests as function-based `matlab.unittest` suites:
  `tests/test_<name>.m` starting with
  `function tests = test_<name>` and `tests = functiontests(localfunctions);`.
- Never use a function-based test when a parameterized `classdef` suite can
  test the same code with wider and more efficient parameter coverage.
- Name the actual result `returned` and the expectation `expected`, per the
  `STYLE.md` testing rules. A test that compares several quantities
  uses `<quantity>_returned` and `<quantity>_expected` (for example
  `S_expected`).
- No magic variables. Name a value when a reader cannot tell what it is:
  a non-obvious expected value, a tolerance or threshold, or an input
  that several tests share. Pass named expected values to assertions and
  helpers, for example
  `verifysegments(testCase, x, S_expected, E_expected, L_expected)`.
  Indexing into a named variable is fine, for example
  `testCase.verifyEqual(t_returned{n}(ib), t_expected{n}(ia))`. Do not name
  indices, obvious literal arguments such as `buildpath('demos', 'mfiles')`,
  trivial derived values such as `MinEventDuration-1`, or option names that
  the call already shows. Use a short comment to say what each case checks.
- A test that opens figures must close them in teardown; a full suite run
  must leave zero open figures.
- Tests must pass headless from the repo root through
  `baseflow.internal.runtests` with no setup beyond
  `addpath('toolbox'); Setup('addpath')`.
- The suite builder skips invalid test files silently. After adding a test
  file, confirm its rows appear in the runner result list.
- Octave smoke tests are plain scripts with bare `assert` calls and no
  matlab.unittest dependency (DesignSpec area I2).

## Prose examples

Rewrite this:

> if nmin is set to 0 (and maybe if it is set to 1) this method will fail
> because runlength returns 1 for consecutive nan values, see isminlength.

as this:

> This method fails when nmin is 0, and possibly when nmin is 1. runlength
> returns 1 for consecutive nan values. See isminlength.
