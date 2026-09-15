# Contributing

Thank you for improving the baseflow toolbox.

## Report a problem

Open an issue at https://github.com/mgcooper/baseflow/issues. Include
the MATLAB or Octave version, the command you ran, and the full error
message.

## Make a change

1. Fork the repository and branch from `dev`. Pull requests target
   `dev`, never `main`.
2. Run the test suite from the repository root before you push:

       matlab -batch "addpath('toolbox'); Setup('addpath'); assertSuccess(baseflow.internal.runtests())"

   The suite must pass with zero failures, and a full run must leave
   zero open figures.
3. Add a test for the change in `tests/`. Follow these rules:
   - Write MATLAB unit tests as `matlab.unittest` suites in
     `tests/test_<name>.m`. Prefer a parameterized `classdef` suite
     when the test sweeps option or input values. `TestBaseflow.m` is
     an example.
   - Write Octave smoke tests as plain scripts with bare `assert`
     calls and no `matlab.unittest` dependency (for example,
     `tests/octave_smoke.m`).
   - Name a value when a reader cannot tell what it is: a non-obvious
     expected value, a tolerance or threshold, or an input that several
     tests share. Keep indices, obvious literals, and option names
     inline, and add a short comment that says what each case checks.
     Name the actual result `returned` and the expectation `expected`.
4. Match the local style: 3-space indentation, lines wrapped near 80
   columns, every function closed with `end`. Follow these rules for
   input parsing:
   - Parse inputs to core analysis functions and demos with
     `inputParser`. Do not add `arguments` blocks to them: Octave
     cannot parse `arguments` blocks.
   - The `+internal` maintenance tooling and its private helpers are
     MATLAB-only. They may use `arguments` blocks. Before you add one,
     confirm that no core function or demo calls the function.
5. CI runs the suite on every push and pull request to `main` and
   `dev`. Maintainers merge a pull request only after its CI run passes.

## Build the docs

Run the docs build from MATLAB in the repository root:

    addpath('toolbox'); Setup('addpath'); baseflow.internal.makedocs()

The demo pages run every live script, and the two theory demos need the
Symbolic Math Toolbox. Without it, build the other parts with
`baseflow.internal.makedocs('functions', 'docpages', 'docsearch')`.
The function reference pages need Graphviz for the dependency graph.
On macOS, install it with `brew install graphviz`. The build uses the
copy of m2html in `tools/m2html`. m2html is licensed under
GPL-2.0-or-later and is not part of the toolbox. See
`tools/m2html/VENDORED.md`.

## Octave

The toolbox targets GNU Octave compatibility. Branch Octave-specific
behavior on the `isoctave` helper. Avoid MATLAB-only syntax in core
analysis functions and demos. The `+internal` maintenance tooling is
MATLAB-only.
