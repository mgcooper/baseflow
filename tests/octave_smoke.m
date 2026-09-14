% OCTAVE_SMOKE Core-chain smoke test runnable in GNU Octave and MATLAB.
%
% Plain script with bare asserts: load the example data, detect events,
% fit events, fit the a-b parameters with 'nls' and 'ols', then exercise
% the handle allocation in the vendored arrow annotation, which has an
% Octave-specific branch.
% TestSuite.fromFolder skips this script (not a valid test file), so it
% does not join the MATLAB suite. Run it directly with
% run('tests/octave_smoke.m') in either language. The script closes the
% figure it opens.

% Resolve paths relative to this script so the smoke test runs the same way
% from any working directory in Octave and in the MATLAB suite.
smokedir = fileparts(mfilename('fullpath'));
addpath(fullfile(fileparts(smokedir), 'toolbox'));
Setup('addpath');

% load the example data; the loader picks the datenum variant on Octave
[T, Q, R] = baseflow.loadExampleData();
assert(~isempty(Q) && numel(Q) == numel(T))

% detect recession events with the default options
opts_getevents = baseflow.setopts('getevents');
EventData = baseflow.getevents(T, Q, R, opts_getevents);
assert(isstruct(EventData) || istable(EventData))

% fit the individual events
opts_fitevents = baseflow.setopts('fitevents');
[EventFits, FitsTable] = baseflow.fitevents(EventData, opts_fitevents);
assert(~isempty(EventFits.q) && ~isempty(EventFits.dqdt))
assert(~isempty(FitsTable))

% fit the event-scale recession equation -dq/dt = aQ^b with 'nls'
abFit = baseflow.fitab(EventFits.q, EventFits.dqdt, 'nls');

% Require a struct whose 'ab' field holds two finite coefficients (a and
% b). Each condition is a separate assert, so a fit that returns no usable
% estimate fails the smoke test and the failing line names the condition.
assert(isstruct(abFit))
assert(isfield(abFit, 'ab'))
assert(isnumeric(abFit.ab))
assert(numel(abFit.ab) == 2)
assert(all(isfinite(abFit.ab)))

% fit the same equation with 'ols', which uses plain linear algebra and no
% Curve Fitting Toolbox functions, so it also runs on Octave
olsFit = baseflow.fitab(EventFits.q, EventFits.dqdt, 'ols');

% Require the same usable estimate as the 'nls' block, plus finite
% confidence bounds that bracket each coefficient
assert(isstruct(olsFit))
assert(isfield(olsFit, 'ab'))
assert(isnumeric(olsFit.ab))
assert(numel(olsFit.ab) == 2)
assert(all(isfinite(olsFit.ab)))
assert(olsFit.aL <= olsFit.a && olsFit.a <= olsFit.aH)
assert(olsFit.bL <= olsFit.b && olsFit.b <= olsFit.bH)

% exercise the vendored arrow handle allocation; close the figure the
% call opens. arrow.m reads the MATLAB-only hidden axes property
% WarpToFill (arrow_WarpToFill) and errors on Octave before it reaches
% the handle allocation. This section therefore runs on MATLAB only.
% TODO.md records the arrow Octave incompatibility.
if exist('OCTAVE_VERSION', 'builtin') == 0
   fig = figure('Visible', 'off');
   % close the figure on failure too, so no run leaves a figure open
   try
      axis([0 1 0 1]);
      harrow = baseflow.deps.arrow([0.2 0.2], [0.8 0.8]);
      assert(~isempty(harrow))
   catch arrowerror
      close(fig);
      rethrow(arrowerror);
   end
   close(fig);
else
   disp('octave_smoke: skipping arrow (WarpToFill is MATLAB-only)')
end

disp('octave_smoke: all asserts passed')
