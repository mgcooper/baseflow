classdef test_getstring < matlab.unittest.TestCase
   %TEST_GETSTRING Test the latex labels of baseflow.getstring.

   properties (TestParameter)
      % The variables whose latex label getstring returns.
      VarStr = {'Q','dQdt','aQb'};
   end

   methods (Test)

      %-------------------------------------------
      %-------------------------------------------
      function test_variableLabel(testCase,VarStr)

         switch VarStr
            case 'Q'
               expected = '$Q$';
            case 'dQdt'
               expected = '$-\mathrm{d}Q/\mathrm{d}t$';
            case 'aQb'
               expected = '$-\mathrm{d}Q/\mathrm{d}t = aQ^b$';
         end

         % Get actual result
         returned = baseflow.getstring(VarStr);

         % Verify that the actual result matches the expected result
         testCase.verifyEqual(returned,expected)
      end
   end
end
