classdef test_anomaly < matlab.unittest.TestCase
   %TEST_ANOMALY Test the private anomaly helper with vector input.
   %
   % anomaly is private, so the tests reach it with
   % baseflow.privatefunction. aquifertrend passes a vector. A row or a
   % column vector gives column outputs relative to the nan-omitted mean.

   properties (TestParameter)
      % Each case holds the same data as a row or a column vector.
      data = struct( ...
         'column', {[2; 4; nan; 6]}, ...
         'row', {[2, 4, nan, 6]})
   end

   properties
      % The private anomaly function handle.
      anomaly
   end

   methods (TestClassSetup)
      function gethandle(testCase)
         % Store the private function handle once for every test.
         testCase.anomaly = baseflow.privatefunction('anomaly');
      end
   end

   methods (Test)
      function test_vectorGivesColumns(testCase, data)
         % The mean of 2, 4, and 6 is 4, so the anomalies are -2, 0, nan,
         % and 2, and the percent differences are -50, 0, nan, and 50.
         anoms_expected = [-2; 0; nan; 2];
         norms_expected = 4;
         pctdif_expected = [-50; 0; nan; 50];

         % A vector is not a matrix with more columns than rows, so it
         % raises no transpose warning.
         [anoms_returned, norms_returned, pctdif_returned] = ...
            testCase.verifyWarningFree(@() testCase.anomaly(data));

         testCase.verifyEqual(anoms_returned, anoms_expected)
         testCase.verifyEqual(norms_returned, norms_expected)
         testCase.verifyEqual(pctdif_returned, pctdif_expected)
      end
   end
end
