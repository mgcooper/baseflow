classdef test_sizefigure < matlab.unittest.TestCase
   %TEST_SIZEFIGURE Test the size of a point-cloud figure.
   %
   % sizefigure is private, so the tests reach it with
   % baseflow.privatefunction. pointcloudplot and plotdqdt both draw a
   % log-log point cloud, so both take the size of the figure from here.
   % The position belongs to whatever opened the figure: pinning it to the
   % bottom-left corner of the screen puts the axis labels under the dock.

   properties (Constant)
      % The size the helper sets, in points.
      size_expected = [640 600]
   end

   properties
      % Handle to the private function under test.
      sizefigure
      % Open-figure snapshot taken before each test.
      figsbefore
   end

   methods (TestClassSetup)
      function gethandle(testCase)
         % Store the private function handle once for every test.
         testCase.sizefigure = baseflow.privatefunction('sizefigure');
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
      function test_keepsThePositionItWasGiven(testCase)
         % Read the position back before and after the call, on the same
         % figure, so the check holds whatever position the figure was
         % given.
         fig = testCase.invisiblefigure();
         position_before = get(fig, 'Position');

         testCase.sizefigure(fig);

         position_returned = get(fig, 'Position');
         testCase.verifyEqual(position_returned(1:2), position_before(1:2))
      end

      function test_setsTheSharedSize(testCase)
         % Both point-cloud figures take this size, so the axis labels fit.
         fig = testCase.invisiblefigure();

         testCase.sizefigure(fig);

         position_returned = get(fig, 'Position');
         testCase.verifyEqual(position_returned(3:4), testCase.size_expected)
      end

      function test_returnsTheFigureItSized(testCase)
         % The caller chains the call, as plotdqdt does.
         fig = testCase.invisiblefigure();

         returned = testCase.sizefigure(fig);

         testCase.verifyEqual(returned, fig)
      end
   end

   methods (Access = private)
      function fig = invisiblefigure(testCase)
         % Open a figure the test closes, with a position of its own.
         fig = figure('Visible', 'off', 'Position', [120 140 300 250]);
         testCase.addTeardown(@close, fig)
      end
   end
end
