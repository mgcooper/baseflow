classdef test_plotrefline < matlab.unittest.TestCase
   %TEST_PLOTREFLINE Test the reference lines and their labels.
   %
   % The upper envelope is -dQ/dt = a*Q^b with b = 1 and a = 2/timestep. The
   % label must sit on that line for every timestep, and the label must stay
   % off unless the caller asks for it.
   %
   % The labelcolor, labelfontsize, and labelstyle options control how the
   % labels are drawn. Each option must reach the drawn text, the drawn
   % arrow, or both, and the label must start inside the axes.

   properties (TestParameter)
      % Timestep of the x data in days. The daily case gives a = 2. The
      % other cases give a different intercept, which moves the line and
      % the label with it.
      timestep = struct('daily', 1, 'sixhourly', 0.25, 'fourdaily', 4)
      % The reference lines that addlabels labels. The first three take the
      % labelstyle option. The upper envelope is drawn along its line for
      % both styles.
      labelrefline = struct('latetime', 'latetime', ...
         'earlytime', 'earlytime', 'userfit', 'userfit', ...
         'upperenvelope', 'upperenvelope')
      % The three lines that take the labelstyle option.
      arrowrefline = struct('latetime', 'latetime', ...
         'earlytime', 'earlytime', 'userfit', 'userfit')
      % Both values of the labelstyle option.
      labelstyle = struct('arrow', 'arrow', 'line', 'line')
   end

   properties
      % Handle to the private function that gives the drawn angle of a
      % slope. Its own suite is tests/test_rotatedLogLogText.m, so these
      % tests use it as the expected value of a rotated label.
      loglogangle
      % Open-figure snapshot taken before each test.
      figsbefore
   end

   methods (TestClassSetup)
      function gethandles(testCase)
         % Store the private function handle once for every test.
         testCase.loglogangle = baseflow.privatefunction('loglogangle');
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
      function test_labelSitsOnUpperEnvelope(testCase, timestep)
         % The label goes halfway across the x range, on the line. Its y
         % coordinate follows a, so it holds for any timestep.
         ax = testCase.logaxes();
         tolerance = 1e-12;
         a_expected = 2/timestep;
         b_expected = 1;

         [~, ab_returned] = baseflow.plotrefline(testCase.q(), ...
            testCase.q(), 'refline', 'upperenvelope', 'labels', true, ...
            'timestep', timestep, 'ax', ax);

         ht = findobj(ax, 'Type', 'text');
         position_returned = get(ht, 'Position');
         xlims = log10(get(ax, 'XLim'));
         xtxt_expected = 10^(xlims(1) + (xlims(2) - xlims(1))/2);
         ytxt_expected = a_expected * xtxt_expected^b_expected;

         testCase.verifyEqual(ab_returned, [a_expected; b_expected])
         testCase.verifyNumElements(ht, 1)
         testCase.verifyEqual(position_returned(1), xtxt_expected, ...
            'RelTol', tolerance)
         testCase.verifyEqual(position_returned(2), ytxt_expected, ...
            'RelTol', tolerance)
      end

      function test_drawsInSuppliedAxes(testCase)
         % plotrefline draws its line in the axes the caller supplies,
         % even when another axes is current.
         fig = figure('Visible', 'off');
         testCase.addTeardown(@close, fig)
         target = subplot(1, 2, 1, 'Parent', fig);
         other = subplot(1, 2, 2, 'Parent', fig);
         set(target, 'XScale', 'log', 'YScale', 'log')
         % Make the other panel current without axes(), which shows and
         % raises the figure whatever the root default asks for.
         set(fig, 'CurrentAxes', other)
         nlines_expected = 0;

         baseflow.plotrefline(testCase.q(), testCase.q(), ...
            'refline', 'upperenvelope', 'ax', target);

         testCase.verifyNotEmpty(findobj(target, 'Type', 'line'))
         testCase.verifyEqual(numel(findobj(other, 'Type', 'line')), ...
            nlines_expected)
      end

      function test_arrowLabelStaysInSuppliedAxes(testCase)
         % The late-time label draws its text and an arrow in the current
         % axes of the current figure. plotrefline makes the supplied axes
         % current for that call, so the label joins its line and the
         % other figure keeps its own children and stays current.
         fig = figure('Visible', 'off');
         testCase.addTeardown(@close, fig)
         ax = axes(fig);
         set(ax, 'XScale', 'log', 'YScale', 'log')
         otherfig = figure('Visible', 'off');
         testCase.addTeardown(@close, otherfig)
         otherax = axes(otherfig);
         nchildren_expected = 0;

         baseflow.plotrefline(testCase.q(), testCase.q(), ...
            'refline', 'latetime', 'ax', ax, 'labels', true, 'userab', ...
            [1 1.5]);

         testCase.verifyNotEmpty(findobj(ax, 'Type', 'text'))
         testCase.verifyEqual(numel(get(otherax, 'Children')), ...
            nchildren_expected)
         testCase.verifyEqual(get(groot, 'CurrentFigure'), otherfig)
      end

      function test_labelsStayOffByDefault(testCase)
         % A caller that asks for no labels gets none. plotdqdt relies on
         % this default.
         ax = testCase.logaxes();

         baseflow.plotrefline(testCase.q(), testCase.q(), ...
            'refline', 'upperenvelope', 'ax', ax);

         testCase.verifyEmpty(findobj(ax, 'Type', 'text'))
      end

      function test_labelOptionsReachTheText(testCase, labelrefline, ...
            labelstyle)
         % Every labelled line takes its text color and font size from the
         % options. Without them the text keeps ColorMode auto, which a
         % dark figure theme draws light grey, and it keeps the axes font
         % size, which a startup file can raise.
         color_expected = [0.8 0.1 0.1];
         fontsize_expected = 9;
         ax = testCase.logaxes();

         testCase.drawlabeled(ax, labelrefline, ...
            'labelstyle', labelstyle, 'labelcolor', color_expected, ...
            'labelfontsize', fontsize_expected);

         ht = findobj(ax, 'Type', 'text');
         testCase.verifyNumElements(ht, 1)
         testCase.verifyEqual(get(ht, 'Color'), color_expected)
         testCase.verifyEqual(get(ht, 'FontSize'), fontsize_expected)
      end

      function test_labelColorReachesTheArrow(testCase, arrowrefline)
         % The arrow is a patch. Both of its colors come from labelcolor,
         % so the arrow matches the text it points from.
         color_expected = [0.8 0.1 0.1];
         ax = testCase.logaxes();

         testCase.drawlabeled(ax, arrowrefline, ...
            'labelstyle', 'arrow', 'labelcolor', color_expected);

         % The arrow patch has HandleVisibility off, so findall finds it
         % and findobj does not.
         harrow = findall(ax, 'Type', 'patch');
         testCase.verifyNumElements(harrow, 1)
         testCase.verifyEqual(get(harrow, 'FaceColor'), color_expected)
         testCase.verifyEqual(get(harrow, 'EdgeColor'), color_expected)
      end

      function test_labelColorFollowsLineColor(testCase, labelstyle)
         % A caller that sets only linecolor gets a label of that color, so
         % the label and its line read as one object in any figure theme.
         color_expected = [0 0 1];
         ax = testCase.logaxes();

         testCase.drawlabeled(ax, 'latetime', 'labelstyle', labelstyle, ...
            'linecolor', color_expected);

         ht = findobj(ax, 'Type', 'text');
         testCase.verifyEqual(get(ht, 'Color'), color_expected)
      end

      function test_labelFontSizeDefaultsToFactorySize(testCase)
         % The label takes the MATLAB factory axes font size. A startup
         % file can raise the axes font size, and the label keeps its own
         % size in that session.
         fontsize_expected = 10;
         axesfontsize = 16;
         ax = testCase.logaxes();
         set(ax, 'FontSize', axesfontsize)

         testCase.drawlabeled(ax, 'latetime');

         ht = findobj(ax, 'Type', 'text');
         testCase.verifyEqual(get(ht, 'FontSize'), fontsize_expected)
      end

      function test_lineStyleDrawsTheLabelOnTheLine(testCase, arrowrefline)
         % The line style replaces the arrow with rotated text on the line.
         % The anchor satisfies y = a*x^b, and the rotation is the drawn
         % angle of the line, which follows the axes size and the limits.
         tolerance = 1e-9;
         narrows_expected = 0;
         ax = testCase.logaxes();

         ab_returned = testCase.drawlabeled(ax, arrowrefline, ...
            'labelstyle', 'line');
         drawnow

         ht = findobj(ax, 'Type', 'text');
         position_returned = get(ht, 'Position');
         y_expected = ab_returned(1) * position_returned(1)^ab_returned(2);
         rotation_expected = testCase.loglogangle(ax, ab_returned(2));

         testCase.verifyNumElements(findall(ax, 'Type', 'patch'), ...
            narrows_expected)
         testCase.verifyEqual(position_returned(2), y_expected, ...
            'RelTol', tolerance)
         testCase.verifyEqual(get(ht, 'Rotation'), rotation_expected, ...
            'AbsTol', tolerance)
      end

      function test_lineStyleKeepsTheArrowStyleText(testCase, arrowrefline)
         % The two styles differ in what they draw, not in what they say.
         ax = testCase.logaxes();
         other = testCase.logaxes();

         testCase.drawlabeled(ax, arrowrefline, 'labelstyle', 'arrow');
         testCase.drawlabeled(other, arrowrefline, 'labelstyle', 'line');

         string_expected = get(findobj(ax, 'Type', 'text'), 'String');
         string_returned = get(findobj(other, 'Type', 'text'), 'String');
         testCase.verifyEqual(string_returned, string_expected)
      end

      function test_anchorGuardKeepsTheLabelInsideAxes(testCase, labelstyle)
         % addlabels anchors the label above YLim(1) and solves the line
         % for that height. The guard case reaches the anchor height left
         % of the axes, so addlabels must raise the anchor until the label
         % starts inside XLim.
         [xlims, ylims, userab] = testCase.guardcase();
         ax = testCase.guardaxes(xlims, ylims);

         testCase.drawlabeled(ax, 'userfit', 'userab', userab, ...
            'labelstyle', labelstyle);

         position_returned = get(findobj(ax, 'Type', 'text'), 'Position');
         testCase.verifyLessThan(testCase.defaultanchor(ylims, userab), ...
            xlims(1))
         testCase.verifyGreaterThanOrEqual(position_returned(1), xlims(1))
         testCase.verifyLessThanOrEqual(position_returned(1), xlims(2))
         testCase.verifyGreaterThanOrEqual(position_returned(2), ylims(1))
         testCase.verifyLessThanOrEqual(position_returned(2), ylims(2))
      end

      function test_anchorGuardKeepsTheArrowInsideAxes(testCase)
         % The arrow points back down the line to the anchor, so the raised
         % anchor also keeps the arrow shaft off the left spine.
         [xlims, ylims, userab] = testCase.guardcase();
         ax = testCase.guardaxes(xlims, ylims);

         testCase.drawlabeled(ax, 'userfit', 'userab', userab, ...
            'labelstyle', 'arrow');

         xdata_returned = get(findall(ax, 'Type', 'patch'), 'XData');
         testCase.verifyGreaterThanOrEqual(min(xdata_returned), xlims(1))
         testCase.verifyLessThanOrEqual(max(xdata_returned), xlims(2))
      end
   end

   methods (Static, Access = private)
      function q = q()
         % Three decades of discharge. The upper envelope does not fit the
         % data, so the values only set the x range of the reference line.
         q = transpose(logspace(0, 3, 50));
      end

      function ax = logaxes()
         % Build the log-log axes that plotrefline draws into. The figure
         % is invisible, so a headless run and a desktop run agree.
         fig = figure('Visible', 'off', 'Position', [100 100 550 510]);
         ax = axes('Parent', fig);
         loglog(ax, test_plotrefline.q(), test_plotrefline.q(), 'o');
         hold(ax, 'on')
      end

      function ax = guardaxes(xlims, ylims)
         % Build log-log axes with the limits of the guard case. The axes
         % holds no data, so the limits stay where the test set them.
         fig = figure('Visible', 'off', 'Position', [100 100 550 510]);
         ax = axes('Parent', fig);
         set(ax, 'XScale', 'log', 'YScale', 'log', ...
            'XLim', xlims, 'YLim', ylims)
         hold(ax, 'on')
      end

      function [xlims, ylims, userab] = guardcase()
         % Axes limits and a user fit whose default label anchor falls left
         % of the axes. The line of slope 1 through the origin of the log
         % axes reaches the anchor height at x = 1.78, and XLim(1) is 100.
         xlims = [1e2 1e5];
         ylims = [1e0 1e5];
         userab = [1 1];
      end

      function xa = defaultanchor(ylims, ab)
         % The x coordinate of the label anchor before the guard raises it.
         % addlabels starts one twentieth of the y decades above YLim(1)
         % and solves y = a*x^b for x.
         defaultfactor = 20;
         ndecsy = log10(ylims(2)) - log10(ylims(1));
         ya = 10^(log10(ylims(1)) + ndecsy/defaultfactor);
         xa = (ya/ab(1))^(1/ab(2));
      end

      function ab = drawlabeled(ax, refline, varargin)
         % Draw one labelled reference line and give back its a/b pair.
         % Trailing arguments pass through to plotrefline.
         [~, ab] = baseflow.plotrefline(test_plotrefline.q(), ...
            test_plotrefline.q(), 'refline', refline, 'ax', ax, ...
            'labels', true, varargin{:});
      end
   end
end
