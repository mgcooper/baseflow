function tests = test_conversions
   %TEST_CONVERSIONS Test bfra.conversions.
   tests = functiontests(localfunctions);
end

function test_convert2b(testCase)
   % Test the conversions from one parameter to another for the 'isflat' condition
   tolerance = 0.001;
   testCase.verifyEqual(bfra.conversions(1.5, 'b', 'n', 'isflat', true), (3-2.*1.5)./(1.5-2), 'AbsTol',0.001,'Failed to convert b to n correctly');
   testCase.verifyEqual(bfra.conversions(1.5, 'n', 'b', 'isflat', true), (2.*1.5+3)./(1.5+2), 'AbsTol', tolerance,'Failed to convert n to b correctly');
   testCase.verifyEqual(bfra.conversions(2.0, 'b', 'd', 'isflat', true), 1./(2-2), 'AbsTol', tolerance,'Failed to convert b to d correctly');
   testCase.verifyEqual(bfra.conversions(1.5, 'b', 'k', 'isflat', true), (1.5-2)./(1-1.5), 'AbsTol', tolerance,'Failed to convert b to k correctly');
   testCase.verifyEqual(bfra.conversions(1.5, 'b', 'N', 'isflat', true), 3-2.*1.5, 'AbsTol', tolerance,'Failed to convert b to N correctly');
   testCase.verifyEqual(bfra.conversions(1.0, 'b', 'alpha', 'isflat', true), 1./(1-1), 'AbsTol', tolerance,'Failed to convert b to alpha correctly');
   testCase.verifyEqual(bfra.conversions(2.0, 'b', 'beta', 'isflat', true), 1./(2-2), 'AbsTol', tolerance,'Failed to convert b to beta correctly');
   testCase.verifyEqual(bfra.conversions(1.5, 'b', 'gamma', 'isflat', true), 1./(2.*1.5-3), 'AbsTol', tolerance,'Failed to convert b to gamma correctly');
end

function test_errorThrownForNonNumericInput(testCase)
   % Testing the function throws an error for non-numeric inputvalue
   testCase.verifyError(@()bfra.conversions('string', 'b', 'n'), 'MATLAB:InputParser:ArgumentFailedValidation');
end

function test_errorThrownForNonCharVarname(testCase)
   % Testing the function throws an error for non-char inputvarname
   testCase.verifyError(@()bfra.conversions(1.5, 123, 'n'), 'MATLAB:unrecognizedStringChoice');
end

function test_errorThrownForUnsupportedVarname(testCase)
   % Testing the function throws an error for unsupported inputvarname
   testCase.verifyError(@()bfra.conversions(1.5, 'unsupported', 'n'), 'MATLAB:unrecognizedStringChoice');
end
