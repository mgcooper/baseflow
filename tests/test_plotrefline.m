classdef test_plotrefline < matlab.unittest.TestCase
   %TEST_PLOTREFLINE Test the upper-envelope reference line and its label.
   %
   % The upper envelope is -dQ/dt = a*Q^b with b = 1 and a = 2/timestep. The
   % label must sit on that line for every timestep, and the label must stay
   % off unless the caller asks for it.

   properties (TestParameter)
      % Timestep of the x data in days. The daily case gives a = 2. The
      % other cases give a different intercept, which moves the line and
      % the label with it.
      timestep = struct('daily', 1, 'sixhourly', 0.25, 'fourdaily', 4)
   end

   properties
      % Open-figure snapshot taken before each test.
      figsbefore
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
         axes(other)
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
   end
end
