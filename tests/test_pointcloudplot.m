classdef test_pointcloudplot < matlab.unittest.TestCase
   %TEST_POINTCLOUDPLOT Test the point-cloud figure, its limits and its ticks.
   %
   % A reference line sets the axis ticks from the limits that are current
   % when the line is drawn, and pointcloudplot sets the final y limit after
   % the lines. Every decade inside the final limits must still carry a
   % tick. The axislimits option selects how far a limit moves to reach its
   % decade. The precision and timestep options must reach the envelope
   % lines, and a supplied axes must receive the plot without changing the
   % figure around it.

   properties (TestParameter)
      % The axis-limit policies. 'none' keeps the limits the data sets.
      axislimits = struct('snap', 'snap', 'decades', 'decades', ...
         'none', 'none')

      % Timestep of the x data in days. The upper-envelope intercept is
      % 2/timestep and the lower-envelope intercept is
      % precision*3600*24/timestep, so both move with it.
      timestep = struct('daily', 1, 'sixhourly', 0.25, 'fourdaily', 4)

      % Reference-line sets that reach the two legend-text branches. A fit
      % line gives one char entry, and a set without one gives a cell of
      % line names. The help calls reflines a cell array, so a caller can
      % pass the names in a column.
      rainreflines = struct( ...
         'withfitline', {{'upperenvelope', 'bestfit'}}, ...
         'withoutfitline', {{'upperenvelope', 'late'}}, ...
         'columnlist', {{'upperenvelope'; 'late'}})
   end

   properties (Constant)
      % Reference lines that exercise both envelopes, both time limits, and
      % the fit line.
      reflines = {'early', 'late', 'upperenvelope', 'lowerenvelope', ...
         'bestfit'}

      % The multipliers pointcloudplot applies to an x limit that does not
      % snap.
      xpad = [0.9 1.1]

      % Seconds in one day, the unit conversion in the lower envelope.
      secondsperday = 3600 * 24

      % Rounding error allowed between a drawn and an expected limit.
      tolerance = 1e-12
   end

   properties
      % Point-cloud test data.
      q
      dqdt
      % Handle to the private limit policy, used as the expected value.
      snaploglims
      % Open-figure snapshot taken before each test.
      figsbefore
   end

   methods (TestClassSetup)
      function preparecase(testCase)
         % Nonlinear test data (b = 1.5). The upper envelope at the largest
         % Q sits more than a decade above the data, so the final y limit
         % adds a decade that the reference lines could not tick.
         a = 1e-2;
         b = 1.5;
         q0 = 100;
         t = 1:100;
         [~, testCase.q, testCase.dqdt] = baseflow.generateTestData( ...
            a, b, q0, t);

         % The limit policy is the expected value of the drawn limits. Its
         % own suite is tests/test_snaploglims.m.
         testCase.snaploglims = baseflow.privatefunction('snaploglims');
      end
   end

   methods (TestMethodSetup)
      function snapshotfigures(testCase)
         % Record the figures that exist before the test runs.
         testCase.figsbefore = findall(0, 'Type', 'figure');
      end
   end

   methods (TestMethodTeardown)
      function closetestfigures(testCase)
         % Close figures created during the test (see tests/closenewfigs.m).
         closenewfigs(testCase.figsbefore)
      end
   end

   methods (Test)
      function test_everyDecadeInsideTheLimitsHasATick(testCase, axislimits)
         % The final y limit reaches the upper envelope at the largest Q,
         % which adds a decade to the axis after the lines set the ticks.
         out = testCase.drawcloud('axislimits', axislimits);

         verifydecadeticks(testCase, out.ax, 'X')
         verifydecadeticks(testCase, out.ax, 'Y')
      end

      function test_axisLimitsFollowThePolicy(testCase, axislimits)
         % 'none' keeps the limits the data sets, so the policy applied to
         % the limits of a 'none' figure gives the limits of every other.
         reference = testCase.drawcloud('axislimits', 'none');
         xlims_reference = get(reference.ax, 'XLim');
         ylims_reference = get(reference.ax, 'YLim');

         % The x limits of the reference figure carry the padding, so
         % divide it out to recover the data limits the policy sees.
         xlims_expected = testCase.snaploglims( ...
            xlims_reference ./ testCase.xpad, testCase.xpad, axislimits);
         ylims_expected = testCase.snaploglims( ...
            ylims_reference, [1 1], axislimits);

         out = testCase.drawcloud('axislimits', axislimits);

         testCase.verifyEqual(get(out.ax, 'XLim'), xlims_expected, ...
            'RelTol', testCase.tolerance)
         testCase.verifyEqual(get(out.ax, 'YLim'), ylims_expected, ...
            'RelTol', testCase.tolerance)
      end

      function test_envelopeInterceptFollowsTimestep(testCase, timestep)
         % pointcloudplot must forward precision and timestep to both
         % envelopes. The upper envelope is -dQ/dt = a*Q with a = 2/timestep
         % and the lower envelope is the discharge precision of the record
         % converted to that timestep.
         precision = 10;
         a_upper_expected = 2/timestep;
         a_lower_expected = precision * testCase.secondsperday / timestep;

         out = baseflow.pointcloudplot(testCase.q, testCase.dqdt, ...
            'reflines', {'upperenvelope', 'lowerenvelope'}, ...
            'precision', precision, 'timestep', timestep);

         testCase.verifyEqual(out.ab.upperenvelope(1), a_upper_expected)
         testCase.verifyEqual(out.ab.lowerenvelope(1), a_lower_expected)
      end

      function test_suppliedAxesKeepsTheFigureAndItsSibling(testCase)
         % A caller that supplies an axes owns the figure, so the figure
         % keeps its size and the other panel keeps its own children. Read
         % the position back rather than asserting the one asked for: a
         % window manager moves and resizes a figure to fit the screen.
         nlines_expected = 1;
         fig = figure('Visible', 'off', 'Position', [1 1 1200 900]);
         testCase.addTeardown(@close, fig)
         position_expected = get(fig, 'Position');
         target = subplot(1, 2, 1, 'Parent', fig);
         other = subplot(1, 2, 2, 'Parent', fig);
         plot(other, 1:10, 1:10);
         axes(other)

         out = testCase.drawcloud('ax', target);

         testCase.verifyEqual(get(fig, 'Position'), position_expected)
         testCase.verifyEqual(numel(findobj(other, 'Type', 'line')), ...
            nlines_expected)
         testCase.verifyNotEmpty(findobj(target, 'Type', 'line'))
         testCase.verifyEqual(out.ax, target)
      end

      function test_labelStyleReachesThePlotrefline(testCase)
         % The labelstyle option selects the arrow or the text on the
         % line, and pointcloudplot must forward it, so a caller reaches
         % the option without calling plotrefline itself.
         narrows_expected = 0;

         arrowfigure = testCase.drawcloud();
         linefigure = testCase.drawcloud('labelstyle', 'line');

         % The arrow patch has HandleVisibility off, so findall finds it
         % and findobj does not.
         testCase.verifyNotEmpty(findall(arrowfigure.ax, 'Type', 'patch'))
         testCase.verifyEqual( ...
            numel(findall(linefigure.ax, 'Type', 'patch')), ...
            narrows_expected)
      end

      function test_labelColorAndFontSizeReachTheLabels(testCase)
         % Without the options the labels follow the figure theme and the
         % axes font size, which a startup file can raise.
         color_expected = [0.8 0.1 0.1];
         labelfontsize_expected = 8;

         out = testCase.drawcloud('labelcolor', color_expected, ...
            'labelfontsize', labelfontsize_expected);

         ht = findobj(out.ax, 'Type', 'text');
         testCase.verifyNotEmpty(ht)
         for n = 1:numel(ht)
            testCase.verifyEqual(get(ht(n), 'Color'), color_expected)
            testCase.verifyEqual(get(ht(n), 'FontSize'), ...
               labelfontsize_expected)
         end
      end

      function test_fontSizeOptionsReachTheAxesAndTheLegend(testCase)
         % The axes font size sets the tick labels and the axis labels,
         % and the legend takes its own size.
         fontsize_expected = 9;
         legendfontsize_expected = 7;

         out = baseflow.pointcloudplot(testCase.q, testCase.dqdt, ...
            'fontsize', fontsize_expected, ...
            'legendfontsize', legendfontsize_expected);

         testCase.verifyEqual(get(out.ax, 'FontSize'), fontsize_expected)
         testCase.verifyEqual(get(get(out.ax, 'XLabel'), 'FontSize'), ...
            fontsize_expected)
         testCase.verifyEqual(get(get(out.ax, 'YLabel'), 'FontSize'), ...
            fontsize_expected)
         testCase.verifyEqual(get(out.legend, 'FontSize'), ...
            legendfontsize_expected)
      end

      function test_theFigureTakesTheSharedSize(testCase)
         % The figure was pinned to [0 0], the bottom-left corner of the
         % screen, where the dock covers the axis labels. Only the size
         % belongs to this function, and sizefigure sets it. Its own suite,
         % tests/test_sizefigure.m, covers the position that is kept: a
         % window manager may move any figure to fit the screen, so a
         % position read here says nothing.
         sizefigure = baseflow.privatefunction('sizefigure');
         reference = figure('Visible', 'off');
         testCase.addTeardown(@close, reference)
         size_expected = get(sizefigure(reference), 'Position');

         out = testCase.drawcloud();

         position_returned = get(ancestor(out.ax, 'figure'), 'Position');
         testCase.verifyEqual(position_returned(3:4), size_expected(3:4))
      end

      function test_rainJoinsTheLegend(testCase, rainreflines)
         % plotrain returns the handles of the rain circles, which the
         % legend guard tests with islinehandle. Two positive values give
         % two circles and one legend entry, so rain adds one entry to the
         % legend of the same figure drawn without it.
         rain = zeros(size(testCase.q));
         rain([1 2]) = 5;
         dry = baseflow.pointcloudplot(testCase.q, testCase.dqdt, ...
            'reflines', rainreflines);
         nentries_expected = numel(dry.legend.String) + 1;

         out = baseflow.pointcloudplot(testCase.q, testCase.dqdt, ...
            'rain', rain, 'reflines', rainreflines);

         testCase.verifyTrue(any(strcmp(out.legend.String, 'rain')))
         testCase.verifyEqual(numel(out.legend.String), nentries_expected)
      end
   end

   methods (Access = private)
      function out = drawcloud(testCase, varargin)
         % Draw the point cloud with the reference lines and the labels
         % these tests measure.
         out = baseflow.pointcloudplot(testCase.q, testCase.dqdt, ...
            'reflines', testCase.reflines, 'reflabels', true, varargin{:});
      end
   end
end
