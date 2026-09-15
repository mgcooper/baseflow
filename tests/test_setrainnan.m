classdef test_setrainnan < matlab.unittest.TestCase
   %TEST_SETRAINNAN Test the private setrainnan helper.
   %
   % setrainnan is private, so the tests reach it with
   % baseflow.privatefunction. Each case puts rain above the threshold rmin
   % at chosen samples. The expected flow is nan at those samples and at
   % their direct neighbors, and unchanged elsewhere.

   properties (TestParameter)
      % Each case holds the flow q, the rain r, and the expected flow.
      rain = struct( ...
         'interior', {{[1; 2; 3; 4; 5], [0; 0; 5; 0; 0], ...
         [1; nan; nan; nan; 5]}}, ...
         'firstSample', {{[1; 2; 3; 4; 5], [5; 0; 0; 0; 0], ...
         [nan; nan; 3; 4; 5]}}, ...
         'lastSample', {{[1; 2; 3], [0; 0; 5], [1; nan; nan]}}, ...
         'atThreshold', {{[1; 2; 3; 4], [1; 1; 1; 1], [1; 2; 3; 4]}}, ...
         'rowVectors', {{[1, 2, 3, 4, 5], [0, 0, 5, 0, 0], ...
         [1, nan, nan, nan, 5]}})
   end

   properties
      % The private setrainnan function handle.
      setrainnan
   end

   methods (TestClassSetup)
      function gethandle(testCase)
         % Store the private function handle once for every test.
         testCase.setrainnan = baseflow.privatefunction('setrainnan');
      end
   end

   methods (Test)
      function test_setsRainSamplesNan(testCase, rain)
         % Rain above rmin sets the sample and its neighbors nan. Rain equal
         % to rmin does not exceed it.
         [q, r, expected] = rain{:};
         rmin = 1;

         returned = testCase.setrainnan(q, r, rmin);
         testCase.verifyEqual(returned, expected)
      end
   end
end
