classdef test_basinname < matlab.unittest.TestCase
   %TEST_BASINNAME Test the basin-name lookup of baseflow.basinname.

   properties (TestParameter)
      % Valid names from the basin database.
      BasinName = {'ALL_BASINS','KUPARUK R NR DEADHORSE AK'};
   end

   methods (Test)

      %-------------------------------------------
      %-------------------------------------------
      function test_validNameMapsToItself(testCase,BasinName)

         % get the basin name from the database
         returned = baseflow.basinname(BasinName);

         % A valid basin name maps to itself
         expected = BasinName;

         % Verify that the actual result matches the expected result
         testCase.verifyEqual(returned,expected);
      end
   end
end
