classdef TestBfra < matlab.unittest.TestCase
   % TestBfra contains a set of 4 simple tests:
   %     1) an equality test for a bfra string variable
   %     2) an equality test for a leap year date
   %     3) a negative test for an invalid date format input
   %     4) a negative test for a correct date format but an invalid date
   %     5) an equality test for a non-leap year date using the alternate
   %        dateFormat (COMMENTED OUT)
   %
   % Notes:
   %     A) A negative test verifies that the code errors/fails in an
   %        expected way (e.g., the code gives the right error for a
   %        specific bad input)
   %     B) The 5th test is included for completeness, but is commented
   %        out to illustrate missing code coverage in continous
   %        integration (CI) systems

   methods (Test)

      function testBfraStrings(testCase)

      % define the test string
      teststr = 'aQb';

      % Calculate expected result
      strExpected = '$-\mathrm{d}Q/\mathrm{d}t = aQ^b$';

      % Get actual result
      strActual = bfra.getstring(teststr);

      % Verify that the two are equal
      testCase.verifyEqual(strActual,strExpected)

      end

      function testBfraDqdt(testCase)
      
      % define the test data
      T = transpose(1:10);
      Q = transpose(1:10);

      % Calculate expected result
      Qm1 = [nan; Q(1:end-1)]; % i minus 1
      dq = Q-Qm1;
      dt = (T(2)-T(1));
      dqdtExpected = dq./dt;


      % Get the actual result
      [~,dqdtActual] = bfra.getdqdt(T,Q,[],'CTS');
         
      % Verify that the two are equal
      testCase.verifyEqual(dqdtActual,dqdtExpected)
      end

   end

end

