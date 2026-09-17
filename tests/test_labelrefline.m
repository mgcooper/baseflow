classdef test_labelrefline < matlab.unittest.TestCase
   %TEST_LABELREFLINE Test the shared reference-line label.
   %
   % labelrefline is private, so the tests reach it with
   % baseflow.privatefunction. plotrefline and plotdqdt both call it, so a
   % reference line carries the same label in the point cloud and in the
   % event-scale fit plot. The arrow points at the line from the right, and
   % its head sits on the line. The 'line' style writes the label along the
   % line and draws no arrow.

   properties (TestParameter)
      % Slopes that reach the anchor height at different x. b = 1 is the
      % late-time line of a linear reservoir and b = 3 is the early-time
      % line.
      slope = struct('linear', 1, 'earlytime', 3, 'nonlinear', 1.5)
   end

   properties (Constant)
      % Axis limits of the test axes, in decades. The point cloud of a
      % daily record spans a comparable range.
      xlims = [1e3 1e8]
      ylims = [1e2 1e8]

      % Intercept of the test line, so the line crosses the axes.
      intercept = 1

      % The arrow must read as an arrow, not as a rule across the axes, so
      % its tail spans between these fractions of the drawn x decades.
      tailbounds = [1/50 1/10]

      % Rounding error allowed between a drawn and an expected position.
      tolerance = 1e-10
   end

   properties
      % Handle to the private function under test.
      labelrefline
      % Open-figure snapshot taken before each test.
      figsbefore
   end

   methods (TestClassSetup)
      function gethandle(testCase)
         % Store the private function handle once for every test.
         testCase.labelrefline = baseflow.privatefunction('labelrefline');
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
      function test_arrowHeadSitsOnTheLine(testCase, slope)
         % The head is the leftmost vertex of the arrow patch. Its point
         % must satisfy the equation of the line the label names.
         ax = testCase.loglogaxes();

         testCase.labelrefline(ax, testCase.intercept, slope, 'label');

         [xhead, yhead] = testCase.arrowhead(ax);
         y_expected = testCase.intercept * xhead^slope;
         testCase.verifyEqual(yhead, y_expected, ...
            'RelTol', testCase.tolerance)
      end

      function test_arrowTailIsShortEnoughToReadAsAnArrow(testCase, slope)
         % The tail runs right from the head, and spans a small part of
         % the x range, so it does not read as a rule across the axes.
         ax = testCase.loglogaxes();

         testCase.labelrefline(ax, testCase.intercept, slope, 'label');

         [xhead, ~, xtail] = testCase.arrowhead(ax);
         ndecsx = log10(testCase.xlims(2)) - log10(testCase.xlims(1));
         taildecades_returned = log10(xtail/xhead) / ndecsx;
         testCase.verifyGreaterThan(taildecades_returned, ...
            testCase.tailbounds(1))
         testCase.verifyLessThan(taildecades_returned, ...
            testCase.tailbounds(2))
      end

      function test_arrowStyleDrawsOneArrowAndOneLabel(testCase)
         % The arrow patch has HandleVisibility off, so findall finds it
         % and findobj does not.
         narrows_expected = 1;
         nlabels_expected = 1;
         ax = testCase.loglogaxes();

         testCase.labelrefline(ax, testCase.intercept, 1, 'label');

         testCase.verifyNumElements(findall(ax, 'Type', 'patch'), ...
            narrows_expected)
         testCase.verifyNumElements(findobj(ax, 'Type', 'text'), ...
            nlabels_expected)
      end

      function test_labelSitsBesideTheTail(testCase)
         % The text starts at the tail, at the height of the head, so the
         % arrow points from the text to the line.
         ax = testCase.loglogaxes();

         testCase.labelrefline(ax, testCase.intercept, 1, 'label');

         [~, yhead, xtail] = testCase.arrowhead(ax);
         position_returned = get(findobj(ax, 'Type', 'text'), 'Position');
         testCase.verifyGreaterThanOrEqual(position_returned(1), xtail)
         testCase.verifyEqual(position_returned(2), yhead, ...
            'RelTol', testCase.tolerance)
      end

      function test_colorAndFontSizeReachBothObjects(testCase)
         % A text object without an explicit color keeps ColorMode auto,
         % which a dark figure theme draws light grey, and one without an
         % explicit size takes the axes font size.
         color_expected = [0.8 0.1 0.1];
         fontsize_expected = 8;
         ax = testCase.loglogaxes();

         testCase.labelrefline(ax, testCase.intercept, 1, 'label', ...
            'Color', color_expected, 'FontSize', fontsize_expected);

         harrow = findall(ax, 'Type', 'patch');
         htext = findobj(ax, 'Type', 'text');
         testCase.verifyEqual(get(harrow, 'FaceColor'), color_expected)
         testCase.verifyEqual(get(harrow, 'EdgeColor'), color_expected)
         testCase.verifyEqual(get(htext, 'Color'), color_expected)
         testCase.verifyEqual(get(htext, 'FontSize'), fontsize_expected)
      end

      function test_emptyColorDrawsTheDefault(testCase)
         % islabelcolor accepts empty, which asks for the default color.
         color_expected = [0 0 0];
         ax = testCase.loglogaxes();

         testCase.labelrefline(ax, testCase.intercept, 1, 'label', ...
            'Color', []);

         testCase.verifyEqual( ...
            get(findobj(ax, 'Type', 'text'), 'Color'), color_expected)
      end

      function test_lineStyleWritesOnTheLineWithoutAnArrow(testCase, slope)
         % The line style lifts the text onto the line and turns it to the
         % drawn angle, so a label needs no arrow and Octave can draw it.
         narrows_expected = 0;
         ax = testCase.loglogaxes();

         testCase.labelrefline(ax, testCase.intercept, slope, 'label', ...
            'Style', 'line');

         testCase.verifyNumElements(findall(ax, 'Type', 'patch'), ...
            narrows_expected)
         htext = findobj(ax, 'Type', 'text');
         position_returned = get(htext, 'Position');
         y_expected = testCase.intercept * position_returned(1)^slope;
         testCase.verifyEqual(position_returned(2), y_expected, ...
            'RelTol', testCase.tolerance)
         testCase.verifyNotEqual(get(htext, 'Rotation'), 0)
      end

      function test_unknownStyleErrors(testCase)
         % The parser lists the styles labelrefline draws.
         ax = testCase.loglogaxes();

         testCase.verifyError( ...
            @() testCase.labelrefline(ax, testCase.intercept, 1, ...
            'label', 'Style', 'squiggle'), ...
            'MATLAB:unrecognizedStringChoice')
      end
   end

   methods (Access = private)
      function ax = loglogaxes(testCase)
         % Open an invisible figure with one log-log axes of known limits.
         fig = figure('Visible', 'off');
         testCase.addTeardown(@close, fig)
         ax = axes(fig);
         set(ax, 'XScale', 'log', 'YScale', 'log', ...
            'XLim', testCase.xlims, 'YLim', testCase.ylims)
      end

      function [xhead, yhead, xtail] = arrowhead(testCase, ax)
         % Return the point of the arrow and the right end of its tail.
         % The patch holds both, and the head is its leftmost vertex.
         harrow = findall(ax, 'Type', 'patch');
         testCase.assertNumElements(harrow, 1)
         xdata = get(harrow, 'XData');
         ydata = get(harrow, 'YData');
         [xhead, ihead] = min(xdata);
         yhead = ydata(ihead);
         xtail = max(xdata);
      end
   end
end
