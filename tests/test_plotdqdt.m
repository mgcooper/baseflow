classdef test_plotdqdt < matlab.unittest.TestCase
   %TEST_PLOTDQDT Test the reference lines, limits and labels of the fit plot.
   %
   % The reflines option selects the reference lines, so a caller can leave
   % out the measurement-precision line at the foot of the cloud. Every
   % decade inside the final limits carries a tick, and the axislimits
   % option selects how far a limit moves to reach its decade. The labels
   % take an explicit color and font size, the rain circles reach the
   % legend, and a supplied axes receives every part of the figure.

   properties (TestParameter)
      % The axis-limit policies. 'none' keeps the limits the data sets.
      axislimits = struct('snap', 'snap', 'decades', 'decades', ...
         'none', 'none')

      % Font sizes the labels must take. The default is the factory axes
      % font size, which a startup file can raise.
      labelfontsize = struct('factory', 10, 'large', 14)
   end

   properties (Constant)
      % The default discharge precision in m3 s-1 and the seconds in one
      % day. Their product is the height of the lower envelope for a daily
      % timestep.
      precision = 1
      secondsperday = 3600 * 24

      % An axes font size large enough to show that the labels do not
      % inherit it. The user startup file sets this value.
      axesfontsize = 16

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
      function test_reflinesSelectsTheLowerEnvelope(testCase)
         % The lower envelope is the horizontal line at the precision of
         % the record. The default draws it, and a list without it does
         % not, which is the only way to switch that line off.
         envelope_expected = testCase.precision * testCase.secondsperday;

         h = baseflow.plotdqdt(testCase.q, testCase.dqdt);
         testCase.verifyTrue(hasflatline(h.ax, envelope_expected))

         h = baseflow.plotdqdt(testCase.q, testCase.dqdt, ...
            'reflines', {'upperenvelope', 'late', 'early'});
         testCase.verifyFalse(hasflatline(h.ax, envelope_expected))
      end

      function test_lowerEnvelopeFollowsTheTimestep(testCase)
         % The lower envelope is the flow precision over one timestep, so
         % a quarter-day timestep raises it by four.
         timestep = 0.25;
         envelope_expected = testCase.precision * testCase.secondsperday ...
            / timestep;

         h = baseflow.plotdqdt(testCase.q, testCase.dqdt, ...
            'timestep', timestep);

         testCase.verifyTrue(hasflatline(h.ax, envelope_expected))
      end

      function test_subdailyTimestepFollowsTheLimitPolicy(testCase)
         % A subdaily timestep keeps the y limits at the data range
         % instead of reaching the upper envelope. The limit policy still
         % applies to that range.
         timestep = 0.25;

         h = baseflow.plotdqdt(testCase.q, testCase.dqdt, ...
            'timestep', timestep, 'axislimits', 'decades');

         ylims_returned = get(h.ax, 'YLim');
         testCase.verifyEqual(ylims_returned, ...
            10.^[floor(log10(ylims_returned(1))) ...
            ceil(log10(ylims_returned(2)))])
      end

      function test_emptyLabelColorDrawsTheDefault(testCase)
         % islabelcolor accepts empty, which asks for the default color.
         % The parser maps it to black, so the label draws.
         color_expected = [0 0 0];

         h = baseflow.plotdqdt(testCase.q, testCase.dqdt, ...
            'labelplot', true, 'labelcolor', []);

         labels = findobj(h.ax, 'Type', 'text');
         testCase.assertNotEmpty(labels)
         testCase.verifyEqual(get(labels(1), 'Color'), color_expected)
      end

      function test_everyDecadeInsideTheLimitsHasATick(testCase, axislimits)
         % The final y limit reaches the upper envelope at the largest Q,
         % which adds a decade to the axis after the lines set the ticks.
         h = baseflow.plotdqdt(testCase.q, testCase.dqdt, ...
            'axislimits', axislimits);

         verifydecadeticks(testCase, h.ax, 'X')
         verifydecadeticks(testCase, h.ax, 'Y')
      end

      function test_axisLimitsFollowThePolicy(testCase, axislimits)
         % 'none' keeps the limits the data sets, so the policy applied to
         % the limits of a 'none' figure gives the limits of every other.
         % plotdqdt pads no limit, so a limit that does not snap stays.
         reference = baseflow.plotdqdt(testCase.q, testCase.dqdt, ...
            'axislimits', 'none');
         xlims_expected = testCase.snaploglims( ...
            get(reference.ax, 'XLim'), [1 1], axislimits);
         ylims_expected = testCase.snaploglims( ...
            get(reference.ax, 'YLim'), [1 1], axislimits);

         h = baseflow.plotdqdt(testCase.q, testCase.dqdt, ...
            'axislimits', axislimits);

         testCase.verifyEqual(get(h.ax, 'XLim'), xlims_expected, ...
            'RelTol', testCase.tolerance)
         testCase.verifyEqual(get(h.ax, 'YLim'), ylims_expected, ...
            'RelTol', testCase.tolerance)
      end

      function test_labelOptionsReachTheLabels(testCase, labelfontsize)
         % A text object without an explicit size takes the axes font size,
         % and one without an explicit color follows the figure theme. Both
         % labels and both arrows must carry the option values instead.
         % labelrefline draws each arrow as a patch, as it does for the
         % point cloud, so the two figures label a line alike.
         color_expected = [0.8 0.1 0.1];
         narrows_expected = 2;
         fig = figure('Visible', 'off');
         testCase.addTeardown(@close, fig)
         ax = axes(fig, 'FontSize', testCase.axesfontsize);

         baseflow.plotdqdt(testCase.q, testCase.dqdt, 'ax', ax, ...
            'labelplot', true, 'labelcolor', color_expected, ...
            'labelfontsize', labelfontsize);

         ht = findobj(ax, 'Type', 'text');
         % The arrow patch has HandleVisibility off, so findall finds it
         % and findobj does not.
         ha = findall(ax, 'Type', 'patch');
         testCase.verifyNotEmpty(ht)
         testCase.verifyNumElements(ha, narrows_expected)
         for n = 1:numel(ht)
            testCase.verifyEqual(get(ht(n), 'FontSize'), labelfontsize)
            testCase.verifyEqual(get(ht(n), 'Color'), color_expected)
         end
         for n = 1:numel(ha)
            testCase.verifyEqual(get(ha(n), 'FaceColor'), color_expected)
            testCase.verifyEqual(get(ha(n), 'EdgeColor'), color_expected)
         end
      end

      function test_labelStyleLineDrawsOnTheLineInsteadOfAnArrow(testCase)
         % The line style writes the label along the line and draws no
         % arrow, so it also labels the lines on Octave.
         narrows_expected = 0;
         fig = figure('Visible', 'off');
         testCase.addTeardown(@close, fig)
         ax = axes(fig);

         baseflow.plotdqdt(testCase.q, testCase.dqdt, 'ax', ax, ...
            'labelplot', true, 'labelstyle', 'line');

         ht = findobj(ax, 'Type', 'text');
         testCase.verifyNotEmpty(ht)
         testCase.verifyEqual(numel(findall(ax, 'Type', 'patch')), ...
            narrows_expected)
         testCase.verifyTrue(any(arrayfun( ...
            @(h) get(h, 'Rotation') ~= 0, ht)))
      end

      function test_fontSizeOptionsReachTheAxesAndTheLegend(testCase)
         % The axes font size sets the tick labels, and the legend takes
         % its own size, so a startup file that raises the axes font size
         % does not enlarge either one.
         fontsize_expected = 9;
         legendfontsize_expected = 7;
         fig = figure('Visible', 'off');
         testCase.addTeardown(@close, fig)
         ax = axes(fig, 'FontSize', testCase.axesfontsize);

         h = baseflow.plotdqdt(testCase.q, testCase.dqdt, 'ax', ax, ...
            'fontsize', fontsize_expected, ...
            'legendfontsize', legendfontsize_expected);

         testCase.verifyEqual(get(h.ax, 'FontSize'), fontsize_expected)
         testCase.verifyEqual(get(get(h.ax, 'XLabel'), 'FontSize'), ...
            fontsize_expected)
         testCase.verifyEqual(get(h.leg, 'FontSize'), ...
            legendfontsize_expected)
      end

      function test_labelDefaultsAreBlackAtFactorySize(testCase)
         % The defaults must not follow the axes font size or the theme.
         color_expected = [0 0 0];
         fontsize_expected = 10;
         fig = figure('Visible', 'off');
         testCase.addTeardown(@close, fig)
         ax = axes(fig, 'FontSize', testCase.axesfontsize);

         baseflow.plotdqdt(testCase.q, testCase.dqdt, 'ax', ax, ...
            'labelplot', true);

         ht = findobj(ax, 'Type', 'text');
         testCase.verifyNotEmpty(ht)
         for n = 1:numel(ht)
            testCase.verifyEqual(get(ht(n), 'FontSize'), fontsize_expected)
            testCase.verifyEqual(get(ht(n), 'Color'), color_expected)
         end
      end

      function test_labelsOnlyTheReferenceLinesThatAreDrawn(testCase)
         % labelReflines labels the early-time and late-time lines. A
         % reflines list without them draws no arrow and raises no error.
         narrows_expected = 0;

         h = baseflow.plotdqdt(testCase.q, testCase.dqdt, ...
            'labelplot', true, 'reflines', {'upperenvelope'});

         narrows_returned = numel(findall(h.ax, 'Type', 'patch'));
         testCase.verifyEqual(narrows_returned, narrows_expected)
      end

      function test_rainJoinsTheLegend(testCase)
         % plotrain returns the handles of the rain circles, which the
         % legend guard tests with islinehandle. One positive value gives
         % one rain circle and one legend entry.
         rain = zeros(size(testCase.q));
         rain(1) = 5;

         h = baseflow.plotdqdt(testCase.q, testCase.dqdt, 'rain', rain);

         testCase.verifyTrue(any(strcmp(h.leg.String, 'rain')))
      end

      function test_theFigureTakesTheSharedSize(testCase)
         % The figure was pinned to [1 1], the bottom-left corner of the
         % screen, where the dock covers the axis labels. Only the size
         % belongs to this function, and pointcloudplot sizes its figure
         % through the same private helper. Its own suite,
         % tests/test_sizefigure.m, covers the position that is kept: a
         % window manager may move any figure to fit the screen, so a
         % position read here says nothing.
         sizefigure = baseflow.privatefunction('sizefigure');
         reference = figure('Visible', 'off');
         testCase.addTeardown(@close, reference)
         size_expected = get(sizefigure(reference), 'Position');

         h = baseflow.plotdqdt(testCase.q, testCase.dqdt);

         position_returned = get(ancestor(h.ax, 'figure'), 'Position');
         testCase.verifyEqual(position_returned(3:4), size_expected(3:4))
      end

      function test_drawsInSuppliedAxes(testCase)
         % Every axes-scoped call goes through the supplied axes, so the
         % other panel keeps its own children and no figure is opened.
         nlines_expected = 1;
         fig = figure('Visible', 'off', 'Position', [1 1 1200 900]);
         testCase.addTeardown(@close, fig)
         target = subplot(1, 2, 1, 'Parent', fig);
         other = subplot(1, 2, 2, 'Parent', fig);
         plot(other, 1:10, 1:10);
         axes(other)
         nfigs_expected = numel(findall(0, 'Type', 'figure'));

         h = baseflow.plotdqdt(testCase.q, testCase.dqdt, 'ax', target, ...
            'labelplot', true);

         testCase.verifyEqual(h.ax, target)
         testCase.verifyNotEmpty(findobj(target, 'Type', 'line'))
         testCase.verifyEqual(numel(findobj(other, 'Type', 'line')), ...
            nlines_expected)
         testCase.verifyEqual(numel(findall(0, 'Type', 'figure')), ...
            nfigs_expected)
      end
   end
end

function tf = hasflatline(ax, yvalue)
   % True when the axes holds a drawn line of constant y at yvalue. The
   % lower envelope has slope zero, so this is its signature.
   tf = false;
   hl = findobj(ax, 'Type', 'line');
   for n = 1:numel(hl)
      ydata = get(hl(n), 'YData');
      if numel(ydata) > 2 && all(ydata == yvalue)
         tf = true;
         return
      end
   end
end
