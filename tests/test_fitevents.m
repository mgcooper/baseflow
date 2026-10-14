classdef test_fitevents < matlab.unittest.TestCase
   %TEST_FITEVENTS Test the fitevents plotfits, fitorder, and ctsmethod options.
   %
   % fitevents passes plotfits to getdqdt, which draws one figure per
   % event. The plotfits cases use a short slice of the example data, so
   % the event loop stays fast. fitevents must pass fitorder to fitab and
   % ctsmethod to getdqdt. The ctsmethod cases fit the first event of the
   % full example record.

   properties (TestParameter)
      % Whether the call asks for the event fit plots.
      plotfits = struct('plotsOff', false, 'plotsOn', true)

      % The constant-time-step stencils fitevents passes to getdqdt.
      CtsMethod = {'B1','B2','F1','F2','C2','C4'};
   end

   properties
      % Events detected in the data slice, and the figures open before the
      % test.
      Events
      figsbefore

      % The first recession event in the example data. The class setup
      % builds it once so the fitevents tests do not repeat getevents.
      firstevent
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

      function loadfirstevent(testCase)
         % Detect events in the example data. Keep only the first event so
         % each fitevents call fits one event and the tests stay fast.
         [T, Q, R] = baseflow.loadExampleData();
         Events = baseflow.getevents(T, Q, R);
         ievent = Events.eventTags == 1;
         testCase.firstevent = struct( ...
            'eventTime', Events.eventTime(ievent), ...
            'eventFlow', Events.eventFlow(ievent), ...
            'eventRain', Events.eventRain(ievent), ...
            'eventTags', Events.eventTags(ievent));
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

      %-------------------------------------------
      %-------------------------------------------
      function test_fitevents_fitorder(testCase)

         % build a one-event Events structure from nonlinear test data
         a = 1e-2;
         b = 1.5;
         q0 = 100;
         t = 1:100;
         % Note: generateTestData returns its own t, sized to match q
         [t,q] = baseflow.generateTestData(a,b,q0,t);
         Events.eventTime = t;
         Events.eventFlow = q;
         Events.eventRain = zeros(size(q));
         Events.eventTags = ones(size(q));

         % fitevents must pass 'fitorder' to fitab so the event is fit
         % with a linear reservoir model
         [~,Results] = baseflow.fitevents(Events,'fitorder',1);

         % Verify a fit was returned and the exponent is forced to 1
         returned = Results.b;
         testCase.verifyNotEmpty(returned);
         expected = ones(size(returned));
         testCase.verifyEqual(returned,expected);
      end

      %-------------------------------------------
      %-------------------------------------------
      function test_fitevents_ctsmethod(testCase,CtsMethod)

         % fitevents must pass 'ctsmethod' to getdqdt, so the dq/dt it
         % stores for the event equals a direct getdqdt call
         Event = testCase.firstevent;
         [~,expected] = baseflow.getdqdt(Event.eventTime, ...
            Event.eventFlow,Event.eventRain,'CTS','ctsmethod',CtsMethod);
         returned = baseflow.fitevents(Event,'derivmethod','CTS', ...
            'ctsmethod',CtsMethod,'plotfits',false);
         testCase.verifyEqual(returned.dqdt,expected);
      end
   end
end
