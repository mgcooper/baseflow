classdef test_todatenum < matlab.unittest.TestCase
   %TEST_TODATENUM Test baseflow/private/todatenum.

   properties (TestParameter)
      % Edge cases (Inf, NaN, very large/small numbers). Each is a numeric
      % input that is not a datetime.
      numericinput = struct('nan', NaN, 'inf', Inf, 'large', 1e200, ...
         'small', 1e-200)
   end

   properties
      % Test data: one datetime and the private todatenum function.
      T
      todatenum
   end

   methods (TestClassSetup)
      function setupdata(testCase)
         % Define test data
         testCase.T = datetime(1,1,1);
         testCase.todatenum = baseflow.privatefunction('todatenum');
      end
   end

   methods (Test)
      function test_oneInput(testCase)
         % Test function accuracy with one input
         expected = datenum(testCase.T); %#ok<*DATNM>
         returned = testCase.todatenum(testCase.T);
         testCase.verifyEqual(returned, expected)
      end

      function test_edgeCases(testCase, numericinput)
         % Test with edge cases (Inf, NaN, very large/small numbers).
         % todatenum returns an input that is not a datetime unchanged, so
         % the input is the theoretical result. verifyEqual treats NaN as
         % equal to NaN.
         expected = numericinput;
         returned = testCase.todatenum(numericinput);
         testCase.verifyEqual(returned, expected)
      end

      function test_multipleInputs(testCase)
         % Test function accuracy with multiple inputs: each datetime input
         % returns its datenum in the same output position.
         expected = repmat({datenum(testCase.T)}, 1, 3);
         returned = cell(1, 3);
         [returned{1}, returned{2}, returned{3}] = ...
            testCase.todatenum(testCase.T, testCase.T, testCase.T);
         testCase.verifyEqual(returned, expected)
      end
   end
end
