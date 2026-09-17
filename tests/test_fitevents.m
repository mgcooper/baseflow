classdef test_fitevents < matlab.unittest.TestCase
   %TEST_FITEVENTS Test the fitevents plotfits option.
   %
   % fitevents passes plotfits to getdqdt, which draws one figure per
   % event. The cases use a short slice of the example data, so the event
   % loop stays fast.

   properties (TestParameter)
      % Whether the call asks for the event fit plots.
      plotfits = struct('plotsOff', false, 'plotsOn', true)
   end

   properties
      % Events detected in the data slice, and the figures open before the
      % test.
      Events
      figsbefore
   end

   methods (TestClassSetup)
      function detectevents(testCase)
         % Detect the events once. The slice holds a few events.
         nsamples = 800;
         [T, Q, R] = baseflow.loadExampleData();
         slice = 1:nsamples;
         testCase.Events = baseflow.getevents(T(slice), Q(slice), ...
            R(slice), baseflow.setopts('getevents'));
      end
   end

   methods (TestMethodSetup)
      function snapshotfigures(testCase)
         % Close the figures each case opens.
         testCase.figsbefore = findall(0, 'Type', 'figure');
         testCase.addTeardown(@() closenewfigs(testCase.figsbefore));
      end
   end

   methods (Test)
      function test_plotfitsDrawsEventFigures(testCase, plotfits)
         % plotfits false draws no figure. plotfits true draws one figure
         % per fitted event, so the count is positive and at most the
         % number of events.
         nevents = max(testCase.Events.eventTags);
         opts = baseflow.setopts('fitevents', 'plotfits', plotfits);

         Fits = baseflow.fitevents(testCase.Events, opts);

         testCase.verifyNotEmpty(Fits.q)
         newfigs_returned = numel(findall(0, 'Type', 'figure')) ...
            - numel(testCase.figsbefore);
         if plotfits
            testCase.verifyGreaterThan(newfigs_returned, 0)
            testCase.verifyLessThanOrEqual(newfigs_returned, nevents)
         else
            newfigs_expected = 0;
            testCase.verifyEqual(newfigs_returned, newfigs_expected)
         end
      end
   end
end
