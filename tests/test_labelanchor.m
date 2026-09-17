classdef test_labelanchor < matlab.unittest.TestCase
   %TEST_LABELANCHOR Test the private labelanchor helper.
   %
   % labelanchor is private, so the tests reach it with
   % baseflow.privatefunction. The anchor sits on the reference line one
   % factor-th of the y decades above the bottom of the axes, and the
   % search raises it until the anchor falls inside the axes.

   properties (Constant)
      % Axes limits and the starting factor that labelrefline uses.
      xlims = [1e2 1e5]
      ylims = [1e0 1e5]
      startfactor = 20

      % The anchor starts this fraction of the x decades inside the left
      % limit, so a centered label does not sit over the y axis.
      inset = 1/20
   end

   properties
      % The private labelanchor function handle.
      labelanchor
   end

   methods (TestClassSetup)
      function gethandle(testCase)
         % Store the private function handle once for every test.
         testCase.labelanchor = baseflow.privatefunction('labelanchor');
      end
   end

   methods (Test)
      function test_anchorSitsOnTheLine(testCase)
         % A line that reaches the starting height inside the axes keeps
         % the starting factor, and the anchor solves y = a*x^b.
         a = 1e-3;
         b = 1;
         tolerance = 1e-9;
         factor_expected = testCase.startfactor;

         [xa, ya, factor_returned] = testCase.labelanchor(a, b, ...
            testCase.xlims, testCase.ylims, testCase.startfactor);

         testCase.verifyEqual(factor_returned, factor_expected)
         testCase.verifyEqual(ya, a * xa^b, 'RelTol', tolerance)
         testCase.verifyGreaterThanOrEqual(xa, testCase.insetlimit())
      end

      function test_raisesAnchorIntoTheAxes(testCase)
         % A line that reaches the starting height left of the axes gets a
         % raised anchor, so the label starts inside the axes.
         a = 1;
         b = 1;
         tolerance = 1e-9;

         [xa, ya, factor_returned] = testCase.labelanchor(a, b, ...
            testCase.xlims, testCase.ylims, testCase.startfactor);

         testCase.verifyLessThan(factor_returned, testCase.startfactor)
         testCase.verifyGreaterThanOrEqual(xa, testCase.insetlimit())
         testCase.verifyEqual(ya, a * xa^b, 'RelTol', tolerance)
      end

      function test_stopsAtTheTopOfTheRange(testCase)
         % No anchor of a line this far left fits inside the axes. The
         % search stops at factor 1, which is the top of the y range, and
         % the call returns.
         a = 1e10;
         b = 1;
         tolerance = 1e-9;
         factor_expected = 1;
         ya_expected = testCase.ylims(2);

         [xa, ya, factor_returned] = testCase.labelanchor(a, b, ...
            testCase.xlims, testCase.ylims, testCase.startfactor);

         testCase.verifyEqual(factor_returned, factor_expected)
         testCase.verifyEqual(ya, ya_expected, 'RelTol', tolerance)
         testCase.verifyLessThan(xa, testCase.xlims(1))
      end

      function test_raisesAnchorClearOfTheLeftSpine(testCase)
         % A line that reaches the starting height just inside the left
         % limit still crowds the y axis, so the anchor is raised.
         tolerance = 1e-9;
         b = 1;

         % Pick a so the unraised anchor sits at the left limit exactly.
         ndecsy = log10(testCase.ylims(2)) - log10(testCase.ylims(1));
         ya_unraised = 10^(log10(testCase.ylims(1)) ...
            + ndecsy/testCase.startfactor);
         a = ya_unraised / testCase.xlims(1)^b;

         [xa, ya, factor_returned] = testCase.labelanchor(a, b, ...
            testCase.xlims, testCase.ylims, testCase.startfactor);

         testCase.verifyLessThan(factor_returned, testCase.startfactor)
         testCase.verifyGreaterThanOrEqual(xa, testCase.insetlimit())
         testCase.verifyEqual(ya, a * xa^b, 'RelTol', tolerance)
      end
   end

   methods (Access = private)
      function xstart = insetlimit(testCase)
         % The leftmost x an anchor may take.
         ndecsx = log10(testCase.xlims(2)) - log10(testCase.xlims(1));
         xstart = 10^(log10(testCase.xlims(1)) + testCase.inset * ndecsx);
      end
   end
end
