classdef test_setlogticks < matlab.unittest.TestCase
   %TEST_SETLOGTICKS Test the decade ticks of a log axis.
   %
   % setlogticks places one tick on every decade the axis limits reach. An
   % axis whose limits no decade can serve, for example a linear axis that
   % spans zero or an axis inside one decade, keeps the ticks it has. A
   % limit of zero is replaced by the smallest plotted value, which the
   % axes can hold in one array per child.

   properties (Constant)
      % Ticks the helper must place on an axis that spans [1, 12].
      ticks_expected = [1 10]
   end

   properties
      % Handle to the private function under test.
      setlogticks
      % Open-figure snapshot taken before each test.
      figsbefore
   end

   methods (TestClassSetup)
      function gethandle(testCase)
         % Store the private function handle once for every test.
         testCase.setlogticks = baseflow.privatefunction('setlogticks');
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
      function test_zeroLimitTakesTheSmallestPlottedValue(testCase)
         % getplotdata returns one cell per child when several children
         % carry the data, so the smallest value comes from every child.
         ax = testCase.emptyplot();
         plot(ax, 1:10, 1:10);
         plot(ax, 1:10, 2:11);
         set(ax, 'XLim', [0 12], 'YLim', [0 12])

         testCase.setlogticks(ax);

         testCase.verifyEqual(get(ax, 'XTick'), testCase.ticks_expected)
         testCase.verifyEqual(get(ax, 'YTick'), testCase.ticks_expected)
      end

      function test_zeroLimitWithNoPositiveDataKeepsTheTicks(testCase)
         % The zero limit has no replacement, so the axis is left alone.
         ax = testCase.emptyplot();
         plot(ax, [-3 -2 -1], [-3 -2 -1]);
         set(ax, 'XLim', [-4 0], 'YLim', [-4 0])
         ticks_before = get(ax, 'XTick');

         testCase.setlogticks(ax);

         testCase.verifyEqual(get(ax, 'XTick'), ticks_before)
      end

      function test_linearAxisAcrossZeroKeepsTheTicks(testCase)
         % A limit of zero or below has no log10, so no decade can serve it.
         ax = testCase.emptyplot();
         plot(ax, -5:5, -5:5);
         set(ax, 'XLim', [-5 5], 'YLim', [-5 5])
         ticks_before = get(ax, 'XTick');

         testCase.setlogticks(ax);

         testCase.verifyEqual(get(ax, 'XTick'), ticks_before)
      end

      function test_axisInsideOneDecadeKeepsTheTicks(testCase)
         % [2e4 9e4] holds no whole decade, so the computed tick list is
         % empty and the ticks the axis has must survive.
         ax = testCase.emptyplot();
         plot(ax, [2e4 9e4], [1 2]);
         set(ax, 'XScale', 'log', 'XLim', [2e4 9e4])
         ticks_before = 5e4;
         set(ax, 'XTick', ticks_before)

         testCase.setlogticks(ax, 'axset', 'x');

         testCase.verifyEqual(get(ax, 'XTick'), ticks_before)
      end

      function test_subUnitRangeKeepsItsTicks(testCase)
         % [0.2 0.9] lies below one decade and below one, so the computed
         % decade 1 falls outside the limits. The axis keeps its ticks.
         ax = testCase.emptyplot();
         plot(ax, [0.2 0.9], [1 2]);
         set(ax, 'XScale', 'log', 'XLim', [0.2 0.9])
         ticks_before = 0.5;
         set(ax, 'XTick', ticks_before)
         outsidetick = 1;

         testCase.setlogticks(ax, 'axset', 'x');

         testCase.verifyEqual(get(ax, 'XTick'), ticks_before)
         testCase.verifyFalse(ismember(outsidetick, get(ax, 'XTick')))
      end

      function test_logAxisTakesOneTickPerDecade(testCase)
         % The usual case: every decade the limits reach carries a tick.
         ax = testCase.emptyplot();
         plot(ax, [1 1e4], [1 1e4]);
         set(ax, 'XScale', 'log', 'YScale', 'log', ...
            'XLim', [1 1e4], 'YLim', [1 1e4])
         decadeticks_expected = [1 10 100 1000 10000];

         testCase.setlogticks(ax);

         testCase.verifyEqual(get(ax, 'XTick'), decadeticks_expected)
         testCase.verifyEqual(get(ax, 'YTick'), decadeticks_expected)
      end
   end

   methods (Access = private)
      function ax = emptyplot(testCase)
         % Open an invisible figure with one axes that holds the plot.
         fig = figure('Visible', 'off');
         testCase.addTeardown(@close, fig)
         ax = axes(fig);
         hold(ax, 'on')
      end
   end
end
