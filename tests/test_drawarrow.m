classdef test_drawarrow < matlab.unittest.TestCase
   %TEST_DRAWARROW Test the arrow of a reference-line label.
   %
   % drawarrow is private, so the tests reach it with
   % baseflow.privatefunction. The head is a triangle of a fixed size in
   % pixels, built from the drawn plot box, so the arrow keeps its shape on
   % a log axis and on an axes whose plot-box aspect ratio is manual. The
   % vendored +deps/arrow reads the undocumented WarpToFill instead, which
   % axis square turns off.

   properties (TestParameter)
      % Axis scales the arrow must draw on.
      scale = struct('loglog', {{'log', 'log'}}, ...
         'linear', {{'linear', 'linear'}}, ...
         'semilogx', {{'log', 'linear'}})
   end

   properties (Constant)
      % A log-log box of five decades in x and six in y.
      xlims = [1e3 1e8]
      ylims = [1e2 1e8]

      % The head length in pixels, and the width the tip angle gives it.
      headlength = 8
      tipangle = 10

      % Rounding error allowed between a drawn and an expected position.
      tolerance = 1e-9
   end

   properties
      % Handles to the private functions under test.
      drawarrow
      axespixelbox
      % Open-figure snapshot taken before each test.
      figsbefore
   end

   methods (TestClassSetup)
      function gethandles(testCase)
         % Store the private function handles once for every test.
         testCase.drawarrow = baseflow.privatefunction('drawarrow');
         testCase.axespixelbox = baseflow.privatefunction('axespixelbox');
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
      function test_pointSitsWhereItIsAsked(testCase, scale)
         % The point of the head is the value the caller gives, on every
         % combination of axis scales.
         ax = testCase.testaxes(scale{:});
         head_expected = [1e4 1e3];
         tail = [1e5 1e3];

         testCase.drawarrow(ax, tail, head_expected);

         hhead = findall(ax, 'Tag', 'refarrowhead');
         xdata = get(hhead, 'XData');
         ydata = get(hhead, 'YData');
         [xpoint, ipoint] = min(xdata);
         testCase.verifyEqual(xpoint, head_expected(1), ...
            'RelTol', testCase.tolerance)
         testCase.verifyEqual(ydata(ipoint), head_expected(2), ...
            'RelTol', testCase.tolerance)
      end

      function test_shaftRunsFromTheTailToTheHead(testCase)
         % The shaft starts at the tail and stops at the base of the head,
         % so the two parts meet and the arrow reads as one object.
         ax = testCase.testaxes('log', 'log');
         head = [1e4 1e3];
         tail = [1e5 1e3];

         testCase.drawarrow(ax, tail, head);

         hshaft = findall(ax, 'Tag', 'refarrowshaft');
         hhead = findall(ax, 'Tag', 'refarrowhead');
         shaftx = get(hshaft, 'XData');
         testCase.verifyEqual(max(shaftx), tail(1), ...
            'RelTol', testCase.tolerance)
         testCase.verifyEqual(min(shaftx), max(get(hhead, 'XData')), ...
            'RelTol', testCase.tolerance)
      end

      function test_headKeepsItsSizeInPixels(testCase)
         % The head is headlength pixels long whatever the axis limits
         % are, so a wider axis draws the same head.
         ax = testCase.testaxes('log', 'log');
         head = [1e4 1e3];
         tail = [1e6 1e3];
         axpos = testCase.axespixelbox(ax);
         decadesperpixel = (log10(testCase.xlims(2)) ...
            - log10(testCase.xlims(1))) / axpos(3);
         headdecades_expected = testCase.headlength * decadesperpixel;

         testCase.drawarrow(ax, tail, head, 'Length', testCase.headlength);

         hhead = findall(ax, 'Tag', 'refarrowhead');
         xdata = get(hhead, 'XData');
         testCase.verifyEqual(log10(max(xdata)/min(xdata)), ...
            headdecades_expected, 'RelTol', 1e-6)
      end

      function test_squareAxesMeasuresTheDrawnBox(testCase)
         % axis square draws a box smaller than the axes Position. The
         % head must follow the drawn box, so it stays the size it is
         % asked for instead of stretching with the Position.
         ax = testCase.testaxes('log', 'log');
         axis(ax, 'square')
         head = [1e4 1e3];
         tail = [1e6 1e3];
         axpos = testCase.axespixelbox(ax);
         decadesperpixel = (log10(testCase.xlims(2)) ...
            - log10(testCase.xlims(1))) / axpos(3);
         headdecades_expected = testCase.headlength * decadesperpixel;

         testCase.drawarrow(ax, tail, head, 'Length', testCase.headlength);

         xdata = get(findall(ax, 'Tag', 'refarrowhead'), 'XData');
         testCase.verifyEqual(log10(max(xdata)/min(xdata)), ...
            headdecades_expected, 'RelTol', 1e-6)
      end

      function test_headIsNoLongerThanTheArrow(testCase)
         % A head longer than the shaft would reach past the tail, so it
         % is clamped and the shaft keeps a length to draw.
         ax = testCase.testaxes('log', 'log');
         head = [1e4 1e3];
         tail = [1.05e4 1e3];
         longhead = 500;

         testCase.drawarrow(ax, tail, head, 'Length', longhead);

         hhead = findall(ax, 'Tag', 'refarrowhead');
         hshaft = findall(ax, 'Tag', 'refarrowshaft');
         testCase.verifyLessThanOrEqual(max(get(hhead, 'XData')), tail(1))
         testCase.verifyGreaterThan(max(get(hshaft, 'XData')), ...
            min(get(hshaft, 'XData')))
      end

      function test_colorReachesTheShaftAndTheHead(testCase)
         % One color option covers both parts, so an arrow matches the
         % label it points from in any figure theme.
         color_expected = [0.8 0.1 0.1];
         ax = testCase.testaxes('log', 'log');

         testCase.drawarrow(ax, [1e6 1e3], [1e4 1e3], ...
            'Color', color_expected);

         hshaft = findall(ax, 'Tag', 'refarrowshaft');
         hhead = findall(ax, 'Tag', 'refarrowhead');
         testCase.verifyEqual(get(hshaft, 'Color'), color_expected)
         testCase.verifyEqual(get(hhead, 'FaceColor'), color_expected)
         testCase.verifyEqual(get(hhead, 'EdgeColor'), color_expected)
      end

      function test_bothPartsStayOutOfTheLegend(testCase)
         % An arrow is an annotation, not a plotted series, so a legend
         % that collects the children of the axes must not name it.
         ax = testCase.testaxes('log', 'log');

         testCase.drawarrow(ax, [1e6 1e3], [1e4 1e3]);

         testCase.verifyEmpty(findobj(ax, 'Type', 'line'))
         testCase.verifyEmpty(findobj(ax, 'Type', 'patch'))
         testCase.verifyNotEmpty(findall(ax, 'Tag', 'refarrowshaft'))
         testCase.verifyNotEmpty(findall(ax, 'Tag', 'refarrowhead'))
      end

      function test_emptyColorDrawsTheDefault(testCase)
         % islabelcolor accepts empty, which asks for the default color,
         % and the graphics Color property takes no empty value.
         color_expected = [0 0 0];
         ax = testCase.testaxes('log', 'log');

         testCase.drawarrow(ax, [1e6 1e3], [1e4 1e3], 'Color', []);

         testCase.verifyEqual( ...
            get(findall(ax, 'Tag', 'refarrowshaft'), 'Color'), ...
            color_expected)
         testCase.verifyEqual( ...
            get(findall(ax, 'Tag', 'refarrowhead'), 'FaceColor'), ...
            color_expected)
      end

      function test_zeroLengthArrowDrawsNothing(testCase)
         % An arrow of no length has no direction to point in.
         ax = testCase.testaxes('log', 'log');
         point = [1e4 1e3];

         returned = testCase.drawarrow(ax, point, point);

         testCase.verifyEmpty(returned)
         testCase.verifyEmpty(findall(ax, 'Tag', 'refarrowhead'))
      end
   end

   methods (Access = private)
      function ax = testaxes(testCase, xscale, yscale)
         % Open an invisible figure with one axes of known scales and
         % limits.
         fig = figure('Visible', 'off', 'Position', [100 100 640 600]);
         testCase.addTeardown(@close, fig)
         ax = axes(fig);
         set(ax, 'XScale', xscale, 'YScale', yscale, ...
            'XLim', testCase.xlims, 'YLim', testCase.ylims)
      end
   end
end
