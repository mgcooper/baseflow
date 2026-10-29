classdef test_hyetograph < matlab.unittest.TestCase
   %TEST_HYETOGRAPH Test the figure that baseflow.hyetograph draws in.
   %
   % hyetograph resizes and retags its figure. Each case opens a visible
   % figure first and checks which figure hyetograph uses: a new figure
   % when no axes is passed, or the figure of the axes that is passed.
   % The lookups in the hyetograph help must each return one handle: the
   % element of H that the help names.

   properties (TestParameter)
      % Whether the call passes the axes of the figure opened first.
      passaxes = struct('newFigure', false, 'suppliedAxes', true)

      % Each lookup in the hyetograph help: the property, its value, and
      % the element of H that the lookup must return.
      lookup = struct( ...
         'figureName', {{'Name', 'Hyetograph', 1}}, ...
         'figureTag', {{'Tag', 'HyetographFigure', 1}}, ...
         'streamflowAxes', {{'Tag', 'HyetographAxis', 2}}, ...
         'streamflowLine', {{'Tag', 'StreamflowPlot', 3}}, ...
         'precipitationBars', {{'Tag', 'PrecipitationPlot', 4}})
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

      function test_helpLookupFindsOneHandle(testCase, lookup)
         % A lookup from the figure H(1) returns exactly the element of H
         % that the help names, once.
         [property, value, index] = lookup{:};
         H = testCase.drawhyetograph();

         returned = findobj(H(1), property, value);

         testCase.verifyEqual(returned, H(index))
      end

      function test_precipitationAxesFromItsBars(testCase)
         % The precipitation axes has no tag. The help finds it as the
         % parent axes of the bars H(4): the reversed right-hand axes, not
         % the streamflow axes H(2).
         H = testCase.drawhyetograph();

         returned = ancestor(H(4), 'axes');

         testCase.verifyNotEqual(returned, H(2))
         testCase.verifyEqual(get(returned, 'YDir'), 'reverse')
      end
   end

   methods (Access = private)
      function H = drawhyetograph(~)
         %DRAWHYETOGRAPH Draw a 60-day hyetograph in a new figure.
         %
         %  H = drawhyetograph(testCase) returns the handles of
         %  baseflow.hyetograph for a falling flow with one rain day.
         ndays = 60;
         time = transpose(datetime(2001, 1, 1:ndays));
         flow = transpose(linspace(10, 1, ndays));
         prec = zeros(ndays, 1);
         prec(10) = 5;
         H = baseflow.hyetograph(time, flow, prec, time(1) - 1, ...
            time(end) + 1);
      end
   end
end
