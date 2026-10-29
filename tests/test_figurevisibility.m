classdef test_figurevisibility < matlab.unittest.TestCase
   %TEST_FIGUREVISIBILITY Test the visibility of a figure asked to show.
   %
   % figurevisibility is private, so the tests reach it with
   % baseflow.privatefunction. A figure created with an explicit 'Visible'
   % of 'on' ignores the root default, so a function that takes a show
   % option asks this helper what to draw. baseflow.internal.runtests sets
   % that default to off for the length of a test run, and the helper then
   % answers 'off' whatever the caller asked for.

   properties (TestParameter)
      % Each case holds the request and the answer with no root default.
      request = struct('show', {{true, 'on'}}, 'hide', {{false, 'off'}})
   end

   properties
      % Handle to the private function under test.
      figurevisibility
   end

   methods (TestClassSetup)
      function gethandle(testCase)
         % Store the private function handle once for every test.
         testCase.figurevisibility = ...
            baseflow.privatefunction('figurevisibility');
      end
   end

   methods (Test)
      function test_answersTheRequestWithNoRootDefault(testCase, request)
         % With no default set, the caller's request stands.
         [show, visibility_expected] = request{:};
         testCase.setrootdefault('remove');

         returned = testCase.figurevisibility(show);

         testCase.verifyEqual(returned, visibility_expected)
      end

      function test_answersTheRequestWhenTheRootAsksForVisible(testCase)
         % A root default of 'on' leaves the request alone, so a caller
         % that asked to hide a figure still hides it.
         visibility_expected = 'off';
         testCase.setrootdefault('on');

         returned = testCase.figurevisibility(false);

         testCase.verifyEqual(returned, visibility_expected)
      end

      function test_rootDefaultOffOverridesTheRequest(testCase)
         % This is the test-run case: the figure is drawn, and no window
         % opens, whatever the caller asked for.
         visibility_expected = 'off';
         testCase.setrootdefault('off');

         returned = testCase.figurevisibility(true);

         testCase.verifyEqual(returned, visibility_expected)
      end

      function test_theFigureItAnswersForOpensNoWindow(testCase)
         % The answer reaches a real figure, which is what the callers do.
         visibility_expected = 'off';
         testCase.setrootdefault('off');

         fig = figure('Visible', testCase.figurevisibility(true));
         testCase.addTeardown(@close, fig)

         testCase.verifyEqual(char(get(fig, 'Visible')), visibility_expected)
      end
   end

   methods (Access = private)
      function setrootdefault(testCase, visibility)
         % Set the root figure default for one test, and put back what the
         % session had. 'remove' clears the default, which is the state of
         % a session that set none, and reading a default the root never
         % set errors, so ask which defaults exist first.
         defaults = get(groot, 'default');
         if isfield(defaults, 'defaultFigureVisible')
            previous = get(groot, 'defaultFigureVisible');
         else
            previous = 'remove';
         end
         testCase.addTeardown( ...
            @() set(groot, 'defaultFigureVisible', previous))
         set(groot, 'defaultFigureVisible', visibility);
      end
   end
end
