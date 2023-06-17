classdef geteventsTest < matlab.unittest.TestCase
   methods (Test)
      function testWithDefaultOpts(testCase)
      T = datetime(2000, 1, 1:10);
      Q = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
      R = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0];

      % Assuming the expected output based on default options
      % and input data
      expectedEvents.inputTime = T;
      expectedEvents.inputFlow = Q;
      expectedEvents.inputRain = R;

      % Add your expected results here
      % expectedEvents.eventTime = ...
      % expectedEvents.eventFlow = ...
      % expectedEvents.eventTags = ...

      [Events, Info] = getevents(T, Q, R);

      testCase.verifyEqual(Events, expectedEvents);
      % You can add more assertions to check the output 'Info'
      end

      function testWithCustomOpts(testCase)
      T = datetime(2000, 1, 1:10);
      Q = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
      R = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0];

      % Specify custom options
      opts.qmin = 2;
      opts.nmin = 2;
      opts.fmax = 2;
      opts.rmax = 2;
      opts.rmin = 0.1;
      opts.cmax = 2;
      opts.rmconvex = false;
      opts.rmnochange = false;
      opts.rmrain = false;
      opts.pickevents = false;
      opts.plotevents = false;

      % Assuming the expected output based on custom options
      % and input data
      expectedEvents.inputTime = T;
      expectedEvents.inputFlow = Q;
      expectedEvents.inputRain = R;

      % Add your expected results here
      % expectedEvents.eventTime = ...
      % expectedEvents.eventFlow = ...
      % expectedEvents.eventTags = ...

      [Events, Info] = getevents(T, Q, R, opts);

      testCase.verifyEqual(Events, expectedEvents);
      % You can add more assertions to check the output 'Info'
      end
   end
end
