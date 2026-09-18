classdef test_getdqdt < matlab.unittest.TestCase
   %TEST_GETDQDT Test the getdqdt fit-plot option.
   %
   % getdqdt passes plotfits to plotdqdt, which fits the point cloud to
   % draw its line. fitmethod 'none' asks for no fit, so getdqdt draws
   % nothing for that method.

   properties (TestParameter)
      % The fit method getdqdt passes to plotdqdt.
      fitmethod = struct('nls', 'nls', 'none', 'none')
   end

   properties
      % One recession event from the example data, and the figures open
      % before each test.
      eventT
      eventQ
      eventR
      figsbefore
   end

   methods (TestClassSetup)
      function buildevent(testCase)
         % Take the first detected event of a short data slice.
         nsamples = 800;
         [T, Q, R] = baseflow.loadExampleData();
         slice = 1:nsamples;
         Events = baseflow.getevents(T(slice), Q(slice), R(slice), ...
            baseflow.setopts('getevents'));
         first = Events.eventTags == 1;
         testCase.eventT = Events.eventTime(first);
         testCase.eventQ = Events.eventFlow(first);
         testCase.eventR = Events.eventRain(first);
      end
   end

   methods (TestMethodSetup)
      function snapshotfigures(testCase)
         % Close the figures each case opens.
         testCase.figsbefore = findall(0, 'Type', 'figure');
         testCase.addTeardown(@() closenewfigs(testCase.figsbefore));

         % A nonlinear fit that stops at the iteration limit warns. The
         % fit plots reach that limit on the example record, so the
         % warning is expected output here rather than a problem to print.
         % A user still sees it.
         testCase.applyFixture( ...
            matlab.unittest.fixtures.SuppressedWarningsFixture( ...
            'stats:nlinfit:IterationLimitExceeded'));
      end
   end

   methods (Test)
      function test_plotKeepsRandomStream(testCase)
         % The 'qtl' fit bootstraps, so the display fit must leave the
         % random stream where the analysis fit expects it. Draw with
         % plotfits true from a fixed seed, then compare the next random
         % value with the value a run without plotting gives.
         seed = 1;
         nextvalue_expected = testCase.nextrandom(seed, false);

         nextvalue_returned = testCase.nextrandom(seed, true);

         testCase.verifyEqual(nextvalue_returned, nextvalue_expected)
      end

      function test_plotfitsByFitmethod(testCase, fitmethod)
         % plotfits draws one figure for a real fit method and none for
         % 'none', which asks for no fit.
         [q_returned, dqdt_returned] = baseflow.getdqdt(testCase.eventT, ...
            testCase.eventQ, testCase.eventR, 'ETS', ...
            'fitmethod', fitmethod, 'plotfits', true);

         testCase.verifyNotEmpty(q_returned)
         testCase.verifyNotEmpty(dqdt_returned)
         newfigs_returned = numel(findall(0, 'Type', 'figure')) ...
            - numel(testCase.figsbefore);
         if strcmp(fitmethod, 'none')
            newfigs_expected = 0;
         else
            newfigs_expected = 1;
         end
         testCase.verifyEqual(newfigs_returned, newfigs_expected)
      end
   end

   methods (Access = private)
      function nextvalue = nextrandom(testCase, seed, plotfits)
         % Run the quantile fit through getdqdt from a fixed seed and
         % return the next random value.
         rng(seed)
         baseflow.getdqdt(testCase.eventT, testCase.eventQ, ...
            testCase.eventR, 'ETS', 'fitmethod', 'qtl', ...
            'plotfits', plotfits);
         nextvalue = rand;
      end
   end
end
