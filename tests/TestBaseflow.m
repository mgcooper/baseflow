classdef TestBaseflow < matlab.unittest.TestCase
   %TESTBASEFLOW Test the baseflow toolbox workflow.
   % 
   % TestBaseflow is the integration suite for the toolbox workflow. It
   % holds the checks that span the event-detection entry points:
   %     1) an equality test for the getevents, eventfinder, and wrapevents
   %        defaults against baseflow.setopts('getevents'), and a negative
   %        test for rmax <= 1
   %
   % The unit tests of each function are in tests/test_<function_name>.m.
   % test_corechain runs the analysis chain on the example data.
   %
   % Notes:
   %     A) A negative test verifies that the code errors/fails in an
   %        expected way (e.g., the code gives the right error for a
   %        specific bad input)
   % 
   % See also: test_internal

   properties (TestParameter)
      SetupOption = {'install','uninstall','dependencies','addpath','savepath','rmpath','delpath'};
      EventFunction = {'getevents', 'eventfinder', 'wrapevents'};
   end

   properties (Access = private)
      % Open-figure snapshot taken before each test. The method teardown
      % closes only figures the test created, so a full suite run leaves
      % zero open figures without touching pre-existing user figures.
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

      %-------------------------------------------
      %-------------------------------------------
      function test_eventdefaults(testCase, EventFunction)

         % A call without options must use the setopts('getevents')
         % defaults. wrapevents needs complete calendar years, so all three
         % functions use the Kuparuk data. eventfinder rejects the setopts
         % fields that it does not parse, so remove them from its struct.
         [T, Q, R] = baseflow.loadExampleData('kuparuk');
         opts = baseflow.setopts('getevents');
         if strcmp(EventFunction, 'eventfinder')
            opts = rmfield(opts, {'qmin', 'cmax', 'pickevents', ...
               'plotevents', 'asannual'});
         end

         % Compare the first two outputs: events and Info, or event times
         % and flows for eventfinder
         eventfunction = str2func(['baseflow.' EventFunction]);
         expected = cell(1, 2);
         returned = cell(1, 2);
         [expected{:}] = eventfunction(T, Q, R, opts);
         [returned{:}] = eventfunction(T, Q, R);
         testCase.verifyEqual(returned, expected)
      end

      %-------------------------------------------
      %-------------------------------------------
      function test_rmaxguard(testCase, EventFunction)

         % rmax must be greater than 1, because each nan counts as a run of
         % length 1 and rmnochange would reject every day. wrapevents
         % passes rmax to getevents, which raises the error.
         [T, Q, R] = baseflow.loadExampleData('kuparuk');
         eventfunction = str2func(['baseflow.' EventFunction]);
         validator = strrep(EventFunction, 'wrapevents', 'getevents');
         testCase.verifyError(@() eventfunction(T, Q, R, 'rmax', 1), ...
            ['MATLAB:' validator ':notGreater'])
      end

   end
end
