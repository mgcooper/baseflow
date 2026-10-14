function tests = test_specialfunctions
   %TEST_SPECIALFUNCTIONS Test the Rupp and Selker (2005) constants.
   %
   % For a homogeneous aquifer (n = 0) the late-time Rupp and Selker
   % constant reduces to the Brutsaert and Nieber (1977) constant 4.804,
   % which fitphi and aquiferprops use for the BS04 solution.
   tests = functiontests(localfunctions);
end

function test_lateTimeConstantAtHomogeneousLimit(testCase)
   % 4.804 is published to three decimals, so allow that rounding.
   expected = 4.804;
   tolerance = 1e-3;

   returned = baseflow.specialfunctions('fR2', 0);

   testCase.verifyEqual(returned, expected, 'RelTol', tolerance)
end
