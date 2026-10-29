function tests = test_setopts
   %TEST_SETOPTS Test the option defaults of baseflow.setopts.
   tests = functiontests(localfunctions);
end

function test_setopts_ctsmethod(testCase)

   % The fitevents options default to the traditional backward
   % first-order stencil
   returned = baseflow.setopts('fitevents');
   expected = 'B1';
   testCase.verifyEqual(returned.ctsmethod,expected);
end
