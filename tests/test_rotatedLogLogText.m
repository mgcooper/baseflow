classdef test_rotatedLogLogText < matlab.unittest.TestCase
   %TEST_ROTATEDLOGLOGTEXT Test the rotated log-log label and its angle.
   %
   % rotatedLogLogText and loglogangle are private, so the tests reach them
   % with baseflow.privatefunction. The expected angle comes from the axes
   % box in pixels and the number of decades in each limit, computed in the
   % test without loglogangle. The drawn angle of one slope changes with the
   % figure size and with the axis limits, so the cases sweep both.

   properties (TestParameter)
      % Slopes that the toolbox draws. 0 is the lower envelope, 1 is the
      % upper envelope, 1.5 is the Brutsaert-Nieber late-time slope, and 3
      % is the early-time slope.
      slope = struct('flat', 0, 'unit', 1, 'late', 1.5, 'early', 3)
      % Figure size in pixels, XLim, and YLim. The wide case changes the
      % pixels per decade in x, and the sixdecades case changes them in y.
      axescase = struct( ...
         'stock', {{[550 510], [1e0 1e3], [1e0 1e3]}}, ...
         'wide', {{[1100 420], [1e0 1e3], [1e0 1e3]}}, ...
         'sixdecades', {{[550 510], [1e0 1e3], [1e0 1e6]}})
   end

   properties
      % Handles to the private functions under test.
      loglogangle
      rotatedLogLogText
      % Open-figure snapshot taken before each test.
      figsbefore
   end

   methods (TestClassSetup)
      function gethandles(testCase)
         % Store the private function handles once for every test.
         testCase.loglogangle = baseflow.privatefunction('loglogangle');
         testCase.rotatedLogLogText = ...
            baseflow.privatefunction('rotatedLogLogText');
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
      function test_angleFromPixelBox(testCase, slope, axescase)
         % The angle is the arctangent of the rise over the run in pixels,
         % so it follows the axes size and the limits, not the slope alone.
         ax = testCase.logaxes(axescase);
         tolerance = 1e-9;

         returned = testCase.loglogangle(ax, slope);

         testCase.verifyEqual(returned, testCase.pixelangle(ax, slope), ...
            'AbsTol', tolerance)
      end

      function test_labelSitsOnLine(testCase, slope, axescase)
         % The label keeps the anchor the caller gave it, the anchor is on
         % the line of slope b, and the drawn rotation is the drawn angle
         % of that line.
         ax = testCase.logaxes(axescase);
         tolerance = 1e-9;
         [xtxt, ytxt, a] = testCase.anchor(ax, slope);

         ht = testCase.rotatedLogLogText(ax, xtxt, ytxt, 'label', slope);
         drawnow

         position_returned = get(ht, 'Position');
         rotation_returned = get(ht, 'Rotation');

         testCase.verifyEqual(position_returned(1:2), [xtxt ytxt], ...
            'RelTol', tolerance)
         testCase.verifyEqual(position_returned(2), ...
            a * position_returned(1)^slope, 'RelTol', tolerance)
         testCase.verifyEqual(rotation_returned, ...
            testCase.pixelangle(ax, slope), 'AbsTol', tolerance)
      end

      function test_rotationFollowsFigure(testCase, slope)
         % A resize and a limit change both change the pixels per decade.
         % The listener rewrites the rotation on the next redraw.
         ax = testCase.logaxes(testCase.stockcase());
         [xtxt, ytxt] = testCase.anchor(ax, slope);

         % The listener writes only when the angle moves by more than 0.01
         % degrees, so the drawn angle can lag the true angle by that much.
         tolerance = 0.02;

         ht = testCase.rotatedLogLogText(ax, xtxt, ytxt, 'label', slope);
         drawnow

         set(ancestor(ax, 'figure'), 'Position', [100 100 1100 420]);
         drawnow
         testCase.verifyEqual(get(ht, 'Rotation'), ...
            testCase.pixelangle(ax, slope), 'AbsTol', tolerance)

         set(ax, 'YLim', [1e0 1e6]);
         drawnow
         testCase.verifyEqual(get(ht, 'Rotation'), ...
            testCase.pixelangle(ax, slope), 'AbsTol', tolerance)
      end

      function test_restoresAxesUnits(testCase)
         % loglogangle reads the plot box in pixels, so it must give the
         % caller back the units it found, including for axes in a panel.
         unitslope = 1;
         units_expected = 'normalized';
         fig = figure('Visible', 'off');
         testCase.addTeardown(@close, fig)
         panel = uipanel(fig);
         ax = axes(panel);
         set(ax, 'XScale', 'log', 'YScale', 'log', 'Units', units_expected)
         drawnow

         testCase.loglogangle(ax, unitslope);

         units_returned = get(ax, 'Units');
         testCase.verifyEqual(units_returned, units_expected)
      end

      function test_squareAxesAngle(testCase)
         % axis square draws a smaller plot box than the axes Position, so
         % the angle comes from the drawn box. Equal decade counts in a
         % square box give 45 degrees for a slope of one.
         unitslope = 1;
         tolerance = 1e-6;
         angle_expected = 45;
         fig = figure('Visible', 'off', 'Position', [100 100 900 400]);
         testCase.addTeardown(@close, fig)
         ax = axes(fig);
         set(ax, 'XScale', 'log', 'YScale', 'log', ...
            'XLim', [1 1e3], 'YLim', [1 1e3])
         axis(ax, 'square')
         drawnow

         angle_returned = testCase.loglogangle(ax, unitslope);

         testCase.verifyEqual(angle_returned, angle_expected, ...
            'AbsTol', tolerance)
      end

      function test_deletedLabelRedraw(testCase)
         % The listener outlives the label it rotates. A redraw after the
         % label is deleted must not raise the invalid-handle error.
         unitslope = 1;
         ax = testCase.logaxes(testCase.stockcase());
         [xtxt, ytxt] = testCase.anchor(ax, unitslope);

         ht = testCase.rotatedLogLogText(ax, xtxt, ytxt, 'label', unitslope);
         drawnow
         delete(ht)

         testCase.verifyWarningFree(@() drawnow)
      end

      function test_linearScaleIsRejected(testCase)
         % b is a power-law exponent, so loglogangle errors on a linear
         % scale. The redraw callback keeps the drawn angle instead of
         % raising that error from the listener.
         unitslope = 1;
         ax = testCase.logaxes(testCase.stockcase());
         [xtxt, ytxt] = testCase.anchor(ax, unitslope);

         ht = testCase.rotatedLogLogText(ax, xtxt, ytxt, 'label', unitslope);
         drawnow
         rotation_expected = get(ht, 'Rotation');
         set(ax, 'YScale', 'linear');

         testCase.verifyWarningFree(@() drawnow)
         testCase.verifyEqual(get(ht, 'Rotation'), rotation_expected)
         testCase.verifyError(@() testCase.loglogangle(ax, unitslope), ...
            'baseflow:loglogangle:scaleNotLog')
      end
   end

   methods (Static, Access = private)
      function axescase = stockcase()
         % The figure size that pointcloudplot sets, with three decades on
         % each axis. The tests that sweep slope alone use this case.
         axescase = {[550 510], [1e0 1e3], [1e0 1e3]};
      end

      function ax = logaxes(axescase)
         % Build the log-log axes of one test case. The figure is
         % invisible, so a headless run and a desktop run agree.
         figsize = axescase{1};
         xlims = axescase{2};
         ylims = axescase{3};

         fig = figure('Visible', 'off', 'Position', [100 100 figsize]);
         ax = axes('Parent', fig);
         set(ax, 'XScale', 'log', 'YScale', 'log', ...
            'XLim', xlims, 'YLim', ylims);
         hold(ax, 'on')
      end

      function theta = pixelangle(ax, b)
         % The drawn angle of a line of slope b, in degrees, from the axes
         % box in pixels. Setting Units reads the same box that
         % getpixelposition returns, so this shares no code with
         % loglogangle.
         oldunits = get(ax, 'Units');
         set(ax, 'Units', 'pixels');
         pixelbox = get(ax, 'Position');
         set(ax, 'Units', oldunits);

         xlims = log10(get(ax, 'XLim'));
         ylims = log10(get(ax, 'YLim'));
         ndecx = xlims(2) - xlims(1);
         ndecy = ylims(2) - ylims(1);

         theta = atand(b * (pixelbox(4)/ndecy) / (pixelbox(3)/ndecx));
      end

      function [xtxt, ytxt, a] = anchor(ax, b)
         % A point one third across the x range, on the line of slope b
         % through the middle of the axes. The label goes there, and the
         % tests check that it stays on that line.
         xlims = log10(get(ax, 'XLim'));
         ylims = log10(get(ax, 'YLim'));
         a = 10^mean(ylims) / (10^mean(xlims))^b;
         xtxt = 10^(xlims(1) + (xlims(2) - xlims(1))/3);
         ytxt = a * xtxt^b;
      end
   end
end
