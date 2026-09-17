classdef test_islinehandle < matlab.unittest.TestCase
   %TEST_ISLINEHANDLE Test the private islinehandle predicate.
   %
   % islinehandle is private, so the tests reach it with
   % baseflow.privatefunction. The plotting functions call it on the value
   % plot returns, which is a graphics object in MATLAB and a numeric
   % handle in Octave, and on the nan they store when they draw no line.

   properties
      % The private islinehandle function handle.
      islinehandle
      % Open-figure snapshot taken before each test.
      figsbefore
   end

   methods (TestClassSetup)
      function gethandle(testCase)
         % Store the private function handle once for every test.
         testCase.islinehandle = baseflow.privatefunction('islinehandle');
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
      function test_graphicsObjectIsALineHandle(testCase)
         % The value plot returns in MATLAB.
         hl = testCase.plotline();

         testCase.verifyTrue(testCase.islinehandle(hl))
      end

      function test_numericHandleIsALineHandle(testCase)
         % The value plot returns in Octave. double() gives the numeric
         % form of the same line in MATLAB, so the branch is testable in
         % both languages.
         hl = testCase.plotline();

         testCase.verifyTrue(testCase.islinehandle(double(hl)))
      end

      function test_severalHandlesAreLineHandles(testCase)
         % plotrain draws one circle per wet day, so the guard takes a
         % vector of handles.
         nlines = 3;
         hl = arrayfun(@(k) testCase.plotline(), 1:nlines);

         testCase.verifyTrue(testCase.islinehandle(double(hl)))
      end

      function test_nanIsNotALineHandle(testCase)
         % The plotting functions store nan when they draw no rain, and
         % the legend guard must leave that entry out.
         testCase.verifyFalse(testCase.islinehandle(nan))
      end

      function test_emptyIsNotALineHandle(testCase)
         % all([]) is true, so empty needs its own guard.
         testCase.verifyFalse(testCase.islinehandle([]))
      end

      function test_deletedHandleIsNotALineHandle(testCase)
         % A closed figure leaves a stale handle, which is not drawn.
         hl = testCase.plotline();
         stalehandle = double(hl);
         delete(hl)

         testCase.verifyFalse(testCase.islinehandle(stalehandle))
      end
   end

   methods (Access = private)
      function hl = plotline(testCase)
         % Plot one line in an invisible figure and return its handle.
         fig = figure('Visible', 'off');
         testCase.addTeardown(@close, fig)
         hl = plot(axes(fig), 1:10, 1:10);
      end
   end
end
