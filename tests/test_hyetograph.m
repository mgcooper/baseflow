classdef test_hyetograph < matlab.unittest.TestCase
   %TEST_HYETOGRAPH Test the figure that baseflow.hyetograph draws in.
   %
   % hyetograph resizes and retags its figure. Each case opens a visible
   % figure first and checks which figure hyetograph uses: a new figure
   % when no axes is passed, or the figure of the axes that is passed.

   properties (TestParameter)
      % Whether the call passes the axes of the figure opened first.
      passaxes = struct('newFigure', false, 'suppliedAxes', true)
   end

   properties
      % Figures open before each test, so teardown closes only new ones.
      figsbefore
   end

   methods (TestMethodSetup)
      function snapshotfigures(testCase)
         % Record the open figures and close the new ones after the test.
         testCase.figsbefore = findall(0, 'Type', 'figure');
         testCase.addTeardown(@() closenewfigs(testCase.figsbefore));
      end
   end

   methods (Test)
      function test_figureChoice(testCase, passaxes)
         % A user figure keeps its name when hyetograph opens its own
         % figure, and gets the hyetograph name when its axes is passed.
         userfigname = 'user figure';
         userfig = figure('Visible', 'off', 'Name', userfigname);
         userax = axes(userfig);

         % Open a second figure, so the supplied axes is not current.
         otherfig = figure('Visible', 'off');
         ndays = 60;
         time = transpose(datetime(2001, 1, 1:ndays));
         flow = transpose(linspace(10, 1, ndays));
         prec = zeros(ndays, 1);
         t1 = time(1) - 1;
         t2 = time(end) + 1;

         if passaxes
            H = baseflow.hyetograph(time, flow, prec, t1, t2, userax);
            figure_expected = userfig;
         else
            H = baseflow.hyetograph(time, flow, prec, t1, t2);
            figure_expected = setdiff(findall(0, 'Type', 'figure'), ...
               [testCase.figsbefore; userfig; otherfig]);
         end

         % H(1) is the figure and H(2) the streamflow axes.
         figure_returned = H(1);
         axesparent_returned = get(H(2), 'Parent');
         testCase.verifyEqual(figure_returned, figure_expected)
         testCase.verifyEqual(axesparent_returned, figure_expected)
         testCase.verifyNotEqual(figure_returned, otherfig)
         if ~passaxes
            testCase.verifyEqual(get(userfig, 'Name'), userfigname)
         end
      end
   end
end
