% OCTAVE_SMOKE Core-chain smoke test runnable in GNU Octave and MATLAB.
%
% Plain script with bare asserts: load the example data, detect events,
% fit events, fit the a-b parameters with 'nls' and 'ols', then draw the
% point cloud, the event-scale fit plot, and a labeled reference line,
% which are the figures with an Octave-specific branch.
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

% fit an 'ols' trend line with a non-default alpha. trendplot calls fitlm,
% coefCI, and predict, which the Octave statistics package also provides.
% Require a finite trend and bounds that bracket the fitted line.
t = transpose(datetime(1990:2020, 7, 1));
y = transpose(0.3 * (1:31) + sin(1:31));
htrend = baseflow.trendplot(t, y, 'method', 'ols', 'alpha', 0.1, ...
   'anomalies', false, 'showfig', false);
close(htrend.figure);
assert(all(isfinite(htrend.ab)))
assert(all(htrend.yci(:, 1) <= htrend.yfit & htrend.yfit <= htrend.yci(:, 2)))

% draw the point cloud. pointcloudplot formats its markers through the
% private formatPlotMarkers, and puts the rain circles in the legend
% through the private islinehandle. Both take the numeric graphics handle
% that Octave returns for a plotted line. One positive rain value draws one
% circle, which the legend must name.
[Fits, FitsTable] = baseflow.fitevents(EventData, opts_fitevents);
[~, qtau, dqdttau] = baseflow.eventtau(FitsTable, EventData, Fits);
raintau = zeros(size(qtau));
raintau(1) = 5;
hcloud = baseflow.pointcloudplot(qtau, dqdttau, 'rain', raintau, ...
   'reflines', {'upperenvelope', 'late'}, 'reflabels', true);
% read the drawn lines and the legend, then close, so a failed assert
% leaves no figure open
ncloudlines = numel(findobj(hcloud.ax, 'Type', 'line'));
legendtext = get(hcloud.legend, 'String');
close(ancestor(hcloud.ax, 'figure'));
assert(ncloudlines > 0)
assert(any(strcmp(legendtext, 'rain')))

% draw the event-scale fit plot with rain. plotdqdt scales its rain
% circles from the marker size of the plotted line, which it must read
% with get, because Octave returns a numeric handle. The legend then names
% the rain through the same islinehandle guard the point cloud uses.
rainfit = zeros(size(EventFits.q));
rainfit(1) = 5;
% The 'line' label style draws no arrow, so it labels the reference lines
% on Octave, where the vendored arrow cannot draw. Its text carries the
% angle of the line.
hfits = baseflow.plotdqdt(EventFits.q, EventFits.dqdt, 'rain', rainfit, ...
   'labelplot', true, 'labelstyle', 'line');
fitlegendtext = get(hfits.leg, 'String');
fitlabels = findobj(hfits.ax, 'Type', 'text');
nfitlabels = numel(fitlabels);
close(ancestor(hfits.ax, 'figure'));
assert(any(strcmp(fitlegendtext, 'rain')))
assert(nfitlabels > 0)

% draw a reference line with its rotated label. plotrefline calls the
% private rotatedLogLogText, which computes the drawn angle of the line.
% Octave has no MarkedClean listener, so the label keeps the angle it
% gets at creation.
figref = figure('Visible', 'off');
axref = axes(figref);
set(axref, 'XScale', 'log', 'YScale', 'log')
qref = transpose(logspace(0, 3, 50));
baseflow.plotrefline(qref, qref, 'refline', 'upperenvelope', ...
   'ax', axref, 'labels', true);
% read the label and its angle, then close, for the same reason
htxt = findobj(axref, 'Type', 'text');
nlabels = numel(htxt);
if nlabels > 0
   labelrotation = get(htxt(1), 'Rotation');
else
   labelrotation = nan;
end
close(figref);
assert(nlabels > 0)
assert(isfinite(labelrotation))

% draw a reference line with an arrow label. drawarrow builds the head
% from the drawn plot box, so the arrow style labels a line on Octave. It
% tags the head patch and the shaft line.
figarrow = figure('Visible', 'off');
axarrow = axes(figarrow);
set(axarrow, 'XScale', 'log', 'YScale', 'log')
baseflow.plotrefline(qref, qref, 'refline', 'latetime', ...
   'ax', axarrow, 'labels', true, 'labelstyle', 'arrow');
nheads = numel(findall(axarrow, 'Tag', 'refarrowhead'));
nshafts = numel(findall(axarrow, 'Tag', 'refarrowshaft'));
close(figarrow);
assert(nheads == 1)
assert(nshafts == 1)

disp('octave_smoke: all asserts passed')
