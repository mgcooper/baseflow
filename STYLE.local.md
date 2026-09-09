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
  blocks: Octave cannot parse them, and Octave compatibility is a project
  goal. The three legacy `arguments` blocks in `+internal/private` are
  scheduled for conversion (bead bfra-3kh.14).
- Branch Octave-specific behavior on the toolbox `isoctave` helper.
- Keep new code free of `gobjects` and other Octave-incompatible calls where
  a portable equivalent exists.

## New-test convention (required for new tests)

Adopted 2026-08-31 under bead bfra-3kh.2 (DesignSpec settled decision).
Every new MATLAB test follows it. Convert legacy files only when a task
touches them.

- Write new unit tests as function-based `matlab.unittest` suites:
  `tests/test_<name>.m` starting with
  `function tests = test_<name>` and `tests = functiontests(localfunctions);`.
  This matches the majority style in `tests/` and keeps each file focused.
- Reserve parameterized `classdef` suites for wide parameter matrices;
  `TestBaseflow.m` is the existing example.
- Name the actual result `returned` and the expectation `expected`, per the
  shared `STYLE.md` testing rules.
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
